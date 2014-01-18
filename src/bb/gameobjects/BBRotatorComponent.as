/**
 * User: VirtualMaestro
 * Date: 17.01.14
 * Time: 23:58
 */
package bb.gameobjects
{
	import bb.bb_spaces.bb_private;
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.core.BBTransform;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	import vm.math.trigonometry.TrigUtil;

	use namespace bb_private;

	/**
	 *
	 */
	public class BBRotatorComponent extends BBComponent
	{
		/**
		 * Angle in radians, which represents of rotation error - mean goal considered achieved if deviation is not bigger than given angle (+/-).
		 * By default 0, absolutely accurate.
		 */
		public var accurate:Number;

		/**
		 */
		private var _angularVelocity:Number;

		private var _onStart:BBSignal;
		private var _onComplete:BBSignal;

		private var _transform:BBTransform;

		private var _isImmediately:Boolean;
		private var _isRotation:Boolean;
		private var _diffTargetAngle:Number;
		private var _sign:int;

		/**
		 */
		public function BBRotatorComponent()
		{
			super();
		}

		/**
		 */
		override protected function init():void
		{
			onAdded.add(addedToNodeHandler);

			_isImmediately = true;
			_isRotation = false;
			_diffTargetAngle = 0;
			_sign = 1;
			_angularVelocity = 0;
			accurate = 0;
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			_transform = node.transform;
		}

		/**
		 *
		 */
		public function set target(p_target:BBNode):void
		{

		}

		/**
		 */
		public function setTargetPosition(p_x:Number, p_y:Number):void
		{
			var selfPosition:Vec2 = _transform.getPositionWorld();
			var aimAngle:Number = Math.atan2(p_y - selfPosition.y, p_x - selfPosition.x);

			if (_isImmediately) _transform.rotationWorld = aimAngle;
			else
			{
				_diffTargetAngle = TrigUtil.fitAngle(aimAngle) - _transform.rotationWorld;
				_sign = _diffTargetAngle < 0 ? -1 : 1;
				_diffTargetAngle *= _sign;

				if (_diffTargetAngle > TrigUtil.PI)
				{
					_diffTargetAngle = TrigUtil.PI2 - _diffTargetAngle;
					_sign = -_sign;
				}

				//
				if (!_isRotation)
				{
					updateEnable = true;
					_isRotation = true;

					if (_onStart) _onStart.dispatch();
				}
			}
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			if (_diffTargetAngle >= -accurate && _diffTargetAngle <= accurate)
			{
				updateEnable = false;
				_isRotation = false;

				if (_onComplete) _onComplete.dispatch();
			}
			else
			{
				var angularShift:Number = _angularVelocity * p_deltaTime / 1000.0;

				if (angularShift > _diffTargetAngle)
				{
					angularShift = _diffTargetAngle;
					_diffTargetAngle = 0;
				}
				else _diffTargetAngle -= angularShift;

				_transform.shiftRotation = angularShift * _sign;
			}
		}

		/**
		 */
		override protected function destroy():void
		{
			_transform = null;

			super.destroy();
		}

		/**
		 */
		public function get angularVelocity():Number
		{
			return _angularVelocity;
		}

		/**
		 * Velocity of rotation in radians (rad/second).
		 * If velocity less then 1 degree per second, angle applies immediately.
		 */
		public function set angularVelocity(p_value:Number):void
		{
			_isImmediately = p_value < Math.PI / 180.0;
			_angularVelocity = p_value;
		}

		/**
		 * Signal dispatched when start rotation.
		 */
		public function get onStart():BBSignal
		{
			if (!_onStart) _onStart = BBSignal.get(this);
			return _onStart;
		}

		/**
		 * Signal dispatched when rotation is finished.
		 */
		public function get onComplete():BBSignal
		{
			if (!_onComplete) _onComplete = BBSignal.get(this);
			return _onComplete;
		}
	}
}
