/**
 * User: VirtualMaestro
 * Date: 02.03.13
 * Time: 21:03
 */
package bb.mouse
{
	import bb.bb_spaces.bb_private;
	import bb.camera.BBCamerasModule;
	import bb.camera.components.BBCamera;
	import bb.core.BabyBox;
	import bb.modules.*;
	import bb.mouse.events.BBMouseEvent;
	import bb.pools.BBNativePool;
	import bb.signals.BBSignal;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

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
		private var _mapNativeMouseEventsConst:Array;

		//
		private var _pendingEventsMap:Array;
		private var _pendingEventsQueue:Vector.<MouseEvent>;
		private var _synchronizeDispatching:uint = 0;

		/**
		 */
		public function BBMouseModule()
		{
			super();

			_mapNativeMouseEventsConst = [];
			_mapNativeMouseEventsConst[MouseEvent.MOUSE_UP] = BBMouseEvent.UP;
			_mapNativeMouseEventsConst[MouseEvent.MOUSE_DOWN] = BBMouseEvent.DOWN;
			_mapNativeMouseEventsConst[MouseEvent.MOUSE_MOVE] = BBMouseEvent.MOVE;

			_onUp = BBSignal.get(this);
			_onDown = BBSignal.get(this);
			_onMove = BBSignal.get(this);
		}

		/**
		 */
		override protected function ready():void
		{
			_camerasList = (getModule(BBCamerasModule) as BBCamerasModule).cameras;
			_viewRect = (engine as BabyBox).config.getViewRect();

			mouseSettings = (engine as BabyBox).config.mouseSettings;
			synchronizeDispatching = (engine as BabyBox).config.synchronizeMouseEventDispatching;
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
		 */
		public function set mouseSettings(p_flags:uint):void
		{
			if ((p_flags & BBMouseEvent.CLICK) != 0)
			{
				stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			}
			else
			{
				if ((p_flags & BBMouseEvent.UP) != 0) stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
				else stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);

				if ((p_flags & BBMouseEvent.DOWN) != 0) stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
				else stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			}

			if ((p_flags & BBMouseEvent.MOVE) != 0) stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
			else stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		}

		/**
		 */
		private function mouseHandler(p_event:MouseEvent):void
		{
			var eventType:uint = _mapNativeMouseEventsConst[p_event.type];

			if ((_synchronizeDispatching & eventType) != 0) addEventToQueue(p_event);
			else mouseProcess(eventType, p_event.stageX, p_event.stageY, p_event.buttonDown, p_event.ctrlKey);
		}

		/**
		 */
		private function mouseProcess(p_type:uint, p_mouseX:Number, p_mouseY:Number, p_buttonDown:Boolean, p_ctrlKey:Boolean):void
		{
			var event:BBMouseEvent = BBMouseEvent.get(p_type, null, null, 0, 0, p_buttonDown, p_ctrlKey);
			event.stageX = p_mouseX;
			event.stageY = p_mouseY;
			event.stopPropagationAfterHandling = (engine as BabyBox).config.stopMousePropagationAfterHandling;

			if (_viewRect.contains(p_mouseX, p_mouseY))
			{
				event.viewRectX = p_mouseX - _viewRect.x;
				event.viewRectY = p_mouseY - _viewRect.y;

				// set mouse position
				var mousePosition:Point = BBNativePool.getPoint(event.viewRectX, event.viewRectY);

				var eventSent:Boolean = false;
				var camera:BBCamera;
				var cameraViewport:Rectangle;
				var tMouseX:Number;
				var tMouseY:Number;

				for (var i:int = _camerasList.length - 1; i >= 0; i--)
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
							event.worldX = mousePosition.x;
							event.worldY = mousePosition.y;
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
				case BBMouseEvent.MOVE:
				{
					_onMove.dispatch(p_event);
					break;
				}

				case BBMouseEvent.UP:
				{
					_onUp.dispatch(p_event);
					break;
				}

				case BBMouseEvent.DOWN:
				{
					_onDown.dispatch(p_event);
					break;
				}
			}
		}

		/**
		 * Synchronize of dispatching given mouse events with update loop.
		 * It's help to reduce handling of mouse events by the node's tree and can significant reduce overhead especially for MOVE event.
		 * It is mean after mouse dispatch event it won't dispatches immediately, but when update happened.
		 * There is possible three const: BBMouseEvent.UP, BBMouseEvent.DOWN, BBMouseEvent.MOVE.
		 * E.g. need to synchronize MOVE and UP events:
		 * <code>
		 *     synchronizeDispatching = BBMouseEvent.UP | BBMouseEvent.MOVE;
		 * </code>
		 */
		public function set synchronizeDispatching(p_val:uint):void
		{
			if (_synchronizeDispatching == p_val) return;
			_synchronizeDispatching = p_val;

			if (_synchronizeDispatching != 0)
			{
				updateEnable = true;
				_pendingEventsMap = [];
				_pendingEventsQueue = new <MouseEvent>[];
			}
			else
			{
				updateEnable = false;
				_pendingEventsMap = null;
				_pendingEventsQueue = null;
			}
		}

		/**
		 */
		public function get synchronizeDispatching():uint
		{
			return _synchronizeDispatching;
		}

		/**
		 */
		[Inline]
		final private function addEventToQueue(p_event:MouseEvent):void
		{
			if (_pendingEventsMap[p_event.type] == null)
			{
				_pendingEventsQueue.push(p_event);
				_pendingEventsMap[p_event.type] = true;
			}
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			var mouseEvent:MouseEvent;
			var numEvents:uint = _pendingEventsQueue.length;
			for (var i:int = 0; i < numEvents; i++)
			{
				mouseEvent = _pendingEventsQueue[i];
				mouseProcess(_mapNativeMouseEventsConst[mouseEvent.type], mouseEvent.stageX, mouseEvent.stageY, mouseEvent.buttonDown, mouseEvent.ctrlKey);

				_pendingEventsMap[mouseEvent.type] = null;
			}

			_pendingEventsQueue.length = 0;
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

		/////////////////////////
		// setters and getters //
		/////////////////////////

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
