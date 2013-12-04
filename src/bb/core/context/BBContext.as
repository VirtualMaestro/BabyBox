/**
 * User: VirtualMaestro
 * Date: 01.02.13
 * Time: 14:13
 */
package bb.core.context
{
	import bb.bb_spaces.bb_private;
	import bb.camera.components.BBCamera;
	import bb.config.BBConfig;
	import bb.core.BabyBox;
	import bb.render.constants.BBRenderMode;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;

	import com.genome2d.context.GContext;
	import com.genome2d.core.GConfig;
	import com.genome2d.core.Genome2D;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.display.StageQuality;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import vm.math.trigonometry.TrigUtil;

	use namespace bb_private;

	/**
	 * Response for rendering. Also determines what renderer (Blitting or Genome) will used.
	 */
	public class BBContext
	{
		static private const RAD_TO_DEG:Number = TrigUtil.RAD_TO_DEG;
		static private const DEG_TO_RAD:Number = TrigUtil.DEG_TO_RAD;

		/**
		 * Sends when context was initialized.
		 */
		private var _onInitialized:BBSignal = null;

		//
		private var _stage:Stage = null;
		private var _config:BBConfig = null;
		private var _isStage3d:Boolean = true;

		// Stage3d context
		private var _genome:Genome2D = null;
		private var _genomeContext:GContext = null;

		// Blitting context
		private var _canvasHolder:Bitmap = null;
		private var _canvas:BitmapData = null;

		//
		private var _canvasViewRect:Rectangle;

		//
		bb_private var currentCamera:BBCamera = null;

		// Temp props for faster access
		private var _currentCameraSIN:Number;
		private var _currentCameraCOS:Number;
		private var _currentCameraX:Number;
		private var _currentCameraY:Number;
		private var _currentCameraRotation:Number;
		private var _currentCameraTotalScaleX:Number;
		private var _currentCameraTotalScaleY:Number;
		private var _currentCameraViewportCenterX:Number;
		private var _currentCameraViewportCenterY:Number;
		private var _currentCameraViewport:Rectangle;
		private var _currentCameraViewportX:Number;
		private var _currentCameraViewportY:Number;
		private var _currentCameraViewportWidth_add_X:Number;
		private var _currentCameraViewportHeight_add_Y:Number;

		//
		private var _rectTextureRender:Rectangle = null;
		private var _point:Point = null;
		private var _matrix:Matrix = null;
		private var _colorTransform:ColorTransform = null;

		private var _sinTable:Vector.<Number>;
		private var _cosTable:Vector.<Number>;

		/**
		 */
		public function BBContext()
		{
			_onInitialized = BBSignal.get(this, true);
			_rectTextureRender = new Rectangle();
			_point = new Point();
			_matrix = new Matrix();
			_colorTransform = new ColorTransform();

			// prepare sin and cos tables
			_sinTable = new <Number>[];
			_cosTable = new <Number>[];
			var angleRad:Number = -2 * Math.PI;
			var stepAngle:Number = Math.PI / 180.0;

			for (var i:int = 0; i < 720; i++)
			{
				_sinTable[i] = Math.sin(angleRad);
				_cosTable[i] = Math.cos(angleRad);
				angleRad += stepAngle;
			}
		}

		/**
		 * Start to init context.
		 */
		public function init(p_stage:Stage):void
		{
			_stage = p_stage;
			_config = BabyBox.get().config;
			_canvasViewRect = _config.getViewRect();

			if (_config.renderMode == BBRenderMode.BLITTING) initBlitting();
			else initGenome();
		}

		/**
		 * Try to init blitting.
		 */
		private function initBlitting():void
		{
			_canvasHolder = new Bitmap(new BitmapData(_canvasViewRect.width, _canvasViewRect.height, true), "auto", true);
			_canvasHolder.x = _canvasViewRect.x;
			_canvasHolder.y = _canvasViewRect.y;
			_stage.addChild(_canvasHolder);
			_canvas = _canvasHolder.bitmapData;

			_config.renderMode = BBRenderMode.BLITTING;
			_isStage3d = false;
			onInitialized.dispatch(_config.renderMode);
		}

		/**
		 * Tries to init genome engine.
		 */
		private function initGenome():void
		{
			_genome = Genome2D.getInstance();
			_genome.onInitialized.add(genomeInitHandler);
			_genome.onFailed.add(genomeFailedHandler);

			var genomeConfig:GConfig = new GConfig(new Rectangle(_canvasViewRect.x, _canvasViewRect.y, _canvasViewRect.width, _canvasViewRect.height),
			                                       _config.renderMode);
			// TODO: Add extra parameters to genome's config
			_genome.init(_stage, genomeConfig);
		}

		/**
		 */
		private function genomeInitHandler():void
		{
			var driverInfo:String = _genome.driverInfo.toLowerCase();

			if (driverInfo.indexOf("software") != -1) _config.renderMode = BBRenderMode.SOFTWARE;
			else if (driverInfo.indexOf("constrained") != -1) _config.renderMode = BBRenderMode.BASELINE_CONSTRAINED;
			else _config.renderMode = BBRenderMode.BASELINE;

			// Switch off update render graph of Genome
			_genome.autoUpdate = false;

			//
			if (_config.softwareTurnToBlitting && _config.renderMode == BBRenderMode.SOFTWARE)
			{
				disposeGenome();
				initBlitting();
			}
			else
			{
				_genomeContext = _genome.context;
				onInitialized.dispatch(_config.renderMode);
			}
		}

		/**
		 */
		private function genomeFailedHandler():void
		{
			trace("Genome failed!");
			disposeGenome();
			initBlitting();
		}

		/**
		 * Destroy genome engine.
		 */
		private function disposeGenome():void
		{
			_genome = null;
			// TODO: For now Genome hasn't method to destroy itself
		}

		/**
		 * Sets current camera for rendering.
		 */
		public function setCamera(p_camera:BBCamera):void
		{
			currentCamera = p_camera;

			_currentCameraViewport = currentCamera.getViewport();
			_currentCameraViewportX = _currentCameraViewport.x;
			_currentCameraViewportY = _currentCameraViewport.y;
			_currentCameraViewportCenterX = currentCamera.viewportCenterX;
			_currentCameraViewportCenterY = currentCamera.viewportCenterY;
			_currentCameraX = currentCamera.cameraX;
			_currentCameraY = currentCamera.cameraY;
			_currentCameraRotation = currentCamera.rotation;
			_currentCameraTotalScaleX = currentCamera.totalScaleX;
			_currentCameraTotalScaleY = currentCamera.totalScaleY;
			_currentCameraCOS = currentCamera.COS;
			_currentCameraSIN = currentCamera.SIN;
			_currentCameraViewportWidth_add_X = _currentCameraViewportX + _currentCameraViewport.width;
			_currentCameraViewportHeight_add_Y = _currentCameraViewportY + _currentCameraViewport.height;
		}

		/**
		 * Calls before any render process.
		 */
		public function beginRender():void
		{
			if (_isStage3d)
			{

			}
			else
			{
				_canvas.lock();

				// fill whole canvas with given color
				fillRect(0, 0, _canvas.width, _canvas.height, _config.canvasColor);
			}
		}

		/**
		 * Calls after any render process.
		 */
		public function endRender():void
		{
			if (_isStage3d)
			{

			}
			else
			{
				_canvas.unlock();
			}
		}

		/**
		 * Method draw texture with given parameters.
		 * It takes into account camera parameters, so it is impossible to use it if camera isn't set.
		 *
		 * All color multipliers must be in range [0, 1].
		 */
		public function draw(p_texture:BBTexture, p_x:Number, p_y:Number, p_rotation:Number = 0, p_scaleX:Number = 1.0, p_scaleY:Number = 1.0,
		                     p_offsetX:Number = 0, p_offsetY:Number = 0, p_offsetRotation:Number = 0, p_offsetScaleX:Number = 1.0, p_offsetScaleY:Number = 1.0,
		                     p_alphaMultiplier:Number = 1.0, p_redMultiplier:Number = 1.0, p_greenMultiplier:Number = 1.0, p_blueMultiplier:Number = 1.0,
		                     p_isCulling:Boolean = false, p_smoothing:Boolean = true, p_allowRotation:Boolean = true, p_allowScale:Boolean = true,
		                     p_blendMode:String = null):void
		{
			var bitmap:BitmapData = p_texture.bitmapData;
			var textureWidth:Number = bitmap.width;
			var textureHeight:Number = bitmap.height;

			var sinCam:Number = _currentCameraSIN;
			var cosCam:Number = _currentCameraCOS;
			var dx:Number = p_x - _currentCameraX;
			var dy:Number = p_y - _currentCameraY;

			var newTextureX:Number = (dx * cosCam - sinCam * dy) * _currentCameraTotalScaleX + _currentCameraViewportCenterX + p_offsetX;
			var newTextureY:Number = (dx * sinCam + cosCam * dy) * _currentCameraTotalScaleY + _currentCameraViewportCenterY + p_offsetY;

			var totalRotation:Number = p_allowRotation ? (p_rotation - _currentCameraRotation + p_offsetRotation) % TrigUtil.PI2 : 0;
			var totalScaleX:Number = 1.0;
			var totalScaleY:Number = 1.0;

			if (p_allowScale)
			{
				totalScaleX = p_scaleX * _currentCameraTotalScaleX * p_offsetScaleX;
				totalScaleY = p_scaleY * _currentCameraTotalScaleY * p_offsetScaleY;
			}

			var texturePivotX:Number = p_texture.pivotX * totalScaleX;
			var texturePivotY:Number = p_texture.pivotY * totalScaleY;

			//
			var xRectTextureRender:Number = 0;
			var yRectTextureRender:Number = 0;
			var widthRectTextureRender:Number = textureWidth;
			var heightRectTextureRender:Number = textureHeight;

			//
			var totalRotABS:Number = Math.abs(totalRotation);
			var isRotationNotChanged:Boolean = totalRotABS < BBConfig.ROTATION_PRECISE || (TrigUtil.PI2 - totalRotABS) < BBConfig.ROTATION_PRECISE;
			var isScaleNotChanged:Boolean = Math.abs(1 - totalScaleX) < BBConfig.SCALE_PRECISE && Math.abs(1 - totalScaleY) < BBConfig.SCALE_PRECISE;
			var isColorTransformNotChanged:Boolean = !((1.0 - (p_alphaMultiplier * p_redMultiplier * p_greenMultiplier * p_blueMultiplier)) > BBConfig.COLOR_PRECISE);
			var isCopyPixelsDrawing:Boolean = isRotationNotChanged && isColorTransformNotChanged && isScaleNotChanged && (p_blendMode == null);

			var totalRotCos:Number = 1.0;
			var totalRotSin:Number = 0.0;

			///  Test for getting into the viewport /////////////
			if (p_isCulling)
			{
				var boundingBoxTopLeftX:Number;
				var boundingBoxTopLeftY:Number;
				var boundingBoxBottomRightX:Number;
				var boundingBoxBottomRightY:Number;

				if (isRotationNotChanged)  // texture isn't rotated
				{
					boundingBoxTopLeftX = newTextureX + texturePivotX;
					boundingBoxTopLeftY = newTextureY + texturePivotY;
					boundingBoxBottomRightX = boundingBoxTopLeftX + textureWidth * totalScaleX;
					boundingBoxBottomRightY = boundingBoxTopLeftY + textureHeight * totalScaleY;

					// is texture and viewport intersected
					if (!isIntersect(boundingBoxTopLeftX, boundingBoxTopLeftY, boundingBoxBottomRightX, boundingBoxBottomRightY,
					                 _currentCameraViewportX, _currentCameraViewportY,
					                 _currentCameraViewportWidth_add_X, _currentCameraViewportHeight_add_Y)) return;

					// if texture can be draw by copyPixels method - try to find only part which in viewport.
					if (isCopyPixelsDrawing)
					{
						xRectTextureRender = max(_currentCameraViewportX - boundingBoxTopLeftX, 0);
						yRectTextureRender = max(_currentCameraViewportY - boundingBoxTopLeftY, 0);
						widthRectTextureRender = textureWidth - xRectTextureRender + min(_currentCameraViewportWidth_add_X - boundingBoxBottomRightX, 0);
						heightRectTextureRender = textureHeight - yRectTextureRender + min(_currentCameraViewportHeight_add_Y - boundingBoxBottomRightY, 0);
					}
				}
				else  // find bounding box for rotated texture
				{
					var rightX:Number = texturePivotX + textureWidth * totalScaleX;
					var bottomY:Number = texturePivotY + textureHeight * totalScaleY;

					totalRotCos = cos(totalRotation);
					totalRotSin = sin(totalRotation);

					var topLeftX:Number = (texturePivotX * totalRotCos - totalRotSin * texturePivotY) + newTextureX;
					var topLeftY:Number = (texturePivotX * totalRotSin + totalRotCos * texturePivotY) + newTextureY;

					var topRightX:Number = (rightX * totalRotCos - totalRotSin * texturePivotY) + newTextureX;
					var topRightY:Number = (rightX * totalRotSin + totalRotCos * texturePivotY) + newTextureY;

					var bottomRightX:Number = (rightX * totalRotCos - totalRotSin * bottomY) + newTextureX;
					var bottomRightY:Number = (rightX * totalRotSin + totalRotCos * bottomY) + newTextureY;

					var bottomLeftX:Number = (texturePivotX * totalRotCos - totalRotSin * bottomY) + newTextureX;
					var bottomLeftY:Number = (texturePivotX * totalRotSin + totalRotCos * bottomY) + newTextureY;

					boundingBoxTopLeftX = min(min(topLeftX, topRightX), min(bottomRightX, bottomLeftX));
					boundingBoxTopLeftY = min(min(topLeftY, topRightY), min(bottomRightY, bottomLeftY));

					boundingBoxBottomRightX = max(max(topLeftX, topRightX), max(bottomRightX, bottomLeftX));
					boundingBoxBottomRightY = max(max(topLeftY, topRightY), max(bottomRightY, bottomLeftY));

					//
					if (!isIntersect(boundingBoxTopLeftX, boundingBoxTopLeftY, boundingBoxBottomRightX, boundingBoxBottomRightY,
					                 _currentCameraViewportX, _currentCameraViewportY,
					                 _currentCameraViewportWidth_add_X, _currentCameraViewportHeight_add_Y)) return;
				}
			}
			////////////////////////////////

			// if need apply color transformation
			var colorTransform:ColorTransform = null;
			if (!isColorTransformNotChanged)
			{
				colorTransform = _colorTransform;
				colorTransform.alphaMultiplier = p_alphaMultiplier;
				colorTransform.redMultiplier = p_redMultiplier;
				colorTransform.greenMultiplier = p_greenMultiplier;
				colorTransform.blueMultiplier = p_blueMultiplier;
			}

			//
			if (isCopyPixelsDrawing)
			{
				_rectTextureRender.setTo(xRectTextureRender, yRectTextureRender, widthRectTextureRender, heightRectTextureRender);
				_point.setTo(newTextureX + texturePivotX + xRectTextureRender, newTextureY + texturePivotY + yRectTextureRender);

				// TODO:
//				var bitmapN:BitmapData = new BitmapData(textureWidth, textureHeight, bitmap.transparent);
//				bitmapN.applyFilter(bitmap, _rect, new Point(0,0), new BlurFilter());
				_canvas.copyPixels(bitmap, _rectTextureRender, _point, null, null, bitmap.transparent);
			}
			else
			{
				// tuning of matrix
//				_matrix.identity();
//				_matrix.scale(totalScaleX, totalScaleY);
//				_matrix.translate(texturePivotX, texturePivotY);
//				_matrix.rotate(totalRotation);
//				_matrix.translate(newTextureX, newTextureY);

				var a:Number = totalScaleX;
				var b:Number = 0;
				var c:Number = 0;
				var d:Number = totalScaleY;

				_matrix.a = a * totalRotCos - b * totalRotSin;
				_matrix.b = a * totalRotSin + b * totalRotCos;
				_matrix.c = c * totalRotCos - d * totalRotSin;
				_matrix.d = c * totalRotSin + d * totalRotCos;
				_matrix.tx = (totalRotCos * texturePivotX - totalRotSin * texturePivotY) + newTextureX;
				_matrix.ty = (totalRotSin * texturePivotX + totalRotCos * texturePivotY) + newTextureY;

				_canvas.drawWithQuality(bitmap, _matrix, colorTransform, p_blendMode, _currentCameraViewport, p_smoothing, StageQuality.MEDIUM);
//				_canvas.draw(bitmap, _matrix, colorTransform, p_blendMode, _currentCameraViewport, p_smoothing);
			}
		}

		/**
		 */
		[Inline]
		final private function max(p_a:Number, p_b:Number):Number
		{
			return p_a > p_b ? p_a : p_b
		}

		/**
		 */
		[Inline]
		final private function min(p_a:Number, p_b:Number):Number
		{
			return p_a < p_b ? p_a : p_b
		}

		/**
		 */
		[Inline]
		final private function isIntersect(p_leftTopX:Number, p_leftTopY:Number, p_rightBottomX:Number, p_rightBottomY:Number, p_leftTopX_1:Number,
		                                   p_leftTopY_1:Number, p_rightBottomX_1:Number, p_rightBottomY_1:Number):Boolean
		{
			if (p_leftTopX > p_rightBottomX_1 || p_rightBottomX < p_leftTopX_1 || p_rightBottomY < p_leftTopY_1 || p_leftTopY > p_rightBottomY_1)  return false;

			var exp:Boolean = false;

			if (p_leftTopX >= p_leftTopX_1)
			{
				if (p_leftTopX <= p_rightBottomX_1) exp = true;
			}

			if (!exp)
			{
				if (p_leftTopX_1 >= p_leftTopX)
				{
					if (!(p_leftTopX_1 <= p_rightBottomX)) return false;
				}
				else return false;
			}

			if (p_leftTopY >= p_leftTopY_1)
			{
				if (p_leftTopY <= p_rightBottomY_1) return true;
			}

			if (p_leftTopY_1 >= p_leftTopY)
			{
				if (p_leftTopY_1 <= p_rightBottomY) return true;
			}

			return false;
		}

		/**
		 */
		[Inline]
		final private function cos(p_angleRad:Number):Number
		{
			return _cosTable[int(p_angleRad * RAD_TO_DEG + 360)];
		}

		/**
		 */
		[Inline]
		final private function sin(p_angleRad:Number):Number
		{
			return _sinTable[int(p_angleRad * RAD_TO_DEG + 360)];
		}

		/**
		 * Fill with specify color some rect area.
		 */
		[Inline]
		final public function fillRect(p_x:Number, p_y:Number, p_width:int, p_height:int, p_color:uint):void
		{
			_rectTextureRender.setTo(p_x, p_y, p_width, p_height);
			_canvas.fillRect(_rectTextureRender, p_color);
		}

		/**
		 * Determines if context working with stage3d or not (with blitting).
		 */
		public function get isStage3d():Boolean
		{
			return _isStage3d;
		}

		/**
		 * Sends when context was initialized.
		 */
		public function get onInitialized():BBSignal
		{
			return _onInitialized;
		}
	}
}
