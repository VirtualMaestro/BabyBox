/**
 * User: VirtualMaestro
 * Date: 01.02.13
 * Time: 13:42
 */
package bb.render.components
{
	import bb.bb_spaces.bb_private;
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.core.BBTransform;
	import bb.core.BabyBox;
	import bb.core.context.BBContext;
	import bb.mouse.events.BBMouseEvent;
	import bb.pools.BBNativePool;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	use namespace bb_private;

	/**
	 * Base component for all renderable components.
	 */
	public class BBRenderable extends BBComponent
	{
		bb_private var z_texture:BBTexture = null;

		/**
		 */
		public var mousePixelEnabled:Boolean = false;

		/**
		 * Allow/Disallow rotating of renderable components. Could be useful with physical component.
		 * If 'false' ignores any self rotation.
		 */
		public var allowSelfRotation:Boolean = true;

		/**
		 * 'allowSelfRotation' param allow/disallow self rotation, but in the same time if camera rotating, also rotating and component.
		 * This is could help with conjunction of physics component - physics body can rotates, but graphics isn't.
		 *
		 * 'allowRotation' allow/disallow rotation at all. Even if camera starts rotate component moves but not rotates.
		 * It is could help when need to render component which could be rendered with the same result without rotation - e.g. particles.
		 * It could save performance.
		 */
		public var allowRotation:Boolean = true;

		/**
		 * Allow/disallow graphic scale (doesn't matter self-scale or camera's scale)
		 */
		public var allowScale:Boolean = true;

		public var offsetScaleX:Number = 1.0;
		public var offsetScaleY:Number = 1.0;

		public var offsetX:Number = 0.0;
		public var offsetY:Number = 0.0;
		public var offsetRotation:Number = 0.0;

		private var _offsetsChecksum:Number = 0;

		/**
		 * Blend mode for renderable component.
		 * Need to use constants from BlendMode class.
		 * By default null (no blend).
		 */
		public var blendMode:String = null;

		/**
		 * If apply frustum culling test.
		 * Mean before render object will be tested on getting on screen.
		 */
		public var isCulling:Boolean = true;

		/**
		 * Set smoothing for current renderable component (by default 'true'. Also depend on settings of BBConfig).
		 * If smoothing 'false', rendering is faster but quality could suffer.
		 */
		public var smoothing:Boolean = true;

		//
		private var _worldBounds:Rectangle = null;

		/**
		 */
		public function BBRenderable()
		{
			super();
			onAdded.add(onAddedToNodeHandler);
		}

		/**
		 */
		public function onAddedToNodeHandler(p_signal:BBSignal):void
		{
			mousePixelEnabled = BabyBox.get().config.mousePixelEnable;
			isCulling = BabyBox.get().config.isCulling;
			smoothing = BabyBox.get().config.smoothingDraw;
		}

		/**
		 */
		override public function set active(p_val:Boolean):void
		{
			if (active == p_val) return;
			super.active = p_val;

			if (node) node.visible = !node.visible;
		}

		/**
		 * Returns current texture.
		 */
		public function getTexture():BBTexture
		{
			return z_texture;
		}

		/**
		 */
		public function get isTextureExist():Boolean
		{
			return z_texture != null;
		}

		/**
		 * Render current component.
		 * Here is possible to implement own logic of rendering.
		 */
		public function render(p_context:BBContext):void
		{
			if (z_texture)
			{
				var transform:BBTransform = node.transform;
				p_context.draw(z_texture, transform.worldX, transform.worldY, (allowSelfRotation ? transform.worldRotation : 0), transform.worldScaleX,
				               transform.worldScaleY, offsetX, offsetY, offsetRotation, offsetScaleX, offsetScaleY, transform.worldAlpha, transform.worldRed,
				               transform.worldGreen, transform.worldBlue, isCulling, smoothing, allowRotation, allowScale, blendMode);
			}
		}

		//
		private var _a:Number = 0;
		private var _b:Number = 0;
		private var _c:Number = 0;
		private var _d:Number = 0;
		private var _tx:Number = 0;
		private var _ty:Number = 0;

		/**
		 * Returns bounds of renderable component in world coordinates.
		 * It is not creates new instance, so if need own instance need to make 'clone' - rectangle.clone();
		 */
		public function getWorldBounds():Rectangle
		{
			if (!_worldBounds) _worldBounds = BBNativePool.getRect();

			if (node || z_texture)
			{
				var transform:BBTransform = node.transform;
				var transMatrix:Matrix;
				var newOffsetsChecksum:Number = offsetScaleX + offsetScaleY + offsetRotation + offsetX + offsetY;

				if (_offsetsChecksum == newOffsetsChecksum) transMatrix = transform.worldTransformMatrix;
				else
				{
					transMatrix = transform.getTransformedWorldMatrix(offsetScaleX, offsetScaleY, offsetRotation, offsetX, offsetY);
					_offsetsChecksum = newOffsetsChecksum;
				}

				var a:Number = transMatrix.a;
				var b:Number = transMatrix.b;
				var c:Number = transMatrix.c;
				var d:Number = transMatrix.d;
				var tx:Number = transMatrix.tx;
				var ty:Number = transMatrix.ty;

				if (!(a == _a && b == _b && c == _c && d == _d && tx == _tx && ty == _ty))
				{
					_a = a;
					_b = b;
					_c = c;
					_d = d;
					_tx = tx;
					_ty = ty;

					var halfWidth:Number = z_texture.width * 0.5;
					var halfHeight:Number = z_texture.height * 0.5;
					var left:Number;
					var top:Number;
					var right:Number;
					var bottom:Number;
					var nX:Number;
					var nY:Number;
					var vx:Number;
					var vy:Number;

					// left top
					vx = -halfWidth;
					vy = -halfHeight;
					nX = vx * a + vy * b + tx;
					nY = vx * c + vy * d + ty;
					left = right = nX;
					top = bottom = nY;

					// right top
					vx = halfWidth;
					vy = -halfHeight;
					nX = vx * a + vy * b + tx;
					nY = vx * c + vy * d + ty;

					if (nX < left) left = nX;
					else if (nX > right) right = nX;

					if (nY < top) top = nY;
					else if (nY > bottom) bottom = nY;

					// right bottom
					vx = halfWidth;
					vy = halfHeight;
					nX = vx * a + vy * b + tx;
					nY = vx * c + vy * d + ty;

					if (nX < left) left = nX;
					else if (nX > right) right = nX;

					if (nY < top) top = nY;
					else if (nY > bottom) bottom = nY;

					// left bottom
					vx = -halfWidth;
					vy = halfHeight;
					nX = vx * a + vy * b + tx;
					nY = vx * c + vy * d + ty;

					if (nX < left) left = nX;
					else if (nX > right) right = nX;

					if (nY < top) top = nY;
					else if (nY > bottom) bottom = nY;

					//
					_worldBounds.x = left;
					_worldBounds.y = top;
					_worldBounds.width = right - left;
					_worldBounds.height = bottom - top;
				}
			}
			else _worldBounds.setEmpty();

			return _worldBounds;
		}

		/**
		 */
		bb_private function processMouseEvent(p_captured:Boolean, p_event:BBMouseEvent):Boolean
		{
			var captureResult:Boolean = false;
			var currentNode:BBNode = node;
			p_event.dispatcher = currentNode;

			if (p_captured && p_event.type == BBMouseEvent.UP) currentNode.mouseDown = null;
			if (p_captured || z_texture == null)
			{
				if (currentNode.mouseOver == currentNode)
				{
					currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);

					// if need stop propagation
					p_event.propagation = !p_event.stopPropagationAfterHandling;
				}
			}
			else
			{
				var matrix:Matrix = currentNode.transform.getTransformedWorldMatrix(offsetScaleX, offsetScaleY, offsetRotation, offsetX, offsetY, true);
				var camX:Number = p_event.cameraX;
				var camY:Number = p_event.cameraY;
				var localMouseX:Number = camX * matrix.a + camY * matrix.c + matrix.tx;
				var localMouseY:Number = camX * matrix.b + camY * matrix.d + matrix.ty;
				var texPivotX:Number = z_texture.pivotX;
				var texPivotY:Number = z_texture.pivotY;

				BBNativePool.putMatrix(matrix);

				p_event.localX = localMouseX + texPivotX;
				p_event.localY = localMouseY + texPivotY;

				//
				if (localMouseX >= texPivotX && localMouseX <= texPivotX + z_texture.width &&
						localMouseY >= texPivotY && localMouseY <= texPivotY + z_texture.height)
				{
					if (mousePixelEnabled && z_texture.getAlphaAt(localMouseX - texPivotX, localMouseY - texPivotY) == 0)
					{
						if (currentNode.mouseOver == currentNode) currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);
					}
					else
					{
						currentNode.handleMouseEvent(p_event, p_event.type);

						if (currentNode && currentNode.mouseOver != currentNode)
						{
							currentNode.handleMouseEvent(p_event, BBMouseEvent.OVER);
						}

						// if need stop propagation
						p_event.propagation = !p_event.stopPropagationAfterHandling;

						captureResult = true;
					}
				}
				else if (currentNode.mouseOver == currentNode)
				{
					currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);

					// if need stop propagation
					p_event.propagation = !p_event.stopPropagationAfterHandling;
				}
			}

			return captureResult;
		}

		/**
		 * Sets 'width' for renderable component (changes appropriate scale params).
		 * Doesn't takes into account rotation.
		 * For more detailed info use getWorldBounds method.
		 */
		public function set width(p_val:Number):void
		{
			if (z_texture && p_val > 1) offsetScaleX = p_val / z_texture.width;
		}

		/**
		 */
		public function get width():Number
		{
			return z_texture ? z_texture.width * offsetScaleX : 0;
		}

		/**
		 * Sets 'height' for renderable component (changes appropriate scale params).
		 * Doesn't takes into account rotation.
		 * For more detailed info use getWorldBounds method.
		 */
		public function set height(p_val:Number):void
		{
			if (z_texture && p_val > 1) offsetScaleY = p_val / z_texture.height;
		}

		/**
		 */
		public function get height():Number
		{
			return z_texture ? z_texture.height * offsetScaleY : 0;
		}

		/**
		 */
		override public function dispose():void
		{
			z_texture = null;

			if (_worldBounds)
			{
				BBNativePool.putRect(_worldBounds);
				_worldBounds = null;
			}

			allowSelfRotation = true;
			allowRotation = true;
			blendMode = null;
			mousePixelEnabled = false;
			isCulling = false;
			offsetScaleX = 1.0;
			offsetScaleY = 1.0;
			offsetX = 0.0;
			offsetY = 0.0;
			offsetRotation = 0.0;

			super.dispose();
		}

		/**
		 */
		override public function toString():String
		{
			var output:String = super.toString();
			output += "{allowSelfRotation: " + allowSelfRotation + "}-{allowSelfRotation: " + allowSelfRotation + "}-{smoothing: " + smoothing + "}-" +
					"{mousePixelEnabled: " + mousePixelEnabled + "}-{isCulling: " + isCulling + "}-{blendMode: " + blendMode + "}-" +
					"{scaleX: " + offsetScaleX + "}-{scaleY: " + offsetScaleY + "}-" +
					"{offsetX: " + offsetX + "}-{offsetY: " + offsetY + "}-{offsetRotation: " + offsetRotation + "}\n";

			return output;
		}

		/**
		 */
		override public function copy():BBComponent
		{
			var renderable:BBRenderable = super.copy() as BBRenderable;
			renderable.allowSelfRotation = allowSelfRotation;
			renderable.allowRotation = allowRotation;
			renderable.smoothing = smoothing;
			renderable.blendMode = blendMode;
			renderable.isCulling = isCulling;
			renderable.offsetScaleX = offsetScaleX;
			renderable.offsetScaleY = offsetScaleY;
			renderable.offsetX = offsetX;
			renderable.offsetY = offsetY;
			renderable.offsetRotation = offsetRotation;

			return renderable;
		}

		/**
		 */
		override public function getPrototype():XML
		{
			var renderableXML:XML = super.getPrototype();
			if (z_texture) addPrototypeProperty("asset", z_texture.id, "string");

			return renderableXML;
		}
	}
}
