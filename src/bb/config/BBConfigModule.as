package bb.config
{
	import bb.bb_spaces.bb_private;
	import bb.core.BabyBox;
	import bb.debug.BBDebugModule;
	import bb.modules.*;
	import bb.physics.BBPhysicsModule;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	use namespace bb_private;

	/**
	 * Response for applying and synchronization of engine configuration.
	 */
	public class BBConfigModule extends BBModule
	{
		private var _physicsModule:BBPhysicsModule;

		/**
		 */
		public function BBConfigModule()
		{
		}

		/**
		 */
		override protected function ready():void
		{
			config.onChanged.add(configChangedHandler);
			applyStartupConfigSettings();
		}

		/**
		 */
		private function applyStartupConfigSettings():void
		{
			stage.frameRate = config.frameRate;
			engine.fixedTimeStep = config.fixedTimeStep;
		}

		/**
		 */
		private function configChangedHandler(p_signal:BBSignal):void
		{
			var param:Object = p_signal.params;
			updateConfig(param.name, param.value);
		}

		/**
		 * Handler updating configuration.
		 * Can be overridden in children for custom config module.
		 */
		protected function updateConfig(p_propertyName:String, p_propertyValue:Object):void
		{
			switch (p_propertyName)
			{
				case "frameRate":
				{
					stage.frameRate = p_propertyValue as int;
					if (config.autoPhysicTimeStep)
					{
						if (!_physicsModule) _physicsModule = getModule(BBPhysicsModule) as BBPhysicsModule;
						if (_physicsModule) _physicsModule.timeStep = 1 / Number(p_propertyValue);
					}

					break;
				}

				case "fixedTimeStep":
				{
					engine.fixedTimeStep = p_propertyValue as int;
					break;
				}

				case "graphicsEnable":
				{

					break;
				}

				case "debugMode":
				{
					var debugModule:BBDebugModule = getModule(BBDebugModule) as BBDebugModule;

					if (debugModule)
					{
						debugModule.drawPhysics = p_propertyValue;
						debugModule.showGrid = p_propertyValue;
						debugModule.showFPS = p_propertyValue;
						debugModule.updateEnable = p_propertyValue;
					}

					break;
				}

				case "keyboardEnable":
				{

					break;
				}

				case "handEnable":
				{
					if (!_physicsModule) _physicsModule = getModule(BBPhysicsModule) as BBPhysicsModule;
					if (_physicsModule) _physicsModule.handEnable = p_propertyValue;

					break;
				}

				case "gravity":
				{
					var gravity:Vec2 = p_propertyValue as Vec2;
					if (!_physicsModule) _physicsModule = getModule(BBPhysicsModule) as BBPhysicsModule;
					if (_physicsModule) _physicsModule.setGravity(gravity.x, gravity.y);

					break;
				}

			}
		}

		/**
		 */
		private function get config():BBConfig
		{
			return (engine as BabyBox).config;
		}
	}
}
