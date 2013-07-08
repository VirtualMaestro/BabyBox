/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 16:34
 */
package bb.input
{
	import bb.signals.BBSignal;

	import flash.utils.Dictionary;

	/**
	 * Implementation of BBIInputDispatcher.
	 */
	public class BBInputDispatcher implements BBIInputDispatcher
	{
		// Using these signal is the fastest way to get in\out actions.
		// Using these way can't to know what action name
		private var _onActionIn:BBSignal;
		private var _onActionOut:BBSignal;

		//
		private var _channels:Dictionary;
		private var _inputType:String;
		private var _enableDispatching:Boolean = true;
		private var _actions:BBActionsHolder;

		/**
		 * p_inputType - use BBInputType.
		 */
		public function BBInputDispatcher(p_inputType:String)
		{
			_channels = new Dictionary();
			_inputType = p_inputType;
			_actions = new BBActionsHolder();
			_actions.inputType = _inputType;

			createChannel(0); // creates default channel
		}

		/**
		 */
		public function addListener(p_listener:BBIInputListener, p_channel:int = 0):void
		{
			var channel:BBInputChannel = getChannel(p_channel);
			if (channel == null) channel = createChannel(p_channel);

			channel.addListener(p_listener);
		}

		/**
		 */
		public function removeListener(p_listener:BBIInputListener):void
		{
			var channel:BBInputChannel = getChannel(p_listener.channel);
			if (channel != null) channel.removeListener(p_listener);
		}

		/**
		 * Removes all listeners of given channel.
		 */
		public function removeChannelListeners(p_channel:int):void
		{
			var channel:BBInputChannel = getChannel(p_channel);
			if (channel != null) channel.removeAllListeners();
		}

		/**
		 * Removes all listeners of all channels.
		 */
		public function removeAllListeners():void
		{
			for each(var channel:BBInputChannel in _channels)
			{
				channel.removeAllListeners();
			}
		}

		/**
		 */
		[Inline]
		private function getChannel(p_channelId:int):BBInputChannel
		{
			return _channels[String(p_channelId)];
		}

		/**
		 */
		[Inline]
		private function createChannel(p_channelId:int):BBInputChannel
		{
			var channel:BBInputChannel = new BBInputChannel(p_channelId);
			_channels[String(p_channelId)] = channel;

			return channel;
		}

		/**
		 * p_code - if device is keyboard then code is code of key.
		 * If same p_code already in it is ignores.
		 */
		public function pushIncoming(p_code:int, p_data:Object = null):void
		{
			if (!_actions.hasByCode(p_code))
			{
				var action:BBActionData = getActionData(p_code, p_data);
				_actions.add(action);

				dispatchIncoming(action);
			}
		}

		/**
		 */
		public function pushOutgoing(p_code:int, p_data:Object = null):void
		{
			var action:BBActionData = getActionData(p_code, p_data);
			_actions.remove(action);

			dispatchOutgoing(action);
		}

		/**
		 */
		[Inline]
		private function getActionData(p_code:int, p_data:Object):BBActionData
		{
			var action:BBActionData = BBActionData.get(p_code, p_data);
			action.actionsHolding = _actions;

			return action;
		}

		/**
		 */
		private function dispatchIncoming(p_action:BBActionData):void
		{
			if (_enableDispatching)
			{
				if (_onActionIn) _onActionIn.dispatch(p_action);

				for each(var channel:BBInputChannel in _channels)
				{
					if (channel.enabled) channel.dispatchIncoming(p_action);
				}
			}
		}

		/**
		 */
		private function dispatchOutgoing(p_action:BBActionData):void
		{
			if (_enableDispatching)
			{
				if (_onActionOut) _onActionOut.dispatch(p_action);

				for each(var channel:BBInputChannel in _channels)
				{
					if (channel.enabled) channel.dispatchOutgoing(p_action);
				}

				p_action.dispose();
			}
		}

		/**
		 * Sends all gathered actions.
		 * p_deltaTime - delta time between two dispatching in milliseconds
		 */
		public function dispatch(p_deltaTime:int):void
		{
			_actions.deltaTime = p_deltaTime;

			if (_enableDispatching && _actions.numActions > 0)
			{
				for each(var channel:BBInputChannel in _channels)
				{
					if (channel.enabled) channel.dispatch(_actions);
				}
			}
		}

		/**
		 * Enable/disable channels for dispatching.
		 * p_channelIds - array with ids of channels should be enabled for dispatching.
		 */
		public function enableChannels(p_channelIds:Array, p_enable:Boolean):void
		{
			var channel:BBInputChannel;
			for (var channelId:String in _channels)
			{
				channel = _channels[channelId];
				if (channel) channel.enabled = p_enable;
			}
		}

		/**
		 * Returns array with channel's ids.
		 */
		public function get channels():Array
		{
			var channels:Array = [];
			var counter:int = 0;
			for each(var channel:BBInputChannel in _channels)
			{
				channels[counter++] = channel.id;
			}

			return channels;
		}

		/**
		 * Removes all channels and clear all their listeners.
		 * Default channel (0) is not removed, but its listeners also clear.
		 */
		public function removeChannels():void
		{
			var channel:BBInputChannel;
			for (var channelNum:String in _channels)
			{
				if (channelNum == "0") continue;
				channel = _channels[channelNum];
				channel.dispose();
				delete _channels[channelNum];
			}
		}

		/**
		 */
		public function get inputType():String
		{
			return _inputType;
		}

		/**
		 */
		public function set enableDispatching(p_val:Boolean):void
		{
			_enableDispatching = p_val;
		}

		/**
		 */
		public function get enableDispatching():Boolean
		{
			return _enableDispatching;
		}

		/**
		 */
		public function get onActionIn():BBSignal
		{
			if (_onActionIn == null) _onActionIn = BBSignal.get(this);
			return _onActionIn;
		}

		/**
		 */
		public function get onActionOut():BBSignal
		{
			if (_onActionOut == null) _onActionOut = BBSignal.get(this);
			return _onActionOut;
		}

		/**
		 */
		public function dispose():void
		{
			if (_onActionIn) _onActionIn.dispose();
			_onActionIn = null;
			if (_onActionOut) _onActionOut.dispose();
			_onActionOut = null;

			removeChannels();
			_channels = null;
			_actions.dispose();
			_actions = null;
		}
	}
}
