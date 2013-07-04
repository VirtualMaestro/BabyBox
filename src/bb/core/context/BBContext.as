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
	import bb.core.BBTransform;
	import bb.core.BabyBox;
	import bb.render.components.BBRenderable;
	import bb.render.constants.BBRenderMode;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;

	import com.genome2d.context.GContext;
	import com.genome2d.core.GConfig;
	import com.genome2d.core.Genome2D;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	use namespace bb_private;

	/**
	 * Response for rendering. Also determines what renderer (Blitting or Genome) will used.
	 */
	public class BBContext
	{
		/**
		 * Sends when context was initialized.
		 */
		public var onInitialized:BBSignal = null;

		/**
		 */
		public var PRECISE_ROTATION:Number = 1.1 * Math.PI / 180.0;

		/**
		 */
		public var PRECISE_SCALE:Number = 0.01;

		/**
		 */
		public var PRECISE_COLOR:Number = 0.1;

		private var PI2:Number = Math.PI * 2;

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
		private var _smoothingDraw:Boolean = true;

		//
		private var _rect:Rectangle = null;
		private var _point:Point = null;
		private var _matrix:Matrix = null;
		private var _colorTransform:ColorTransform = null;

		/**
		 */
		public function BBContext()
		{
			onInitialized = BBSignal.get(this, true);
			_rect = new Rectangle();
			_point = new Point();
			_matrix = new Matrix();
			_colorTransform = new ColorTransform();
		}

		/**
		 * Start to init context.
		 */
		public function init(p_stage:Stage):void
		{
			_stage = p_stage;
			_config = BabyBox.getInstance().config;
			_canvasViewRect = _config.getViewRect();
			isFrustum = _config.isFrustum;

			if (_config.renderMode == BBRenderMode.BLITTING) initBlitting();
			else initGenome();
		}

		/**
		 * Try to init blitting.
		 */
		private function initBlitting():void
		{
			_canvasHolder = new Bitmap(new BitmapData(_canvasViewRect.width, _canvasViewRect.height, true, 0xFFf0f3c7), "auto", true);
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

			var genomeConfig:GConfig = new GConfig(new Rectangle(_canvasViewRect.x, _canvasViewRect.y, _canvasViewRect.width, _canvasViewRect.height), _config.renderMode);
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
				_smoothingDraw = _config.smoothingDraw;
				isFrustum = _config.isFrustum;
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
		 * If apply frustum culling test.
		 * Mean before render object will be tested on getting on screen.
		 */
		public var isFrustum:Boolean = false;

		/**
		 * Render the renderable component to screen.
		 */
		public function renderComponent(p_renderableComponent:BBRenderable):void
		{
			var texture:BBTexture = p_renderableComponent.getTexture();
			var textureTransform:BBTransform = p_renderableComponent.node.transform;
			var textureBitmapData:BitmapData = texture.bitmapData;

			// Color update
			var colorTransform:ColorTransform = null;
			if (textureTransform.isColorShouldBeDisplayed)
			{
				colorTransform = _colorTransform;
				colorTransform.redMultiplier = textureTransform.worldRed;
				colorTransform.greenMultiplier = textureTransform.worldGreen;
				colorTransform.blueMultiplier = textureTransform.worldBlue;
				colorTransform.alphaMultiplier = textureTransform.worldAlpha;
			}

			//
			var texturePivotX:Number = texture.pivotX;
			var texturePivotY:Number = texture.pivotY;
			var textureX:Number = textureTransform.worldX;
			var textureY:Number = textureTransform.worldY;
			var textureScaleX:Number = textureTransform.worldScaleX;
			var textureScaleY:Number = textureTransform.worldScaleY;
			var textureRotation:Number = p_renderableComponent.allowRotation ? textureTransform.worldRotation : 0;

			if (_isStage3d)
			{
				// TODO: Implement stage3d

//				_genomeContext.draw();
//				_genomeContext.blit();
			}
			else
			{
				var sin:Number = _currentCameraSIN;
				var cos:Number = _currentCameraCOS;
				var dx:Number = textureX - _currentCameraX;
				var dy:Number = textureY - _currentCameraY;

				var newTextureX:Number = (dx * cos - sin * dy) * _currentCameraTotalScaleX + _currentCameraViewportCenterX + p_renderableComponent.offsetX;
				var newTextureY:Number = (dx * sin + cos * dy) * _currentCameraTotalScaleY + _currentCameraViewportCenterY + p_renderableComponent.offsetY;

				var totalRotation:Number = (textureRotation - _currentCameraRotation + p_renderableComponent.offsetRotation) % PI2;
				var totalScaleX:Number = textureScaleX * _currentCameraTotalScaleX * p_renderableComponent.scaleX;
				var totalScaleY:Number = textureScaleY * _currentCameraTotalScaleY * p_renderableComponent.scaleY;

				texturePivotX *= totalScaleX;
				texturePivotY *= totalScaleY;

				///  Test for getting into the viewport /////////////
				if (isFrustum)
				{
					var leftX:Number = texturePivotX;
					var topY:Number = texturePivotY;
					var rightX:Number = texturePivotX + textureBitmapData.width * totalScaleX;
					var bottomY:Number = texturePivotY + textureBitmapData.height * totalScaleY;

					var totalRotCos:Number = Math.cos(totalRotation);
					var totalRotSin:Number = Math.sin(totalRotation);

					var topLeftX:Number = (leftX * totalRotCos - totalRotSin * topY) + newTextureX;
					var topLeftY:Number = (leftX * totalRotSin + totalRotCos * topY) + newTextureY;

					var topRightX:Number = (rightX * totalRotCos - totalRotSin * topY) + newTextureX;
					var topRightY:Number = (rightX * totalRotSin + totalRotCos * topY) + newTextureY;

					var bottomRightX:Number = (rightX * totalRotCos - totalRotSin * bottomY) + newTextureX;
					var bottomRightY:Number = (rightX * totalRotSin + totalRotCos * bottomY) + newTextureY;

					var bottomLeftX:Number = (leftX * totalRotCos - totalRotSin * bottomY) + newTextureX;
					var bottomLeftY:Number = (leftX * totalRotSin + totalRotCos * bottomY) + newTextureY;

					var boundingBoxTopLeftX:Number = min(min(topLeftX, topRightX), min(bottomRightX, bottomLeftX));
					var boundingBoxTopLeftY:Number = min(min(topLeftY, topRightY), min(bottomRightY, bottomLeftY));

					var boundingBoxBottomRightX:Number = max(max(topLeftX, topRightX), max(bottomRightX, bottomLeftX));
					var boundingBoxBottomRightY:Number = max(max(topLeftY, topRightY), max(bottomRightY, bottomLeftY));

					if (!isIntersect(boundingBoxTopLeftX, boundingBoxTopLeftY, boundingBoxBottomRightX, boundingBoxBottomRightY,
							_currentCameraViewportX, _currentCameraViewportY,
							_currentCameraViewportWidth_add_X, _currentCameraViewportHeight_add_Y)) return;
				}
				////////////////////////////////

				var totalRotABS:Number = Math.abs(totalRotation);
				var PI_sub_RAD:Number = PI2 - totalRotABS;
				var isScaleNotChanged:Boolean = totalScaleX > 0 && totalScaleY > 0 && Math.abs(1.0 - totalScaleX * totalScaleY) < PRECISE_SCALE;

				//
				if ((PI_sub_RAD < PRECISE_ROTATION || totalRotABS < PRECISE_ROTATION) && isScaleNotChanged && (!colorTransform))
				{
					_rect.setTo(0, 0, textureBitmapData.width, textureBitmapData.height);
					_point.setTo(newTextureX + texturePivotX, newTextureY + texturePivotY);

					_canvas.copyPixels(textureBitmapData, _rect, _point, null, null, textureBitmapData.transparent);
				}
				else
				{
					// tuning of matrix
					_matrix.identity();
					_matrix.scale(totalScaleX, totalScaleY);
					_matrix.translate(texturePivotX, texturePivotY);
					_matrix.rotate(totalRotation);
					_matrix.translate(newTextureX, newTextureY);

					_canvas.draw(textureBitmapData, _matrix, colorTransform, null, _currentCameraViewport, _smoothingDraw);
				}
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
		final private function isIntersect(p_leftTopX:Number, p_leftTopY:Number, p_rightBottomX:Number, p_rightBottomY:Number, p_leftTopX_1:Number, p_leftTopY_1:Number, p_rightBottomX_1:Number, p_rightBottomY_1:Number):Boolean
		{
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
		 * Render texture.
		 * TODO:
		 */
		public function renderTexture(p_texture:BBTexture):void
		{
			if (_isStage3d)
			{

			}
			else
			{

			}
		}

		/**
		 * Fill with specify color some rect area.
		 */
		[Inline]
		final public function fillRect(p_x:Number, p_y:Number, p_width:int, p_height:int, p_color:uint):void
		{
			_rect.setTo(p_x, p_y, p_width, p_height);
			_canvas.fillRect(_rect, p_color);
		}

		/**
		 * Determines if context working with stage3d or not (with blitting).
		 */
		public function get isStage3d():Boolean
		{
			return _isStage3d;
		}
	}
}
