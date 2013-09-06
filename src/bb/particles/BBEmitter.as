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

		//
		private var _head:BBParticle;
		private var _tail:BBParticle;

		private var _numParticles:uint = 0;

		private var _transform:BBTransform;

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
//			var posX:Number = _transform.worldX;
//			var posY:Number = _transform.worldY;
//			var rotation:Number = _transform.rotationWorld;
			var scaleX:Number = _transform.worldScaleX;
			var scaleY:Number = _transform.worldScaleY;

			var particle:BBParticle = _head;
			while (particle)
			{
				p_context.draw(z_texture, particle.posX, particle.posY, 0, particle.scaleX * scaleX, particle.scaleY * scaleY);

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
		static private function getDefaultTexture():BBTexture
		{
			var texture:BBTexture = BBTexture.createFromColorCircle(10, "defaultParticleTexture", [0xffff0000, 0x00ffffff]);
			return texture;
		}
	}
}
