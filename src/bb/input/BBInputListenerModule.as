/**
 * User: VirtualMaestro
 * Date: 08.07.13
 * Time: 18:44
 */
package bb.input
{
	import bb.modules.BBModule;
	import bb.signals.BBSignal;

	/**
	 * Implementation listener functionality in module.
	 * It is help to implement listener in specific module - need just extends BBInputListenerModule.
	 */
	public class BBInputListenerModule extends BBModule implements BBIInputListener
	{
		private var _inputListener:BBInputListener;
		private var _onUnlinkedListener:BBSignal;

		/**
		 */
		public function BBInputListenerModule()
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
		 */
		public function actionIn(p_action:BBActionData):void
		{
			// override in children
		}

		/**
		 * Invokes every update.
		 */
		public function actionsHolding(p_actions:BBActionsHolder):void
		{
			// override in children
		}

		/**
		 * Invokes immediately when action out (leave).
		 */
		public function actionOut(p_action:BBActionData):void
		{
			// override in children
		}

		/**
		 * Returns number of channel to which the listener is attached.
		 */
		public function get channel():int
		{
			return _inputListener.channel;
		}

		/**
		 */
		override public function dispose():void
		{
			_inputListener.dispose();
			_inputListener = null;
			_onUnlinkedListener.dispose();
			_onUnlinkedListener = null;

			super.dispose();
		}
	}
}
