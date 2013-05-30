/**
 * User: VirtualMaestro
 * Date: 02.02.13
 * Time: 12:55
 */
package src.bb.components
{
	import bb.signals.BBSignal;

	import flash.geom.Point;
	import flash.geom.Rectangle;

	import src.bb.bb_spaces.bb_private;
	import src.bb.core.BBConfig;
	import src.bb.core.BBNodeStatus;
	import src.bb.core.BabyBox;
	import src.bb.core.context.BBContext;
	import src.bb.events.BBMouseEvent;
	import src.bb.modules.BBCamerasModule;
	import src.bb.modules.BBGraphModule;
	import src.bb.pools.BBComponentPool;
	import src.bb.vo.BBColor;

	import vm.debug.Assert;

	use namespace bb_private;

	/**
	 * Represents camera.
	 */
	public class BBCamera extends BBComponent
	{
		// viewport
		private var _viewPort:Rectangle = null;

		/**
		 */
		private var _fitContentToViewport:Boolean = false;

		/**
		 * Color of filling background.
		 */
		public var backgroundColor:BBColor = null;

		/**
		 * Determines if need to flood fill viewport by given backgroundColor.
		 * (in most cases if exist multi-cameras this property set to 'false')
		 */
		public var isFillViewport:Boolean = false;

		/**
		 * Mask number of camera. Determines if camera can render current node (node also has a mask).
		 * If camera.mask & node.mask != 0 - camera can render current node.
		 */
		public var mask:int = 0xffffffff;

		/**
		 * Enable mouse interaction with this camera.
		 */
		public var mouseEnable:Boolean = true;

		/**
		 * Zoom of camera.
		 */
		private var _zoom:Number = 1;

		//
		private var _core:BBGraphModule = null;
		private var _config:BBConfig = null;

		//
		bb_private var isCaptured:Boolean = false;
//		bb_private var canvas:BitmapData;

		// previous parent camera position
		private var _parentCameraX:Number = 0;
		private var _parentCameraY:Number = 0;
		private var _parentCameraR:Number = 0;

		/**
		 */
		public function BBCamera()
		{
			super();

			_config = BabyBox.getInstance().config;

			_viewPort = new Rectangle();

			backgroundColor = new BBColor();

			onAdded.add(cameraAddedToNode);
//			onRemoved.add(cameraRemovedFromNode);
		}

		/**
		 *     @private
		 */
		bb_private function captureMouseEvent(p_captured:Boolean, p_event:BBMouseEvent):Boolean
		{
			if (isCaptured) return false;
			isCaptured = true;

			return _core.root.processMouseEvent(p_captured, p_event);
		}

//		bb_private function captureMouseEvent(p_captured:Boolean, p_event:MouseEvent, p_position:Point):Boolean
//		{
//			if (isCaptured || !node.active) return false;
//			isCaptured = true;
//
//			if (!calcRelatedPosition(p_position)) return false;
//
//			return _core.root.processMouseEvent(p_captured, p_event, p_position, this);
//		}
//
		/**
		 * Calculate new position of given point related to coordinate system of camera.
		 * Return false if point is not in the camera's viewPort.
		 */
		bb_private function calcRelatedPosition(p_point:Point):Boolean
		{
			var posX:Number = p_point.x;
			var posY:Number = p_point.y;

			if (!_viewPort.contains(posX, posY)) return false;

			posX -= _viewPort.x + _viewPort.width / 2;
			posY -= _viewPort.y + _viewPort.height / 2;

			var transform:BBTransform = node.transform;

			var cos:Number = Math.cos(transform.worldRotation);
			var sin:Number = Math.sin(transform.worldRotation);

			var tx:Number = posX * cos - posY * sin;
			var ty:Number = posY * cos + posX * sin;

			tx /= _zoom;
			ty /= _zoom;

			p_point.x = tx + transform.worldX;
			p_point.y = ty + transform.worldY;

			return true;
		}

		/**
		 */
		private function cameraAddedToNode(p_signal:BBSignal):void
		{
			node.independentTransformation = true;
			node.transform.setScale(_zoom, _zoom);
			setViewport(0, 0, _config.getViewRect().width, _config.getViewRect().height);

			node.onAdded.add(nodeAddedToParentHandler);
//			node.onRemoved.add(nodeRemovedFromParentHandler, true);

			if (node.isOnStage) addCameraToEngine();
		}

		/**
		 */
		private function nodeAddedToParentHandler(p_signal:BBSignal):void
		{
			var status:BBNodeStatus = p_signal.params as BBNodeStatus;
			if (status.isOnStage) addCameraToEngine();
		}
//
//		/**
//		 */
//		private function nodeRemovedFromParentHandler(p_signal:BBSignal):void
//		{
//			if (_core) _core.removeCamera(this);
//		}
//
//		/**
//		 */
//		private function cameraRemovedFromNode(p_signal:BBSignal):void
//		{
//			if (_core) _core.removeCamera(this);
//		}

		/**
		 */
		private function addCameraToEngine():void
		{
			_core = node.z_core;
			(_core.getModule(BBCamerasModule) as BBCamerasModule).addCamera(this);
		}

		/**
		 * Set zoom of camera. 1 mean nature size. 0.5 mean smaller by half.
		 */
		public function set zoom(val:Number):void
		{
			_zoom = val < 0.1 ? 0.1 : val;
			if (node) node.transform.setScale(val, val);
		}

		/**
		 * @private
		 */
		public function get zoom():Number
		{
			if (node)
			{
				_zoom = node.transform.scaleX;
				if (_zoom < 0.1) node.transform.scaleX = _zoom = 0.1;
			}

			return _zoom;
		}

		//
		bb_private var viewportCenterX:Number = 0;
		bb_private var viewportCenterY:Number = 0;
		bb_private var viewPortScaleX:Number = 1;
		bb_private var viewPortScaleY:Number = 1;

		/**
		 * Sets camera's view port.
		 */
		public function setViewport(p_x:int, p_y:int, p_width:int, p_height:int):void
		{
			var prevWidth:Number = _viewPort.width;
			var prevHeight:Number = _viewPort.height;
			_viewPort.setTo(p_x, p_y, p_width, p_height);
			viewportCenterX = p_x + p_width * 0.5;
			viewportCenterY = p_y + p_height * 0.5;

			if (prevWidth == p_width && prevHeight == p_height) return;

			if (_fitContentToViewport)
			{
				viewPortScaleX = p_width / _config.gameWidth;
				viewPortScaleY = p_height / _config.gameHeight;
			}
			else viewPortScaleX = viewPortScaleY = 1.0;

			//
//			if (canvas) canvas.dispose();
//			canvas = new BitmapData(p_width, p_height);
		}

		/**
		 */
		public function getViewport():Rectangle
		{
			return _viewPort;
		}

		/**
		 * If 'false' all content is scaled depending on game size params (gameWidth/Height) and fit to camera's view port.
		 */
		public function set fitContentToViewport(p_val:Boolean):void
		{
			_fitContentToViewport = p_val;

			if (_fitContentToViewport)
			{
				viewPortScaleX = _viewPort.width  / _config.gameWidth;
				viewPortScaleY = _viewPort.height / _config.gameHeight;
			}
			else viewPortScaleX = viewPortScaleY = 1.0;

			//
			node.transform.isTransformChanged = true;
		}

		/**
		 */
		public function get fitContentToViewport():Boolean
		{
			return _fitContentToViewport;
		}

		//
		bb_private var rotation:Number = 0;

		bb_private var SIN:Number = Math.sin(-rotation);
		bb_private var COS:Number = Math.cos(-rotation);

		// total scale = zoom*viewPortScale
		bb_private var totalScaleX:Number = 1;
		bb_private var totalScaleY:Number = 1;

		// camera position
		bb_private var cameraX:Number = 0;
		bb_private var cameraY:Number = 0;

		/**
		 */
		bb_private function invalidate():void
		{
			var transform:BBTransform = node.transform;

			if (transform.isTransformChanged)
			{
				transform.isTransformChanged = false;

				// if rotation changed
				if (transform.worldRotation != rotation)
				{
					rotation = transform.worldRotation;
					SIN = Math.sin(-rotation);
					COS = Math.cos(-rotation);
				}

				// total scale
				var cameraZoom:Number = transform.worldScaleX;
				cameraZoom = cameraZoom < 0.1 ? 0.1 : cameraZoom;
				totalScaleX = cameraZoom * viewPortScaleX;
				totalScaleY = cameraZoom * viewPortScaleY;

				// camera position
				cameraX = transform.worldX;
				cameraY = transform.worldY;
			}
		}

		/**
		 * Render current view port of current camera.
		 */
		public function render(p_context:BBContext):void
		{
			// invalidate camera's parameters
			invalidate();

			// set current camera
			p_context.setCamera(this);

			// fill the background
			if (isFillViewport && backgroundColor.z_alpha > 0) p_context.fillRect(_viewPort.x, _viewPort.y, _viewPort.width, _viewPort.height, backgroundColor.color);
//			clearCanvas();

			// start to rendering all nodes
			_core.root.render(p_context);
		}

//		/**
//		 */
//		private function clearCanvas():void
//		{
//			canvas.fillRect(canvas.rect, backgroundColor.color);
//		}

		/**
		 */
		private var _dependOnCamera:BBCamera;
		private var _offsetFactorX:Number = 1.0;
		private var _offsetFactorY:Number = 1.0;
		private var _offsetFactorRotation:Number = 1.0;

		/**
		 * Depend moving from another camera.
		 * p_camera - camera. Camera should be added to node.
		 *
		 * Offset factor:
		 * 1.0 - mean one to one;
		 * 0.5 - mean with half speed;
		 * 2.0 - mean with 2x speed;
		 */
		public function dependOnCamera(p_camera:BBCamera, p_offsetFactorX:Number = 1.0, p_offsetFactorY:Number = 1.0, p_offsetFactorRotation:Number = 1.0):void
		{
			CONFIG::debug
			{
				Assert.isTrue((p_camera != this), "depend camera the same as this", "BBCamera.dependOnCamera");
				Assert.isTrue((p_camera.node != null), "current camera hasn't node", "BBCamera.dependOnCamera");
			}

			_dependOnCamera = p_camera;
			_offsetFactorX = p_offsetFactorX;
			_offsetFactorY = p_offsetFactorY;
			_offsetFactorRotation = p_offsetFactorRotation;

			var parentTransform:BBTransform = _dependOnCamera.node.transform;
			_parentCameraX = parentTransform.x;
			_parentCameraY = parentTransform.y;
			_parentCameraR = parentTransform.rotation;

			updateEnable = true;
		}

		/**
		 * Set offset related to parent camera (from which this camera depends).
		 */
		public function setOffsets(p_offsetFactorX:Number, p_offsetFactorY:Number, p_offsetFactorRotation:Number):void
		{
			_offsetFactorX = p_offsetFactorX;
			_offsetFactorY = p_offsetFactorY;
			_offsetFactorRotation = p_offsetFactorRotation;
		}

		/**
		 */
		public function get offsetX():Number
		{
			return _offsetFactorX;
		}

		/**
		 */
		public function get offsetY():Number
		{
			return _offsetFactorY;
		}

		/**
		 */
		public function get offsetRotation():Number
		{
			return _offsetFactorRotation;
		}

		/**
		 */
		override public function update(p_deltaTime:Number):void
		{
			if (_dependOnCamera)
			{
				var transformDependCamera:BBTransform = _dependOnCamera.node.transform;
				var nParentCameraX:Number = transformDependCamera.x;
				var nParentCameraY:Number = transformDependCamera.y;
				var nParentCameraR:Number = transformDependCamera.rotation;

				var shiftX:Number = nParentCameraX - _parentCameraX;
				var shiftY:Number = nParentCameraY - _parentCameraY;
				var shiftR:Number = nParentCameraR - _parentCameraR;

				if ((shiftX + shiftY + shiftR) != 0)
				{
					node.transform.shiftPositionAndRotation(shiftX * _offsetFactorX, shiftY * _offsetFactorY,
							shiftR * _offsetFactorRotation);
				}

				_parentCameraX = nParentCameraX;
				_parentCameraY = nParentCameraY;
				_parentCameraR = nParentCameraR;
			}
		}

		/**
		 * Disposes camera. Remove from render graph and from system.
		 */
		override public function dispose():void
		{
			if (_core)
			{
				(_core.getModule(BBCamerasModule) as BBCamerasModule).removeCamera(this);
				_core = null;
			}

			super.dispose();
		}

		// static pool methods

		/**
		 * Return new component BBCamera added to node.
		 */
		static public function get(p_cameraName:String = ""):BBCamera
		{
			return BBComponentPool.getWithNode(BBCamera, p_cameraName) as BBCamera;
		}
	}
}
