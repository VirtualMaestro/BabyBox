/**
 * User: VirtualMaestro
 * Date: 11.06.13
 * Time: 15:38
 */
package bb.level
{
	import bb.core.BBNode;
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
