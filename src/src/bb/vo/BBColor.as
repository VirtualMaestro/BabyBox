/**
 * User: VirtualMaestro
 * Date: 18.02.13
 * Time: 18:25
 */
package src.bb.vo
{
	import src.bb.bb_spaces.bb_private;

	use namespace bb_private;

	/**
	 * Represents color for convenient color manipulation.
	 * Range for color from 0 to 1.
	 * Color represents in ARBA format.
	 */
	public class BBColor
	{
		//
		bb_private var z_alpha:Number = 1.0;
		bb_private var z_red:Number = 1.0;
		bb_private var z_green:Number = 1.0;
		bb_private var z_blue:Number = 1.0;

		private var _colorChanged:Boolean = false;

		/**
		 */
		public function BBColor(p_alpha:Number = 1.0, p_red:Number = 1.0, p_green:Number = 1.0, p_blue:Number = 1.0)
		{
			z_alpha = p_alpha;
			z_red = p_red;
			z_green = p_green;
			z_blue = p_blue;
		}

		/**
		 * Gets color in HEX.
		 */
		public function get color():uint
		{
			var alpha:uint = uint(z_alpha*255)<<24;
			var red:uint = uint(z_red*255)<<16;
			var green:uint = uint(z_green*255)<<8;
			var blue:uint = uint(z_blue*255);

			return alpha+red+green+blue;
		}

		/**
		 * Sets color in HEX, ARGB model.
		 */
		public function set color(p_color:uint):void
		{
			z_alpha = ((p_color >> 24) & 0xff) / 255;
			z_red = ((p_color >> 16) & 0xff) / 255;
			z_green = ((p_color >> 8) & 0xff) / 255;
			z_blue = (p_color & 0xff) / 255;

			_colorChanged = true;
		}

		/**
		 */
		public function get alpha():Number
		{
			return z_alpha;
		}

		/**
		 * Sets alpha channel. Possible values 0-1.
		 */
		public function set alpha(value:Number):void
		{
			z_alpha = cutToRange(value);
		}

		public function get red():Number
		{
			return z_red;
		}

		/**
		 * Sets red channel. Possible values 0-1.
		 */
		public function set red(value:Number):void
		{
			z_red = cutToRange(value);
		}

		/**
		 */
		public function get green():Number
		{
			return z_green;
		}

		/**
		 * Sets green channel. Possible values 0-1.
		 */
		public function set green(value:Number):void
		{
			z_green = cutToRange(value);
		}

		public function get blue():Number
		{
			return z_blue;
		}

		/**
		 * Sets blue channel. Possible values 0-1.
		 */
		public function set blue(value:Number):void
		{
			z_blue = cutToRange(value);
		}

		/**
		 * Cut value to range 0-1
		 */
		private function cutToRange(p_value:Number):Number
		{
			if (p_value > 1) p_value = 1.0;
			else if (p_value < 0) p_value = 0.0;

			_colorChanged = true;

			return p_value;
		}

		/**
		 * Determines if color was changed.
		 * After first calling this method flag reset to false.
		 */
		public function isColorChanged():Boolean
		{
			var isChanged:Boolean = _colorChanged;
			_colorChanged = false;

			return isChanged;
		}

		/**
		 * Reset values to default.
		 */
		public function reset():void
		{
			z_alpha = 1.0;
			z_red = 1.0;
			z_green = 1.0;
			z_blue = 1.0;
		}

		///////////////////////////
		/// CONSTANTS OF COLORS ///
		///////////////////////////

		static public const SKY:uint = 0xff73bdd5;
		static public const GRASS:uint = 0xff9abe5e;
	}
}
