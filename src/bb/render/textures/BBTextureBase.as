/**
 * User: VirtualMaestro
 * Date: 24.04.13
 * Time: 13:27
 */
package bb.render.textures
{
	import flash.display.BitmapData;

	import vm.math.unique.UniqueId;
	import vm.str.StringUtil;

	/**
	 * Base class for texture/atlas.
	 */
	public class BBTextureBase
	{
		//
		private var _id:String = "";

		/**
		 */
		public function BBTextureBase(p_id:String = "")
		{
			_id = StringUtil.trim(p_id);
			if (_id == "")
			{
				if (isTexture) _id = BBTexture.getTextureId();
				else _id = BBTextureAtlas.getAtlasId();
			}
		}

		/**
		 * Returns id of texture/atlas.
		 */
		public function get id():String
		{
			return _id;
		}

		/**
		 * Returns bitmap data of texture/atlas.
		 */
		public function get bitmapData():BitmapData
		{
			return null; // NEED OVERRIDE
		}

		/**
		 * If returns 'true' mean that this is instance of BBTexture class, else BBTextureAtlas.
		 */
		public function get isTexture():Boolean
		{
			return (this is BBTexture);  // NEED OVERRIDE
		}

		/**
		 * Cast to BBTexture.
		 */
		public function castTexture():BBTexture
		{
			return (this as BBTexture);
		}

		/**
		 * Cast to BBTextureAtlas.
		 */
		public function castTextureAtlas():BBTextureAtlas
		{
			return (this as BBTextureAtlas);
		}

		/**
		 * Determines if current texture/atlas is disposed.
		 */
		public function get isDisposed():Boolean
		{
			return false;   // NEED OVERRIDE
		}

		/**
		 * Dispose current resource (texture/atlas).
		 */
		public function dispose():void
		{
			// NEED OVERRIDE
		}

		/**
		 * Generate id for texture base children.
		 */
		static public function getId():String
		{
			return UniqueId.getUniqueName("textureBase");
		}
	}
}
