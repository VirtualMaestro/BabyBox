/**
 * User: VirtualMaestro
 * Date: 21.03.13
 * Time: 17:57
 */
package bb.debug
{
	import bb.config.BBConfig;
	import bb.core.BabyBox;
	import bb.modules.*;
	import bb.physics.BBPhysicsModule;
	import bb.signals.BBSignal;

	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;

	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;

	import vm.stat.Stats;

	/**
	 * Response for debug drawing and tools.
	 */
	public class BBDebugModule extends BBModule
	{
		private var _showGrid:Boolean = false;
		private var _physicDraw:Boolean = false;
		private var _showFPS:Boolean = false;

		private var _grid:BBGridDebug;
		private var _physicsDebugDefault:Debug;
		private var _physDebugList:Vector.<Debug>;

		private var _config:BBConfig;
		private var _space:Space;
		private var _stats:Stats;

		/**
		 */
		public function BBDebugModule()
		{
			super();
			onReadyToUse.add(onReadyToUseHandler);
		}

		/**
		 */
		private function onReadyToUseHandler(p_signal:BBSignal):void
		{
			_config = (engine as BabyBox).config;
			if (_config.physicsEnable)
			{
				_space = (getModule(BBPhysicsModule) as BBPhysicsModule).space;
				var viewRect:Rectangle = _config.getViewRect();
				_physicsDebugDefault = addPhysicsDebug(viewRect.width, viewRect.height, viewRect.x, viewRect.y, _config.canvasColor);
			}

			if (_config.debugMode)
			{
				drawPhysics = true;
				showGrid = true;
				showFPS = true;

				updateEnable = true;
			}
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			// update physics debug draw
			if (_physicDraw)
			{
				var len:int = _physDebugList.length;
				var debugDraw:Debug;
				for (var i:int = 0; i < len; i++)
				{
					debugDraw = _physDebugList[i];
					debugDraw.clear();
					debugDraw.draw(_space);
					debugDraw.flush();
				}
			}
		}

		/**
		 */
		public function addPhysicsDebug(p_width:int, p_height:int, p_x:Number = 0, p_y:Number = 0, p_bgColor:uint = 0x3355443):Debug
		{
			if (_physDebugList == null) _physDebugList = new <Debug>[];
			if (_physicsDebugDefault)
			{
				removePhysicsDraw(_physicsDebugDefault);
				_physicsDebugDefault = null;
			}

//			var shapeDebug:ShapeDebug = new ShapeDebug(p_width, p_height, p_bgColor);
			var shapeDebug:Debug = new BitmapDebug(p_width, p_height, p_bgColor, true);
//			var shapeDebug:ShapeDebug = new ShapeDebug(800, 600, p_bgColor);  // TODO: Bug Не работает ширина высота для  ShapeDebug
			shapeDebug.drawConstraints = true;
//			shapeDebug.transform.transform(Vec2.weak(p_x, p_y));
			_physDebugList.push(shapeDebug);

			if (_physicDraw) stage.addChild(shapeDebug.display);
//			shapeDebug.thickness = 2;
			shapeDebug.display.x = p_x;
			shapeDebug.display.y = p_y;

			return shapeDebug;
		}

		/**
		 */
		public function removePhysicsDraw(p_physicsDraw:Debug):void
		{
			var index:int = _physDebugList.indexOf(p_physicsDraw);
			if (index >= 0)
			{
				_physDebugList.splice(index, 1);
				var parent:DisplayObjectContainer = p_physicsDraw.display.parent;
				if (parent) parent.removeChild(p_physicsDraw.display);
			}
		}

		/**
		 * Turn on/off debug physics draw.
		 */
		public function set drawPhysics(p_val:Boolean):void
		{
			if (_physDebugList == null || _physicDraw == p_val) return;
			_physicDraw = p_val;

			var len:int = _physDebugList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (_physicDraw) stage.addChild(_physDebugList[i].display);
				else stage.removeChild(_physDebugList[i].display);
			}

			if (_physicDraw && !updateEnable) updateEnable = true;
		}

		/**
		 */
		public function get drawPhysics():Boolean
		{
			return _physicDraw;
		}

		/**
		 * Returns grid.
		 */
		public function get grid():BBGridDebug
		{
			if (!_grid) _grid = new BBGridDebug(_config.appWidth, _config.appHeight);
			return _grid;
		}

		/**
		 */
		public function get showGrid():Boolean
		{
			return _showGrid;
		}

		/**
		 * Shows debug grid on the screen.
		 */
		public function set showGrid(p_value:Boolean):void
		{
			if (_showGrid == p_value) return;
			_showGrid = p_value;

			if (_showGrid) stage.addChildAt(grid, stage.numChildren - 1);
			else stage.removeChild(grid);
		}

		/**
		 */
		public function set showFPS(p_val:Boolean):void
		{
			if (_showFPS == p_val) return;
			_showFPS = p_val;

			if (_showFPS)
			{
				if (!_stats) _stats = new Stats();
				stage.addChild(_stats);
			}
			else stage.removeChild(_stats);
		}

		/**
		 */
		public function get showFPS():Boolean
		{
			return _showFPS;
		}
	}
}
