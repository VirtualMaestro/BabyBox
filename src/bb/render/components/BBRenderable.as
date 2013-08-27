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
	import flash.geom.Point;
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
			if (!_worldBounds) _worldBounds = new Rectangle();

			if (!node || !z_texture) _worldBounds.setEmpty();
			else
			{
				var transform:BBTransform = node.transform;
				var transMatrix:Matrix = transform.transformWorldMatrix(scaleX, scaleY, offsetRotation, offsetX, offsetY);
				var halfWidth:Number = z_texture.width * 0.5;
				var halfHeight:Number = z_texture.height * 0.5;

				var topLeft:Point = transMatrix.transformPoint(BBNativePool.getPoint(-halfWidth, -halfHeight));
				var bottomLeft:Point = transMatrix.transformPoint(BBNativePool.getPoint(-halfWidth, halfHeight));
				var bottomRight:Point = transMatrix.transformPoint(BBNativePool.getPoint(halfWidth, halfHeight));
				var topRight:Point = transMatrix.transformPoint(BBNativePool.getPoint(halfWidth, -halfHeight));

				var leftX:Number = topLeft.x;
				var topY:Number = topLeft.y;
				var rightX:Number = leftX;
				var bottomY:Number = topY;
				var nX:Number;
				var nY:Number;

				var vertices:Vector.<Number> = new <Number>[
					bottomLeft.x, bottomLeft.y,
					bottomRight.x, bottomRight.y,
					topRight.x, topRight.y
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

				// disposing
				BBNativePool.putPoint(topLeft);
				BBNativePool.putPoint(bottomLeft);
				BBNativePool.putPoint(bottomRight);
				BBNativePool.putPoint(topRight);
			}

			return _worldBounds;
		}

		/**
		 */
		bb_private function processMouseEvent(p_captured:Boolean, p_event:BBMouseEvent):Boolean
		{
			var currentNode:BBNode = node;
			p_event.dispatcher = currentNode;

			if (p_captured && p_event.type == BBMouseEvent.UP) currentNode.mouseDown = null;
			if (p_captured || z_texture == null)
			{
				if (currentNode.mouseOver == currentNode) currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);
				return false;
			}

			var cameraPoint:Point = BBNativePool.getPoint(p_event.cameraX, p_event.cameraY);
			var localMousePosition:Point = currentNode.transform.worldToLocal(cameraPoint);
			var localMouseX:Number = localMousePosition.x;
			var localMouseY:Number = localMousePosition.y;
			var texPivotX:Number = z_texture.pivotX;
			var texPivotY:Number = z_texture.pivotY;

			BBNativePool.putPoint(cameraPoint);

			p_event.localX = localMouseX + texPivotX;
			p_event.localY = localMouseY + texPivotY;

			var texPivotXScaled:Number = texPivotX * scaleX;
			var texPivotYScaled:Number = texPivotY * scaleY;

			//
			if (localMouseX >= texPivotXScaled && localMouseX <= texPivotXScaled + z_texture.width * scaleX &&
					localMouseY >= texPivotYScaled && localMouseY <= texPivotYScaled + z_texture.height * scaleY)
			{
				if (mousePixelEnabled && z_texture.getAlphaAt(localMouseX - texPivotX, localMouseY - texPivotY) == 0)
				{
					if (currentNode.mouseOver == currentNode) currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);
					return false;
				}

				// **************
				currentNode.handleMouseEvent(p_event, p_event.type);
				// ***************

				//
				if (currentNode && currentNode.mouseOver != currentNode) currentNode.handleMouseEvent(p_event, BBMouseEvent.OVER);
				return true;
			}
			else if (currentNode.mouseOver == currentNode) currentNode.handleMouseEvent(p_event, BBMouseEvent.OUT);

			return false;
		}

		/**
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
			_worldBounds = null;
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
