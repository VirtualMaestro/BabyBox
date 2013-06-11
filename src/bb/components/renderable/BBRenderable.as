/**
 * User: VirtualMaestro
 * Date: 01.02.13
 * Time: 13:42
 */
package bb.components.renderable
{
	import bb.bb_spaces.bb_private;
	import bb.components.*;
	import bb.core.BabyBox;
	import bb.core.context.BBContext;
	import bb.events.BBMouseEvent;
	import bb.pools.BBNativePool;
	import bb.textures.BBTexture;

	import flash.geom.Point;

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

		//
//		private var _worldBounds:Rectangle = null;

		/**
		 */
		public function BBRenderable()
		{
			super();

			mousePixelEnabled = BabyBox.getInstance().config.mousePixelEnable;
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
		 * Render current component.
		 * Here is possible to implement own logic of rendering.
		 */
		public function render(p_context:BBContext):void
		{
			if (z_texture) p_context.renderComponent(this);
		}

		/**
		 * Returns bounds of renderable component in world coordinates.
		 * TODO: implement getWorldBounds
		 */
//		public function getWorldBounds():Rectangle
//		{
//			if (!_worldBounds) _worldBounds = new Rectangle();
//
//
//			node.transform.worldTransformMatrix.transformPoint();
//
//			return _worldBounds;
//		}

		/**
		 */
		bb_private function processMouseEvent(p_captured:Boolean, p_event:BBMouseEvent):Boolean
		{
			p_event.dispatcher = node;

			if (p_captured && p_event.type == BBMouseEvent.UP) node.mouseDown = null;
			if (p_captured || z_texture == null)
			{
				if (node.mouseOver == node) node.handleMouseEvent(p_event, BBMouseEvent.OUT);
				return false;
			}

			var cameraPoint:Point = BBNativePool.getPoint(p_event.cameraX, p_event.cameraY);
			var localMousePosition:Point = node.transform.worldToLocal(cameraPoint);
			var localMouseX:Number = localMousePosition.x;
			var localMouseY:Number = localMousePosition.y;
			var texPivotX:Number = z_texture.pivotX;
			var texPivotY:Number = z_texture.pivotY;

			BBNativePool.putPoint(cameraPoint);

			p_event.localX = localMouseX + texPivotX;
			p_event.localY = localMouseY + texPivotY;

			//
			if (localMouseX >= texPivotX && localMouseX <= texPivotX + z_texture.width &&
					localMouseY >= texPivotY && localMouseY <= texPivotY + z_texture.height)
			{
				if (mousePixelEnabled && z_texture.getAlphaAt(localMouseX - texPivotX, localMouseY - texPivotY) == 0)
				{
					if (node.mouseOver == node) node.handleMouseEvent(p_event, BBMouseEvent.OUT);
					return false;
				}

				// **************
				node.handleMouseEvent(p_event, p_event.type);
				// ***************

				//
				if (node.mouseOver != node) node.handleMouseEvent(p_event, BBMouseEvent.OVER);
				return true;
			}
			else if (node.mouseOver == node) node.handleMouseEvent(p_event, BBMouseEvent.OUT);

			return false;
		}

		/**
		 */
		override public function dispose():void
		{
			z_texture = null;
			super.dispose();
		}

		/**
		 */
		override public function toString():String
		{
			var output:String = super.toString();
			output += "{allowRotation: "+allowRotation+"}-{scaleX: "+scaleX+"}-{scaleY: "+scaleY+"}\n";

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

			return renderable;
		}

		/**
		 */
		override public function getPrototype():XML
		{
			var renderableXML:XML = super.getPrototype();
			if (z_texture) addPrototypeProperty("asset", z_texture.id, "string");

			// no need because public properties, they are automatically added to prototype
//			addPrototypeProperty("allowRotation", allowRotation, "boolean");
//			addPrototypeProperty("scaleX", scaleX, "number");
//			addPrototypeProperty("scaleY", scaleY, "number");

			return renderableXML;
		}
	}
}
