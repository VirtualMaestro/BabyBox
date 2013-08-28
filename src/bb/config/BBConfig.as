package bb.config
{
	import bb.assets.BBAssetsManager;
	import bb.bb_spaces.bb_private;
	import bb.render.constants.BBRenderMode;
	import bb.signals.BBSignal;

	import flash.geom.Rectangle;

	import nape.geom.Vec2;

	/**
	 * Config of engine.
	 */
	public class BBConfig
	{
		/**
		 * If property set in 'true' mean If stage3d is initialized in 'software' mode it turn to blitting mode instead.
		 *
		 * [startup]
		 */
		public var softwareTurnToBlitting:Boolean = true;

		/**
		 * Sets color of canvas.
		 * Uses format ARGB (black color = 0xFF000000).
		 *
		 * [runtime]
		 */
		public var canvasColor:uint = 0xFFf0f3c7;

		/**
		 * Should renderer apply anti-aliasing or not. With anti-aliasing image more smooth but it is hit by performance.
		 * [runtime]
		 */
		public var smoothingDraw:Boolean = true;

		/**
		 * Turn on mouse pixel perfect collision.
		 *
		 * [runtime]
		 */
		public var mousePixelEnable:Boolean = false;

		/**
		 * Mouse propagation stops immediately after some node handled it.
		 */
		public var stopMousePropagationAfterHandling:Boolean = true;

		/**
		 * If true uses 'sweep and prune' algorithm for physics engine.
		 * Else uses 'dynamic aabb tree'.
		 *
		 * [startup]
		 */
		public var broadphaseSweepAndPrune:Boolean = true;

		/**
		 * After engine is initialized this value contains param render mode engine was launched.
		 * There are three possible values:
		 * BBRenderMode.BASELINE
		 * BBRenderMode.BASELINE_CONSTRAINED
		 * BBRenderMode.SOFTWARE
		 *
		 * [startup]
		 */
		public var renderMode:String = BBRenderMode.BLITTING;

		/**
		 * If 'true' init physics engine.
		 *
		 * [startup]
		 */
		public var physicsEnable:Boolean = false;

		/**
		 * If 'true' physic time step changes depend on frame rate.
		 */
		public var autoPhysicTimeStep:Boolean = true;

		/**
		 * Set frame rate for animations by default.
		 * Each animation can has own frame rate.
		 *
		 * [startup]
		 */
		public var animationFrameRate:int = 30;

		/**
		 * Whether need to apply a culling test.
		 * Mean before render object will be tested on getting on screen.
		 *
		 * [runtime]
		 */
		public var isCulling:Boolean = false;

		/**
		 * Determines what type of game is creating.
		 * By default value is -1, what mean no predefine game type.
		 * Possible constants store in BBGameType class.
		 *
		 * [startup]
		 */
		public var gameType:int = -1;

		/**
		 * If value greater than 0 all system modules and components takes that fixed delta time.
		 */
		private var _fixedTimeStep:int = 0;

		/**
		 * Position and size of area of game field (canvas).
		 */
		private var _canvasRect:Rectangle = null;

		//
		private var _gravity:Vec2;
		private var _physicTimeStep:Number = 0;

		//
		private var _mouseSettings:int = 0;
		private var _mouseNodeSettings:int = 0;

		//
		private var _onChanged:BBSignal;
		private var _param:Object;

		// Options which can be changed in runtime
		private var _graphicsEnable:Boolean = true;
		private var _keyboardEnable:Boolean = false;
		private var _debugMode:Boolean = false;
		private var _appWidth:int = 800;
		private var _appHeight:int = 600;
		private var _appFrameRate:int = 30;
		private var _gameWidth:int = 0;
		private var _gameHeight:int = 0;
		private var _handEnable:Boolean = false;
		private var _levelManager:Boolean = false;

		/**
		 */
		public function BBConfig(p_appWidth:int, p_appHeight:int, p_frameRate:int = 30, p_gameWidth:int = 0, p_gameHeight:int = 0)
		{
			_appWidth = p_appWidth;
			_appHeight = p_appHeight;
			_appFrameRate = p_frameRate;
			_gameWidth = p_gameWidth < 2 ? _appWidth : p_gameWidth;
			_gameHeight = p_gameHeight < 2 ? _appHeight : p_gameHeight;

			setCanvasRect(0, 0, _appWidth, _appHeight);

			_onChanged = BBSignal.get(this);
			_param = {};
		}

		/**
		 * Application width.
		 */
		public function get appWidth():int
		{
			return _appWidth;
		}

		/**
		 * Application height.
		 */
		public function get appHeight():int
		{
			return _appHeight;
		}

		/**
		 * Game width.
		 * Width of vew field of game.
		 */
		public function get gameWidth():int
		{
			return _gameWidth;
		}

		/**
		 * Game height.
		 * Height of vew field of game.
		 */
		public function get gameHeight():int
		{
			return _gameHeight;
		}

		/**
		 * Turn on/off debug mode.
		 *
		 * [runtime]
		 */
		public function set debugMode(p_val:Boolean):void
		{
			if (_debugMode == p_val) return;
			_debugMode = p_val;
			sendChanges("debugMode", _debugMode)
		}

		public function get debugMode():Boolean
		{
			return _debugMode;
		}

		/**
		 * Set frame rate for APP (for all needed related modules)
		 *
		 * [runtime]
		 */
		public function set frameRate(p_val:int):void
		{
			if (_appFrameRate == p_val) return;
			_appFrameRate = p_val;
			sendChanges("frameRate", _appFrameRate);
		}

		public function get frameRate():int
		{
			return _appFrameRate;
		}

		/**
		 * Turn on/off graphics. Can be useful for debug mode.
		 * This is not just switched on/off visibility, but absolutely add/remove graphics module.
		 *
		 * [runtime]
		 */
		public function set graphicsEnable(p_val:Boolean):void
		{
			if (_graphicsEnable == p_val) return;
			_graphicsEnable = p_val;
			sendChanges("graphicsEnable", _graphicsEnable);
		}

		public function get graphicsEnable():Boolean
		{
			return _graphicsEnable;
		}

		/**
		 * Turn on/off keyboard.
		 * By default off.
		 *
		 * [startup]
		 */
		public function set keyboardEnable(p_val:Boolean):void
		{
			if (_keyboardEnable == p_val) return;
			_keyboardEnable = p_val;
//			sendChanges("keyboardEnable", _keyboardEnable);
		}

		public function get keyboardEnable():Boolean
		{
			return _keyboardEnable;
		}

		/**
		 * Enable/disable BBLevelsModule.
		 * If visual editor is not using have no sense to have active BBLevelsModule.
		 */
		public function set levelManager(p_val:Boolean):void
		{
			if (_levelManager == p_val) return;
			_levelManager = p_val;
		}

		/**
		 */
		public function get levelManager():Boolean
		{
			return _levelManager;
		}

		/**
		 *
		 */
		public function set assetInitializationTimeStep(p_val:int):void
		{
			BBAssetsManager.INITIALIZATION_TIME_STEP = p_val;
		}

		/**
		 *
		 */
		public function get assetInitializationTimeStep():int
		{
			return BBAssetsManager.INITIALIZATION_TIME_STEP;
		}

		/**
		 * Sets gravity for physics engine.
		 *
		 * [runtime]
		 */
		public function setGravity(p_x:Number, p_y:Number):void
		{
			if (_gravity == null) _gravity = Vec2.get();
			_gravity.setxy(p_x, p_y);
			sendChanges("gravity", _gravity);
		}

		/**
		 */
		public function getGravity():Vec2
		{
			if (_gravity == null) _gravity = Vec2.get(0, 1200);
			return _gravity;
		}

		/**
		 * Set time step for physic simulation.
		 * If this method was used, property 'autoPhysicTimeStep' automatically set to 'false'.
		 * [startup]
		 */
		public function set physicTimeStep(p_val:Number):void
		{
			_physicTimeStep = p_val;
			autoPhysicTimeStep = false;
		}

		/**
		 */
		public function get physicTimeStep():Number
		{
			return _physicTimeStep;
		}

		/**
		 * Sets position and size of area of game field (canvas).
		 *
		 * [startup]
		 */
		public function setCanvasRect(p_x:int = 0, p_y:int = 0, p_width:int = 0, p_height:int = 0):void
		{
			if (_canvasRect == null) _canvasRect = new Rectangle();

			if (p_x < 0) p_x = 0;
			if (p_x > _appWidth - 2) p_x = _appWidth - 2;
			if (p_y < 0) p_y = 0;
			if (p_y > _appHeight - 2) p_y = _appHeight - 2;

			if (p_width < 2) p_width = _appWidth;
			if (p_height < 2) p_height = _appHeight;
			if ((p_x + p_width) > _appWidth) p_width += _appWidth - (p_x + p_width);
			if ((p_y + p_height) > _appHeight) p_height += _appHeight - (p_y + p_height);

			_canvasRect.setTo(p_x, p_y, p_width, p_height);
		}

		/**
		 */
		public function getViewRect():Rectangle
		{
			return _canvasRect;
		}

		/**
		 * Returns fixed time step value.
		 */
		public function get fixedTimeStep():int
		{
			return _fixedTimeStep;
		}

		/**
		 * If value greater than 0 all system modules and components takes that fixed delta time.
		 *
		 * [runtime]
		 */
		public function set fixedTimeStep(p_value:int):void
		{
			_fixedTimeStep = p_value;
			sendChanges("fixedTimeStep", p_value);
		}

		/**
		 * Config of dispatching mouse events. Configuration is done via BBMouseEvent.
		 * E.g. if we want to enable dispatching click and move events - should to do (it will dispatch up and down events):
		 * <code>
		 *     mouseSettings = BBMouseEvent.UP | BBMouseEvent.DOWN | BBMouseEvent.MOVE;
		 * </code>
		 *
		 * if need to enable dispatching only e.g. UP event and MOVE, it is possible to do in the following way:
		 * <code>
		 *     mouseSettings = BBMouseEvent.UP | BBMouseEvent.MOVE;
		 * </code>
		 *
		 * By default module is not dispatching any events.
		 *
		 * [startup]
		 */
		public function set mouseSettings(p_val:int):void
		{
			_mouseSettings = p_val;
		}

		/**
		 */
		public function get mouseSettings():int
		{
			return _mouseSettings;
		}

		/**
		 * Set which mouse events will receive and dispatches node.
		 * E.g. need to dispatch mouse click and move:
		 * <code>
		 *     mouseSettings = BBMouseEvent.CLICK | BBMouseEvent.MOVE;
		 * </code>
		 *
		 * Except this it is should to allow dispatching appropriate events by BBMouseModule.
		 */
		public function set mouseNodeSettings(p_val:int):void
		{
			_mouseNodeSettings = p_val;
		}

		/**
		 */
		public function get mouseNodeSettings():int
		{
			return _mouseNodeSettings;
		}

		/**
		 */
		public function get handEnable():Boolean
		{
			return _handEnable;
		}

		/**
		 */
		public function set handEnable(value:Boolean):void
		{
			_handEnable = value;
			sendChanges("handEnable", _handEnable);
		}

		/**
		 * Dispatches changed property.
		 * First param is name of property, second its value.
		 * (Method can be overridden in children for custom config)
		 * <code>
		 *     var param:Object = {};
		 *     param.name = propName;
		 *     param.value = propValue;
		 * </code>
		 */
		protected function sendChanges(propName:String, propValue:Object):void
		{
			_param.name = propName;
			_param.value = propValue;
			_onChanged.dispatch(_param);
		}

		/**
		 * @private
		 * Dispatches when some param was changed.
		 * As parameter sends Object with properties:
		 * - name - name of changed property (String);
		 * - value - value of changed property (Object);
		 */
		bb_private function get onChanged():BBSignal
		{
			return _onChanged;
		}
	}
}
