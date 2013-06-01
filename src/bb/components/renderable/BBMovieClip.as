/**
 * User: VirtualMaestro
 * Date: 20.02.13
 * Time: 20:55
 */
package bb.components.renderable
{
	import bb.bb_spaces.bb_private;
	import bb.components.BBComponent;
	import bb.core.BBNode;
	import bb.core.BabyBox;
	import bb.signals.BBSignal;
	import bb.textures.BBTextureAtlas;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private

	/**
	 * Represents animation. Like native MovieClip just converted to raster.
	 */
	public class BBMovieClip extends BBRenderable
	{
		//
		private var _onAnimationEnd:BBSignal;

		/**
		 * Determines if animation continue playing after it reach the end.
		 */
		public var repeatable:Boolean = true;

		/**
		 * Independent on delta time all frames will be played in correct sequence.
		 */
		public var keepSequence:Boolean = true;

		//
		private var _textureAtlas:BBTextureAtlas;
		private var _currentFrame:int = 0;

		private var _speed:Number;
		private var _accumulatedTime:Number = 0;

		private var _allTextures:Array;
		private var _allFrameIds:Array;
		private var _frameIds:Array;
		private var _framesCount:int = 0;

		/**
		 */
		public function BBMovieClip()
		{
			super();
			updateEnable = false;
			_componentClass = BBMovieClip;

			_speed = 1000.0 / BabyBox.getInstance().config.animationFrameRate;
		}

		/**
		 * Sets texture atlas to movie clip.
		 */
		public function setTextureAtlas(p_textureAtlas:BBTextureAtlas):void
		{
			if (p_textureAtlas)
			{
				_textureAtlas = p_textureAtlas;
				_allTextures = _textureAtlas.textures;
				_allFrameIds = [];

				var texturesIds:Array = _textureAtlas.getSubTextureIds();
				var textureId:String;
				var len:int = texturesIds.length;

				for (var i:int = 0; i < len; i++)
				{
					textureId = texturesIds[i];
					_allFrameIds[i] = textureId;
				}

				_frameIds = _allFrameIds;
				_framesCount = _frameIds.length;
				_currentFrame = 0;

				gotoAndStop(_currentFrame);
			}
			else
			{
				stop();
				_textureAtlas = null;
				_allTextures = null;
				_allFrameIds = null;
			}
		}

		/**
		 * Sets frames which will play in animation.
		 * p_frames - array with index of frames which should be set as animation of MovieClip.
		 */
		public function setFrames(p_frames:Array):void
		{
			_frameIds = p_frames;
			_framesCount = p_frames.length;
			_currentFrame = 0;

			gotoAndStop(_currentFrame);
		}

		/**
		 * Sets speed of playing of animation.
		 */
		public function get frameRate():int
		{
			if (_speed == 0) return 0;
			return Math.round(1000 / _speed);
		}

		/**
		 * Set frame rate at which this clip should play
		 */
		public function set frameRate(p_frameRate:int):void
		{
			if (p_frameRate < 1) _speed = 0;
			else _speed = 1000.0 / p_frameRate;
		}

		/**
		 */
		public function play():void
		{
			updateEnable = true;
		}

		/**
		 */
		public function stop():void
		{
			updateEnable = false;
		}

		/**
		 * Start playing from given frame index or frame label.
		 * Index like in original MovieClip begins from  1.
		 */
		public function gotoAndPlay(p_frame:Object):void
		{
			setCurrentFrame(p_frame);
			play();
		}

		/**
		 * Plays and stops at given frame index or frame label.
		 * Index like in original MovieClip begins from  1.
		 */
		public function gotoAndStop(p_frame:Object):void
		{
			setCurrentFrame(p_frame);
			stop();
		}

		//
		private var _isRender:Boolean = false;

		/**
		 */
		private function setCurrentFrame(p_frame:Object):void
		{
			if (_textureAtlas)
			{
				if (p_frame is String)
				{
					_frameIds = _textureAtlas.getAnimationFrames(p_frame as String);
					_framesCount = _frameIds.length;
					_currentFrame = 0;
				}
				else
				{
					_currentFrame = (p_frame as Number) - 1;

					if (_currentFrame < 0) _currentFrame = 0;
					else if (_currentFrame >= _framesCount) _currentFrame = _framesCount-1;
				}

				z_texture = _allTextures[_frameIds[_currentFrame]];
				_isRender = false;
			}
		}

		/**
		 * Determines if animation is playing now.
		 */
		public function get isPlaying():Boolean
		{
			return updateEnable;
		}

		/**
		 * Returns current frame index.
		 */
		public function get currentFrame():int
		{
			return _currentFrame + 1;
		}

		/**
		 * Gets total frames of current animation.
		 */
		public function get totalFrames():int
		{
			return _framesCount;
		}

		/**
		 */
		override public function set updateEnable(p_val:Boolean):void
		{
			if (_textureAtlas) super.updateEnable = p_val;
		}

		/**
		 */
		override public function update(p_deltaTime:Number):void
		{
			_accumulatedTime += p_deltaTime;

			if (_accumulatedTime >= _speed)
			{
				if (keepSequence)
				{
					if (_isRender) ++_currentFrame;
					_isRender = true;

					if (_currentFrame >= _framesCount)
					{
						if (repeatable) _currentFrame = 0;
						else
						{
							_currentFrame = _framesCount - 1;
							stop();
						}

						if (_onAnimationEnd) _onAnimationEnd.dispatch();
					}
				}
				else
				{
					_currentFrame += _accumulatedTime / _speed;

					if (_currentFrame < _framesCount) _currentFrame %= _framesCount;
					else
					{
						if (repeatable) _currentFrame %= _framesCount;
						else
						{
							_currentFrame = _framesCount - 1;
							stop();
						}

						if (_onAnimationEnd) _onAnimationEnd.dispatch();
					}
				}

				z_texture = _allTextures[_frameIds[_currentFrame]];
			}

			_accumulatedTime %= _speed;
		}

		/**
		 * Signal dispatches when animation reach to end.
		 */
		public function get onAnimationEnd():BBSignal
		{
			if (_onAnimationEnd == null) _onAnimationEnd = BBSignal.get(this);
			return _onAnimationEnd;
		}

		/**
		 */
		override public function dispose():void
		{
			if (_onAnimationEnd) _onAnimationEnd.dispose();
			_onAnimationEnd = null;

			_textureAtlas = null;
			_allFrameIds = null;
			_allFrameIds = null;
			_allTextures = null;

			super.dispose();
		}

		/**
		 * Makes copy of current component.
		 */
		override public function copy():BBComponent
		{
			var mc:BBMovieClip = super.copy() as BBMovieClip;
			mc.setTextureAtlas(_textureAtlas);
			mc.frameRate = frameRate;
			isPlaying ? mc.gotoAndPlay(currentFrame) : mc.gotoAndStop(currentFrame);
			mc.repeatable = repeatable;
			mc.keepSequence = keepSequence;

			return mc;
		}

		/**
		 */
		override public function toString():String
		{
			var textureAtlasExist:Boolean = _textureAtlas != null;
			return "------------------------------------------------------------------------------------------------------------------------\n" +
					"[BBMovieClip:\n" +
					super.toString()+ "\n" +
					"{texture atlas exist: "+ textureAtlasExist + (textureAtlasExist ? "}-{textureAtlas id: "+_textureAtlas.id : "") + "}" +
					(textureAtlasExist && z_texture ? "-{current texture id: "+z_texture.id + "}": "") + "-{frames: "+_framesCount+"}" + "\n" +
					"{speed: "+_speed+"}-{repeatable: "+repeatable+"}-{keepSequence: "+keepSequence+"}-{isPlaying: "+isPlaying+"}]\n" +
					"------------------------------------------------------------------------------------------------------------------------";
		}

		/**
		 */
		override public function getPrototype():XML
		{
			var renderableXML:XML = super.getPrototype();

			if (_textureAtlas)
			{
				renderableXML.asset = _textureAtlas.id;
				renderableXML.asset.@type = "string";
			}

			return renderableXML;
		}

		/**
		 */
		override public function updateFromPrototype(p_prototype:XML):void
		{
			CONFIG::debug
			{
				var className:String = p_prototype.@componentClass.split("-")[1];
				Assert.isTrue((className == "BBMovieClip"), "prototype isn't appropriate to BBMovieClip component", "BBMovieClip.getFromPrototype");
			}

			super.updateFromPrototype(p_prototype);

			// unset properties
			var assetName:String = p_prototype.properties.elements("asset");
			var atlas:BBTextureAtlas = BBTextureAtlas.getTextureAtlasById(assetName);
			setTextureAtlas(atlas);
		}

		///////////
		// UTILS //
		///////////

		static public function get(p_textureAtlas:BBTextureAtlas = null, p_frameRate:int = 30):BBMovieClip
		{
			var movieClip:BBMovieClip = BBComponent.get(BBMovieClip) as BBMovieClip;
			if (p_textureAtlas)
			{
				movieClip.setTextureAtlas(p_textureAtlas);
				movieClip.frameRate = p_frameRate;
			}

			return movieClip;
		}

		/**
		 *
		 */
		static public function getWithNode(p_textureAtlas:BBTextureAtlas = null, p_nodeName:String = "", p_frameRate:int = 30):BBMovieClip
		{
			var movieClip:BBMovieClip = BBComponent.getWithNode(BBMovieClip, p_nodeName) as BBMovieClip;

			if (p_textureAtlas)
			{
				movieClip.setTextureAtlas(p_textureAtlas);
				movieClip.frameRate = p_frameRate;
			}

			return movieClip;
		}

		/**
		 * Create movie clip from prototype.
		 */
		static public function getFromPrototype(p_prototype:XML):BBMovieClip
		{
			var movieClip:BBMovieClip = BBMovieClip.get();
			movieClip.updateFromPrototype(p_prototype);
			return movieClip;
		}

		/**
		 * Create movie clip from prototype attached to node.
		 */
		static public function getFromPrototypeWithNode(p_prototype:XML, p_nodeName:String = ""):BBMovieClip
		{
			var movieClip:BBMovieClip = getFromPrototype(p_prototype);
			BBNode.get(p_nodeName).addComponent(movieClip);
			return movieClip;
		}
	}
}
