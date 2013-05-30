package bb.core
{
	import bb.BBModuleEngine;
	import bb.signals.BBSignal;

	import flash.display.Stage;

	import bb.assets.BBAssetsManager;
	import bb.components.physics.joints.BBJoint;
	import bb.core.context.BBContext;
	import bb.events.BBMouseEvent;
	import bb.modules.BBCamerasModule;
	import bb.modules.BBConfigModule;
	import bb.modules.BBDebugModule;
	import bb.modules.BBGraphModule;
	import bb.modules.BBLayerModule;
	import bb.modules.BBMouseModule;
	import bb.modules.BBPhysicsModule;
	import bb.modules.BBWorldModule;
	import bb.pools.BBActorPool;
	import bb.pools.BBComponentPool;
	import bb.pools.BBMasterPool;
	import bb.pools.BBNativePool;

	/**
	 * Enter point to engine.
	 *
	 * - TODO: Добавить вывод ошибок на экран, чтобы когда происходит критическая ошибка (напр. рендер не инициализировался) вывело на экран,
	 *   а не в дебаг консоль.
	 * -
	 */
	public class BabyBox extends BBModuleEngine
	{
		// After engine is initialized this field shows if engine launched in stage3d mode or blitting
		static public var isStage3d:Boolean = false;

		//
		private var _onInitialized:BBSignal = null;
		private var _onFailed:BBSignal = null;

		private var _isInitialized:Boolean = false;
		private var _config:BBConfig = null;
		private var _context:BBContext = null;

		/**
		 */
		public function BabyBox(p_enforce:Enforce)
		{
			super();
		}

		/**
		 * Start to init engine.
		 */
		public function init(p_stage:Stage, p_config:BBConfig):void
		{
			stage = p_stage;
			BBAssetsManager.stage = p_stage;

			_config = p_config;
			_context = new BBContext();
			_context.onInitialized.add(contextInitialized, true);
			_context.init(stage);
		}

		/**
		 */
		private function contextInitialized(p_signal:BBSignal):void
		{
			// add all rid methods of pools to master pool
			BBMasterPool.addRidPoolMethod(BBNode.rid);
			BBMasterPool.addRidPoolMethod(BBComponentPool.rid);
			BBMasterPool.addRidPoolMethod(BBNodeStatus.rid);
			BBMasterPool.addRidPoolMethod(BBMouseEvent.rid);
			BBMasterPool.addRidPoolMethod(BBNativePool.rid);
			BBMasterPool.addRidPoolMethod(BBActorPool.rid);
			BBMasterPool.addRidPoolMethod(BBJoint.rid);

			//
			isStage3d = _context.isStage3d;

			//
			initSystemModules();
		}

		/**
		 * Initialize all engine's modules by default.
		 */
		private function initSystemModules():void
		{
			addModule(BBCamerasModule);
			addModule(BBGraphModule);
			addModule(BBWorldModule);
			addModule(BBLayerModule);
			if (_config.physicsEnable) addModule(BBPhysicsModule);
			addModule(BBConfigModule);
			addModule(BBMouseModule);
			addModule(BBDebugModule);

			//
			_isInitialized = true;
			onInitialized.dispatch();
		}

		/**
		 */
		public function get onInitialized():BBSignal
		{
			if (_onInitialized == null) _onInitialized = BBSignal.get(this, true);
			return _onInitialized;
		}

		/**
		 * Dispatches different errors of engine.
		 */
		public function get onFailed():BBSignal
		{
			if (_onFailed == null) _onFailed = BBSignal.get(this, true);
			return _onFailed;
		}

		/**
		 * Returns if engine is initialized already.
		 */
		public function get isInitialized():Boolean
		{
			return _isInitialized;
		}

		/**
		 * Get configuration options for engine.
		 */
		public function get config():BBConfig
		{
			return _config;
		}

		/**
		 * Returns current context.
		 */
		public function get context():BBContext
		{
			return _context;
		}

		/**
		 * Entirely dispose engine.
		 */
		public function dispose():void
		{
			// dispose master pool
			BBMasterPool.dispose();

			// TODO: Implement
		}

		/*******************************/
		static private var _instance:BabyBox;

		static public function getInstance():BabyBox
		{
			if (_instance == null) _instance = new BabyBox(new Enforce());
			return _instance;
		}
	}
}

internal class Enforce
{
}