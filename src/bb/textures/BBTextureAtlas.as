/**
 * User: VirtualMaestro
 * Date: 03.02.13
 * Time: 1:20
 */
package bb.textures
{
	import bb.bb_spaces.bb_private;
	import bb.core.BabyBox;

	import com.genome2d.textures.GTexture;
	import com.genome2d.textures.GTextureAtlas;
	import com.genome2d.textures.factories.GTextureAtlasFactory;

	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import vm.math.unique.UniqueId;
	import vm.str.StringUtil;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Represents texture atlas. Contains data for rendering. Data stored as sprite sheet.
	 */
	public class BBTextureAtlas extends BBTextureBase
	{
		private var gTextureAtlas:GTextureAtlas = null;
		private var _atlasBitmap:BitmapData = null;
		private var _textures:Array = null;

		private var _textureIds:Array = null;
		private var _animations:Array = null;

		/**
		 */
		public function BBTextureAtlas(p_id:String = "", p_atlasBitmap:BitmapData = null)
		{
			super(p_id);

			_atlasBitmap = p_atlasBitmap;
			_textures = [];
			_textureIds = [];

			//
			addToGlobalStorage(this);
		}

		/**
		 * Adds new texture to atlas.
		 * p_id - id for given texture which will use in scope this texture atlas by getTexture method. Original texture id won't changed.
		 * If p_id is not set uses original texture id.
		 * If p_assignParent is true parent for this texture becomes this atlas. This mean if calls method removeSubTextureById, this texture completely removes.
		 */
		public function addTexture(p_texture:BBTexture, p_id:String = "", p_assignParent:Boolean = false):void
		{
			if (p_assignParent) p_texture.parent = this;

			var textureId:String = StringUtil.trim(p_id);
			textureId = textureId == "" ? p_texture.id : textureId;
			addTextureInternal(textureId, p_texture);
		}

		/**
		 * Adds new texture from current bitmap of texture atlas.
		 */
		public function addSubTexture(p_region:Rectangle, p_id:String = "", alignByCenter:Boolean = true):BBTexture
		{
			CONFIG::debug
			{
				Assert.isTrue((_atlasBitmap != null), "You can't to add sub-texture due to atlas bitmap is absent", "BBTextureAtlas.addSubTexture");
			}

			p_id = StringUtil.trim(p_id);
			var textureId:String = (p_id == "") ? BBTexture.getTextureId() : p_id;
			textureId = id + "_" + textureId;

			var texture:BBTexture = new BBTexture(_atlasBitmap, textureId, alignByCenter, p_region);
			texture.parent = this;
			return addTextureInternal(p_id, texture);
		}

		/**
		 */
		private function addSubTextureGPU(p_id:String, p_gTexture:GTexture):BBTexture
		{
			return addTextureInternal(p_id, new BBTexture(null, id + "_" + p_id, false, null, p_gTexture));
		}

		/**
		 */
		private function addTextureInternal(p_textureId:String, p_texture:BBTexture):BBTexture
		{
			CONFIG::debug
			{
				isTextureIdAlreadyInUse(p_textureId);
			}

			_textureIds[_textureIds.length] = p_textureId;
			_textures[p_textureId] = p_texture;
			return p_texture;
		}

		/**
		 * Returns texture by its id.
		 */
		public function getTexture(p_id:String):BBTexture
		{
			CONFIG::debug
			{
				Assert.isTrue(!isDisposed, "Current texture atlas is disposed. You can't use disposed atlas", "BBTextureAtlas.getTexture");
			}

			return _textures[p_id];
		}

		/**
		 * Returns bitmap data of atlas, of course if it exist at all, if not returns null.
		 */
		override public function get bitmapData():BitmapData
		{
			return _atlasBitmap
		}

		/**
		 * Returns assoc array with all sub-textures of atlas.
		 */
		bb_private function get textures():Array
		{
			return _textures;
		}

		/**
		 * Removes texture from atlas.
		 * If parent of texture is this atlas then texture removes completely, so it is impossible use it from atlas and outside of it.
		 * In other way texture just unlink from this atlas.
		 */
		public function removeSubTextureById(p_textureId:String):void
		{
			var texture:BBTexture = _textures[p_textureId];
			if (texture)
			{
				if (gTextureAtlas) gTextureAtlas.removeSubTexture(p_textureId);
				if (texture.parent == this) texture.dispose();

				_textures[p_textureId] = null;
				_textureIds.splice(_textureIds.indexOf(p_textureId), 1);
			}
		}

		/**
		 * Removes all sub-textures.
		 */
		public function removeAllSubTextures():void
		{
			for (var i:int = _textureIds.length - 1; i >= 0; i--)
			{
				removeSubTextureById(_textureIds[i]);
			}
		}

		/**
		 * Unlink texture from atlas. Texture still could be used.
		 */
		bb_private function unlinkTexture(textureId:String):void
		{
			_textures[textureId] = null;
		}

		/**
		 * Returns count of sub-textures.
		 */
		public function get subTexturesCount():int
		{
			return _textureIds.length;
		}

		/**
		 * Returns array of sub-textures ids which in this atlas.
		 */
		public function getSubTextureIds():Array
		{
			return _textureIds;
		}

		/**
		 * Creates assoc array where key is animation name and value is array with ids of textures which included to that animation.
		 * Parse of animation is possible only if frames on timeline have labels.
		 */
		private function parseAnimations():void
		{
			_animations = [];

			var len:int = _textureIds.length;
			var prevLabel:String = "";
			var currLabel:String = "";
			var textureId:String = "";

			for (var i:int = 0; i < len; i++)
			{
				textureId = _textureIds[i];
				currLabel = (_textures[textureId] as BBTexture).label;

				if (currLabel && currLabel != "" && currLabel != prevLabel)
				{
					_animations[currLabel] = [textureId];
					prevLabel = currLabel;
				}
				else _animations[prevLabel].push(textureId);
			}
		}

		/**
		 * If returns 'false' mean that this is instance of BBTextureAtlas class, else BBTexture.
		 */
		override public function get isTexture():Boolean
		{
			return false;
		}

		/**
		 * Determines if texture atlas was disposed.
		 */
		override public function get isDisposed():Boolean
		{
			return _textures == null;
		}

		/**
		 * Returns assoc. array where key is animation name and value is array with names of textures which included to animation.
		 * Of course it is happens if animations exist at all.
		 */
		public function getAnimationFrames(p_animationName:String):Array
		{
			return _animations[p_animationName];
		}

		/**
		 * Disposes texture atlas.
		 */
		override public function dispose():void
		{
			textureAtlasesGlobalStorage[id] = null;

			//
			removeAllSubTextures();
			_textures = null;
			_textureIds = null;

			//
			if (_atlasBitmap) _atlasBitmap.dispose();
			_atlasBitmap = null;
			if (gTextureAtlas) gTextureAtlas.dispose();
			gTextureAtlas = null;
		}

		CONFIG::debug
		private function isTextureIdAlreadyInUse(p_textureId:String):void
		{
			var texture:BBTexture = _textures[p_textureId];
			var inUse:Boolean = (texture == null) || texture.isDisposed;
			Assert.isTrue(inUse, "Texture with id '" + p_textureId + "' already in use by this atlas", "BBTextureAtlas.addTexture");
		}

		/////

		/**
		 * Global storage for all created atlases.
		 */
		static private var textureAtlasesGlobalStorage:Array = [];

		/**
		 * Adds new created texture atlas to global storage.
		 */
		static private function addToGlobalStorage(p_textureAtlas:BBTextureAtlas):void
		{
			var textureAtlas:BBTextureAtlas = getTextureAtlasById(p_textureAtlas.id);
			if (textureAtlas != null) throw new Error("You try to create texture atlas with id already in used. Texture atlas id '" + p_textureAtlas.id + "'. BBTextureAtlas.addToGlobalStorage");

			textureAtlasesGlobalStorage[p_textureAtlas.id] = p_textureAtlas;
		}

		/**
		 * Returns texture by its id.
		 */
		static public function getTextureAtlasById(p_textureAtlasId:String):BBTextureAtlas
		{
			var textureAtlas:BBTextureAtlas = (p_textureAtlasId == "") ? null : textureAtlasesGlobalStorage[p_textureAtlasId];
			if (textureAtlas && textureAtlas.isDisposed) textureAtlas = null;
			return textureAtlas;
		}

		// Utils

		/**
		 *
		 */
		public static function createFromBitmapDataAndXML(p_bitmapData:BitmapData, p_xml:XML, p_atlasId:String = ""):BBTextureAtlas
		{
			var textureAtlas:BBTextureAtlas = new BBTextureAtlas(p_atlasId, p_bitmapData);
			var i:int = 0;
			var element:XML;
			var region:Rectangle;
			var children:XMLList = p_xml.children();
			var len:int = children.length();

			if (BabyBox.isStage3d)
			{
				textureAtlas.gTextureAtlas = GTextureAtlasFactory.createFromBitmapDataAndXML(textureAtlas.id, p_bitmapData, p_xml);

				while (i < len)
				{
					element = children[i];
					textureAtlas.addSubTextureGPU(element.@name, textureAtlas.gTextureAtlas.getTexture(element.@name));
					i++
				}
			}
			else
			{
				while (i < len)
				{
					element = children[i];
					region = new Rectangle(element.@x, element.@y, element.@width, element.@height);
					textureAtlas.addSubTexture(region, element.@name);
					i++
				}
			}

			return textureAtlas;
		}

		/**
		 * Makes atlas from given movie clip.
		 * Method converts vector clips to raster.
		 */
		static public function createFromMovieClip(p_movieClip:MovieClip, p_atlasId:String = ""):BBTextureAtlas
		{
			var resultTextureAtlas:BBTextureAtlas = new BBTextureAtlas(p_atlasId);
			var totalFrames:int = p_movieClip.totalFrames;
			var texture:BBTexture;
			var label:String;
			var isAnimationExist:Boolean = false;

			for (var i:int = 1; i <= totalFrames; i++)
			{
				p_movieClip.gotoAndStop(i);
				texture = BBTexture.createFromVector(p_movieClip);
				resultTextureAtlas.addTexture(texture, "", true);

				// get frame label
				label = p_movieClip.currentFrameLabel;
				if (label)
				{
					texture.label = label;
					isAnimationExist = true;
				}

				// make next frame for every nested movie clips
				childNextFrame(p_movieClip);
			}

			// if animation labels exist try to parse animations
			if (isAnimationExist) resultTextureAtlas.parseAnimations();

			return resultTextureAtlas;
		}

		/**
		 */
		static private function childNextFrame(p_child:MovieClip):void
		{
			var numChildren:int = p_child.numChildren;
			var child:MovieClip;

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_child.getChildAt(i) as MovieClip;
				if (child)
				{
					childNextFrame(child);
					child.nextFrame();
				}
			}
		}

		/**
		 * Returns generated unique atlas name.
		 */
		static public function getAtlasId():String
		{
			return UniqueId.getUniqueName("atlas");
		}
	}
}
