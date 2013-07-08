/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 14:56
 */
package bb.input
{
	/**
	 * Class which stored data dispatched by input devices like keyboard, joystick...
	 */
	public class BBActionData
	{
		public var actionName:String = "";
		public var code:int = -1;
		public var data:Object;

		public var actionsHolding:BBActionsHolder;

		/**
		 */
		public function BBActionData(p_code:int = -1, p_data:Object = null)
		{
			code = p_code;
			data = p_data;
		}

		/**
		 */
		public function dispose():void
		{
			actionName = "";
			code = -1;
			data = null;
			actionsHolding = null;

			put(this);
		}

		///////////////////
		/// POOL /////////
		//////////////////

		static private var _pool:Vector.<BBActionData> = new <BBActionData>[];
		static private var _size:int = 0;

		/**
		 */
		static public function get(p_code:int, p_data:Object = null):BBActionData
		{
			var actionData:BBActionData;
			if (_size > 0)
			{
				 actionData = _pool[--_size];
				actionData.code = p_code;
				actionData.data = p_data;
				_pool[_size] = null;
			}
			else actionData = new BBActionData(p_code, p_data);

			return actionData;
		}

		/**
		 */
		static private function put(p_actionData:BBActionData):void
		{
			_pool[_size++] = p_actionData;
		}

		/**
		 */
		static public function rid():void
		{
			var actionData:BBActionData;
			for (var i:int = 0; i < _size; i++)
			{
				actionData = _pool[i];
				_pool[i] = null;
				actionData.actionName = null;
			}

			_size = 0;
			_pool.length = 0;
			_pool = new <BBActionData>[];
		}
	}
}
