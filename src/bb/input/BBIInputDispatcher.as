/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 14:45
 */
package bb.input
{
	/**
	 * Represents of interface of dispatcher input data. Use in conjunction with BBIInputListener.
	 */
	public interface BBIInputDispatcher
	{
		function addListener(p_listener:BBIInputListener, p_channel:int = 0):void;
		function removeListener(p_listener:BBIInputListener):void;
		function get inputType():String;
		function pushIncoming(p_code:int, p_data:Object = null):void;
		function pushOutgoing(p_code:int, p_data:Object = null):void;
		function enableChannels(p_channelIds:Array):void;
		function get channels():Array;
		function set enableDispatching(p_val:Boolean):void;
		function get enableDispatching():Boolean;
		function dispatch(p_deltaTime:int):void;
		function dispose():void;
	}
}
