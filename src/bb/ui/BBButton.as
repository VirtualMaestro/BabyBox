/**
 * User: VirtualMaestro
 * Date: 25.07.13
 * Time: 15:26
 */
package bb.ui
{
	import bb.core.BBComponent;
	import bb.mouse.events.BBMouseEvent;
	import bb.render.components.BBSprite;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;

	/**
	 * Represents button.
	 * For creating instance of class use static method 'get'.
	 */
	public class BBButton extends BBSprite
	{
		private var _upState:BBTexture;
		private var _downState:BBTexture;
		private var _overState:BBTexture;
		private var _isOver:Boolean = false;

		/**
		 */
		public function BBButton()
		{
			super();
		}

		/**
		 */
		public function set upState(p_val:BBTexture):void
		{
			_upState = p_val;
			setTexture(_upState);
		}

		/**
		 */
		public function set downState(p_val:BBTexture):void
		{
			if (_downState == p_val) return;
			_downState = p_val;

			//
			if (_downState)
			{
				node.onMouseDown.add(handleMouse);
				node.onMouseUp.add(handleMouse);
			}
			else
			{
				node.onMouseDown.remove(handleMouse);
				node.onMouseUp.remove(handleMouse);
			}
		}

		/**
		 */
		public function set overState(p_val:BBTexture):void
		{
			if (_overState == p_val) return;
			_overState = p_val;

			//
			if (_overState)
			{
				node.onMouseOver.add(handleMouse);
				node.onMouseOut.add(handleMouse);
			}
			else
			{
				node.onMouseOver.remove(handleMouse);
				node.onMouseOut.remove(handleMouse);
			}
		}

		/**
		 */
		private function handleMouse(p_signal:BBSignal):void
		{
			var event:BBMouseEvent = p_signal.params as BBMouseEvent;

			switch (event.type)
			{
				case BBMouseEvent.DOWN:
				{
					setTexture(_downState);
					break;
				}

				case BBMouseEvent.UP:
				{
					_isOver ? setTexture(_overState) : setTexture(_upState);
					break;
				}

				case BBMouseEvent.OVER:
				{
					_isOver = true;

					setTexture(_overState);
					break;
				}

				case BBMouseEvent.OUT:
				{
					_isOver = false;

					setTexture(_upState);
					break;
				}
			}
		}

		/**
		 */
		override public function dispose():void
		{
			_upState = null;
			_downState = null;
			_overState = null;
			_isOver = false;

			super.dispose();
		}

		/**
		 * Methods creates instance of BBButton.
		 * Component created with node and properly settings.
		 */
		static public function get(p_upState:BBTexture, p_downState:BBTexture = null, p_overState:BBTexture = null):BBButton
		{
			var button:BBButton = BBComponent.getWithNode(BBButton) as BBButton;
			button.upState = p_upState;
			button.downState = p_downState;
			button.overState = p_overState;
			button.node.mouseSettings = BBMouseEvent.OVER | BBMouseEvent.OUT | BBMouseEvent.UP | BBMouseEvent.DOWN;

			return button;
		}
	}
}
