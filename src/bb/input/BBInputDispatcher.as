/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 16:34
 */
package bb.input
{
	import bb.signals.BBSignal;

	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	/**
	 * Implementation of BBIInputDispatcher.
	 */
	public class BBInputDispatcher implements BBIInputDispatcher
	{
		// Using these signal is the fastest way to get in\out actions.
		// Using these way can't to know what action name
		private var _onActionIn:BBSignal;
		private var _onActionOut:BBSignal;
		private var _onActionsHolding:BBSignal;

		//
		private var _channels:Dictionary;
		private var _inputType:String;
		private var _enableDispatching:Boolean = false;
		private var _actions:BBActionsHolder;

		//
		private var _prevTime:int = 0;
		private var _timeBuffer:int = 0;

		/**
		 * Determines how often 'dispatch' method is invoked. By default it is set to 0, mean that method is invoked as often as app runs.
		 * It can be helpful if app has high frame rate and need to keep dispatching between specific time range.
		 * It is could be need because of if dispatching happens often and therefore controlling game object handled faster then need.
		 * E.g. if app runs in different frame rates, but controlling games object is calculated for 30 fps, therefore should to set up dispatchTime to 33 (ms).
		 */
		public var dispatchTime:int = 0;

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
		final private function getChannel(p_channelId:int):BBInputChannel
		{
			return _channels[String(p_channelId)];
		}

		/**
		 */
		[Inline]
		final private function createChannel(p_channelId:int):BBInputChannel
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
		final private function getActionData(p_code:int, p_data:Object):BBActionData
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
		public function dispatch():void
		{
			var currentTime:int = getTimer();
			_timeBuffer += currentTime - _prevTime;

			if (_timeBuffer > dispatchTime)
			{
				_actions.deltaTime = _timeBuffer;
				_timeBuffer = 0;

				if (_enableDispatching && _actions.numActions > 0)
				{
					if (_onActionsHolding) _onActionsHolding.dispatch(_actions);

					for each(var channel:BBInputChannel in _channels)
					{
						if (channel.enabled) channel.dispatch(_actions);
					}
				}

				_prevTime = currentTime;
			}
		}

		/**
		 * Enables channels for dispatching which were set in p_channelIds array. Other channels will disabled.
		 * p_channelIds - array with ids of channels should be enabled for dispatching.
		 * E.g. - p_channelIds[0,1,2,3]
		 */
		public function enableChannels(p_channelIds:Array):void
		{
			var channel:BBInputChannel;

			for each (channel in _channels)
			{
				channel.enabled = false;
			}

			var num:int = p_channelIds.length;
			for (var i:int = 0; i < num; i++)
			{
				channel = getChannel(p_channelIds[i]);
				if (channel) channel.enabled = true;
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
		 * Makes mapping between action code and action name and attaches to specific channel.
		 * p_actions - array with mapping.
		 * E.g.
		 * p_actions = [
		 *                  Keyboard.UP, "fly",
		 *                  Keyboard.DOWN, "sit",
		 *                  Keyboard.LEFT, "runLeft",
		 *                  Keyboard.RIGHT, "runRight"
		 *             ]
		 */
		public function actionsMapping(p_actions:Array, p_channel:int = 0):void
		{
			var channel:BBInputChannel = getChannel(p_channel);
			if (channel == null) channel = createChannel(p_channel);
			var len:int = p_actions.length;

			for (var i:int = 0; i < len; i+=2)
			{
				channel.addActionMapping(p_actions[i], p_actions[i+1]);
			}
		}

		/**
		 * Clear all actions.
		 */
		public function clearActions():void
		{
			_actions.removeAll();
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
			_prevTime = getTimer();
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
		public function get onActionsHolding():BBSignal
		{
			if (_onActionsHolding == null) _onActionsHolding = BBSignal.get(this);
			return _onActionsHolding;
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
