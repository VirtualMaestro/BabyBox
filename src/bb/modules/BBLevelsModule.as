/**
 * User: VirtualMaestro
 * Date: 11.06.13
 * Time: 15:38
 */
package bb.modules
{
	import bb.components.physics.BBPhysicsBody;
	import bb.core.BBNode;
	import bb.parsers.BBLevelParser;
	import bb.signals.BBSignal;

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
			}

			var actorsList:XMLList = level.actors.children();
			var actorXML:XML;
			var actor:BBNode;
			var actorAlias:String;
			var actorPosition:Array;
			var actorRotation:Number;
			var actorScale:Array;
			var actorLayer:String;
			var actorInternalCollision:Boolean;
			var actorType:String;
			var numActors:int = actorsList.length();

			for (var i:int = 0; i < numActors; i++)
			{
				actorXML = actorsList[i];

				actorAlias = actorXML.elements("alias");
				actorType = actorXML.elements("type");
				actorPosition = String(actorXML.elements("position")).split(",");
				actorRotation = actorXML.elements("rotation");
				actorScale = String(actorXML.elements("scale")).split(",");
				actorLayer = actorXML.elements("layer");
				actorInternalCollision = actorXML.elements("internalCollision") == "true";

				actor = BBNode.getFromCache(actorAlias);
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
