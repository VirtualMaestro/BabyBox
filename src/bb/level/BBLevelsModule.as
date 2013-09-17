/**
 * User: VirtualMaestro
 * Date: 11.06.13
 * Time: 15:38
 */
package bb.level
{
	import bb.camera.BBCamerasModule;
	import bb.camera.components.BBCamera;
	import bb.core.BBNode;
	import bb.layer.BBLayerModule;
	import bb.level.parsers.BBLevelParser;
	import bb.modules.*;
	import bb.physics.components.BBPhysicsBody;
	import bb.physics.joints.BBJoint;
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
				layers = getVectorXMLLayersSortedByDeepIndex(layersHasCamera, false);
				i = 0;
				infiniteCounter = 0;
				var dependOnCamera:BBCamera;
				while (layers.length > 0)
				{
					layerXML = layers[i];
					layerName = layerXML.elements("name");
					dependOnCameraName = layerXML.elements("dependOnCamera");

					if (dependOnCameraName == "none")  // independent camera
					{
						_layerModule.get(layerName).attachCamera(BBCamera.get(layerName));
						layers.splice(i, 1);
						--i;
					}
					else   // dependent camera
					{
						dependOnCamera = _layerModule.get(dependOnCameraName).camera;
						if (dependOnCamera)
						{
							camera = BBCamera.get(layerName);
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

			// creates actors
			var actorsList:XMLList = level.actors.children();
			var actorXML:XML;
			var actor:BBNode;
			var actorAlias:String;
			var actorName:String;
			var actorPosition:Array;
			var actorRotation:Number;
			var actorScale:Array;
			var actorLayer:String;
			var actorInternalCollision:Boolean;
			var actorType:String;
			var actorsWithNameTable:Array = [];
			var numActors:int = actorsList.length();

			for (i = 0; i < numActors; i++)
			{
				actorXML = actorsList[i];

				actorAlias = actorXML.elements("alias");
				actorName = actorXML.elements("name");
				actorType = actorXML.elements("type");
				actorPosition = String(actorXML.elements("position")).split(",");
				actorRotation = actorXML.elements("rotation");
				actorScale = String(actorXML.elements("scale")).split(",");
				actorLayer = actorXML.elements("layer");
				actorInternalCollision = actorXML.elements("internalCollision") == "true";

				actor = BBNode.getFromCache(actorAlias);
				actor.name = actorName;
				if (actorName != "") actorsWithNameTable[actorName] = actor;
				actor.transform.setPositionAndRotation(actorPosition[0], actorPosition[1], actorRotation);
				actor.transform.setScale(actorScale[0], actorScale[1]);

				if (actor.isComponentExist(BBPhysicsBody))
				{
					var physicsComponent:BBPhysicsBody = actor.getComponent(BBPhysicsBody) as BBPhysicsBody;
					physicsComponent.type = BBLevelParser.bodyTypeTable[actorType];
					physicsComponent.childrenCollision = actorInternalCollision;
				}

				_world.add(actor, actorLayer);
			}

			//
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
			else return 1;
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
