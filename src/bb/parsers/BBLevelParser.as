/**
 * User: VirtualMaestro
 * Date: 10.06.13
 * Time: 13:51
 */
package bb.parsers
{
	import bb.assets.BBAssetsManager;
	import bb.components.physics.BBPhysicsBody;
	import bb.components.physics.joints.BBJoint;
	import bb.components.renderable.BBMovieClip;
	import bb.components.renderable.BBRenderable;
	import bb.core.BBNode;
	import bb.pools.BBNativePool;
	import bb.signals.BBSignal;
	import bb.tools.physics.BBPhysicalMaterials;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;

	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;
	import nape.phys.BodyType;
	import nape.phys.FluidProperties;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.shape.Shape;

	import vm.classes.ClassUtil;
	import vm.debug.Assert;
	import vm.math.trigonometry.TrigUtil;
	import vm.str.StringUtil;

	/**
	 */
	public class BBLevelParser
	{
		/**
		 * Signal dispatches when some type of actor was parsed.
		 * It could be useful when need make some modifications for current type of actor (e.g. add additional components).
		 * Sends two parameters: class name of actor and actor itself (BBNode):
		 *  - signal.params.className;
		 *  - signal.params.actor;
		 */
		static public var onActorParsed:BBSignal = BBSignal.get();

		//
		static public var bodyTypeTable:Array = [];
		bodyTypeTable["STATIC"] = BodyType.STATIC;
		bodyTypeTable["DYNAMIC"] = BodyType.DYNAMIC;
		bodyTypeTable["KINEMATIC"] = BodyType.KINEMATIC;

		//
		static private var externalHandlersTable:Array = [];
		externalHandlersTable["actors::ActorScheme"] = externalActorHandler;

		//
		static private var internalHandlersTable:Array = [];
		internalHandlersTable["graphics::GraphicsScheme"] = internalGraphicsHandler;
		internalHandlersTable["shapes::BoxShapeScheme"] = internalShapesHandler;
		internalHandlersTable["shapes::CircleShapeScheme"] = internalShapesHandler;
		internalHandlersTable["actors::ActorScheme"] = internalActorHandler;

		internalHandlersTable["joints::PivotJointScheme"] = internalPivotHandler;
		internalHandlersTable["joints::DistanceJointScheme"] = internalDistanceHandler;
		internalHandlersTable["joints::WeldJointScheme"] = internalWeldHandler;
		internalHandlersTable["joints::LineJointScheme"] = internalLineHandler;
		internalHandlersTable["joints::MotorJointScheme"] = internalMotorHandler;
//		internalHandlersTable["joints::AngleJointScheme"] = internalActorHandler;

		//
		static private var _currentLevel:XML;

		/**
		 */
		static public function parseLevelSWF(p_levelSWF:MovieClip):XML
		{
			var levelAlias:String = getQualifiedClassName(p_levelSWF);
			var numChildren:int = p_levelSWF.numChildren;

			_currentLevel = <level alias={levelAlias}/>;

			var child:MovieClip;
			var childSuperClassName:String;
			var handler:Function;

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_levelSWF.getChildAt(i) as MovieClip;
				childSuperClassName = child.className; //getQualifiedSuperclassName(child);

				handler = externalHandlersTable[childSuperClassName];
				if (handler != null) handler(child);
			}

			return _currentLevel;
		}

		/**
		 */
		static private function externalActorHandler(p_actorScheme:MovieClip):void
		{
			var className:String = getQualifiedClassName(p_actorScheme);
			if (!BBNode.isCacheExist(className))
			{
				var actor:BBNode = internalActorHandler(p_actorScheme, null, null);
				onActorParsed.dispatch({className: className, actor: actor});
				BBNode.addCache(actor, className);
			}

			var actorXML:XML = <actor/>;
			actorXML.alias = className;
			actorXML.type = p_actorScheme.actorType;
			actorXML.position = p_actorScheme.x + "," + p_actorScheme.y;
			actorXML.rotation = p_actorScheme.rotation * TrigUtil.DEG_TO_RAD;
			actorXML.scale = p_actorScheme.scaleX + "," + p_actorScheme.scaleY;
			actorXML.layer = String(p_actorScheme.layerName).toLowerCase();
			actorXML.internalCollision = p_actorScheme.isCollisionInternalActors;

			if (!_currentLevel.hasOwnProperty("actors"))
			{
				_currentLevel.actors = <actors/>;
			}

			_currentLevel.actors.appendChild(actorXML);
		}

		/**
		 */
		static private function internalGraphicsHandler(p_graphics:MovieClip, p_actorScheme:MovieClip, p_actor:BBNode):void
		{
			var renderableComponent:BBRenderable = parseGraphics(p_graphics);
			renderableComponent.allowRotation = p_actorScheme.graphicsRotation;
			p_actor.addComponent(renderableComponent);
		}

		/**
		 */
		static private function internalShapesHandler(p_shape:MovieClip, p_actorScheme:MovieClip, p_actor:BBNode):void
		{
			var body:BBPhysicsBody;
			if (!p_actor.isComponentExist(BBPhysicsBody))
			{
				body = BBPhysicsBody.get(bodyTypeTable[p_actorScheme.actorType]);
				body.body.allowMovement = p_actorScheme.allowMovement;
				body.body.allowRotation = p_actorScheme.allowRotation;
				body.allowHand = p_actorScheme.useHand;
				body.isBullet = p_actorScheme.isBullet;
				p_actor.addComponent(body);
			}
			else body = p_actor.getComponent(BBPhysicsBody) as BBPhysicsBody;

			body.addShape(parseShape(p_shape));
		}

		/**
		 */
		static private function internalActorHandler(p_actorScheme:MovieClip, p_parentActorScheme:MovieClip, p_parentActor:BBNode):BBNode
		{
			var childActor:BBNode;
			if (p_parentActor)
			{
				var sameType:Boolean = p_parentActorScheme.sameTypeForChildren;
				if (sameType)
				{
					(p_actorScheme as Object).sameTypeForChildren = sameType;
					(p_actorScheme as Object).actorType = p_parentActorScheme.actorType;
				}

				childActor = parseActor(p_actorScheme);
				p_parentActor.addChild(childActor);
			}
			else childActor = parseActor(p_actorScheme);

			return childActor;
		}

		/**
		 */
		static private function internalPivotHandler(p_pivotScheme:MovieClip, p_actorScheme:MovieClip, p_parentActor:BBNode):void
		{
			var jointedActorName:String = StringUtil.trim(p_pivotScheme.jointedActorName);
			var ownerAnchor:Vec2 = Vec2.weak(p_pivotScheme.x, p_pivotScheme.y);
			var jointedActor:MovieClip = findInternalActor(jointedActorName, p_actorScheme);

			CONFIG::debug
			{
				Assert.isTrue(jointedActor != null, "Internal actor with name '" + jointedActorName + "' doesn't exist. Error in joint's options", "BBLevelParser.internalPivotHandler");
			}

			var jointedAnchor:Vec2 = jointedActorName == "" ? null : getLocalPosition(p_pivotScheme, jointedActor);

			var pivotJoint:BBJoint = BBJoint.pivotJoint(jointedActorName, ownerAnchor, jointedAnchor);
			parseBaseJointProps(p_pivotScheme, pivotJoint);

			(p_parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(pivotJoint);
		}

		/**
		 */
		static private function internalDistanceHandler(p_distanceScheme:MovieClip, p_actorScheme:MovieClip, p_parentActor:BBNode):void
		{
			var jointName:String = p_distanceScheme.jointName;
			var jointedActorName:String = StringUtil.trim(p_distanceScheme.jointedActorName);

			var ownerAnchor:Vec2 = Vec2.weak(p_distanceScheme.x, p_distanceScheme.y);
			var jointedActor:MovieClip = findInternalActor(jointedActorName, p_actorScheme);
			var endJoint:MovieClip = findEndJoint(jointName, p_actorScheme);

			CONFIG::debug
			{
				Assert.isTrue(jointedActor != null, "Internal actor with name '" + jointedActorName + "' doesn't exist. Error in joint's options", "BBLevelParser.internalDistanceHandler");
				Assert.isTrue(endJoint != null, "End jointwith name '" + jointName + "' couldn't find. Maybe forgotten to put it", "BBLevelParser.internalDistanceHandler");
			}

			var jointedAnchor:Vec2 = jointedActorName == "" ? null : getLocalPosition(endJoint, jointedActor);
			var jointMinMax:Array = p_distanceScheme.jointMinMax;
			var distanceJoint:BBJoint = BBJoint.distanceJoint(jointedActorName, ownerAnchor, jointedAnchor, jointMinMax[0], jointMinMax[1]);
			parseBaseJointProps(p_distanceScheme, distanceJoint);

			(p_parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(distanceJoint);
		}

		/**
		 */
		static private function internalLineHandler(p_lineScheme:MovieClip, p_actorScheme:MovieClip, p_parentActor:BBNode):void
		{
			var jointName:String = p_lineScheme.jointName;
			var jointedActorName:String = StringUtil.trim(p_lineScheme.jointedActorName);

			var ownerAnchor:Vec2 = Vec2.weak(p_lineScheme.x, p_lineScheme.y);
			var jointedActor:MovieClip = findInternalActor(jointedActorName, p_actorScheme);
			var endJoint:MovieClip = findEndJoint(jointName, p_actorScheme);

			CONFIG::debug
			{
				Assert.isTrue(jointedActor != null, "Internal actor with name '" + jointedActorName + "' doesn't exist. Error in joint's options", "BBLevelParser.internalDistanceHandler");
				Assert.isTrue(endJoint != null, "End joint with name '" + jointName + "' couldn't find. Maybe forgotten to put it", "BBLevelParser.internalDistanceHandler");
			}

			var jointedAnchor:Vec2 = jointedActorName == "" ? null : getLocalPosition(endJoint, jointedActor);
			var jointMinMax:Array = p_lineScheme.jointMinMax;
			var radRotation:Number = p_lineScheme.rotation*TrigUtil.DEG_TO_RAD;
			var direction:Vec2 = Vec2.weak(Math.cos(radRotation), Math.sin(radRotation));
			var lineJoint:BBJoint = BBJoint.lineJoint(jointedActorName, ownerAnchor, jointedAnchor, direction, jointMinMax[0], jointMinMax[1]);
			parseBaseJointProps(p_lineScheme, lineJoint);

			(p_parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(lineJoint);
		}

		/**
		 */
		static private function internalWeldHandler(p_weldScheme:MovieClip, p_actorScheme:MovieClip, p_parentActor:BBNode):void
		{
			var jointedActorName:String = StringUtil.trim(p_weldScheme.jointedActorName);
			var ownerAnchor:Vec2 = Vec2.weak(p_weldScheme.x, p_weldScheme.y);
			var jointedActor:MovieClip = findInternalActor(jointedActorName, p_actorScheme);

			CONFIG::debug
			{
				Assert.isTrue(jointedActor != null, "Internal actor with name '" + jointedActorName + "' doesn't exist. Error in joint's options", "BBLevelParser.internalWeldHandler");
			}

			var jointedAnchor:Vec2 = jointedActorName == "" ? null : getLocalPosition(p_weldScheme, jointedActor);

			var weldJoint:BBJoint = BBJoint.weldJoint(jointedActorName, ownerAnchor, jointedAnchor, p_weldScheme.phase*TrigUtil.DEG_TO_RAD);
			parseBaseJointProps(p_weldScheme, weldJoint);

			(p_parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(weldJoint);
		}

		/**
		 */
		static private function internalMotorHandler(p_motorScheme:MovieClip, p_actorScheme:MovieClip, p_parentActor:BBNode):void
		{
			var jointedActorName:String = StringUtil.trim(p_motorScheme.jointedActorName);
			var motorJoint:BBJoint = BBJoint.motorJoint(jointedActorName, p_motorScheme.rate, p_motorScheme.ratio);
			parseBaseJointProps(p_motorScheme, motorJoint);

			(p_parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(motorJoint);
		}

		/**
		 */
		static private function parseBaseJointProps(p_jointScheme:MovieClip, p_joint:BBJoint):void
		{
			p_joint.name = p_jointScheme.jointName;
			p_joint.ignore = p_jointScheme.ignore;
			p_joint.active = p_jointScheme.active;
			p_joint.stiff = p_jointScheme.stiff;
			p_joint.frequency = p_jointScheme.frequency;
			p_joint.damping = p_jointScheme.damping;
			p_joint.maxForce = p_jointScheme.maxForce;
			p_joint.maxError = p_jointScheme.maxError;
			p_joint.removeOnBreak = p_jointScheme.removeOnBreak;
			p_joint.breakUnderForce = p_jointScheme.breakUnderForce;
			p_joint.breakUnderError = p_jointScheme.breakUnderError;
		}

		/**
		 */
		static private function findInternalActor(p_actorName:String, p_parentActor:MovieClip):MovieClip
		{
			if (p_actorName != "")
			{
				var numChildren:int = p_parentActor.numChildren;
				var child:DisplayObject;
				for (var i:int = 0; i < numChildren; i++)
				{
					child = p_parentActor.getChildAt(i);
					if (child.hasOwnProperty("actorName"))
					{
						var actor:MovieClip = child as MovieClip;
						if (actor.actorName == p_actorName) return actor;
					}
				}
			}

			return null;
		}

		/**
		 */
		static private function findEndJoint(p_endJointName:String, p_parentActor:MovieClip):MovieClip
		{
			var numChildren:int = p_parentActor.numChildren;
			var child:DisplayObject;
			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_parentActor.getChildAt(i);
				if (child.hasOwnProperty("jointName") && !child.hasOwnProperty("stiff"))
				{
					var actor:MovieClip = child as MovieClip;
					if (actor.jointName == p_endJointName) return actor;
				}
			}

			return null;
		}

		/**
		 */
		static private function getLocalPosition(p_joint:MovieClip, p_actor:MovieClip):Vec2
		{
			var localPoint:Point = BBNativePool.getPoint(p_joint.x, p_joint.y);
			var globalPoint:Point = p_joint.parent.localToGlobal(localPoint);
			BBNativePool.putPoint(localPoint);
			localPoint = p_actor.globalToLocal(globalPoint);
			var localPosition:Vec2 = Vec2.fromPoint(localPoint, true);
			BBNativePool.putPoint(localPoint);
			BBNativePool.putPoint(globalPoint);

			return localPosition;
		}

		/**
		 */
		[Inline]
		static private function parseActor(p_actorScheme:MovieClip):BBNode
		{
			var node:BBNode = BBNode.get(p_actorScheme.actorName);
			node.transform.setPositionAndRotation(p_actorScheme.x, p_actorScheme.y, p_actorScheme.rotation * TrigUtil.DEG_TO_RAD);
			node.transform.setScale(p_actorScheme.scaleX, p_actorScheme.scaleY);

			var internalJoints:Array;
			var numChildren:int = p_actorScheme.numChildren;
			var child:MovieClip;
			var childSuperClassName:String;
			var handler:Function;

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_actorScheme.getChildAt(i) as MovieClip;
				childSuperClassName = child.className; //getQualifiedSuperclassName(child);

				if (childSuperClassName.indexOf("joints::") != -1)
				{
					if (internalJoints == null) internalJoints = [];
					internalJoints.push(child);
					continue;
				}

				handler = internalHandlersTable[childSuperClassName];
				if (handler != null) handler(child, p_actorScheme, node);
			}

			// if internal joints exist
			if (internalJoints)
			{
				var numJoints:int = internalJoints.length;
				for (i = 0; i < numJoints; i++)
				{
					child = internalJoints[i];
					childSuperClassName = child.className; //getQualifiedSuperclassName(child);
					handler = internalHandlersTable[childSuperClassName];
					if (handler != null) handler(child, p_actorScheme, node);
				}
			}

			return node;
		}

		/**
		 */
		[Inline]
		static private function parseGraphics(p_graphics:MovieClip):BBRenderable
		{
			var assetId:String = getQualifiedClassName(p_graphics);

			if (!BBAssetsManager.isAssetExist(assetId))
			{
				assetId = BBAssetsManager.add(p_graphics, assetId);
				BBAssetsManager.initAssets(true);
			}

			var renderComponent:BBRenderable = BBAssetsManager.getRenderableByName(assetId);
			if (renderComponent is BBMovieClip)
			{
				var movie:BBMovieClip = renderComponent as BBMovieClip;
				movie.frameRate = p_graphics.frameRate;
				p_graphics.playFrom > 0 ? movie.gotoAndPlay(p_graphics.playFrom) : movie.stop();
			}

			renderComponent.scaleX = p_graphics.scaleX;
			renderComponent.scaleY = p_graphics.scaleY;
			renderComponent.offsetX = p_graphics.x;
			renderComponent.offsetY = p_graphics.y;
			renderComponent.offsetRotation = p_graphics.rotation * TrigUtil.DEG_TO_RAD;

			return renderComponent;
		}

		/**
		 */
		[Inline]
		static private function parseShape(p_shape:MovieClip):Shape
		{
			// init material
			var material:Material;
			var predefineMaterial:String = String(p_shape.materialPredefine).toLowerCase();
			if (predefineMaterial != "none") material = BBPhysicalMaterials.getByName(predefineMaterial);
			else material = new Material(p_shape.elasticity, p_shape.dynamicFriction, p_shape.staticFriction, p_shape.density, p_shape.rollingFriction);

			// init interaction filter
			var filter:InteractionFilter = new InteractionFilter(p_shape.collisionGroup, p_shape.collisionMask, p_shape.sensorGroup, p_shape.sensorMask,
					p_shape.fluidGroup, p_shape.fluidMask);

			var className:String = ClassUtil.getClassNameWithoutPackage(p_shape, true);
			var shape:Shape;

			if (className == "CircleShapeScheme") shape = new Circle(p_shape.width / 2, Vec2.weak(p_shape.x, p_shape.y), material, filter);
			else if (className == "BoxShapeScheme") shape = new Polygon(Polygon.box(p_shape.width, p_shape.height, true), material, filter);
//			else Polygon;

			shape.rotate(p_shape.rotation * TrigUtil.DEG_TO_RAD);
			shape.fluidEnabled = p_shape.fluidEnable;

			if (shape.fluidEnabled)
			{
				shape.fluidProperties = new FluidProperties(p_shape.fluidDensity, p_shape.viscosity);
				var gravity:Array = p_shape.fluidGravity;
				if (gravity) shape.fluidProperties.gravity = Vec2.weak(gravity[0], gravity[1]);
			}

			return shape;
		}
	}
}
