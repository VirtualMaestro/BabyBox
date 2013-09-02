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
		 * Disallow rotating of renderable components. Could be useful with physical component.
		 * If 'false' ignores any self rotation.
		 */
		public var allowRotation:Boolean = true;

		public var scaleX:Number = 1.0;
		public var scaleY:Number = 1.0;

		public var offsetX:Number = 0.0;
		public var offsetY:Number = 0.0;
		public var offsetRotation:Number = 0.0;

		//
		private var _worldBounds:Rectangle = null;

		/**
		 */
		public function BBRenderable()
		{
			super();

			mousePixelEnabled = BabyBox.get().config.mousePixelEnable;
		}

		/**
		 */
		override public function set active(p_val:Boolean):void
		{
			if (_active == p_val) return;
			super.active = p_val;

			if (node) node.visible = node.visible;
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
			if (z_texture) p_context.renderComponent(this);
		}

		/**
		 * Returns bounds of renderable component in world coordinates.
		 */
		public function getWorldBounds():Rectangle
		{
			if (!_worldBounds) _worldBounds = BBNativePool.getRect();

			if (!node || !z_texture) _worldBounds.setEmpty();
			else
			{
				var halfWidth:Number = z_texture.width * 0.5;
				var halfHeight:Number = z_texture.height * 0.5;
				var transform:BBTransform = node.transform;
				var transMatrix:Matrix = transform.transformWorldMatrix(scaleX, scaleY, offsetRotation, offsetX, offsetY);
				var a:Number = transMatrix.a;
				var b:Number = transMatrix.b;
				var c:Number = transMatrix.c;
				var d:Number = transMatrix.d;
				var tx:Number = transMatrix.tx;
				var ty:Number = transMatrix.ty;
				BBNativePool.putMatrix(transMatrix);

				var leftX:Number = -halfWidth * a + -halfHeight * c + tx;
				var topY:Number = -halfWidth * b + -halfHeight * d + ty;
				var rightX:Number = leftX;
				var bottomY:Number = topY;
				var nX:Number;
				var nY:Number;

				var vertices:Vector.<Number> = new <Number>[
					-halfWidth * a + halfHeight * c + tx, -halfWidth * b + halfHeight * d + ty,
					halfWidth * a + halfHeight * c + tx, halfWidth * b + halfHeight * d + ty,
					halfWidth * a + -halfHeight * c + tx, halfWidth * b + -halfHeight * d + ty
				];

				for (var i:int = 0; i < 6; i += 2)
				{
					nX = vertices[i];
					nY = vertices[i + 1];

					if (leftX > nX) leftX = nX;
					else if (rightX < nX) rightX = nX;

					if (topY > nY) topY = nY;
					else if (bottomY < nY) bottomY = nY;
				}

				_worldBounds.setTo(leftX, topY, rightX - leftX, bottomY - topY);
			}

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
				var matrix:Matrix = currentNode.transform.transformWorldMatrix(scaleX, scaleY, offsetRotation, offsetX, offsetY, true);
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
			if (z_texture && p_val > 1) scaleX = p_val / z_texture.width;
		}

		/**
		 */
		public function get width():Number
		{
			return z_texture ? z_texture.width * scaleX : 0;
		}

		/**
		 * Sets 'height' for renderable component (changes appropriate scale params).
		 * Doesn't takes into account rotation.
		 * For more detailed info use getWorldBounds method.
		 */
		public function set height(p_val:Number):void
		{
			if (z_texture && p_val > 1) scaleY = p_val / z_texture.height;
		}

		/**
		 */
		public function get height():Number
		{
			return z_texture ? z_texture.height * scaleY : 0;
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

			allowRotation = true;
			scaleX = 1.0;
			scaleY = 1.0;
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
			output += "{allowRotation: " + allowRotation + "}-{scaleX: " + scaleX + "}-{scaleY: " + scaleY + "}-{offsetX: " + offsetX + "}-{offsetY: " + offsetY + "}-{offsetRotation: " + offsetRotation + "}\n";

			return output;
		}

		/**
		 */
		override public function copy():BBComponent
		{
			var renderable:BBRenderable = super.copy() as BBRenderable;
			renderable.allowRotation = allowRotation;
			renderable.scaleX = scaleX;
			renderable.scaleY = scaleY;
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
