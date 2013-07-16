/**
 * User: VirtualMaestro
 * Date: 14.07.13
 * Time: 17:30
 */
package bb.camera
{
	import vm.math.numbers.NumberUtil;
	import vm.math.rand.Noise;
	import vm.math.rand.RandUtil;

	/**
	 * Represents of shaker for simulation of shake effect.
	 */
	public class BBShaker
	{
		public var duration:uint = 0;
		public var scaleMaster:Number = 20;
		public var attenuation:Boolean = false;

		//
		private var _shakeIntensityMaster:Number;
		private var _shakeIntensityX:Number;
		private var _shakeIntensityY:Number;
		private var _shakeIntensityRotation:Number;

		private var _destabiliseIntensityMaster:Number;
		private var _destabiliseScaleX:Number;
		private var _destabiliseScaleY:Number;
		private var _destabiliseScaleRotation:Number;

		private var _jitterIntensityMaster:Number;
		private var _jitterIntensityX:Number;
		private var _jitterIntensityY:Number;
		private var _jitterIntensityRotation:Number;

		private var _isDisposed:Boolean = false;

		/**
		 * All parameters have to be in range [0; 100];
		 */
		public function BBShaker(p_duration:uint,
		                         p_shakeIntensityMaster:Number = 50, p_destabiliseIntensityMaster:Number = 50, p_jitterIntensityMaster:Number = 50,
		                         p_shakeIntensityX:Number = 100, p_shakeIntensityY:Number = 100, p_shakeIntensityRotation:Number = 100,
		                         p_destabiliseScaleX:Number = 100, p_destabiliseScaleY:Number = 100, p_destabiliseScaleRotation:Number = 100,
		                         p_jitterIntensityX:Number = 100, p_jitterIntensityY:Number = 100, p_jitterIntensityRotation:Number = 100)
		{
			init(p_duration,
					p_shakeIntensityMaster, p_destabiliseIntensityMaster, p_jitterIntensityMaster,
					p_shakeIntensityX, p_shakeIntensityY, p_shakeIntensityRotation,
					p_destabiliseScaleX, p_destabiliseScaleY, p_destabiliseScaleRotation,
					p_jitterIntensityX, p_jitterIntensityY, p_jitterIntensityRotation);
		}

		/**
		 */
		private function init(p_duration:uint, p_shakeIntensityMaster:Number, p_destabiliseIntensityMaster:Number, p_jitterIntensityMaster:Number, p_shakeIntensityX:Number, p_shakeIntensityY:Number, p_shakeIntensityRotation:Number, p_destabiliseScaleX:Number, p_destabiliseScaleY:Number, p_destabiliseScaleRotation:Number, p_jitterIntensityX:Number, p_jitterIntensityY:Number, p_jitterIntensityRotation:Number):void
		{
			_isDisposed = false;

			duration = p_duration;

			_shakeIntensityMaster = correctRange(p_shakeIntensityMaster);
			_destabiliseIntensityMaster = correctRange(p_destabiliseIntensityMaster);
			_jitterIntensityMaster = correctRange(p_jitterIntensityMaster);

			_shakeIntensityX = correctRange(p_shakeIntensityX);
			_shakeIntensityY = correctRange(p_shakeIntensityY);
			_shakeIntensityRotation = correctRange(p_shakeIntensityRotation);

			_destabiliseScaleX = correctRange(p_destabiliseScaleX);
			_destabiliseScaleY = correctRange(p_destabiliseScaleY);
			_destabiliseScaleRotation = correctRange(p_destabiliseScaleRotation);

			_jitterIntensityX = correctRange(p_jitterIntensityX);
			_jitterIntensityY = correctRange(p_jitterIntensityY);
			_jitterIntensityRotation = correctRange(p_jitterIntensityRotation);
		}

		/**
		 * Check number and fit to range [0; 100]
		 */
		[Inline]
		private function correctRange(p_number:Number):Number
		{
			if (p_number < 0) p_number = 0;
			else if (p_number > 100) p_number = 100;
			p_number *= 0.01;

			return p_number;
		}

		/**
		 */
		public function getX(p_time:Number):Number
		{
			var time:Number = (p_time - 50) / duration;
			var shakeFactor:Number = _shakeIntensityMaster * _shakeIntensityX * scaleMaster;
			var shake:Number = RandUtil.getGaussian() * shakeFactor;
			var destabilise:Number = Noise.simplex1d(time * _destabiliseScaleX) * _destabiliseIntensityMaster * 5*scaleMaster;
			var jitter:Number = RandUtil.getFloatRange(_jitterIntensityMaster * _jitterIntensityX * -scaleMaster, _jitterIntensityMaster * _jitterIntensityX * scaleMaster);
			var yOffset:Number = shake + destabilise + jitter;

			return attenuation ? applyAttenuation(yOffset, p_time) : yOffset;
		}

		/**
		 */
		public function getY(p_time:Number):Number
		{
			var time:Number = p_time / duration;
			var shakeFactor:Number = _shakeIntensityMaster * _shakeIntensityY * scaleMaster;
			var shake:Number = RandUtil.getGaussian() * shakeFactor;
			var destabilise:Number = Noise.simplex1d(time * _destabiliseScaleY) * _destabiliseIntensityMaster * 5*scaleMaster;
			var jitter:Number = RandUtil.getFloatRange(_jitterIntensityMaster * _jitterIntensityY * -scaleMaster, _jitterIntensityMaster * _jitterIntensityY * scaleMaster);
			var xOffset:Number = shake + destabilise + jitter;

			return attenuation ? applyAttenuation(xOffset, p_time) : xOffset;
		}

		/**
		 */
		public function getRotation(p_time:Number):Number
		{
			var time:Number = p_time / duration;
			var shakeFactor:Number = _shakeIntensityMaster * _shakeIntensityRotation * scaleMaster;
			var shake:Number = RandUtil.getGaussian() * shakeFactor;
			var destabilise:Number = (Noise.perlin3d(time) * 2 - 1) * _destabiliseScaleRotation * _destabiliseIntensityMaster;// * 5;//*scaleMaster;
			var jitter:Number = RandUtil.getFloatRange(_jitterIntensityMaster * _jitterIntensityRotation * -scaleMaster, _jitterIntensityMaster * _jitterIntensityRotation * scaleMaster);
			var rotationOffset:Number = shake + destabilise + jitter;
			var oldRange:Number = 3*scaleMaster + 5*scaleMaster + scaleMaster;

			rotationOffset = NumberUtil.convertToRange(rotationOffset, -oldRange, oldRange, -0.8, 0.8);

			return attenuation ? applyAttenuation(rotationOffset, p_time) : rotationOffset;
		}

		/**
		 */
		[Inline]
		private function applyAttenuation(p_val:Number, p_currentTime:Number):Number
		{
			var attenuationFactor:Number = 1-p_currentTime/(duration*1.5);
			return p_val * attenuationFactor;
		}

		/**
		 */
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * Removes shaker and back to pool.
		 */
		public function dispose():void
		{
			if (isDisposed)
			{
				_isDisposed = true;
				put(this);
			}
		}

		///////////////////
		/// POOL /////////
		//////////////////

		static private var _pool:Vector.<BBShaker>;
		static private var _size:int = 0;

		/**
		 */
		static public function get(p_duration:uint,
				                         p_shakeIntensityMaster:Number = 50, p_destabiliseIntensityMaster:Number = 50, p_jitterIntensityMaster:Number = 50,
				                         p_shakeIntensityX:Number = 100, p_shakeIntensityY:Number = 100, p_shakeIntensityRotation:Number = 100,
				                         p_destabiliseScaleX:Number = 100, p_destabiliseScaleY:Number = 100, p_destabiliseScaleRotation:Number = 100,
				                         p_jitterIntensityX:Number = 100, p_jitterIntensityY:Number = 100, p_jitterIntensityRotation:Number = 100):BBShaker
		{
			var shaker:BBShaker;
			if (_size > 0)
			{
				 shaker = _pool[--_size];
				_pool[_size] = null;

				shaker.init(
						p_duration,
						p_shakeIntensityMaster, p_destabiliseIntensityMaster, p_jitterIntensityMaster,
						p_shakeIntensityX, p_shakeIntensityY, p_shakeIntensityRotation,
						p_destabiliseScaleX, p_destabiliseScaleY, p_destabiliseScaleRotation,
						p_jitterIntensityX, p_jitterIntensityY, p_jitterIntensityRotation);
			}
			else shaker = new BBShaker(
					p_duration,
					p_shakeIntensityMaster, p_destabiliseIntensityMaster, p_jitterIntensityMaster,
					p_shakeIntensityX, p_shakeIntensityY, p_shakeIntensityRotation,
					p_destabiliseScaleX, p_destabiliseScaleY, p_destabiliseScaleRotation,
					p_jitterIntensityX, p_jitterIntensityY, p_jitterIntensityRotation);

			return shaker;
		}

		/**
		 */
		static private function put(p_shaker:BBShaker):void
		{
			if (_pool == null) _pool = new <BBShaker>[];
			_pool[_size++] = p_shaker;
		}

		/**
		 * Clear pool.
		 */
		static public function rid():void
		{
			if (_pool)
			{
				for (var i:int = 0; i < _size; i++)
				{
					_pool[i] = null;
				}

				_size = 0;
				_pool.length = 0;
				_pool = null;
			}
		}
	}
}
