/**
 * User: VirtualMaestro
 * Date: 05.07.13
 * Time: 14:56
 */
package bb.input
{
	/**
	 * Class which stored data dispatched by input devices like keyboard, joystick...
	 */
	public class BBActionData
	{
		public var actionName:String = "";
		public var code:int = -1;
		public var data:Object;

		public var actionsHolding:BBActionsHolder;

		/**
		 */
		public function BBActionData(p_code:int = -1, p_data:Object = null)
		{
			code = p_code;
			data = p_data;
		}

		/**
		 */
		public function dispose():void
		{
			actionName = "";
			code = -1;
			data = null;
			actionsHolding = null;
		}
	}
}
