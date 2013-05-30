/**
 * User: VirtualMaestro
 * Date: 02.03.13
 * Time: 21:03
 */
package src.bb.modules
{
	import bb.modules.BBModule;
	import bb.signals.BBSignal;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import src.bb.bb_spaces.bb_private;
	import src.bb.components.BBCamera;
	import src.bb.constants.mouse.BBMouseFlags;
	import src.bb.core.BabyBox;
	import src.bb.events.BBMouseEvent;
	import src.bb.pools.BBNativePool;

	use namespace bb_private;

	/**
	 * Response for dispatching mouse events.
	 */
	public class BBMouseModule extends BBModule
	{
		private var _onUp:BBSignal;
		private var _onDown:BBSignal;
		private var _onMove:BBSignal;

		private var _camerasList:Vector.<BBCamera> = null;
		private var _viewRect:Rectangle = null;

		/**
		 */
		public function BBMouseModule()
		{
			super();

			_onUp = BBSignal.get(this);
			_onDown = BBSignal.get(this);
			_onMove = BBSignal.get(this);

			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			_camerasList = (getModule(BBCamerasModule) as BBCamerasModule).cameras;
			_viewRect = (engine as BabyBox).config.getViewRect();

			mouseSettings = (engine as BabyBox).config.mouseSettings;
		}

		/**
		 * Config of dispatching mouse events. Configuration is done via BBMouseFlags.
		 * E.g. if we want to enable dispatching click and move events - should to do:
		 * <code>
		 *     mouseSettings = BBMouseFlags.CLICK | BBMouseFlags.MOVE;
		 * </code>
		 */
		public function set mouseSettings(p_flags:uint):void
		{
			if ((p_flags & BBMouseFlags.UP) != 0) stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
			else stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);

			if ((p_flags & BBMouseFlags.DOWN) != 0) stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			else stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);

			if ((p_flags & BBMouseFlags.MOVE) != 0) stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
			else stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		}

		/**
		 */
		private function mouseHandler(p_event:MouseEvent):void
		{
			var stageX:Number = p_event.stageX;
			var stageY:Number = p_event.stageY;

			var event:BBMouseEvent = BBMouseEvent.get(p_event.type, null, null, 0, 0, p_event.buttonDown, p_event.ctrlKey);
			event.stageX = stageX;
			event.stageY = stageY;

			if (_viewRect.contains(stageX, stageY))
			{
				event.viewRectX = stageX - _viewRect.x;
				event.viewRectY = stageY - _viewRect.y;

				// set mouse position
				var mousePosition:Point = BBNativePool.getPoint(event.viewRectX, event.viewRectY);

				var numCameras:int = _camerasList.length;
				var eventSent:Boolean = false;
				var camera:BBCamera;
				var cameraViewport:Rectangle;
				var tMouseX:Number;
				var tMouseY:Number;

				for (var i:int = numCameras - 1; i >= 0; i--)
				{
					camera = _camerasList[i];
					if (camera.mouseEnable && camera.node.active)
					{
						tMouseX = mousePosition.x;
						tMouseY = mousePosition.y;

						if (camera.calcRelatedPosition(mousePosition))
						{
							cameraViewport = camera.getViewport();
							event.cameraViewPortX = tMouseX - cameraViewport.x;
							event.cameraViewPortY = tMouseY - cameraViewport.y;
							event.cameraX = mousePosition.x;
							event.cameraY = mousePosition.y;
							event.capturedCamera = camera;
						}

						dispatchEvent(event);
						eventSent = true;
					}
				}

				BBNativePool.putPoint(mousePosition);
			}

			if (!eventSent) dispatchEvent(event);

			//
			event.dispose();
		}

		/**
		 */
		private function dispatchEvent(p_event:BBMouseEvent):void
		{
			switch (p_event.type)
			{
				case MouseEvent.MOUSE_MOVE:
				{
					_onMove.dispatch(p_event);
					break;
				}

				case MouseEvent.MOUSE_UP:
				{
					_onUp.dispatch(p_event);
					break;
				}

				case MouseEvent.MOUSE_DOWN:
				{
					_onDown.dispatch(p_event);
					break;
				}
			}
		}

		/**
		 */
		override public function dispose():void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);

			_onUp.dispose();
			_onUp = null;
			_onDown.dispose();
			_onDown = null;
			_onMove.dispose();
			_onMove = null;

			super.dispose();
		}

		// setters and getters //

		public function get onUp():BBSignal
		{
			return _onUp;
		}

		public function get onDown():BBSignal
		{
			return _onDown;
		}

		public function get onMove():BBSignal
		{
			return _onMove;
		}
	}
}
