/**
 * User: VirtualMaestro
 * Date: 03.02.13
 * Time: 14:31
 */
package src.bb.components.renderable
{
	import src.bb.bb_spaces.bb_private;
	import src.bb.components.BBComponent;
	import src.bb.core.BBNode;
	import src.bb.pools.BBComponentPool;
	import src.bb.textures.BBTexture;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Represents sprite.
	 */
	public class BBSprite extends BBRenderable
	{
		public function BBSprite()
		{
			super();
			_componentClass = BBSprite;
		}

		/**
		 * Sets new texture.
		 */
		public function setTexture(p_texture:BBTexture):void
		{
			z_texture = p_texture;
		}

		/**
		 */
		override public function updateFromPrototype(p_prototype:XML):void
		{
			CONFIG::debug
			{
				var className:String = p_prototype.@componentClass.split("-")[1];
				Assert.isTrue((className == "BBSprite"), "prototype isn't appropriate to BBSprite component", "BBSprite.updateFromPrototype");
			}

			super.updateFromPrototype(p_prototype);

			// unset properties
			var assetName:String = p_prototype.properties.elements("asset");
			var texture:BBTexture = BBTexture.getTextureById(assetName);
			setTexture(texture);
		}

		/**
		 * Makes copy of BBSprite.
		 */
		override public function copy():BBComponent
		{
			var sprite:BBSprite = super.copy() as BBSprite;
			sprite.setTexture(z_texture);
			return sprite;
		}

		/**
		 */
		override public function toString():String
		{
			var textureExist:Boolean = z_texture != null;
			return "------------------------------------------------------------------------------------------------------------------------\n" +
					"[BBSprite:\n" +
					super.toString()+ "\n" +
					"{texture exist: "+ textureExist + "}" + (textureExist ? "-{texture id: "+z_texture.id + "}" : "") + "]\n" +
					"------------------------------------------------------------------------------------------------------------------------";
		}

		///////////////////////
		////// FACTORIES //////
		///////////////////////

		/**
		 * Returns instance of BBSprite.
		 * @return BBSprite
		 */
		static public function get(p_texture:BBTexture = null):BBSprite
		{
			var sprite:BBSprite = BBComponentPool.get(BBSprite) as BBSprite;
			if (p_texture) sprite.setTexture(p_texture);
			return sprite;
		}

		/**
		 * Returns instance of BBSprite attached to BBNode.
		 * @return BBSprite with BBNode
		 */
		static public function getWithNode(p_nodeName:String = "", p_texture:BBTexture = null):BBSprite
		{
			var sprite:BBSprite = BBComponentPool.getWithNode(BBSprite, p_nodeName) as BBSprite;
			if (p_texture) sprite.setTexture(p_texture);
			return sprite;
		}

		/**
		 * Create sprite from prototype.
		 */
		static public function getFromPrototype(p_prototype:XML):BBSprite
		{
			var sprite:BBSprite = get();
			sprite.updateFromPrototype(p_prototype);
			return sprite;
		}

		/**
		 * Create sprite from prototype attached to node.
		 */
		static public function getFromPrototypeWithNode(p_prototype:XML, p_nodeName:String = ""):BBSprite
		{
			var sprite:BBSprite = getFromPrototype(p_prototype);
			BBNode.get(p_nodeName).addComponent(sprite);
			return sprite;
		}
	}
}
