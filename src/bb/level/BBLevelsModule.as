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
	import bb.layer.BBLayer;
	import bb.layer.BBLayerModule;
	import bb.level.parsers.BBLevelParser;
	import bb.modules.*;
	import bb.physics.components.BBPhysicsBody;
	import bb.physics.joints.BBJoint;
	import bb.signals.BBSignal;
	import bb.world.BBWorldModule;

	import flash.display.MovieClip;
	import flash.utils.Dictionary;

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
				var layer:BBLayer;
				var layerName:String;
				var numLayers:int;
				var camera:BBCamera;
				var dependOnCameraName:String;
				var dependOffset:Array;

				var layersIndependent:XMLList = layersXMLList.(addToLayer == "none");
				var layersHasCamera:XMLList = layersIndependent.(attachCamera == "true");
				var layersCameraIndependent:XMLList = layersHasCamera.(dependOnCamera == "none");
				var layersCameraDependent:XMLList = layersHasCamera.(dependOnCamera != "none");

				// creates independent layers with independent cameras
				numLayers = layersCameraIndependent.length();
				for (var j:int = 0; j < numLayers; j++)
				{
					layerXML = layersCameraIndependent[j];

					layerName = String(layerXML.elements("name"));
					_layerModule.add(layerName, true).attachCamera(BBCamera.get(layerName));
				}

				// creates independent layers with dependent cameras
				numLayers = layersCameraDependent.length();
				for (j = 0; j < numLayers; j++)
				{
					layerXML = layersCameraDependent[j];

					layerName = String(layerXML.elements("name"));
					camera = BBCamera.get(layerName);
					dependOnCameraName = String(layerXML.elements("dependOnCamera"));
					dependOffset = String(layerXML.elements("dependOffset")).split(",");
					camera.dependOnCamera(_cameraModule.getCameraByName(dependOnCameraName), parseFloat(dependOffset[0]), parseFloat(dependOffset[1]), parseFloat(dependOffset[2]));
					_layerModule.add(layerName, true).attachCamera(camera);
				}

				// creates dependent layers
				var layersDependent:XMLList = layersXMLList.(addToLayer != "none");
				var layersDependWithoutCamera:XMLList = layersDependent.(attachCamera == "false");

				// creates depend layers without cameras
				numLayers = layersDependWithoutCamera.length();
				for (j = 0; j < numLayers; j++)
				{
					layerXML = layersDependWithoutCamera[j];
					_layerModule.addTo(String(layerXML.elements("name")), String(layerXML.elements("addToLayer")));
				}

				// creates depend layers with cameras
				var layersDependWithCamera:XMLList = layersDependent.(attachCamera == "true");
				numLayers = layersDependWithCamera.length();
				for (j = 0; j < numLayers; j++)
				{
					layerXML = layersDependWithCamera[j];
					layerName = String(layerXML.elements("name"));
					camera = BBCamera.get(layerName);

					dependOnCameraName = layerXML.elements("dependOnCamera");

					if (dependOnCameraName != "none")
					{
						dependOffset = String(layerXML.elements("dependOffset")).split(",");
						camera.dependOnCamera(_cameraModule.getCameraByName(dependOnCameraName), parseFloat(dependOffset[0]), parseFloat(dependOffset[1]), parseFloat(dependOffset[2]));
					}

					layer = _layerModule.addTo(layerName, String(layerXML.elements("addToLayer")));
					layer.attachCamera(camera);
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

			for (var i:int = 0; i < numActors; i++)
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
		 * Dispatches when level constructed.
		 */
		public function get onLevelComplete():BBSignal
		{
			if (!_onLevelComplete) _onLevelComplete = BBSignal.get(this);
			return _onLevelComplete;
		}
	}
}
