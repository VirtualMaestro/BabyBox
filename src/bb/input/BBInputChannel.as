/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 15:47
 */
package bb.input
{
	/**
	 */
	internal class BBInputChannel
	{
		//
		public var enabled:Boolean = true;

		/**
		 * Mapping of actions.
		 * key is code of action (as string), value - action name.
		 * E.g. [String(Keyboard.UP), "fly"]
		 */
		private var _keysMap:Array;

		private var _id:int = 0;
		private var _list:Array = [];

		/**
		 */
		public function BBInputChannel(p_id:int = 0)
		{
			_id = p_id;
			_keysMap = [];
		}

		/**
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Adds listener to channel.
		 */
		public function addListener(p_listener:BBIInputListener):void
		{
			_list.push(p_listener);
			p_listener.onAddedListener.dispatch(_id);
		}

		/**
		 * Removes listener from channel.
		 */
		public function removeListener(p_listener:BBIInputListener):void
		{
			_list.splice(_list.indexOf(p_listener), 1);
			p_listener.onUnlinkedListener.dispatch();
		}

		/**
		 * Removes all listeners.
		 */
		public function removeAllListeners():void
		{
			var listener:BBIInputListener;
			var num:int = _list.length;
			for (var i:int = 0; i < num; i++)
			{
				listener = _list[i];
				listener.onUnlinkedListener.dispatch();
			}
		}

		/**
		 * Adds mapping of the key.
		 * E.g. for keyboard - addKey(Keyboard.UP, "jump");
		 */
		public function addKey(p_code:int, p_actionName:String):void
		{
			_keysMap[String(p_code)] = p_actionName;
		}

		/**
		 *
		 */
		public function removeKey(p_code:int):void
		{
			if (_keysMap[String(p_code)] != null) delete _keysMap[String(p_code)];
		}

		/**
		 * Removes mapping table of actions.
		 */
		public function clearKeys():void
		{
			_keysMap = [];
		}

		/**
		 * Returns action name by given code of action.
		 */
		public function getActionName(p_code:int):String
		{
			return _keysMap[String(p_code)];
		}

		/**
		 */
		public function dispatchIncoming(p_action:BBActionData):void
		{
			p_action.actionsHolding.currentChannel = this;

			var listener:BBIInputListener;
			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				listener = _list[i];
				listener.actionIn(p_action);
			}
		}

		/**
		 */
		public function dispatchOutgoing(p_action:BBActionData):void
		{
			p_action.actionsHolding.currentChannel = this;

			var listener:BBIInputListener;
			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				listener = _list[i];
				listener.actionOut(p_action);
			}
		}

		/**
		 */
		public function dispatch(p_actions:BBActionsHolder):void
		{
			p_actions.currentChannel = this;

			var listener:BBIInputListener;
			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				listener = _list[i];
				listener.actionsHolding(p_actions);
			}
		}
	}
}
