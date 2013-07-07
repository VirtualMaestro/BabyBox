/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 14:01
 */
package bb.input
{
	import bb.signals.BBSignal;

	/**
	 * Any entity who wants to listen input events (input devices like keyboard, joystick...) have to implement this interface.
	 */
	public interface BBIInputListener
	{
		function get onAddedListener():BBSignal;
		function get onUnlinkedListener():BBSignal;
		function unlinkListener():void;

		/**
		 * Invokes immediately when action in.
		 * As param sets BBActionData instance which come in.
		 */
		function actionIn(p_action:BBActionData):void;

		/**
		 * Invokes one time per game loop.
		 */
		function actionsHolding(p_actions:BBActionsHolder):void;

		/**
		 * Invokes immediately when action out (leave).
		 * As param sets BBActionData instance which leave.
		 */
		function actionOut(p_action:BBActionData):void;
		function get channel():int;
		function dispose():void;
	}
}
