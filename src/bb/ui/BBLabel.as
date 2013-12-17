/**
 * User: VirtualMaestro
 * Date: 18.07.13
 * Time: 16:05
 */
package bb.ui
{
	import bb.core.BBComponent;
	import bb.render.components.BBSprite;
	import bb.render.textures.BBTexture;

	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	/**
	 * Represents label.
	 * Should to use only for label (unchanging text).
	 * It is possible to change text in runtime but every time creates new texture.
	 */
	public class BBLabel extends BBSprite
	{
		//
		private var _textField:TextField;
		private var _textFormat:TextFormat;
		private var _alignByCenter:Boolean = true;

		/**
		 */
		public function BBLabel()
		{
			super();
			_textField = new TextField();
			_textField.autoSize = TextFieldAutoSize.RIGHT;
			_textField.multiline = true;
			_textField.antiAliasType = AntiAliasType.ADVANCED;
			_textFormat = _textField.defaultTextFormat;
		}

		/**
		 */
		public function set textField(p_val:TextField):void
		{
			_textField = p_val;
			_textFormat = _textField.getTextFormat();
			updateEnable = true;
		}

		/**
		 */
		public function get textField():TextField
		{
			return _textField;
		}

		/**
		 */
		public function set text(p_val:String):void
		{
			_textField.text = p_val;
			updateEnable = true;
		}

		/**
		 */
		public function get text():String
		{
			return _textField.text;
		}

		/**
		 */
		public function set wordWrap(p_val:Boolean):void
		{
			_textField.wordWrap = p_val;
		}

		/**
		 */
		public function get wordWrap():Boolean
		{
			return _textField.wordWrap;
		}

		/**
		 */
		override public function set width(p_val:Number):void
		{
			_textField.width = p_val;
		}

		/**
		 */
		override public function get width():Number
		{
			return _textField.width;
		}

		/**
		 */
		override public function set height(p_val:Number):void
		{
			_textField.height = p_val;
		}

		override public function get height():Number
		{
			return _textField.height;
		}

		/**
		 * Align text by center.
		 * By default aligning by left.
		 */
		public function set centerAlign(p_val:Boolean):void
		{
			_alignByCenter = p_val;
			if (isTextureExist) updateAligning();
		}

		/**
		 */
		public function get centerAlign():Boolean
		{
			return _alignByCenter;
		}

		/**
		 */
		private function updateAligning():void
		{
			var texture:BBTexture = getTexture();

			if (_alignByCenter)
			{
				texture.pivotX = -texture.width / 2;
				texture.pivotY = -texture.height / 2;
			}
			else texture.pivotX = texture.pivotY = 0;
		}

		/**
		 */
		public function set font(p_val:String):void
		{
			_textFormat.font = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get font():String
		{
			return _textFormat.font;
		}

		/**
		 * Size of font.
		 */
		public function set size(p_val:int):void
		{
			_textFormat.size = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get size():int
		{
			return int(_textFormat.size);
		}

		/**
		 */
		public function set color(p_val:uint):void
		{
			_textFormat.color = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get color():uint
		{
			return uint(_textFormat.color);
		}

		/**
		 */
		public function set bold(p_val:Boolean):void
		{
			_textFormat.bold = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get bold():Boolean
		{
			return _textFormat.bold;
		}

		/**
		 */
		public function set italic(p_val:Boolean):void
		{
			_textFormat.italic = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get italic():Boolean
		{
			return _textFormat.italic;
		}

		/**
		 */
		public function set underline(p_val:Boolean):void
		{
			_textFormat.underline = p_val;
			_textField.setTextFormat(_textFormat);
			_textField.defaultTextFormat = _textFormat;

			updateEnable = true;
		}

		/**
		 */
		public function get underline():Boolean
		{
			return _textFormat.underline;
		}

		/**
		 */
		protected function invalidate():void
		{
			var texture:BBTexture = getTexture();

			if (texture != null) texture.dispose();

			texture = BBTexture.createFromVector(_textField);
			setTexture(texture);

			updateAligning();
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			invalidate();
			updateEnable = false;
		}

		/**
		 */
		override public function dispose():void
		{
			_textField.text = "";
			_textFormat = new TextFormat();
			_textField.defaultTextFormat = _textFormat;
			_textField.setTextFormat(_textFormat);

			super.dispose();
		}

		/**
		 */
		override protected function rid():void
		{
			_textField = null;
			_textFormat = null;

			super.rid();
		}

		/**
		 */
		static public function get(p_text:String = "", p_alignByCenter:Boolean = true, p_size:int = 12, p_color:uint = 0xffffff,
		                           p_font:String = "Arial"):BBLabel
		{
			var label:BBLabel = BBComponent.get(BBLabel) as BBLabel;
			label.centerAlign = p_alignByCenter;
			label.size = p_size;
			label.color = p_color;
			label.font = p_font;
			label.text = p_text;

			return label;
		}

		/**
		 */
		static public function getWithNode(p_text:String = "", p_alignByCenter:Boolean = true, p_size:int = 12, p_color:uint = 0xffffff,
		                                   p_font:String = "Arial"):BBLabel
		{
			var label:BBLabel = BBComponent.getWithNode(BBLabel) as BBLabel;
			label.centerAlign = p_alignByCenter;
			label.size = p_size;
			label.color = p_color;
			label.font = p_font;
			label.text = p_text;

			return label;
		}
	}
}
