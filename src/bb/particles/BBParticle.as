/**
 * User: VirtualMaestro
 * Date: 05.09.13
 * Time: 10:35
 */
package bb.particles
{
	/**
	 */
	internal class BBParticle
	{
		public var posX:Number;
		public var posY:Number;

		public var dirX:Number;
		public var dirY:Number;

		public var gravityX:Number = 0;
		public var gravityY:Number = 0;

		public var scaleX:Number = 1.0;
		public var scaleY:Number = 1.0;

		//
		internal var next:BBParticle = null;
		internal var prev:BBParticle = null;
		internal var emitter:BBEmitter = null;

		// im milliseconds
		private var _lifeTime:int = 1000;
		private var _currentLifeTime:int = 1000;

		private var _speedX:Number;
		private var _speedY:Number;

		/**
		 */
		public function BBParticle(p_emitter:BBEmitter)
		{
			emitter = p_emitter;
		}

		/**
		 */
		public function update(p_deltaTime:int):void
		{
			if (_currentLifeTime < 1)
			{
				dispose();
				return;
			}

			var dt:Number = p_deltaTime / 1000.0;
			posX += dirX * _speedX * dt;
			posY += dirY * _speedY * dt;

			_speedX += gravityX * dt;
			_speedY -= gravityY * dt;

			_currentLifeTime -= p_deltaTime;
		}

		/**
		 * Time of life of particle in milliseconds.
		 */
		public function set lifeTime(p_val:int):void
		{
			_lifeTime = p_val;
			_currentLifeTime = p_val;
		}

		/**
		 */
		public function set speed(p_val:Number):void
		{
			_speedX = _speedY = p_val;
		}

		/**
		 */
		public function dispose():void
		{
			emitter.unlinkParticle(this);
			emitter = null;
			next = prev = null;

			put(this);
		}

		///////////////////////
		/// POOL /////////////
		/////////////////////

		static private var _poolHead:BBParticle = null;

		/**
		 */
		static public function get(p_emitter:BBEmitter):BBParticle
		{
			var particle:BBParticle;

			if (_poolHead)
			{
				particle = _poolHead;
				_poolHead = _poolHead.next;

				particle.next = null;
				particle.emitter = p_emitter;
			}
			else particle = new BBParticle(p_emitter);

			return particle;
		}

		/**
		 */
		static private function put(p_particle:BBParticle):void
		{
			if (_poolHead)
			{
				p_particle.next = _poolHead;
				_poolHead = p_particle;
			}
			else _poolHead = p_particle;
		}

		/**
		 */
		static public function rid():void
		{
			var particle:BBParticle;
			while (_poolHead)
			{
				particle = _poolHead;
				_poolHead = _poolHead.next;
				particle.next = null;
			}
		}
	}
}
