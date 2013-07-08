/**
 * User: VirtualMaestro
 * Date: 07.07.13
 * Time: 15:44
 */
package bb.input
{
	/**
	 *
	 */
	public class BBActionsHolder
	{
		//
		internal var currentChannel:BBInputChannel;

		//
		public var deltaTime:int = 0;
		public var inputType:String = "";

		/**
		 * Storage for actions.
		 * Associative array where key is code of action (represented as String), value - action itself.
		 */
		private var _actionListCode:Array;
		private var _numActions:int = 0;

		/**
		 */
		public function BBActionsHolder()
		{
			_actionListCode = [];
		}

		/**
		 * Adds given action to storage.
		 */
		public function add(p_action:BBActionData):void
		{
			_actionListCode[String(p_action.code)] = p_action;

			_numActions++;
		}

		/**
		 * Removes given action from storage.
		 */
		public function remove(p_action:BBActionData):void
		{
			_actionListCode[String(p_action.code)] = null;

			_numActions--;
		}

		/**
		 * Removes all actions.
		 */
		public function removeAll():void
		{
			if (_numActions > 0)
			{
				for each(var action:BBActionData in _actionListCode)
				{
					if (action)
					{
						var actionCode:String = String(action.code);
						_actionListCode[actionCode] = null;
						delete _actionListCode[actionCode];

						action.dispose();
					}
				}

				_numActions = 0;
			}
		}

		/**
		 * Checks if action with given name exists.
		 */
		public function hasByName(p_actionName:String):Boolean
		{
			if (currentChannel)
			{
				return Object(currentChannel.getActionCode(p_actionName)) != null;
			}

			return false;
		}

		/**
		 * Checks if action with given code exists.
		 */
		public function hasByCode(p_actionCode:int):Boolean
		{
			return _actionListCode[String(p_actionCode)] != null;
		}

		/**
		 * Iterate through all actions.
		 */
		public function forEach(p_forEach:Function):void
		{
			for each (var action:BBActionData in _actionListCode)
			{
				if (action) p_forEach(action);
			}
		}

		/**
		 */
		public function get numActions():int
		{
			return _numActions;
		}

		/**
		 */
		public function dispose():void
		{
			currentChannel = null;
			inputType = null;
			removeAll();
			_actionListCode = null;
			_numActions = 0;
		}
	}
}
