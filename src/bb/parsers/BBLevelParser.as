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
		static public var bodyTypeTable:Array = [];
		bodyTypeTable["STATIC"] = BodyType.STATIC;
		bodyTypeTable["DYNAMIC"] = BodyType.DYNAMIC;
		bodyTypeTable["KINEMATIC"] = BodyType.KINEMATIC;

		/**
		 */
		static public function parseLevelSWF(p_levelSWF:MovieClip):XML
		{
			var levelAlias:String = getQualifiedClassName(p_levelSWF);
			var numChildren:int = p_levelSWF.numChildren;

			var levelXML:XML = <level alias={levelAlias}/>;
			var actorsListXML:XML = <actors/>;

			var child:MovieClip;
			var childClassName:String;
			var childSuperClassName:String;

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_levelSWF.getChildAt(i) as MovieClip;
				childClassName = getQualifiedClassName(child);
				childSuperClassName = getQualifiedSuperclassName(child);

				switch (childSuperClassName)
				{
					case "actors::ActorScheme":
					{
						if (!BBNode.isCacheExist(childClassName))
						{
							var actorPattern:BBNode = parseActor(child);
							BBNode.addCache(actorPattern, childClassName);
						}

						var actorXML:XML = <actor/>;
						actorXML.alias = childClassName;
						actorXML.type = child.actorType;
						actorXML.position = child.x + "," + child.y;
						actorXML.rotation = child.rotation * TrigUtil.DEG_TO_RAD;
						actorXML.scale = child.scaleX + "," + child.scaleY;
						actorXML.layer = String(child.layerName).toLowerCase();
						actorXML.internalCollision = child.isCollisionInternalActors;
						actorsListXML.appendChild(actorXML);

						break;
					}

//					case "worlds::WorldScheme":
//					{
//						break;
//					}
				}
			}

			levelXML.appendChild(actorsListXML);
			trace(levelXML.toXMLString());

			return levelXML;
		}

		//
		static private var parserHandlersTable:Array = [];
		parserHandlersTable["graphics::GraphicsScheme"] = graphicsHandler;
		parserHandlersTable["shapes::BaseShapeScheme"] = shapesHandler;
		parserHandlersTable["shapes::BoxShapeScheme"] = shapesHandler;
		parserHandlersTable["shapes::CircleShapeScheme"] = shapesHandler;

		/**
		 */
		static private function parseActor(p_actor:MovieClip):BBNode
		{
			var numChildren:int = p_actor.numChildren;
			var child:MovieClip;
			var childSuperClassName:String;
			var node:BBNode = BBNode.get(p_actor.actorName);
			node.transform.setPositionAndRotation(p_actor.x, p_actor.y, p_actor.rotation * TrigUtil.DEG_TO_RAD);
			node.transform.setScale(p_actor.scaleX, p_actor.scaleY);

			var sameTypeForChildren:Boolean = p_actor.sameTypeForChildren;
			var body:BBPhysicsBody;
			var bodyType:BodyType = bodyTypeTable[p_actor.actorType];

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_actor.getChildAt(i) as MovieClip;
				childSuperClassName = getQualifiedSuperclassName(child);

				switch (childSuperClassName)
				{
					case "graphics::GraphicsScheme":
					{
						var renderableComponent:BBRenderable = parseGraphics(child);
						renderableComponent.allowRotation = p_actor.graphicsRotation;
						node.addComponent(renderableComponent);
						break;
					}

					case "shapes::BaseShapeScheme":
					case "shapes::BoxShapeScheme":
					case "shapes::CircleShapeScheme":
					{
						if (body == null)
						{
							body = BBPhysicsBody.get(bodyType);
							body.body.allowMovement = p_actor.allowMovement;
							body.body.allowRotation = p_actor.allowRotation;
							body.allowHand = p_actor.useHand;
							node.addComponent(body);
						}

						body.addShape(parseShape(child));
						break;
					}

					case "actors::ActorScheme":
					{
						if (sameTypeForChildren)
						{
							child.sameTypeForChildren = true;
							child.actorType = p_actor.actorType;
						}

						node.addChild(parseActor(child));
						break;
					}

					default :
					{
						if (childSuperClassName.indexOf("joint"))
						{

						}
					}
				}
			}

			return node;
		}

		/**
		 */
		static private function graphicsHandler(p_graphics:MovieClip, p_actorScheme:MovieClip, p_actor:BBNode):void
		{
			var renderableComponent:BBRenderable = parseGraphics(p_graphics);
			renderableComponent.allowRotation = p_actorScheme.graphicsRotation;
			p_actor.addComponent(renderableComponent);
		}

		/**
		 */
		static private function shapesHandler(p_shape:MovieClip, p_actorScheme:MovieClip, p_actor:BBNode):void
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
