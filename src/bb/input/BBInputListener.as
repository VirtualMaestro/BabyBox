/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 18:08
 */
package bb.input
{
	import bb.signals.BBSignal;

	/**
	 * Implementation of BBIInputListener
	 */
	public class BBInputListener implements BBIInputListener
	{
		private var _onAddedListener:BBSignal;
		private var _onUnlinkedListener:BBSignal;

		private var _channel:int = 0;

		/**
		 */
		public function BBInputListener()
		{
			onAddedListener.add(setChannel);
		}

		/**
		 * Dispatched when listener was added to dispatcher.
		 */
		public function get onAddedListener():BBSignal
		{
			if (_onAddedListener == null) _onAddedListener = BBSignal.get(this);
			return _onAddedListener;
		}

		/**
		 * Dispatches when listener was unlinked from dispatcher.
		 */
		public function get onUnlinkedListener():BBSignal
		{
			if (_onUnlinkedListener == null) _onUnlinkedListener = BBSignal.get(this);
			return _onUnlinkedListener;
		}

		/**
		 */
		public function unlinkListener():void
		{
			if (_onUnlinkedListener) _onUnlinkedListener.dispatch();
		}

		/**
		 * Invokes immediately when action in.
		 * As param sets BBActionData instance which come in.
		 */
		public function actionIn(p_actionData:BBActionData):void
		{
			//
		}

		/**
		 * Invokes one times per game loop.
		 */
		public function actionsHolding(p_actions:BBActionsHolder):void
		{
			//
		}

		/**
		 * Invokes immediately when action out (leave).
		 * As param sets BBActionData instance which leave.
		 */
		public function actionOut(p_actionData:BBActionData):void
		{
			//
		}

		/**
		 */
		private function setChannel(p_signal:BBSignal):void
		{
			_channel = p_signal.params as int;
		}

		/**
		 * Returns number of channel which current listener attached to.
		 */
		public function get channel():int
		{
			return _channel;
		}

		/**
		 */
		public function dispose():void
		{
			unlinkListener();

			_onAddedListener.dispose();
			_onAddedListener = null;
			_onUnlinkedListener.dispose();
			_onUnlinkedListener = null;
			_channel = 0;
		}
	}
}
