/**
 * User: VirtualMaestro
 * Date: 29.06.13
 * Time: 12:17
 */
package bb.ai.components
{
	import bb.core.BBComponent;
	import bb.signals.BBSignal;

	import bb_fsm.BBFSM;

	/**
	 * Component implemented FSM for describing logic in states.
	 */
	public class BBFSMComponent extends BBComponent
	{
		private var _fsm:BBFSM;
		private var _defaultState:Class;
		private var _isStack:Boolean = false;

		/**
		 */
		public function BBFSMComponent()
		{
			super();
		}

		override protected function init():void
		{
			onAdded.add(addedToNode);
		}

		/**
		 */
		private function addedToNode(p_signal:BBSignal):void
		{
			if (_fsm == null && _defaultState) _fsm = BBFSM.get(node, _defaultState, _isStack);
			updateEnable = true;
		}

		/**
		 */
		override public function set updateEnable(p_val:Boolean):void
		{
			super.updateEnable = p_val && _fsm;
		}

		/**
		 * Initializes FSM.
		 * IMPORTANT: component won't working without invoking of this method, you should to set default state for FSM.
		 */
		protected function initFSM(p_defaultState:Class, p_isStack:Boolean = false):void
		{
			if (_fsm == null)
			{
				_defaultState = p_defaultState;
				_isStack = p_isStack;

				if (node)
				{
					_fsm = BBFSM.get(node, _defaultState, _isStack);
					updateEnable = true;
				}
			}
		}

		/**
		 */
		public function get fsm():BBFSM
		{
			return _fsm;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			_fsm.update(p_deltaTime);
		}

		/**
		 */
		override protected function destroy():void
		{
			_fsm.dispose();
			_fsm = null;
			_defaultState = null;
			_isStack = false;

			super.destroy();
		}

		/**
		 */
		override public function copy():BBComponent
		{
			var copied:BBFSMComponent = super.copy() as BBFSMComponent;
			copied.initFSM(_defaultState, _isStack);

			return copied;
		}

		/**
		 * TODO: Implement
		 */
		override public function getPrototype():XML
		{
			return super.getPrototype();
		}

		/**
		 */
		static public function get(p_defaultState:Class, p_isStack:Boolean = false):BBFSMComponent
		{
			var fsmComponent:BBFSMComponent = BBComponent.get(BBFSMComponent) as BBFSMComponent;
			fsmComponent.initFSM(p_defaultState, p_isStack);

			return fsmComponent;
		}
	}
}
