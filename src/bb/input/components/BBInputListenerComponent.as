/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 14:23
 */
package bb.input.components
{
	import bb.core.BBComponent;
	import bb.input.BBActionData;
	import bb.input.BBActionsHolder;
	import bb.input.BBIInputListener;
	import bb.input.BBInputListener;
	import bb.signals.BBSignal;

	/**
	 */
	public class BBInputListenerComponent extends BBComponent implements BBIInputListener
	{
		//
		private var _inputListener:BBInputListener;
		private var _onUnlinkedListener:BBSignal;

		/**
		 */
		public function BBInputListenerComponent()
		{
			super();

			_inputListener = new BBInputListener();
		}

		/**
		 */
		public function get onAddedListener():BBSignal
		{
			return _inputListener.onAddedListener;
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
		 * Unlink listener from source.
		 */
		public function unlinkListener():void
		{
			if (_onUnlinkedListener) _onUnlinkedListener.dispatch();
		}

		/**
		 */
		override public function dispose():void
		{
			if (!isDisposed)
			{
				_inputListener.dispose();
				if (_onUnlinkedListener) _onUnlinkedListener.removeAllListeners();

				super.dispose();
			}
		}

		/**
		 */
		override protected function rid():void
		{
			super.rid();

			if (_onUnlinkedListener) _onUnlinkedListener.dispose();
			_onUnlinkedListener = null;
			_inputListener = null;
		}

		/**
		 */
		public function get channel():int
		{
			return _inputListener.channel;
		}

		/**
		 */
		public function actionIn(p_action:BBActionData):void
		{
			// override in children
		}

		/**
		 */
		public function actionsHolding(p_actions:BBActionsHolder):void
		{
			// override in children
		}

		/**
		 */
		public function actionOut(p_action:BBActionData):void
		{
			// override in children
		}
	}
}
