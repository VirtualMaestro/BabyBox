/**
 * User: VirtualMaestro
 * Date: 03.02.13
 * Time: 1:19
 */
package bb.render.textures
{
	import bb.bb_spaces.bb_private;
	import bb.core.BabyBox;
	import bb.pools.BBNativePool;
	import bb.vo.BBColor;

	import com.genome2d.textures.GTexture;
	import com.genome2d.textures.factories.GTextureFactory;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import vm.math.unique.UniqueId;

	use namespace bb_private;

	/**
	 * Represents texture class. Texture contains data for rendering.
	 */
	public class BBTexture extends BBTextureBase
	{
		// Helper field
		static private const point:Point = new Point();

		// Texture atlas to which texture belongs to (of course if texture was created from atlas)
		bb_private var parent:BBTextureAtlas = null;

		/**
		 * Additional label for texture.
		 * Could use for storing label which was parsed from MovieClip's timeline.
		 */
		public var label:String = "";

		//
		private var _pivotX:Number = 0;
		private var _pivotY:Number = 0;

		/**
		 * Represents texture which is used in gpu mode.
		 */
		private var _gpuTexture:GTexture = null;

		/**
		 * Represents texture which is used with blitting mode (non-stage3d)
		 */
		private var _bitmapData:BitmapData = null;

		/**
		 */
		public function BBTexture(p_bitmapData:BitmapData, p_textureId:String = "", p_alignByCenter:Boolean = true, p_region:Rectangle = null,
		                          p_gTexture:GTexture = null)
		{
			super(p_textureId);

			//
			if (p_gTexture)
			{
				_gpuTexture = p_gTexture;
				_bitmapData = _gpuTexture.bitmapData;
				_pivotX = _gpuTexture.pivotX;
				_pivotY = _gpuTexture.pivotY;
			}
			else
			{
				if (p_region)
				{
					_bitmapData = new BitmapData(p_region.width, p_region.height);
					_bitmapData.copyPixels(p_bitmapData, p_region, point);
				}
				else _bitmapData = p_bitmapData;

				//
				if (BabyBox.isStage3d)
				{
					_gpuTexture = GTextureFactory.createFromBitmapData(p_textureId, _bitmapData);

					if (p_alignByCenter)
					{
						_pivotX = -_gpuTexture.width / 2;
						_pivotY = -_gpuTexture.height / 2;
					}
				}
				else
				{
					if (p_alignByCenter)
					{
						_pivotX = -_bitmapData.width / 2;
						_pivotY = -_bitmapData.height / 2;
					}
				}
			}

			// add to global texture storage
			addToGlobalStorage(this);
		}

		/**
		 */
		public function set pivotX(val:Number):void
		{
			_pivotX = val;
			if (BabyBox.isStage3d) _gpuTexture.pivotX = _pivotX;
		}

		/**
		 */
		public function get pivotX():Number
		{
			return _pivotX;
		}

		/**
		 */
		public function set pivotY(val:Number):void
		{
			_pivotY = val;
			if (BabyBox.isStage3d) _gpuTexture.pivotY = _pivotY;
		}

		/**
		 */
		public function get pivotY():Number
		{
			return _pivotY;
		}

		/**
		 * Returns width of texture.
		 */
		public function get width():int
		{
			return _bitmapData.width;
		}

		/**
		 * Returns height of texture.
		 */
		public function get height():int
		{
			return _bitmapData.height;
		}

		/**
		 * Returns texture which is used in stage3d mode.
		 */
		public function get gpuTexture():GTexture
		{
			return _gpuTexture;
		}

		/**
		 * Gets bitmap data of texture.
		 */
		override public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}

		/**
		 * Returns alpha value by given coordinates.
		 */
		public function getAlphaAt(p_x:Number, p_y:Number):uint
		{
//			if (_bitmapData == null) return 255;
			return _bitmapData.getPixel32(p_x, p_y) >> 24 & 255;
		}

		/**
		 * If returns 'true' mean that this is instance of BBTexture class, else BBTextureAtlas.
		 */
		override public function get isTexture():Boolean
		{
			return true;
		}

		/**
		 * Returns true if texture was disposed.
		 */
		override public function get isDisposed():Boolean
		{
			return _bitmapData == null;
		}

		/**
		 * Disposes texture.
		 */
		override public function dispose():void
		{
			if (isDisposed) return;

			texturesGlobalStorage[id] = null;

			//
			if (_gpuTexture) _gpuTexture.dispose();
			_bitmapData.dispose();
			_bitmapData = null;

			if (parent)
			{
				parent.unlinkTexture(id);
				parent = null;
			}
		}

		//

		/**
		 * Global storage of all created textures
		 */
		static private var texturesGlobalStorage:Array = [];

		/**
		 * Adds new created texture to global storage.
		 */
		static private function addToGlobalStorage(p_texture:BBTexture):void
		{
			var texture:BBTexture = getTextureById(p_texture.id);
			if (texture != null) throw new Error("You try to create texture with id already used. Texture id '" + p_texture.id + "'. BBTexture.addToGlobalStorage");

			texturesGlobalStorage[p_texture.id] = p_texture;
		}

		/**
		 * Returns texture by its id.
		 */
		static public function getTextureById(p_textureId:String):BBTexture
		{
			var texture:BBTexture = (p_textureId == "") ? null : texturesGlobalStorage[p_textureId];
			if (texture && texture.isDisposed) texture = null;
			return texture;
		}

		/////////////////////////////
		// Texture factory methods //
		/////////////////////////////

		/**
		 * Create texture from bitmap data.
		 *
		 * @param p_textureId - texture id (or name)
		 * @param p_bitmapData - bitmap data
		 * @param p_alignByCenter - align texture by its center.
		 * @return
		 */
		static public function createFromBitmapData(p_bitmapData:BitmapData, p_textureId:String = "", p_alignByCenter:Boolean = true):BBTexture
		{
			return new BBTexture(p_bitmapData, p_textureId, p_alignByCenter);
		}

		/**
		 * Create texture from asset. In this case it is mean embed Bitmap class (some image).
		 * @param p_textureId - texture id (or name)
		 * @param p_asset - ref to class of Bitmap.
		 * @param p_alignByCenter - align texture by its center.
		 * @return BBTexture
		 */
		static public function createFromAsset(p_asset:Class, p_textureId:String = "", p_alignByCenter:Boolean = true):BBTexture
		{
			var texture:BBTexture;
			var asset:Object = new p_asset();

			if (asset is Bitmap) texture = createFromBitmapData(asset.bitmapData, p_textureId, p_alignByCenter);
			else texture = createFromVector(asset as DisplayObject, p_textureId);

			return texture;
		}

		//
		static private var MATRIX:Matrix = BBNativePool.getMatrix();
		static private var DESTINATION_POINT:Point = BBNativePool.getPoint();

		/**
		 */
		static public function createFromVector(p_vector:DisplayObject, p_textureId:String = ""):BBTexture
		{
			var resultTexture:BBTexture;
			var dirtyBitmap:BitmapData;
			var rect:Rectangle;
			var pivotX:int;
			var pivotY:int;

			rect = p_vector.getBounds(p_vector);
			rect.width = Math.ceil(rect.width) + 128;
			rect.height = Math.ceil(rect.height) + 128;

			pivotX = Math.floor(rect.x) - 64;
			pivotY = Math.floor(rect.y) - 64;

			MATRIX.identity();
			MATRIX.tx = -pivotX;
			MATRIX.ty = -pivotY;

			dirtyBitmap = new BitmapData(rect.width, rect.height, true, 0);
			dirtyBitmap.draw(p_vector, MATRIX);

			// do trimming by visible color
			var trimBounds:Rectangle = dirtyBitmap.getColorBoundsRect(0xFF000000, 0x00000000, false);
			trimBounds.x -= 1;
			trimBounds.y -= 1;
			trimBounds.width += 2;
			trimBounds.height += 2;

			//
			var bitmapData:BitmapData = new BitmapData(trimBounds.width, trimBounds.height, true, 0);
			bitmapData.copyPixels(dirtyBitmap, trimBounds, DESTINATION_POINT);
			dirtyBitmap.dispose();

			pivotX += trimBounds.x;
			pivotY += trimBounds.y;

			//
			resultTexture = new BBTexture(bitmapData, p_textureId);
			resultTexture.pivotX = pivotX;
			resultTexture.pivotY = pivotY;

			return resultTexture;
		}

		/**
		 * Creates texture rect with given color.
		 */
		static public function createFromColorRect(p_width:int, p_height:int, p_textureId:String = "", p_color:uint = 0xff73bdd5,
		                                           p_alignByCenter:Boolean = true):BBTexture
		{
			var texture:BBTexture = getTextureById(p_textureId);
			if (texture) return texture;

			var alpha:int = (p_color >> 24) & 0xff;
			var isTransparent:Boolean = alpha > 0 && alpha < 255;
			//
			var bitmapData:BitmapData = new BitmapData(p_width, p_height, isTransparent, p_color);
			return createFromBitmapData(bitmapData, p_textureId, p_alignByCenter);
		}

		/**
		 * p_colors - array with colors for gradient. If set one color it uses for solid fill.
		 * If p_colors null or empty it is use default color.
		 */
		static public function createFromColorCircle(p_radius:int, p_textureId:String = "", p_colors:Array = null, p_outlineColor:uint = 0x00000000,
		                                             p_thicknessOutline:uint = 0, p_alignByCenter:Boolean = true):BBTexture
		{
			var texture:BBTexture = getTextureById(p_textureId);
			if (texture) return texture;

			var bitmapData:BitmapData = new BitmapData(p_radius * 2, p_radius * 2, true, 0x00000000);
			var circle:Shape = new Shape();

			var thickness:int = 0;
			if (p_thicknessOutline > 0)
			{
				thickness = p_thicknessOutline;
				var alphaOutline:Number = BBColor.getAlpha(p_outlineColor, true);
				var colorOutline:uint = p_outlineColor & 0x00ffffff;
				circle.graphics.lineStyle(thickness, colorOutline, alphaOutline);

				thickness += (thickness % 2) == 0 ? 0 : 1;
			}

			var color:uint = 0xff9abe5e;
			var alpha:Number;

			if (p_colors == null || p_colors.length <= 1)
			{

				alpha = BBColor.getAlpha(color, true);
				color = color & 0x00ffffff;

				circle.graphics.beginFill(color, alpha);
				circle.graphics.drawCircle(0, 0, p_radius - thickness);
				circle.graphics.endFill();
			}
			else
			{
				var colors:Array = [];
				var alphas:Array = [];
				var numColors:int = p_colors.length;
				var ratio:Number = 255 / (numColors - 1);
				var ratios:Array = [];

				for (var i:int = 0; i < numColors; i++)
				{
					color = p_colors[i];
					alphas[i] = BBColor.getAlpha(color, true);
					colors[i] = color & 0x00ffffff;
					ratios[i] = Math.ceil(i * ratio);
				}

				var matrixGrad:Matrix = BBNativePool.getMatrix();
				matrixGrad.createGradientBox(p_radius * 2, p_radius * 2, 0, -p_radius, -p_radius);

				circle.graphics.beginGradientFill(GradientType.RADIAL, colors, alphas, ratios, matrixGrad);
				circle.graphics.drawCircle(0, 0, p_radius - thickness);
				circle.graphics.endFill();
				BBNativePool.putMatrix(matrixGrad);
			}

			var matrix:Matrix = BBNativePool.getMatrix();
			matrix.translate(p_radius, p_radius);
			bitmapData.draw(circle, matrix, null, null, null, true);
			BBNativePool.putMatrix(matrix);

			return createFromBitmapData(bitmapData, p_textureId, p_alignByCenter);
		}

		/**
		 * Creates texture circle with given color.
		 */
		static public function createFromColorEllipse(p_radiusX:int, p_radiusY:int, p_textureId:String = "", p_color:uint = 0xff9abe5e,
		                                              p_alignByCenter:Boolean = true):BBTexture
		{
			var texture:BBTexture = getTextureById(p_textureId);
			if (texture) return texture;

			p_radiusX *= 2;
			p_radiusY *= 2;

			//
			var bitmapData:BitmapData = new BitmapData(p_radiusX, p_radiusY, true, 0x00000000);
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(p_color);
			circle.graphics.drawEllipse(0, 0, p_radiusX, p_radiusY);
			circle.graphics.endFill();

			var matrix:Matrix = BBNativePool.getMatrix();
			bitmapData.draw(circle, matrix, null, null, null, true);
			BBNativePool.putMatrix(matrix);

			return createFromBitmapData(bitmapData, p_textureId, p_alignByCenter);
		}

		/**
		 * Returns generated unique texture id.
		 */
		static public function getTextureId():String
		{
			return UniqueId.getUniqueName("texture");
		}
	}
}
