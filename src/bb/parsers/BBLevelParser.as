/**
 * User: VirtualMaestro
 * Date: 10.06.13
 * Time: 13:51
 */
package bb.parsers
{
	import bb.assets.BBAssetsManager;
	import bb.components.physics.BBPhysicsBody;
	import bb.components.renderable.BBMovieClip;
	import bb.components.renderable.BBRenderable;
	import bb.core.BBNode;
	import bb.signals.BBSignal;
	import bb.tools.physics.BBPhysicalMaterials;

	import flash.display.MovieClip;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;

	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;
	import nape.phys.BodyType;
	import nape.phys.FluidProperties;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.shape.Shape;

	import vm.classes.ClassUtil;
	import vm.math.trigonometry.TrigUtil;

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
				childSuperClassName = getQualifiedSuperclassName(child);

				handler = externalHandlersTable[childSuperClassName];
				if (handler) handler(child);
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
		[Inline]
		static private function parseActor(p_actorScheme:MovieClip):BBNode
		{
			var node:BBNode = BBNode.get(p_actorScheme.actorName);
			node.transform.setPositionAndRotation(p_actorScheme.x, p_actorScheme.y, p_actorScheme.rotation * TrigUtil.DEG_TO_RAD);
			node.transform.setScale(p_actorScheme.scaleX, p_actorScheme.scaleY);

			var numChildren:int = p_actorScheme.numChildren;
			var child:MovieClip;
			var childSuperClassName:String;
			var handler:Function;

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_actorScheme.getChildAt(i) as MovieClip;
				childSuperClassName = getQualifiedSuperclassName(child);
				handler = internalHandlersTable[childSuperClassName];
				if (handler) handler(child, p_actorScheme, node);
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
