/**
 * User: VirtualMaestro
 * Date: 11.06.13
 * Time: 15:38
 */
package bb.level
{
	import bb.assets.BBAssetsManager;
	import bb.camera.BBCamerasModule;
	import bb.camera.components.BBCamera;
	import bb.core.BBNode;
	import bb.layer.BBLayerModule;
	import bb.level.parsers.BBLevelParser;
	import bb.modules.*;
	import bb.physics.components.BBPhysicsBody;
	import bb.physics.joints.BBJoint;
	import bb.render.components.BBMovieClip;
	import bb.render.components.BBRenderable;
	import bb.signals.BBSignal;
	import bb.world.BBWorldModule;

	import flash.display.MovieClip;
	import flash.utils.Dictionary;

	import vm.debug.Assert;

	/**
	 * Manager of creating and destroying levels.
	 */
	public class BBLevelsModule extends BBModule
	{
		//
		private var _onLevelComplete:BBSignal;

		//
		private var _levelsCache:Dictionary;
		private var _world:BBWorldModule;
		private var _layerModule:BBLayerModule;
		private var _cameraModule:BBCamerasModule;

		/**
		 */
		public function BBLevelsModule()
		{
			super();

			_levelsCache = new Dictionary();
			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			_world = getModule(BBWorldModule) as BBWorldModule;
			_layerModule = getModule(BBLayerModule) as BBLayerModule;
			_cameraModule = getModule(BBCamerasModule) as BBCamerasModule;
		}

		/**
		 */
		public function createLevelFromMC(p_level:Class):void
		{
			var level:XML = _levelsCache[p_level];
			if (level == null)
			{
				var levelMC:MovieClip = new p_level();
				level = BBLevelParser.parseLevelSWF(levelMC);
				levelMC = null;
				_levelsCache[p_level] = level;
			}

			// creates levels
			if (level.hasOwnProperty("layers"))
			{
				var layersXMLList:XMLList = level.layers.children();
				var layerXML:XML;
				var layerName:String;
				var numLayers:int;
				var camera:BBCamera;
				var dependOnCameraName:String;
				var dependOffset:Array;

				var layersIndependent:XMLList = layersXMLList.(addToLayer == "none");
				var layersDependent:XMLList = layersXMLList.(addToLayer != "none");
				var layersHasCamera:XMLList = layersIndependent.(attachCamera == "true");

				// adds all independent layers
				var layers:Vector.<XML> = getVectorXMLLayersSortedByDeepIndex(layersIndependent);
				numLayers = layers.length;
				for (var i:int = 0; i < numLayers; i++)
				{
					layerXML = layers[i];
					_layerModule.add(String(layerXML.elements("name")), true);
				}

				// adds all dependent layers
				layers = getVectorXMLLayersSortedByDeepIndex(layersDependent);
				var addToLayerName:String;
				var infiniteCounter:uint = 0;
				i = 0;
				while (layers.length > 0)
				{
					layerXML = layers[i];
					addToLayerName = layerXML.elements("addToLayer");

					if (_layerModule.isExist(addToLayerName))
					{
						_layerModule.addTo(layerXML.elements("name"), addToLayerName);
						layers.splice(i, 1);
						--i;
					}

					if (++i >= layers.length) i = 0;

					CONFIG::debug
					{
						++infiniteCounter;
						Assert.isTrue(infiniteCounter < 1000, "Infinite loop during creating depending layers. Cause: seems like some layers to which dependent layers should be added doesn't exist", "BBLevelsModule.createLevelFromMC");
					}
				}

				// adds all cameras
				layers = getVectorXMLLayersSortedByDeepIndex(layersHasCamera);
				i = 0;
				infiniteCounter = 0;
				var dependOnCamera:BBCamera;
				var position:Array;
				var camX:Number;
				var camY:Number;
				var cameraMouseEnable:Boolean;
				while (layers.length > 0)
				{
					layerXML = layers[i];
					layerName = layerXML.elements("name");
					dependOnCameraName = layerXML.elements("dependOnCamera");

					if (dependOnCameraName == "none")  // independent camera
					{
						position = String(layerXML.elements("cameraPosition")).split(",");
						camX = parseFloat(position[0]);
						camY = parseFloat(position[1]);
						cameraMouseEnable = layerXML.elements("cameraMouseEnable") == "true";
						camera = BBCamera.get(layerName);
						camera.node.transform.setPosition(camX, camY);
						camera.mouseEnable = cameraMouseEnable;
						_layerModule.get(layerName).attachCamera(camera);
						layers.splice(i, 1);
						--i;
					}
					else   // dependent camera
					{
						dependOnCamera = _layerModule.get(dependOnCameraName).camera;
						if (dependOnCamera)
						{
							position = String(layerXML.elements("cameraPosition")).split(",");
							camX = parseFloat(position[0]);
							camY = parseFloat(position[1]);
							cameraMouseEnable = layerXML.elements("cameraMouseEnable") == "true";
							camera = BBCamera.get(layerName);
							camera.node.transform.setPosition(camX, camY);
							camera.mouseEnable = cameraMouseEnable;
							dependOffset = String(layerXML.elements("dependOffset")).split(",");
							camera.dependOnCamera(dependOnCamera, dependOffset[0], dependOffset[1], dependOffset[2]);
							_layerModule.get(layerName).attachCamera(camera);
							layers.splice(i, 1);
							--i;
						}
					}

					if (++i >= layers.length) i = 0;

					CONFIG::debug
					{
						++infiniteCounter;
						Assert.isTrue(infiniteCounter < 1000, "Infinite loop during creating cameras. Cause: seems like some 'dependentOn' cameras doesn't exist", "BBLevelsModule.createLevelFromMC");
					}
				}
			}

			// combine all entities which should be added to world into one vector
			var addingToWorldEntities:Vector.<XML> = uniteXMLListsToVectorXML(level.actors.children(), level.externalGraphics.children());
			addingToWorldEntities.sort(sortByDeepIndex); // sort them by deep index

			// creates actors
			var actorXML:XML;
			var actor:BBNode;
			var actorsWithNameTable:Array = [];
			var numActors:int = addingToWorldEntities.length;

			for (i = 0; i < numActors; i++)
			{
				actorXML = addingToWorldEntities[i];
				trace("actorXML.name(): " + actorXML.name());
				if (actorXML.name() == "actor")
				{
					actor = createActorByXML(actorXML);
					if (actor.name != "") actorsWithNameTable[actor.name] = actor;
				}
				else  // this is graphics
				{
					actor = createGraphicsByXML(actorXML);
				}

				_world.add(actor, actorXML.elements("layer"));
			}

			// creates external joints
			var externalJointList:XMLList = level.externalJoints.children();
			var externalJoint:XML;
			var ownerActorName:String;
			var joint:BBJoint;
			var numExternalJoints:int = externalJointList.length();
			for (i = 0; i < numExternalJoints; i++)
			{
				externalJoint = externalJointList[i];
				joint = BBJoint.getFromPrototype(externalJoint);
				ownerActorName = externalJoint.ownerActorName;
				actor = actorsWithNameTable[ownerActorName];
				(actor.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(joint);
			}

			//
			if (_onLevelComplete) _onLevelComplete.dispatch();
		}

		/**
		 */
		static private function createActorByXML(p_actorXML:XML):BBNode
		{
			var actor:BBNode = BBNode.getFromCache(p_actorXML.elements("alias"));
			actor.name = p_actorXML.elements("name");

			var actorPosition:Array = String(p_actorXML.elements("position")).split(",");
			var actorScale:Array = String(p_actorXML.elements("scale")).split(",");

			actor.transform.setPositionAndRotation(actorPosition[0], actorPosition[1], p_actorXML.elements("rotation"));
			actor.transform.setScale(actorScale[0], actorScale[1]);

			if (actor.isComponentExist(BBPhysicsBody))
			{
				var physicsComponent:BBPhysicsBody = actor.getComponent(BBPhysicsBody) as BBPhysicsBody;
				physicsComponent.type = BBLevelParser.bodyTypeTable[p_actorXML.elements("type")];
				physicsComponent.childrenCollision = p_actorXML.elements("internalCollision") == "true";
			}

			return actor;
		}

		/**
		 */
		static private function createGraphicsByXML(p_graphicsXML:XML):BBNode
		{
			var graphics:BBNode = BBNode.get(p_graphicsXML.elements("name"));
			var renderable:BBRenderable = BBAssetsManager.getRenderableById(p_graphicsXML.elements("alias"));

			if (renderable is BBMovieClip)
			{
				(renderable as BBMovieClip).frameRate = parseInt(p_graphicsXML.elements("frameRate"));
				var playFrom:int = parseInt(p_graphicsXML.elements("playFrom"));
				if (playFrom > 0) (renderable as BBMovieClip).gotoAndPlay(playFrom);
			}

			graphics.addComponent(renderable);
			var position:Array = String(p_graphicsXML.elements("position")).split(",");
			graphics.transform.setPositionAndRotation(parseFloat(position[0]), parseFloat(position[1]), parseFloat(p_graphicsXML.elements("rotation")));

			return graphics;
		}

		/**
		 */
		static private function uniteXMLListsToVectorXML(...xmlLists):Vector.<XML>
		{
			var vector:Vector.<XML> = new <XML>[];
			var numLists:int = xmlLists.length;
			var numNodes:int;
			var list:XMLList;

			for (var i:int = 0; i < numLists; i++)
			{
				list = xmlLists[i];
				numNodes = list.length();

				for (var j:int = 0; j < numNodes; j++)
				{
					vector.push(list[j]);
				}
			}

			return vector;
		}

		/**
		 */
		static private function sortByDeepIndex(p_x:XML, p_y:XML):int
		{
			var deepX:int = parseInt(p_x.elements("deepIndex"));
			var deepY:int = parseInt(p_y.elements("deepIndex"));

			if (deepX < deepY) return -1;
			else if (deepX == deepY) return 0;

			return 1;
		}

		/**
		 */
		static private function getVectorXMLLayersSortedByDeepIndex(p_layers:XMLList, p_isNeedSort:Boolean = true):Vector.<XML>
		{
			var layers:Vector.<XML> = new <XML>[];
			var numLayers:int = p_layers.length();
			for (var i:int = 0; i < numLayers; i++)
			{
				layers[i] = p_layers[i];
			}

			if (p_isNeedSort) layers.sort(compare);

			return layers;
		}

		/**
		 */
		static private function compare(p_x:XML, p_y:XML):int
		{
			var xIndex:int = parseInt(p_x.elements("layerIndex"));
			var yIndex:int = parseInt(p_y.elements("layerIndex"));

			if (xIndex < yIndex) return -1;
			else if (xIndex == yIndex) return 0;

			return 1;
		}

		/**
		 * Dispatches when level constructed.
		 */
		public function get onLevelComplete():BBSignal
		{
			if (!_onLevelComplete) _onLevelComplete = BBSignal.get(this);
			return _onLevelComplete;
		}
	}
}
