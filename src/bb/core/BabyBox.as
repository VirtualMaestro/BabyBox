package bb.core
{
	import bb.BBModuleEngine;
	import bb.assets.BBAssetsManager;
	import bb.camera.BBCamerasModule;
	import bb.camera.BBShaker;
	import bb.config.BBConfig;
	import bb.config.BBConfigModule;
	import bb.core.context.BBContext;
	import bb.debug.BBDebugModule;
	import bb.input.BBActionData;
	import bb.input.BBKeyboardModule;
	import bb.layer.BBLayerModule;
	import bb.level.BBLevelsModule;
	import bb.mouse.BBMouseModule;
	import bb.mouse.events.BBMouseEvent;
	import bb.physics.BBPhysicsModule;
	import bb.physics.joints.BBJoint;
	import bb.pools.BBMasterPool;
	import bb.pools.BBNativePool;
	import bb.signals.BBSignal;
	import bb.tree.BBTreeModule;
	import bb.world.BBWorldModule;

	import flash.display.Stage;

	/**
	 * Enter point to engine.
	 *
	 * - TODO: Добавить вывод ошибок на экран, чтобы когда происходит критическая ошибка (напр. рендер не инициализировался) вывело на экран,
	 *   а не в дебаг консоль.
	 * -
	 */
	final public class BabyBox extends BBModuleEngine
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
		final public function init(p_stage:Stage, p_config:BBConfig):void
		{
			stage = p_stage;
			BBAssetsManager.stage = stage;

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
			BBMasterPool.addRidPoolMethod(BBNode.ridCaches);
			BBMasterPool.addRidPoolMethod(BBComponent.rid);
			BBMasterPool.addRidPoolMethod(BBNodeStatus.rid);
			BBMasterPool.addRidPoolMethod(BBMouseEvent.rid);
			BBMasterPool.addRidPoolMethod(BBNativePool.rid);
			BBMasterPool.addRidPoolMethod(BBJoint.rid);
			BBMasterPool.addRidPoolMethod(BBActionData.rid);
			BBMasterPool.addRidPoolMethod(BBShaker.rid);

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
			addModule(BBTreeModule);
			addModule(BBWorldModule);
			addModule(BBLayerModule);
			addModule(BBConfigModule);
			if (_config.physicsEnable) addModule(BBPhysicsModule);
			if (_config.mouseSettings != 0) addModule(BBMouseModule);
			if (_config.debugMode) addModule(BBDebugModule);
			if (_config.levelManager) addModule(BBLevelsModule);
			if (_config.keyboardEnable) addModule(BBKeyboardModule);

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
		 * Methods tries to free some memory in way cleaning caches, pools and rid other resources.
		 */
		public function freeMemory():void
		{
			BBMasterPool.clearAllPools();
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

		static public function get():BabyBox
		{
			if (_instance == null) _instance = new BabyBox(new Enforce());
			return _instance;
		}
	}
}

internal class Enforce
{
}