/**
 * User: VirtualMaestro
 * Date: 05.09.13
 * Time: 10:35
 */
package bb.particles
{
	import bb.vo.BBColor;

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
		private var _scaleNext:Number = 1.0;
		private var _currentScaleIndex:int = 0;
		private var _numScales:int = 0;
		private var _scaleLifePeriod:Number;
		private var _initScaleLifePeriod:Number;
		private var _dtScale:Number;
		private var _initScale:Number;

		// color params
		public var alpha:Number = 1.0;
		public var red:Number = 1.0;
		public var green:Number = 1.0;
		public var blue:Number = 1.0;

		private var _colorRatio:Number = 1.0;
		private var _colorSequence:Array = null;

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

			//
			if (_isScaleSequence)
			{
				if (_scaleLifePeriod <= 0)
				{
					_scaleLifePeriod = _lifeTime / _numScales;
					_initScaleLifePeriod = _scaleLifePeriod;
					_scaleNext = _scaleSequence[++_currentScaleIndex] * _scaleRatio;
					_initScale = scale;
					_dtScale = _scaleNext - _initScale;
				}

				scale = _initScale + (_dtScale * (1 - _scaleLifePeriod / _initScaleLifePeriod));

				_scaleLifePeriod -= p_deltaTime;
			}

			//
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
		public function scaleSetup(p_initScale:Number, p_scaleSequence:Array = null, p_scaleRatio:Number = 1.0):void
		{
			scale = _initScale = p_initScale * p_scaleRatio;
			_scaleSequence = p_scaleSequence;
			_scaleRatio = p_scaleRatio;

			if (p_scaleSequence && (_numScales = p_scaleSequence.length) > 0)
			{
				_isScaleSequence = true;
				_scaleNext = p_scaleSequence[_currentScaleIndex] * p_scaleRatio;
				_scaleLifePeriod = _lifeTime / _numScales;
				_initScaleLifePeriod = _scaleLifePeriod;
				_dtScale = _scaleNext - _initScale;
			}
		}

		/**
		 */
		public function colorSetup(p_initColor:uint, p_colorSequence:Array = null, p_colorRatio:Number = 1.0):void
		{
			_colorRatio = p_colorRatio;
			alpha = BBColor.getAlpha(p_initColor, true) * p_colorRatio;
			red = BBColor.getRed(p_initColor, true) * p_colorRatio;
			green = BBColor.getGreen(p_initColor, true) * p_colorRatio;
			blue = BBColor.getBlue(p_initColor, true) * p_colorRatio;

			_colorSequence = p_colorSequence;
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
			_currentScaleIndex = 0;

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
