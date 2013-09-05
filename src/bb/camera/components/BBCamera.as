/**
 * User: VirtualMaestro
 * Date: 02.02.13
 * Time: 12:55
 */
package bb.camera.components
{
	import bb.bb_spaces.bb_private;
	import bb.camera.BBCamerasModule;
	import bb.camera.BBShaker;
	import bb.config.BBConfig;
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.core.BBNodeStatus;
	import bb.core.BBTransform;
	import bb.core.BabyBox;
	import bb.core.context.BBContext;
	import bb.mouse.events.BBMouseEvent;
	import bb.signals.BBSignal;
	import bb.tree.BBTreeModule;
	import bb.vo.BBColor;

	import flash.geom.Point;
	import flash.geom.Rectangle;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Represents camera.
	 */
	public class BBCamera extends BBComponent
	{
		//
		private const MIN_ZOOM:Number = 0.05;

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
		public var mask:int = -1;

		/**
		 * Enable mouse interaction with this camera.
		 */
		public var mouseEnable:Boolean = false;

		/**
		 * Boundary that limits the movement of camera.
		 * Camera can't leave that border.
		 * If border no need just set null.
		 */
		public var border:Rectangle = null;

		/**
		 * Make movement of camera smoothly.
		 * If 'false' the camera strictly follow object pixel by pixel
		 * If 'true' there is possible to use in conjunction with properties 'fadeMove' and 'radiusCalm'.
		 */
		public var smoothMove:Boolean = false;

		/**
		 * Gives possible to setup speed of start fading and end fading of camera movement.
		 * By default is 0. For start try to use value 0.05.
		 */
		public var fadeMove:Number = 0.0;

		/**
		 * Until object not further then given radiusCalm from the camera, camera will not move.
		 * By default value is calculated as viewport's bigger side (width/height) divided by 6.
		 * So, if viewport width = 800 and height = 600, radiusCalm = width/6 = 133
		 */
		public var radiusCalm:int = 133;

		//
		private var _accumulateFadeMoveX:Number = 0;
		private var _accumulateFadeMoveY:Number = 0;

		// viewport
		private var _viewPort:Rectangle = null;

		/**
		 */
		private var _fitContentToViewport:Boolean = false;

		/**
		 * Transform of camera.
		 */
		private var _transform:BBTransform = null;

		/**
		 * Camera following to this leader.
		 */
		private var _leader:BBTransform;

		/**
		 * Dispatches when shake complete.
		 */
		private var _onShakeComplete:BBSignal;

		/**
		 * Zoom of camera.
		 */
		private var _zoom:Number = 1;

		//
		private var _core:BBTreeModule = null;
		private var _config:BBConfig = null;

		//
		bb_private var isCaptured:Boolean = false;
		bb_private var viewportCenterX:Number = 0;
		bb_private var viewportCenterY:Number = 0;
		private var _viewPortScaleX:Number = 1;
		private var _viewPortScaleY:Number = 1;

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

		//
		private var _dependOnCamera:BBCamera;
		private var _dependOnCameraTransform:BBTransform;
		private var _offsetX:Number = 1.0;
		private var _offsetY:Number = 1.0;
		private var _offsetZoom:Number = 1.0;
		private var _offsetRotation:Number = 1.0;

		// previous parent camera position
		private var _parentCameraX:Number = 0;
		private var _parentCameraY:Number = 0;
		private var _parentCameraZ:Number = 0;
		private var _parentCameraR:Number = 0;

		/**
		 */
		public function BBCamera()
		{
			super();

			_config = BabyBox.get().config;
			_viewPort = new Rectangle();
			backgroundColor = new BBColor();
			cacheable = false;

			onAdded.add(cameraAddedToNode);
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
			_transform = node.transform;
			_transform.setScale(_zoom, _zoom);
			setViewport(0, 0, _config.getViewRect().width, _config.getViewRect().height);

			radiusCalm = (_viewPort.width > _viewPort.height ? _viewPort.width : _viewPort.height) / 6;

			node.onAdded.add(nodeAddedToParentHandler);

			if (node.isOnStage) addCameraToEngine();
		}

		/**
		 */
		private function nodeAddedToParentHandler(p_signal:BBSignal):void
		{
			var status:BBNodeStatus = p_signal.params as BBNodeStatus;
			if (status.isOnStage) addCameraToEngine();

			updateEnable = true;
		}

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
			_zoom = val < MIN_ZOOM ? MIN_ZOOM : val;
			if (_transform) _transform.setScale(val, val);
		}

		/**
		 * @private
		 */
		public function get zoom():Number
		{
			if (_transform)
			{
				_zoom = _transform.scaleX;
				if (_zoom < MIN_ZOOM) _transform.scaleX = _zoom = MIN_ZOOM;
			}

			return _zoom;
		}

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
				_viewPortScaleX = p_width / _config.gameWidth;
				_viewPortScaleY = p_height / _config.gameHeight;
			}
			else _viewPortScaleX = _viewPortScaleY = 1.0;
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
				_viewPortScaleX = _viewPort.width / _config.gameWidth;
				_viewPortScaleY = _viewPort.height / _config.gameHeight;
			}
			else _viewPortScaleX = _viewPortScaleY = 1.0;
		}

		/**
		 */
		public function get fitContentToViewport():Boolean
		{
			return _fitContentToViewport;
		}

		/**
		 */
		[Inline]
		final private function invalidate():void
		{
			var transform:BBTransform = _transform;

			// if rotation changed
			if (transform.worldRotation != rotation)
			{
				rotation = transform.worldRotation;
				SIN = Math.sin(-rotation);
				COS = Math.cos(-rotation);
			}

			// total scale
			var cameraZoom:Number = transform.worldScaleX;
			cameraZoom = cameraZoom < MIN_ZOOM ? MIN_ZOOM : cameraZoom;
			totalScaleX = cameraZoom * _viewPortScaleX;
			totalScaleY = cameraZoom * _viewPortScaleY;

			// camera position
			cameraX = transform.worldX;
			cameraY = transform.worldY;
		}

		/**
		 */
		[Inline]
		final private function updateDependOn():void
		{
			if (_dependOnCamera)
			{
				var nParentCameraX:Number = _dependOnCameraTransform.x;
				var nParentCameraY:Number = _dependOnCameraTransform.y;
				var nParentCameraZ:Number = _dependOnCamera.zoom;
				var nParentCameraR:Number = _dependOnCameraTransform.rotation;

				var shiftX:Number = nParentCameraX - _parentCameraX;
				var shiftY:Number = nParentCameraY - _parentCameraY;
				var shiftZ:Number = nParentCameraZ - _parentCameraZ;
				var shiftR:Number = nParentCameraR - _parentCameraR;

				if ((shiftX + shiftY + shiftR + shiftZ) != 0)
				{
					_transform.shiftPositionAndRotation(shiftX * _offsetX, shiftY * _offsetY, shiftR * _offsetRotation);
					_transform.shiftScale(shiftZ * _offsetZoom, shiftZ * _offsetZoom);
					_transform.invalidate(true, false);
					_transform.resetInvalidationFlags();
					invalidate();
				}

				_parentCameraX = nParentCameraX;
				_parentCameraY = nParentCameraY;
				_parentCameraZ = nParentCameraZ;
				_parentCameraR = nParentCameraR;
			}
		}

		/**
		 * Render current view port of current camera.
		 */
		public function render(p_context:BBContext):void
		{
			updateDependOn();

			// set current camera
			p_context.setCamera(this);

			// fill the background
			if (isFillViewport && backgroundColor.z_alpha > 0) p_context.fillRect(_viewPort.x, _viewPort.y, _viewPort.width, _viewPort.height, backgroundColor.color);

			// start to rendering all nodes
			_core.root.render(p_context);
		}

		/**
		 * Depend moving from another camera.
		 * p_camera - camera. Camera should be added to node.
		 *
		 * Offset factor:
		 * 1.0 - mean one to one;
		 * 0.5 - mean with half speed;
		 * 2.0 - mean with 2x speed;
		 */
		public function dependOnCamera(p_camera:BBCamera, p_offsetX:Number = 1.0, p_offsetY:Number = 1.0, p_offsetZoom:Number = 1.0):void
		{
			CONFIG::debug
			{
				Assert.isTrue((p_camera != this), "depend camera the same as this", "BBCamera.dependOnCamera");
				Assert.isTrue((p_camera.node != null), "current camera hasn't node", "BBCamera.dependOnCamera");
			}

			_dependOnCamera = p_camera;
			_dependOnCameraTransform = _dependOnCamera.node.transform;
			_offsetX = p_offsetX;
			_offsetY = p_offsetY;
			_offsetZoom = p_offsetZoom;

			_parentCameraX = _dependOnCameraTransform.x;
			_parentCameraY = _dependOnCameraTransform.y;
			_parentCameraZ = _dependOnCamera.zoom;
		}

		/**
		 * Set offset related to parent camera (which this camera depends on).
		 */
		public function setOffsets(p_offsetX:Number, p_offsetY:Number, p_offsetZoom:Number):void
		{
			_offsetX = p_offsetX;
			_offsetY = p_offsetY;
			_offsetZoom = p_offsetZoom;
		}

		/**
		 */
		public function get offsetX():Number
		{
			return _offsetX;
		}

		/**
		 */
		public function get offsetY():Number
		{
			return _offsetY;
		}

		/**
		 */
		public function get offsetZoom():Number
		{
			return _offsetZoom;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			invalidate();

			// if leader presents, update position
			if (_leader) moveCamera(_leader.x, _leader.y);
			if (_shaker) shakeCamera(p_deltaTime);
		}

		/**
		 */
		final private function moveCamera(p_x:Number, p_y:Number):void
		{
			if (smoothMove)
			{
				var camX:Number = _transform.x;
				var camY:Number = _transform.y;
				var diffX:Number = p_x - camX;
				var diffY:Number = p_y - camY;
				var signX:int = diffX < 0 ? -1 : 1;
				var signY:int = diffY < 0 ? -1 : 1;

				if (fadeMove > 0)
				{
					if (Math.abs(diffX) > radiusCalm)
					{
						_accumulateFadeMoveX += fadeMove;
						if (_accumulateFadeMoveX > 1.0) _accumulateFadeMoveX = 1.0;
						_transform.x = camX + (Math.abs(diffX) - radiusCalm) * _accumulateFadeMoveX * signX;
					}
					else if (_accumulateFadeMoveX > 0)
					{
						_accumulateFadeMoveX -= fadeMove;
						if (_accumulateFadeMoveX < 0) _accumulateFadeMoveX = 0;
						_transform.x = camX + _accumulateFadeMoveX * signX;
					}

					if (Math.abs(diffY) > radiusCalm)
					{
						_accumulateFadeMoveY += fadeMove;
						if (_accumulateFadeMoveY > 1.0) _accumulateFadeMoveY = 1.0;
						_transform.y = camY + (Math.abs(diffY) - radiusCalm) * _accumulateFadeMoveY * signY;
					}
					else if (_accumulateFadeMoveY > 0)
					{
						_accumulateFadeMoveY -= fadeMove;
						if (_accumulateFadeMoveY < 0) _accumulateFadeMoveY = 0;
						_transform.y = camY + _accumulateFadeMoveY * signY;
					}
				}
				else
				{
					if (Math.abs(diffX) > radiusCalm) _transform.x = camX + (Math.abs(diffX) - radiusCalm) * signX;
					if (Math.abs(diffY) > radiusCalm) _transform.y = camY + (Math.abs(diffY) - radiusCalm) * signY;
				}
			}
			else _transform.setPosition(p_x, p_y);

			//
			if (border) correctPositionByBorder();
		}

		/**
		 */
		[Inline]
		final private function correctPositionByBorder():void
		{
			var tX:Number = _transform.x;
			var tY:Number = _transform.y;
			var vpW:Number = _viewPort.width / 2;
			var vpH:Number = _viewPort.height / 2;
			var bX:Number = border.x;
			var bY:Number = border.y;
			var bW:Number = border.width;
			var bH:Number = border.height;

			if (tX < bX + vpW) _transform.x = bX + vpW;
			else if (tX > bX + bW - vpW) _transform.x = bX + bW - vpW;

			if (tY < bY + vpH) _transform.y = bY + vpH;
			else if (tY > bY + bH - vpH) _transform.y = bY + bH - vpH;
		}

		/**
		 * Sets object to which camera should follow.
		 */
		public function set follow(p_leader:BBNode):void
		{
			if (_leader)
			{
				// if the same leader return
				if (_leader.node == p_leader) return;

				_leader.node.onRemoved.remove(heroDisposedHandler);
				_leader = null;
			}

			if (p_leader)
			{
				p_leader.onRemoved.add(heroDisposedHandler);
				_leader = p_leader.transform;
			}
		}

		/**
		 */
		private function heroDisposedHandler(p_signal:BBSignal):void
		{
			p_signal.removeCurrentListener();
			_leader = null;
		}

		/**
		 * Moves camera to given coordinates.
		 * Should to use without using 'follow' method.
		 */
		public function moveTo(p_x:Number, p_y:Number):void
		{
			// TODO:
		}

		//
		private var _timeAccumulator:int;
		private var _shaker:BBShaker = null;
		private var _shiftPositionX:Number = 0;
		private var _shiftPositionY:Number = 0;
		private var _shiftRotation:Number = 0;

		/**
		 * Shake the camera.
		 */
		public function shake(p_shaker:BBShaker):void
		{
			if (_shaker) return;
			CONFIG::debug
			{
				Assert.isTrue(!p_shaker.isDisposed, "current instance of BBShaker is disposed - impossible to use disposed shaker. " +
						"Instead need to use static method 'get' of BBShaker to created new one", "BBCamera.shake");
			}

			_shaker = p_shaker;
			_timeAccumulator = 0;
		}

		/**
		 */
		private function shakeCamera(p_deltaTime:int):void
		{
			_transform.shiftPositionAndRotation(-_shiftPositionX, -_shiftPositionY, -_shiftRotation);

			if (_timeAccumulator < _shaker.duration)
			{
				_shiftPositionX = _shaker.getX(_timeAccumulator);
				_shiftPositionY = _shaker.getY(_timeAccumulator);
				_shiftRotation = _shaker.getRotation(_timeAccumulator);

				_transform.shiftPositionAndRotation(_shiftPositionX, _shiftPositionY, _shiftRotation);
			}
			else
			{
				_shaker.dispose();
				_shaker = null;
				_shiftPositionX = _shiftPositionY = _shiftRotation = 0;
				if (_onShakeComplete) _onShakeComplete.dispatch();
			}

			_timeAccumulator += p_deltaTime;
		}

		/**
		 * Dispatches when shake complete.
		 */
		public function get onShakeComplete():BBSignal
		{
			if (_onShakeComplete == null) _onShakeComplete = BBSignal.get(this);
			return _onShakeComplete;
		}

		/**
		 * Determines if camera is shaking now.
		 */
		public function isShaking():Boolean
		{
			return _shaker != null;
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

			if (_onShakeComplete) _onShakeComplete.dispose();
			_onShakeComplete = null;

			_dependOnCamera = null;
			_dependOnCameraTransform = null;
			_config = null;
			_viewPort = null;
			_transform = null;
			backgroundColor = null;

			super.dispose();
		}

		// static pool methods

		/**
		 * Return new component BBCamera added to node.
		 */
		static public function get(p_cameraName:String = ""):BBCamera
		{
			return BBComponent.getWithNode(BBCamera, p_cameraName) as BBCamera;
		}
	}
}
