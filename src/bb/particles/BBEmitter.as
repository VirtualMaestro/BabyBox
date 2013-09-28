/**
 * User: VirtualMaestro
 * Date: 05.09.13
 * Time: 10:34
 */
package bb.particles
{
	import bb.bb_spaces.bb_private;
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.core.BBTransform;
	import bb.core.context.BBContext;
	import bb.render.components.BBRenderable;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;
	import bb.vo.BBColor;

	import vm.math.rand.RandUtil;

	use namespace bb_private;

	/**
	 * Emitter component of particle system.
	 */
	public class BBEmitter extends BBRenderable
	{
		/**
		 * Number of emission particles per second.
		 */
		public var emissionRate:uint = 100;

		/**
		 * Dampening of particle. 0 - absolute dampening, 1 - no dampening.
		 */
		public var dampening:Number = 1.0;

		/**
		 * If emitter moving very fast it is possible set this props to true, it makes creation particles more smoothly.
		 */
		public var fastMoving:Boolean = false;

		private var _widthField:uint = 1;
		private var _heightField:uint = 1;

		private var _speedFrom:uint = 0;
		private var _speedTo:uint = 0;

		private var _gravityX:Number = 0;
		private var _gravityY:Number = 0;
		private var _gravityRatioFrom:Number = 1.0;
		private var _gravityRatioTo:Number = 1.0;

		private var _angleFrom:Number = 0;
		private var _angleTo:Number = 0;

		private var _lifeTimeFrom:int = 100;
		private var _lifeTimeTo:int = 100;

		// scale setup
		private var _scale:Number = 1.0;
		private var _scaleSequence:Array = null;
		private var _scaleRatioFrom:Number = 1.0;
		private var _scaleRatioTo:Number = 1.0;

		// color setup
		private var _alpha:Number = 1.0;
		private var _red:Number = 1.0;
		private var _green:Number = 1.0;
		private var _blue:Number = 1.0;
		private var _colorSequence:Vector.<Number> = null;
		private var _colorRatioFrom:Number = 1.0;
		private var _colorRatioTo:Number = 1.0;

		//
		private var _head:BBParticle;
		private var _tail:BBParticle;

		private var _numParticles:uint = 0;

		private var _transform:BBTransform;

		// default particle texture settings
		private var _defParticleColor:uint = 0xffffffff;
		private var _defParticleRadius:uint = 20;

		private var _prevX:Number;
		private var _prevY:Number;
		private var _nextX:Number;
		private var _nextY:Number;

		/**
		 */
		public function BBEmitter()
		{
			super();

			onAdded.add(addedToNodeHandler);
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			isCulling = true;
			smoothing = false;
			allowRotation = false;

			node.onAdded.add(addedToStage);
		}

		/**
		 */
		private function addedToStage(p_signal:BBSignal):void
		{
			if (node.isOnStage)
			{
				_transform = node.transform;
				if (z_texture == null) z_texture = getDefaultTexture();

				_prevX = _transform.worldX;
				_prevY = _transform.worldY;

				updateEnable = true;
			}
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			_nextX = _transform.worldX;
			_nextY = _transform.worldY;

			var particle:BBParticle = _head;
			var currentParticle:BBParticle;
			while (particle)
			{
				currentParticle = particle;
				particle = particle.next;

				currentParticle.update(p_deltaTime);
			}

			var dt:Number = p_deltaTime / 1000.0;
			var numNewParticles:uint = Math.round(emissionRate * dt);
			createParticles(numNewParticles, dt);

			_prevX = _nextX;
			_prevY = _nextY;
		}

		/**
		 */
		override public function render(p_context:BBContext):void
		{
			var scaleX:Number = _transform.worldScaleX;
			var scaleY:Number = _transform.worldScaleY;
			var alpha:Number = _transform.worldAlpha;
			var red:Number = _transform.worldRed;
			var green:Number = _transform.worldGreen;
			var blue:Number = _transform.worldBlue;

			var particle:BBParticle = _head;
			while (particle)
			{
				p_context.draw(z_texture, particle.posX, particle.posY, 0, particle.scale * scaleX, particle.scale * scaleY, 0, 0, 0, 1.0, 1.0,
				               particle.alpha * alpha, particle.red * red, particle.green * green, particle.blue * blue,
				               isCulling, smoothing, allowRotation, blendMode);

				particle = particle.next;
			}
		}

		/**
		 */
		private function createParticles(p_numParticles:int, p_deltaTime:Number):void
		{
			var posX:Number = _transform.worldX;
			var posY:Number = _transform.worldY;
			var rot:Number = _transform.worldRotation;

			var randX:int = _widthField * 0.5;
			var randY:int = _heightField * 0.5;

			var rPosX:Number;
			var rPosY:Number;
			var rX:Number;
			var rY:Number;
			var cos:Number = _transform.COS;
			var sin:Number = _transform.SIN;
			var rDirX:Number;
			var rDirY:Number;
			var rSpeed:Number;
			var rLifeTime:int;
			var startLife:Number = 0;

			var particle:BBParticle;

			for (var i:int = 0; i < p_numParticles; i++)
			{
				particle = BBParticle.get(this);

				rX = RandUtil.getIntRange(-randX, randX);
				rY = RandUtil.getIntRange(-randY, randY);

				rPosX = rX * cos - sin * rY;
				rPosY = rX * sin + cos * rY;

				rDirX = Math.cos(rot + RandUtil.getFloatRange(_angleFrom, _angleTo));
				rDirY = Math.sin(rot + RandUtil.getFloatRange(_angleFrom, _angleTo));

				rSpeed = RandUtil.getIntRange(_speedFrom, _speedTo);
				rLifeTime = RandUtil.getIntRange(_lifeTimeFrom, _lifeTimeTo);

				if (fastMoving)
				{
					var t:Number = i / Number(p_numParticles);
					var elapsedTime:Number = (1.0 - t) * p_deltaTime;

					rPosX += (_prevX + (_nextX - _prevX) * t) + (rDirX * rSpeed * elapsedTime);
					rPosY += (_prevY + (_nextY - _prevY) * t) + (rDirY * rSpeed * elapsedTime);

					particle.posX = rPosX;
					particle.posY = rPosY;

					startLife = 1 - (rLifeTime - elapsedTime * 1000.0) / rLifeTime;
				}
				else
				{
					particle.posX = rPosX + posX;
					particle.posY = rPosY + posY;
				}

				particle.dirX = rDirX;
				particle.dirY = rDirY;

				particle.speed = rSpeed;
				particle.lifeTime(rLifeTime, startLife);

				particle.gravityX = _gravityX * RandUtil.getFloatRange(_gravityRatioFrom, _gravityRatioTo);
				particle.gravityY = _gravityY * RandUtil.getFloatRange(_gravityRatioFrom, _gravityRatioTo);

				particle.dampening = dampening;

				particle.scaleSetup(_scale, _scaleSequence, RandUtil.getFloatRange(_scaleRatioFrom, _scaleRatioTo));
				particle.colorSetup(_alpha, _red, _green, _blue, _colorSequence, RandUtil.getFloatRange(_colorRatioFrom, _colorRatioTo));

				addParticle(particle);
			}
		}

		/**
		 * Speed of particle - pixel per second.
		 */
		public function speed(p_from:uint, p_to:uint):void
		{
			_speedFrom = p_from;
			_speedTo = p_to;
		}

		/**
		 * Set emission angle in radians.
		 */
		public function angleEmission(p_angleFrom:Number, p_angleTo:Number):void
		{
			_angleFrom = p_angleFrom;
			_angleTo = p_angleTo;
		}

		/**
		 * Range of life of particles in seconds.
		 */
		public function lifeTime(p_lifeTimeFrom:Number, p_lifeTimeTo:Number):void
		{
			_lifeTimeFrom = p_lifeTimeFrom * 1000;
			_lifeTimeTo = p_lifeTimeTo * 1000;
		}

		/**
		 * Size of emitter.
		 */
		public function size(p_width:uint = 1, p_height:uint = 1):void
		{
			_widthField = p_width;
			_heightField = p_height;
		}

		/**
		 */
		public function gravity(p_gravityX:Number, p_gravityY:Number, p_ratioFrom:Number = 1.0, p_ratioTo:Number = 1.0):void
		{
			_gravityX = p_gravityX;
			_gravityY = p_gravityY;
			_gravityRatioFrom = p_ratioFrom;
			_gravityRatioTo = p_ratioTo;
		}

		/**
		 *
		 */
		public function scale(p_initScale:Number, p_scaleSequence:Array = null, p_scaleRatioFrom:Number = 1.0, p_scaleRatioTo:Number = 1.0):void
		{
			_scale = p_initScale;
			_scaleSequence = p_scaleSequence;
			_scaleRatioFrom = p_scaleRatioFrom;
			_scaleRatioTo = p_scaleRatioTo;
		}

		/**
		 * ARGB
		 * ratio in range [0, 1]
		 */
		public function color(p_initColor:uint, p_colorSequence:Array = null, p_colorRatioFrom:Number = 1.0, p_colorRatioTo:Number = 1.0):void
		{
			_alpha = BBColor.getAlpha(p_initColor, true);
			_red = BBColor.getRed(p_initColor, true);
			_green = BBColor.getGreen(p_initColor, true);
			_blue = BBColor.getBlue(p_initColor, true);

			_colorRatioFrom = p_colorRatioFrom > 1.0 ? 1.0 : p_colorRatioFrom < 0 ? 0 : p_colorRatioFrom;
			_colorRatioTo = p_colorRatioTo > 1.0 ? 1.0 : p_colorRatioTo < 0 ? 0 : p_colorRatioTo;

			//
			var numColors:uint;
			if (p_colorSequence && (numColors = p_colorSequence.length) > 0)
			{
				_colorSequence = new <Number>[];

				var colorStart:uint = p_initColor;
				var colorEnd:uint;
				var gradient:Vector.<uint>;
				var numGradientColors:uint;
				var curGradColor:uint;
				var colorSeqIndex:int;

				for (var i:int = 0; i < numColors; i++)
				{
					colorEnd = p_colorSequence[i];
					gradient = BBColor.getGradientStrip(colorStart, colorEnd, 100);
					colorStart = colorEnd;

					numGradientColors = gradient.length;
					for (var j:int = 0; j < numGradientColors; j++)
					{
						curGradColor = gradient[j];

						colorSeqIndex = _colorSequence.length;
						_colorSequence[colorSeqIndex] = BBColor.getAlpha(curGradColor, true);
						_colorSequence[++colorSeqIndex] = BBColor.getRed(curGradColor, true);
						_colorSequence[++colorSeqIndex] = BBColor.getGreen(curGradColor, true);
						_colorSequence[++colorSeqIndex] = BBColor.getBlue(curGradColor, true);
					}
				}
			}
		}

		/**
		 * Settings for generating particle.
		 * Useful if don't use external texture for particle.
		 * Also method gives possible for optimization - creates texture with specify size to avoid scale effect.
		 */
		public function defaultParticle(p_radius:uint = 20, p_color:uint = 0xffffffff):void
		{
			_defParticleRadius = p_radius < 1 ? 1 : p_radius;
			_defParticleColor = p_color;
		}

		/**
		 */
		private function addParticle(p_particle:BBParticle):void
		{
			if (_tail)
			{
				_tail.next = p_particle;
				p_particle.prev = _tail;
				_tail = p_particle;
			}
			else _tail = _head = p_particle;

			_numParticles++;
		}

		/**
		 */
		internal function unlinkParticle(p_particle:BBParticle):void
		{
			if (p_particle == _head)
			{
				_head = _head.next;
				if (_head == null) _tail = null;
				else _head.prev = null;
			}
			else if (p_particle == _tail)
			{
				_tail = _tail.prev;
				if (_tail == null) _head = null;
				else _tail.next = null;
			}
			else
			{
				var prevParticle:BBParticle = p_particle.prev;
				var nextParticle:BBParticle = p_particle.next;
				prevParticle.next = nextParticle;
				nextParticle.prev = prevParticle;
			}

			_numParticles--;
		}

		/**
		 */
		private function clearParticles():void
		{
			var particle:BBParticle;

			while (_tail)
			{
				particle = _tail;
				_tail = _tail.prev;

				particle.dispose();
			}

			_head = _tail = null;
			_numParticles = 0;
		}

		/**
		 */
		public function set texture(p_texture:BBTexture):void
		{
			z_texture = p_texture;
			if (z_texture == null && node && node.isOnStage) z_texture = getDefaultTexture();
		}

		/**
		 */
		public function get texture():BBTexture
		{
			return z_texture;
		}

		/**
		 */
		override public function dispose():void
		{
			var curNode:BBNode = node;
			curNode.onAdded.remove(addedToStage);
			clearParticles();
			super.dispose();

			if (curNode.parent) curNode.parent.removeChild(curNode);
		}

		/**
		 * Emitter component returns with node.
		 */
		static public function get(p_texture:BBTexture = null, p_nodeName:String = ""):BBEmitter
		{
			var emitter:BBEmitter = BBComponent.getWithNode(BBEmitter, p_nodeName) as BBEmitter;
			emitter.texture = p_texture;

			return emitter;
		}

		/**
		 */
		private function getDefaultTexture():BBTexture
		{
			var particleId:String = "def_particle_" + _defParticleRadius + "_" + _defParticleColor;
			var gradient:Array = [_defParticleColor, _defParticleColor, _defParticleColor & 0x00ffffff];

			return BBTexture.createFromColorCircle(_defParticleRadius, particleId, gradient);
		}

		/**
		 * Rid some resource e.g. caches.
		 */
		static public function rid():void
		{
			BBParticle.rid();
		}
	}
}
