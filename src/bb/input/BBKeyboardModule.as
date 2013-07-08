/**
 * User: VirtualMaestro
 * Date: 04.07.13
 * Time: 14:29
 */
package bb.input
{
	import bb.input.constants.BBInputType;
	import bb.modules.BBModule;
	import bb.signals.BBSignal;

	import flash.events.KeyboardEvent;

	/**
	 * Represents controller like keyboard.
	 */
	public class BBKeyboardModule extends BBModule
	{
		//
		private var _inputDispatcher:BBInputDispatcher;

		/**
		 */
		public function BBKeyboardModule()
		{
			super();

			_inputDispatcher = new BBInputDispatcher(BBInputType.KEYBOARD);

			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			enableDispatching = true;
		}

		/**
		 */
		private function keyboardDownHandler(p_event:KeyboardEvent):void
		{
			_inputDispatcher.pushIncoming(p_event.keyCode, p_event)
		}

		/**
		 */
		private function keyboardUpHandler(p_event:KeyboardEvent):void
		{
			_inputDispatcher.pushOutgoing(p_event.keyCode, p_event)
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			_inputDispatcher.dispatch(p_deltaTime);
		}

		/**
		 */
		override public function dispose():void
		{
			enableDispatching = false;
			_inputDispatcher.dispose();

			super.dispose();
		}

		/**
		 * Adds given listener to specific channel.
		 */
		public function addListener(p_listener:BBIInputListener, p_channel:int = 0):void
		{
			_inputDispatcher.addListener(p_listener, p_channel);
		}

		/**
		 * Removes given listener from the list.
		 */
		public function removeListener(p_listener:BBIInputListener):void
		{
			_inputDispatcher.removeListener(p_listener);
		}

		/**
		 * Removes all attached listeners.
		 */
		public function removeAllListeners():void
		{
			_inputDispatcher.removeAllListeners();
		}

		/**
		 * Enables channels for dispatching which were set in p_channelIds array. Other channels will disabled.
		 * p_channelIds - array with ids of channels should be enabled for dispatching.
		 * if p_channelIds array is empty it is disable all channels.
		 * E.g. - p_channelIds[0,1,2,3]
		 */
		public function enableChannels(p_channelIds:Array):void
		{
			_inputDispatcher.enableChannels(p_channelIds);
		}

		/**
		 * Returns existing channels - array with channel's ids.
		 * E.g. channels[0,1,2,3...]
		 */
		public function get channels():Array
		{
			return _inputDispatcher.channels;
		}

		/**
		 * Makes mapping between button code and action name and attaches to specific channel.
		 * p_actions - array with mapping.
		 * E.g.
		 * p_actions = [
		 *                  Keyboard.UP, "fly",
		 *                  Keyboard.DOWN, "sit",
		 *                  Keyboard.LEFT, "runLeft",
		 *                  Keyboard.RIGHT, "runRight"
		 *             ]
		 */
		public function addButtonsMapping(p_actions:Array, p_channel:int = 0):void
		{
			_inputDispatcher.actionsMapping(p_actions, p_channel);
		}

		/**
		 */
		public function set enableDispatching(p_val:Boolean):void
		{
			_inputDispatcher.enableDispatching = p_val;
			updateEnable = p_val;

			if (stage)
			{
				if (p_val)
				{
					stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardDownHandler);
					stage.addEventListener(KeyboardEvent.KEY_UP, keyboardUpHandler);
				}
				else
				{
					stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardDownHandler);
					stage.removeEventListener(KeyboardEvent.KEY_UP, keyboardUpHandler);
				}
			}
		}

		/**
		 */
		public function get enableDispatching():Boolean
		{
			return _inputDispatcher.enableDispatching;
		}

		/**
		 * Simplest way to listen key down (without implementing any interfaces).
		 * With this signal you can't use keys map, so you can't to know action name (can't use actionName of BBActionData)
		 * As parameter sends BBActionData.
		 */
		public function get onDown():BBSignal
		{
			return _inputDispatcher.onActionIn;
		}

		/**
		 * Simplest way to listen key up (without implementing any interfaces)
		 * With this signal you can't use keys map, so you can't to know action name (can't use actionName of BBActionData)
		 * As parameter sends BBActionData.
		 */
		public function get onUp():BBSignal
		{
			return _inputDispatcher.onActionOut;
		}
	}
}
