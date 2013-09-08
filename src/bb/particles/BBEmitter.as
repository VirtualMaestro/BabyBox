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

	import vm.math.rand.RandUtil;

	use namespace bb_private;

	/**
	 * Emitter component of particle system.
	 */
	public class BBEmitter extends BBRenderable
	{
		private var _widthField:uint = 1;
		private var _heightField:uint = 1;

		/**
		 * Number of emission particles per second.
		 */
		public var emissionRate:uint = 100;

		private var _speedFrom:Number = 100;
		private var _speedTo:Number = 200;

		private var _gravityX:Number = 0;
		private var _gravityY:Number = 0;

		private var _angleFrom:Number = 0;
		private var _angleTo:Number = 0;

		private var _lifeTimeFrom:int = 100;
		private var _lifeTimeTo:int = 500;

		// scale setup
		private var _scale:Number = 1.0;
		private var _scaleSequence:Array = null;
		private var _scaleRatioFrom:Number = 1.0;
		private var _scaleRatioTo:Number = 1.0;

		// color setup
		private var _color:uint = 0xffffffff;
		private var _colorSequence:Array = null;
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

		/**
		 */
		public function BBEmitter()
		{
			super();

			onAdded.add(addedToNode);
		}

		/**
		 */
		private function addedToNode(p_signal:BBSignal):void
		{
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

				updateEnable = true;
			}
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			var particle:BBParticle = _head;
			var currentParticle:BBParticle;
			while (particle)
			{
				currentParticle = particle;
				particle = particle.next;

				currentParticle.update(p_deltaTime);
			}

			var numNewParticles:uint = Math.round(emissionRate * p_deltaTime / 1000.0);
			createParticles(numNewParticles, p_deltaTime);
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
				p_context.draw(z_texture, particle.posX, particle.posY, 0, particle.scale * scaleX, particle.scale * scaleY,
						0, 0, 0, 1.0, 1.0, particle.alpha * alpha, particle.red * red, particle.green * green, particle.blue * blue);

				particle = particle.next;
			}
		}

		/**
		 */
		private function createParticles(p_numParticles:int, p_deltaTime:int):void
		{
			var posX:Number = _transform.worldX;
			var posY:Number = _transform.worldY;
			var rot:Number = _transform.worldRotation;

			var posXFrom:int = posX - _widthField * 0.5;
			var posXTo:int = posX + _widthField * 0.5;
			var posYFrom:int = posY - _heightField * 0.5;
			var posYTo:int = posY + _heightField * 0.5;

			var particle:BBParticle;

			for (var i:int = 0; i < p_numParticles; i++)
			{
				particle = BBParticle.get(this);
				particle.posX = RandUtil.getIntRange(posXFrom, posXTo);
				particle.posY = RandUtil.getIntRange(posYFrom, posYTo);

				particle.speed = RandUtil.getIntRange(_speedFrom, _speedTo);

				particle.gravityX = _gravityX;
				particle.gravityY = _gravityY;

				particle.dirX = Math.cos(rot + RandUtil.getFloatRange(_angleFrom, _angleTo));
				particle.dirY = Math.sin(rot + RandUtil.getFloatRange(_angleFrom, _angleTo));

				particle.lifeTime = RandUtil.getIntRange(_lifeTimeFrom, _lifeTimeTo);

				particle.scaleSetup(_scale, _scaleSequence, RandUtil.getFloatRange(_scaleRatioFrom, _scaleRatioTo));
				particle.colorSetup(_color, _colorSequence, RandUtil.getFloatRange(_colorRatioFrom, _colorRatioTo));

				addParticle(particle);
			}
		}

		/**
		 * Speed of particle - pixel per second.
		 */
		public function speed(p_from:Number, p_to:Number):void
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
		public function gravity(p_gravityX:Number, p_gravityY:Number):void
		{
			_gravityX = p_gravityX;
			_gravityY = p_gravityY;
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
		 */
		public function color(p_initColor:uint, p_colorSequence:Array = null, p_colorRatioFrom:Number = 1.0, p_colorRatioTo:Number = 1.0):void
		{
			_color = p_initColor;
			_colorSequence = p_colorSequence;
			_colorRatioFrom = p_colorRatioFrom;
			_colorRatioTo = p_colorRatioTo;
		}

		/**
		 * Settings for generating particle.
		 * Useful if don't use external texture for particle.
		 * Also method gives possible for optimization - creates texture with specify size to avoid scale effect.
		 */
		public function defaultParticle(p_radius:uint, p_color:uint):void
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
