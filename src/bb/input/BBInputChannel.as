/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 15:47
 */
package bb.input
{
	import flash.utils.Dictionary;

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
		private var _actionsMap:Dictionary;

		/**
		 * Stored actions names.
		 */
		private var _actionsNames:Dictionary;

		private var _id:int = 0;
		private var _list:Vector.<BBIInputListener>;

		/**
		 */
		public function BBInputChannel(p_id:int = 0)
		{
			_id = p_id;
			_list = new <BBIInputListener>[];
			_actionsMap = new Dictionary();
			_actionsNames = new Dictionary();
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
			var num:int = _list.length;
			for (var i:int = 0; i < num; i++)
			{
				_list[i].onUnlinkedListener.dispatch();
			}
		}

		/**
		 * Adds mapping of the key.
		 * E.g. for keyboard - addActionMapping(Keyboard.UP, "jump");
		 */
		public function addActionMapping(p_code:int, p_actionName:String):void
		{
			_actionsMap[String(p_code)] = p_actionName;
			_actionsNames[p_actionName] = p_code;
		}

		/**
		 * Removes specify action mapping by given code of action.
		 */
		public function removeActionMapping(p_code:int):void
		{
			var actionCode:String = String(p_code);
			var actionName:String = _actionsMap[actionCode];
			if (actionName != null)
			{
				delete _actionsMap[actionCode];
				delete _actionsNames[actionName];
			}
		}

		/**
		 * Removes mapping table of actions.
		 */
		public function clearActionsMapping():void
		{
			_actionsMap = new Dictionary();
			_actionsNames = new Dictionary();
		}

		/**
		 * Returns action name by given code of action.
		 */
		public function getActionName(p_code:int):String
		{
			return _actionsMap[String(p_code)];
		}

		/**
		 * Returns action code by given action name.
		 */
		public function getActionCode(p_actionName:String):int
		{
			return _actionsNames[p_actionName];
		}

		/**
		 */
		public function dispatchIncoming(p_action:BBActionData):void
		{
			p_action.actionsHolding.currentChannel = this;

			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				_list[i].actionIn(p_action);
			}
		}

		/**
		 */
		public function dispatchOutgoing(p_action:BBActionData):void
		{
			p_action.actionsHolding.currentChannel = this;

			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				_list[i].actionOut(p_action);
			}
		}

		/**
		 */
		public function dispatch(p_actions:BBActionsHolder):void
		{
			p_actions.currentChannel = this;

			var len:int = _list.length;
			for (var i:int = 0; i < len; i++)
			{
				_list[i].actionsHolding(p_actions);
			}
		}

		/**
		 */
		public function dispose():void
		{
			removeAllListeners();
			_actionsMap = null;
			_actionsNames = null;
			_list = null;
			enabled = false;
		}
	}
}
