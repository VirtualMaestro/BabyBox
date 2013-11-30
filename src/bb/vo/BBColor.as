/**
 * User: VirtualMaestro
 * Date: 18.02.13
 * Time: 18:25
 */
package bb.vo
{
	import bb.bb_spaces.bb_private;

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
			alpha = p_alpha;
			red = p_red;
			green = p_green;
			blue = p_blue;
		}

		/**
		 * Gets color in HEX.
		 */
		public function get color():uint
		{
			var alpha:uint = uint(z_alpha * 255) << 24;
			var red:uint = uint(z_red * 255) << 16;
			var green:uint = uint(z_green * 255) << 8;
			var blue:uint = uint(z_blue * 255);

			return alpha + red + green + blue;
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
		 * All color values should be in range 0-255.
		 */
		public function setARGB255(p_alpha:uint, p_red:uint, p_green:uint, p_blue:uint):void
		{
			z_alpha = cutToRange255(p_alpha) / 255.0;
			z_red = cutToRange255(p_red) / 255.0;
			z_green = cutToRange255(p_green) / 255.0;
			z_blue = cutToRange255(p_blue) / 255.0;
		}

		/**
		 */
		private function cutToRange255(p_value:uint):Number
		{
			if (p_value > 255) p_value = 255;
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

		/** Constant of color */
		static public const SKY:uint = 0xff73bdd5;

		/** Constant of color */
		static public const BLUE:uint = 0xff0000ff;

		/** Constant of color */
		static public const GRASS:uint = 0xff9abe5e;

		/** Constant of color */
		static public const POISON:uint = 0xff85D118;

		/** Constant of color */
		static public const GREEN:uint = 0xff00ff00;

		/** Constant of color */
		static public const BLOOD:uint = 0xffe7402d;

		/** Constant of color */
		static public const RED:uint = 0xffff0000;

		/** Constant of color */
		static public const BLACK:uint = 0xff000000;

		/** Constant of color */
		static public const WHITE:uint = 0xffffffff;

		/** Constant of color */
		static public const YELLOW:uint = 0xffffff00;

		/**
		 * Extract alpha channel.
		 * p_color - ARGB
		 * toFloat - mean convert color value to range [0, 1]. By default return in range [0, 255].
		 */
		static public function getAlpha(p_color:uint, toFloat:Boolean = false):Number
		{
			return extractColor(p_color, 24, toFloat);
		}

		/**
		 * Extract red channel.
		 * p_color - ARGB
		 * toFloat - mean convert color value to range [0, 1]. By default return in range [0, 255].
		 */
		static public function getRed(p_color:uint, toFloat:Boolean = false):Number
		{
			return extractColor(p_color, 16, toFloat);
		}

		/**
		 * Extract green channel.
		 * p_color - ARGB
		 * toFloat - mean convert color value to range [0, 1]. By default return in range [0, 255].
		 */
		static public function getGreen(p_color:uint, toFloat:Boolean = false):Number
		{
			return extractColor(p_color, 8, toFloat);
		}

		/**
		 * Extract blue channel.
		 * p_color - ARGB
		 * toFloat - mean convert color value to range [0, 1]. By default return in range [0, 255].
		 */
		static public function getBlue(p_color:uint, toFloat:Boolean = false):Number
		{
			return extractColor(p_color, 0, toFloat);
		}

		/**
		 */
		[Inline]
		static private function extractColor(p_color:uint, p_shift:int, toFloat:Boolean):Number
		{
			return ((p_color >> p_shift) & 0xff) / (toFloat ? 255.0 : 1);
		}

		//
		public static const INTERPOLATION_LINEAR:uint = 0;
		public static const INTERPOLATION_COS:uint = 1;
		public static const INTERPOLATION_COS_LINEAR:uint = 2;

		/**
		 * Returns Vector.<uint> with color's values for gradient rectangle.
		 */
		static public function getGradient(x1:uint, y1:uint, color1:uint, x2:uint, y2:uint, color2:uint, width:uint, height:uint = 1,
		                                   interpolation:uint = 2):Vector.<uint>
		{
			var rgb:Vector.<uint> = new <uint>[];
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			var AB:Number = Math.sqrt(dx * dx + dy * dy);

			for (var y:uint = 0; y < height; y++)
			{
				for (var x:uint = 0; x < width; x++)
				{
					dx = x1 - x;
					dy = y1 - y;
					var AE2:Number = dx * dx + dy * dy;
					var AE:Number = Math.sqrt(AE2);

					dx = x2 - x;
					dy = y2 - y;
					var EB2:Number = dx * dx + dy * dy;
					var EB:Number = Math.sqrt(EB2);

					var p:Number = (AB + AE + EB) / 2;

					var EF:Number = 2 / AB * Math.sqrt(Math.abs(p * (p - AB) * (p - AE) * (p - EB)));
					var EF2:Number = EF * EF;

					var AF:Number = Math.sqrt(Math.abs(AE2 - EF2));
					var BF:Number = Math.sqrt(Math.abs(EB2 - EF2));

					if (AF + BF - 0.1 > AB)
					{
						rgb[y * width + x] = AF < BF ? color1 : color2;
					}
					else
					{
						var progress:Number = AF / AB;
						rgb[y * width + x] = interpolate(color1, color2, progress, interpolation);
					}
				}
			}

			return rgb;
		}

		/**
		 */
		static private function interpolate(color1:uint, color2:uint, progress:Number, interpolation:uint):uint
		{
			var a1:uint = (color1 & 0xff000000) >>> 24;
			var r1:uint = (color1 & 0x00ff0000) >>> 16;
			var g1:uint = (color1 & 0x0000ff00) >>> 8;
			var b1:uint = color1 & 0x000000ff;

			var a2:uint = (color2 & 0xff000000) >>> 24;
			var r2:uint = (color2 & 0x00ff0000) >>> 16;
			var g2:uint = (color2 & 0x0000ff00) >>> 8;
			var b2:uint = color2 & 0x000000ff;

			var f:Number;
			var ft:Number = progress * 3.1415927;
			if (interpolation == INTERPOLATION_LINEAR) f = progress;
			else if (interpolation == INTERPOLATION_COS)
			{
				f = (1 - Math.cos(ft)) * 0.5;
			}
			else if (interpolation == INTERPOLATION_COS_LINEAR)
			{
				f = (progress + (1 - Math.cos(ft)) * 0.5) / 2;
			}

			var newA:uint = clip(a1 * (1 - f) + a2 * f);
			var newR:uint = clip(r1 * (1 - f) + r2 * f);
			var newG:uint = clip(g1 * (1 - f) + g2 * f);
			var newB:uint = clip(b1 * (1 - f) + b2 * f);

			return (newA << 24) + (newR << 16) + (newG << 8) + newB;
		}

		/**
		 */
		[Inline]
		static private function clip(num:int):uint
		{
			return num <= 0 ? 0 : (num >= 255 ? 255 : num);
		}

		/**
		 * Returns Vector.<uint> with color's values for gradient strip.
		 */
		static public function getGradientStrip(p_colorStart:uint, p_colorEnd:uint, p_length:int = 100, p_interpolation:uint = 0):Vector.<uint>
		{
			return getGradient(0, 0, p_colorStart, p_length, 0, p_colorEnd, p_length, 1, p_interpolation);
		}

		////

		/**
		 * Returns instance of BBColor from ARGB components.
		 * All components have to be from 0.0 to 1.0;
		 * @return BBColor
		 */
		static public function get(p_alpha:Number = 1.0, p_red:Number = 1.0, p_green:Number = 1.0, p_blue:Number = 1.0):BBColor
		{
			return new BBColor(p_alpha, p_red, p_green, p_blue);
		}

		/**
		 * Returns instance of BBColor from HEX number which represent of color.
		 * @return BBColor
		 */
		static public function getFromHex(p_color:uint):BBColor
		{
			var color:BBColor = new BBColor();
			color.color = p_color;

			return color;
		}
	}
}
