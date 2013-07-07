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
		 * Signal dispatches when listener was unlinked from source.
		 */
		public function get onUnlinkedListener():BBSignal
		{
			return _inputListener.onUnlinkedListener;
		}

		/**
		 * Unlink listener from source.
		 */
		public function unlinkListener():void
		{
			_inputListener.unlinkListener();
		}

		/**
		 */
		override public function dispose():void
		{
			if (!isDisposed)
			{
				_inputListener.dispose();
				super.dispose();
			}
		}


		public function get channel():int
		{
			return 0;
		}

		public function actionIn(p_action:BBActionData):void
		{
		}

		public function actionsHolding(p_actions:BBActionsHolder):void
		{
		}

		public function actionOut(p_action:BBActionData):void
		{
		}
	}
}
