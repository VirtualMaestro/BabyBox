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

		//
		internal var next:BBParticle = null;
		internal var prev:BBParticle = null;
		internal var emitter:BBEmitter = null;

		// im milliseconds
		private var _lifeTime:int = 1000;
		private var _currentLifeTime:int = 1000;

		private var _speedX:Number;
		private var _speedY:Number;

		// scale params
		public var scale:Number = 1.0;

		private var _isScaleSequence:Boolean = false;
		private var _scaleSequence:Array = null;
		private var _scaleRatio:Number = 1.0;
		private var _curIndexScale:int = -1;
		private var _numScales:int = 0;
		private var _scaleLifePeriod:Number = 0;
		private var _scaleFrom:Number = 0;
		private var _scaleTo:Number = 0;

		// color params
		public var alpha:Number = 1.0;
		public var red:Number = 1.0;
		public var green:Number = 1.0;
		public var blue:Number = 1.0;

		private var _colorRatio:Number = 1.0;
		private var _colorSequence:Vector.<Number> = null;
		private var _isColorSequence:Boolean = false;
		private var _numColors:uint = 0;

		// dampening
		public var dampening:Number = 1.0;

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
			posX += dirX * _speedX * dt + gravityX * dt;
			posY += dirY * _speedY * dt + gravityY * dt;

			_speedX *= dampening;
			_speedY *= dampening;

			//
			if (_isScaleSequence)
			{
				var indexScale:uint = Number(1.0 - _currentLifeTime / Number(_lifeTime)) * _numScales;
				var percentElapsedTimeScale:Number = ((_lifeTime - _currentLifeTime) - _scaleLifePeriod * indexScale) / _scaleLifePeriod;

				// changes
				if (indexScale != _curIndexScale)
				{
					_curIndexScale = indexScale;
					_scaleFrom = _scaleTo;
					_scaleTo = _scaleSequence[_curIndexScale] * _scaleRatio;
				}

				scale = _scaleFrom + (_scaleTo - _scaleFrom) * percentElapsedTimeScale;
			}

			if (_isColorSequence)
			{
				var index:int = int(_numColors * (1.0 - _currentLifeTime / _lifeTime)) * 4;
				alpha = _colorSequence[index] * _colorRatio;
				red = _colorSequence[++index] * _colorRatio;
				green = _colorSequence[++index] * _colorRatio;
				blue = _colorSequence[++index] * _colorRatio;
			}

			//
			_currentLifeTime -= p_deltaTime;
		}

		/**
		 * Time of life of particle in milliseconds.
		 * p_startsLive - time from which particle starts live. It gives in percents from 0.0 (begin of life) - 1.0 (end of life).
		 */
		public function lifeTime(p_val:int, p_startsLive:Number = 0.0):void
		{
			_lifeTime = p_val;
			_currentLifeTime = _lifeTime - _lifeTime * p_startsLive;
		}

		/**
		 */
		public function set speed(p_val:Number):void
		{
			_speedX = _speedY = p_val;
		}

		/**
		 */
		public function scaleSetup(p_initScale:Number, p_scaleSequence:Array = null, p_scaleRatio:Number = 1.0):void
		{
			scale = _scaleFrom = _scaleTo = p_initScale * p_scaleRatio;
			_scaleSequence = p_scaleSequence;
			_scaleRatio = p_scaleRatio;

			if (p_scaleSequence && (_numScales = p_scaleSequence.length) > 0)
			{
				_isScaleSequence = true;
				_scaleLifePeriod = _lifeTime / _numScales;
			}
		}

		/**
		 */
		public function colorSetup(p_alpha:Number, p_red:Number, p_green:Number, p_blue:Number, p_colorSequence:Vector.<Number> = null, p_colorRatio:Number = 1.0):void
		{
			_colorRatio = p_colorRatio;
			alpha = p_alpha * p_colorRatio;
			red = p_red * p_colorRatio;
			green = p_green * p_colorRatio;
			blue = p_blue * p_colorRatio;

			if (p_colorSequence)
			{
				_colorSequence = p_colorSequence;
				_numColors = p_colorSequence.length / 4;
				_isColorSequence = true;
			}
		}

		/**
		 */
		public function dispose():void
		{
			emitter.unlinkParticle(this);
			emitter = null;
			next = prev = null;
			_isScaleSequence = false;
			_scaleSequence = null;
			_scaleRatio = 1.0;
			_scaleRatio = 1.0;
			_curIndexScale = -1;
			_scaleFrom = 0;
			_scaleTo = 0;
			_isColorSequence = false;
			_colorSequence = null;
			_colorRatio = 1.0;
			_scaleLifePeriod = 0;
			dampening = 1;

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
