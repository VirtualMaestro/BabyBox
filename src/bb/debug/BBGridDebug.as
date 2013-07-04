/**
 * User: VirtualMaestro
 * Date: 21.03.13
 * Time: 18:52
 */
package bb.debug
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import vm.debug.DebugUtil;

	/**
	 * Represent visual grid for debugging.
	 */
	public class BBGridDebug extends Sprite
	{
		private var _width:int;
		private var _height:int;
		private var _cellSize:int;
		private var _fontSize:int;
		private var _textColor:int;
		private var _gridColor:int;
		private var _nodeColor:int;
		private var _lineThickness:int;

		private var _nodeSize:int = 3;
		private var _gridAlpha:Number = 0.1;

		private var _labels:Array;
		private var _showCoordinates:Boolean = true;

		/**
		 */
		public function BBGridDebug(p_width:int, p_height:int, p_cellSize:int = 100, p_fontSize:int = 12, p_textColor:uint = 0x382510, p_gridColor:uint = 0x333333, p_lineThickness:int = 2, p_nodeColor:uint = 0x79172a)
		{
			_width = p_width;
			_height = p_height;
			_cellSize = p_cellSize;
			_fontSize = p_fontSize;
			_textColor = p_textColor;
			_gridColor = p_gridColor;
			_lineThickness = p_lineThickness;
			_nodeColor = p_nodeColor;

			_labels = [];

			update();
		}

		/**
		 */
		private function update():void
		{
			var gr:Graphics = graphics;
			gr.clear();

			var iterX:int = _width / _cellSize;
			var iterY:int = _height / _cellSize;
			var xp:Number = 0;
			var yp:Number = 0;
			var coords:TextField;

			if (_showCoordinates)
			{
				var needLabels:int = iterX * iterY;
				if (needLabels > _labels.length)
				{
					needLabels = needLabels - _labels.length;
					for (var k:int = 0; k < needLabels; k++)
					{
						coords = DebugUtil.getTextField(_fontSize, _textColor);
						coords.border = false;
						coords.selectable = false;
						coords.mouseEnabled = false;

						_labels.push(coords);
					}
				}
			}

			var labelIterator:int = 0;

			for (var i:int = 0; i < iterY; i++)
			{
				for (var j:int = 0; j < iterX; j++)
				{
					gr.lineStyle(_lineThickness, _gridColor, _gridAlpha);
					gr.moveTo(xp, yp);
					gr.lineTo(xp + _cellSize, yp);
					gr.lineTo(xp + _cellSize, yp + _cellSize);
					gr.lineTo(xp, yp + _cellSize);
					gr.lineTo(xp, yp);

					if (_showCoordinates)
					{
						coords = _labels[labelIterator];
						coords.text = "" + xp + ", " + yp + "";
						coords.x = xp;
						coords.y = yp;
						if (!coords.parent) addChild(coords);
					}

					gr.lineStyle(0, _nodeColor, _gridAlpha + 0.5);
					gr.beginFill(_nodeColor, _gridAlpha + 0.5);
					gr.drawCircle(xp, yp, _nodeSize);
					gr.drawCircle(xp + _cellSize / 2, yp + _cellSize / 2, 1);
					gr.endFill();

					xp += _cellSize;
					labelIterator++;
				}

				xp = 0;
				yp += _cellSize;
			}
		}

		/**
		 * Set size of grid.
		 */
		public function setSize(p_width:int, p_height:int):void
		{
			_width = p_width;
			_height = p_height;

			clearCoordinates();
			update();
		}

		/**
		 */
		public function set showCoordinates(p_val:Boolean):void
		{
			if (_showCoordinates == p_val) return;
			_showCoordinates = p_val;

			if (!_showCoordinates) clearCoordinates();
			update();
		}

		/**
		 */
		public function get showCoordinates():Boolean
		{
			return _showCoordinates;
		}

		/**
		 */
		private function clearCoordinates():void
		{
			var len:int = _labels.length;
			var textField:TextField;
			for (var i:int = 0; i < len; i++)
			{
				textField = _labels[i];
				if (textField.parent) removeChild(textField);
			}
		}

		public function get cellSize():int
		{
			return _cellSize;
		}

		public function set cellSize(p_value:int):void
		{
			_cellSize = p_value;
			update();
		}

		public function get fontSize():int
		{
			return _fontSize;
		}

		public function set fontSize(p_value:int):void
		{
			_fontSize = p_value;

			var len:int = _labels.length;
			if (len > 0)
			{
				var textField:TextField;
				var textFormat:TextFormat = (_labels[0] as TextField).getTextFormat();
				textFormat.size = p_value;
				for (var i:int = 0; i < len; i++)
				{
					textField = _labels[i];
					textField.setTextFormat(textFormat);
				}
			}
		}

		public function get textColor():int
		{
			return _textColor;
		}

		public function set textColor(p_value:int):void
		{
			_textColor = p_value;

			var len:int = _labels.length;
			var textField:TextField;
			for (var i:int = 0; i < len; i++)
			{
				textField = _labels[i];
				textField.textColor = p_value;
			}
		}

		public function get gridColor():int
		{
			return _gridColor;
		}

		public function set gridColor(p_value:int):void
		{
			_gridColor = p_value;
			update();
		}

		public function get nodeColor():int
		{
			return _nodeColor;
		}

		public function set nodeColor(p_value:int):void
		{
			_nodeColor = p_value;
			update();
		}

		public function get lineThickness():int
		{
			return _lineThickness;
		}

		public function set lineThickness(p_value:int):void
		{
			_lineThickness = p_value;
			update();
		}

		public function get gridAlpha():Number
		{
			return _gridAlpha;
		}

		public function set gridAlpha(value:Number):void
		{
			_gridAlpha = value;
			update();
		}
	}
}
