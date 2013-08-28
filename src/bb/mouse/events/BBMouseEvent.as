/**
 * User: VirtualMaestro
 * Date: 18.02.13
 * Time: 13:15
 */
package bb.mouse.events
{
	import bb.bb_spaces.bb_private;
	import bb.camera.components.BBCamera;
	import bb.core.BBNode;

	use namespace bb_private;

	/**
	 * Mouse event object.
	 */
	public class BBMouseEvent
	{
		//
		static public const NONE:uint = 0x000000;
		static public const CLICK:uint = 0x000001;
		static public const UP:uint = 0x000010;
		static public const DOWN:uint = 0x000100;
		static public const MOVE:uint = 0x001000;
		static public const OVER:uint = 0x010000;
		static public const OUT:uint = 0x100000;
		static public const ALL:uint = 0xFFFFFF;

		//
		public var target:BBNode;
		public var dispatcher:BBNode;

		/**
		 * Type of mouse event. There is possible few values which are static constants of this class (CLICK, UP, DOWN etc.).
		 */
		public var type:uint;
		public var isButtonDown:Boolean = false;
		public var isCtrlDown:Boolean = false;

		public var localX:int = 0;
		public var localY:int = 0;

		public var stageX:int = 0;
		public var stageY:int = 0;

		/**
		 *    if value less then 0 it is mean mouse point isn't inside viewRect (canvas).
		 */
		public var viewRectX:int = -1;
		public var viewRectY:int = -1;

		/**
		 *    if value less then 0 it is mean mouse point isn't inside viewRect of camera.
		 */
		public var cameraViewPortX:Number = -1;
		public var cameraViewPortY:Number = -1;

		public var cameraX:int = 0;
		public var cameraY:int = 0;
		public var capturedCamera:BBCamera = null;

		public var propagation:Boolean = true;
		public var stopPropagationAfterHandling:Boolean = true;

		private var _isDisposed:Boolean = false;

		/**
		 */
		public function BBMouseEvent(p_type:uint = 0, p_target:BBNode = null, p_dispatcher:BBNode = null, p_localX:int = 0, p_localY:int = 0, p_buttonDown:Boolean = false, p_ctrlDown:Boolean = false)
		{
			type = p_type;
			target = p_target;
			dispatcher = p_dispatcher;
			localX = p_localX;
			localY = p_localY;
			isButtonDown = p_buttonDown;
			isCtrlDown = p_ctrlDown;
		}

		/**
		 */
		public function clone():BBMouseEvent
		{
			var cloneInstance:BBMouseEvent = BBMouseEvent.get(type, target, dispatcher, localX, localY, isButtonDown, isCtrlDown);
			cloneInstance.stageX = stageX;
			cloneInstance.stageY = stageY;
			cloneInstance.viewRectX = viewRectX;
			cloneInstance.viewRectY = viewRectY;
			cloneInstance.cameraViewPortX = cameraViewPortX;
			cloneInstance.cameraViewPortY = cameraViewPortY;
			cloneInstance.cameraX = cameraX;
			cloneInstance.cameraY = cameraY;
			cloneInstance.capturedCamera = capturedCamera;
			cloneInstance.stopPropagationAfterHandling = stopPropagationAfterHandling;

			return cloneInstance;
		}

		/**
		 */
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * Dispose object and back to pool.
		 */
		public function dispose():void
		{
			if (!isDisposed)
			{
				_isDisposed = true;
				target = null;
				dispatcher = null;
				capturedCamera = null;
				type = 0;
				localX = localY = 0;
				stageX = stageY = 0;
				viewRectX = viewRectY = -1;
				cameraX = cameraY = 0;
				cameraViewPortX = cameraViewPortY = -1;
				isButtonDown = false;
				isCtrlDown = false;
				propagation = true;

				// back to pool
				put(this);
			}
		}

		////////////
		/// pool ///
		////////////

		static private var _pool:Vector.<BBMouseEvent>;
		static private var _size:int = 0;

		/**
		 * Returns instance of BBMouseEvent.
		 */
		static public function get(p_type:uint = 0, p_target:BBNode = null, p_dispatcher:BBNode = null, p_localX:int = 0, p_localY:int = 0, p_buttonDown:Boolean = false, p_ctrlDown:Boolean = false):BBMouseEvent
		{
			var mouseEvent:BBMouseEvent;

			if (_size > 0)
			{
				mouseEvent = _pool[--_size];
				_pool[_size] = null;

				mouseEvent.type = p_type;
				mouseEvent.target = p_target;
				mouseEvent.dispatcher = p_dispatcher;
				mouseEvent.localX = p_localX;
				mouseEvent.localY = p_localY;
				mouseEvent.isButtonDown = p_buttonDown;
				mouseEvent.isCtrlDown = p_ctrlDown;
				mouseEvent._isDisposed = false;
			}
			else mouseEvent = new BBMouseEvent(p_type, p_target, p_dispatcher, p_localX, p_localY, p_buttonDown, p_ctrlDown);

			return mouseEvent;
		}

		/**
		 */
		static private function put(p_mouseEvent:BBMouseEvent):void
		{
			if (_pool == null) _pool = new <BBMouseEvent>[];
			_pool[_size++] = p_mouseEvent;
		}

		/**
		 * Returns number of elements in pool.
		 */
		static public function get size():int
		{
			return _size;
		}

		/**
		 * Rid the pool.
		 */
		static public function rid():void
		{
			if (_pool)
			{
				for (var i:int = 0; i < _size; i++)
				{
					_pool[i] = null;
				}

				_size = 0;
				_pool.length = 0;
				_pool = null;
			}
		}
	}
}
