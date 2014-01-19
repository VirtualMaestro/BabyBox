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
	import bb.mouse.BBMouseModule;
	import bb.mouse.events.BBMouseEvent;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	import vm.math.rand.RandUtil;
	import vm.math.trigonometry.TrigUtil;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Rotator engine for rotational mechanism.
	 */
	public class BBRotatorComponent extends BBComponent
	{
		/**
		 */
		private var _accurate:Number;

		/**
		 */
		private var _angularVelocity:Number;

		private var _onStart:BBSignal;
		private var _onComplete:BBSignal;

		private var _transform:BBTransform;
		private var _targetTransform:BBTransform;

		private var _isImmediately:Boolean;
		private var _isRotation:Boolean;
		private var _diffTargetAngle:Number;
		private var _sign:int;

		//
		private var _prevX:Number = 0;
		private var _prevY:Number = 0;
		private var _prevAimAngle:Number = 0;

		private var _isMouseFollow:Boolean = false;

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
			onRemoved.add(removedFromNodeHandler);

			_isImmediately = true;
			_isRotation = false;
			_diffTargetAngle = 0;
			_sign = 1;
			_angularVelocity = 0;
			_accurate = 0;
			_prevX = 0;
			_prevY = 0;
			_prevAimAngle = 0;
			_isMouseFollow = false;
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			_transform = node.transform;

			//
			if (node.isOnStage && _isMouseFollow) addFollowMouse();
			else node.onAddedToStage.add(initMouseFollowHandler);
		}

		/**
		 */
		private function removedFromNodeHandler(p_signal:BBSignal):void
		{
			_transform = null;
			followTarget = null;
			followMouse = false;
		}

		/**
		 */
		private function initMouseFollowHandler(p_signal:BBSignal):void
		{
			p_signal.removeCurrentListener();
			if (_isMouseFollow) addFollowMouse();
		}

		/**
		 * Set target for which rotator have to follow.
		 * If need stop follow just set null.
		 */
		public function set followTarget(p_target:BBNode):void
		{
			if (p_target)
			{
				if (!p_target.isDisposed && _targetTransform != p_target.transform)
				{
					// in case if rotator follow to mouse set it false
					followMouse = false;

					//
					_targetTransform = p_target.transform;
					p_target.onRemovedFromStage.add(targetRemovedHandler);

					updateEnable = true;
				}
			}
			else
			{
				if (_targetTransform)
				{
					_targetTransform.node.onRemovedFromStage.remove(targetRemovedHandler);
					_targetTransform = null;
				}
			}
		}

		/**
		 */
		private function targetRemovedHandler(p_signal:BBSignal):void
		{
			p_signal.removeCurrentListener();
			_targetTransform = null;
		}

		/**
		 */
		public function get followTarget():BBNode
		{
			return _targetTransform ? _targetTransform.node : null;
		}

		/**
		 * Enable/disable follow for mouse. For that functionality mouse should be enabled and it should to dispatch move event.
		 * If 'follow mouse' is enabled when rotator follows target, so 'follow target' is interrupted.
		 */
		public function set followMouse(p_val:Boolean):void
		{
			if (_isMouseFollow == p_val) return;
			_isMouseFollow = p_val;

			if (node.isOnStage)
			{
				if (_isMouseFollow) addFollowMouse();
				else removeMouseFollow();
			}
		}

		/**
		 */
		private function addFollowMouse():void
		{
			// in case if rotator follow for target disable it
			followTarget = null;

			//
			var mouseModule:BBMouseModule = node.tree.getModule(BBMouseModule) as BBMouseModule;
			CONFIG::debug
			{
				Assert.isTrue(mouseModule != null,
				              "BBMouseModule isn't in engine. For using 'followMouse' functionality mouse module should be in the system",
				              "BBRotatorComponent.addFollowMouse");
			}

			mouseModule.onMove.add(mouseMoveHandler);

			node.onRemovedFromStage.add(deinitMouseFollowHandler);
		}

		/**
		 */
		private function deinitMouseFollowHandler(p_signal:BBSignal):void
		{
			p_signal.removeCurrentListener();
			removeMouseFollow();
		}

		/**
		 */
		private function removeMouseFollow():void
		{
			(node.tree.getModule(BBMouseModule) as BBMouseModule).onMove.remove(mouseMoveHandler);
			_isMouseFollow = false;
		}

		/**
		 */
		private function mouseMoveHandler(p_signal:BBSignal):void
		{
			var event:BBMouseEvent = p_signal.params as BBMouseEvent;
			setTargetPosition(event.worldX, event.worldY);
		}

		/**
		 */
		public function get followMouse():Boolean
		{
			return _isMouseFollow;
		}

		/**
		 */
		public function setTargetPosition(p_x:Number, p_y:Number):void
		{
			if (p_x == _prevX && p_y == _prevY) return;
			_prevX = p_x;
			_prevY = p_y;

			//
			var selfPosition:Vec2 = _transform.getPositionWorld();
			var aimAngle:Number = Math.atan2(p_y - selfPosition.y, p_x - selfPosition.x);

			if (aimAngle >= (_prevAimAngle - _accurate) && aimAngle <= (_prevAimAngle + _accurate)) return;
			_prevAimAngle = aimAngle;

			//
			if (_isImmediately) _transform.rotationWorld = aimAngle;
			else
			{
				_diffTargetAngle = TrigUtil.fitAngle(aimAngle) - _transform.rotationWorld;
				_sign = _diffTargetAngle < 0 ? -1 : 1;
				_diffTargetAngle *= _sign;
				_diffTargetAngle += RandUtil.getFloatRange(-_accurate, _accurate);

				//
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
			if (_targetTransform)
			{
				var targetPosition:Vec2 = _targetTransform.getPositionWorld();
				setTargetPosition(targetPosition.x, targetPosition.y);
			}

			//
			if (checkComplete() && _isRotation) rotationComplete();
			else shiftRotation(p_deltaTime);
		}

		/**
		 */
		[Inline]
		final private function checkComplete():Boolean
		{
			return (_diffTargetAngle >= -_accurate && _diffTargetAngle <= _accurate);
		}

		/**
		 */
		[Inline]
		final private function rotationComplete():void
		{
			if (!_targetTransform) updateEnable = false;
			_isRotation = false;

			if (_onComplete) _onComplete.dispatch();
		}

		/**
		 */
		[Inline]
		final private function shiftRotation(p_deltaTime:int):void
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

		/**
		 */
		override protected function destroy():void
		{

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
		 * Angle in radians, which represents of rotation error - mean goal considered achieved if deviation is not bigger than given angle (+/-).
		 * By default 0, absolutely accurate.
		 */
		public function set accurate(p_val:Number):void
		{
			_accurate = TrigUtil.fitAngle(p_val);
		}

		/**
		 */
		public function get accurate():Number
		{
			return _accurate;
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
