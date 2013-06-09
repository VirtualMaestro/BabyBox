/**
 * User: VirtualMaestro
 * Date: 01.03.13
 * Time: 17:54
 */
package bb.modules
{
	import bb.bb_spaces.bb_private;
	import bb.components.physics.BBPhysicsBody;
	import bb.components.physics.joints.BBConstraintFactory;
	import bb.components.physics.joints.BBJoint;
	import bb.core.BBConfig;
	import bb.core.BabyBox;
	import bb.events.BBMouseEvent;
	import bb.signals.BBSignal;

	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.ConstraintCallback;
	import nape.callbacks.ConstraintListener;
	import nape.constraint.PivotJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyIterator;
	import nape.phys.BodyList;
	import nape.space.Broadphase;
	import nape.space.Space;

	use namespace bb_private;

	/**
	 * Response for physics simulation.
	 */
	public class BBPhysicsModule extends BBModule
	{
		public var timeStep:Number = 1 / 30.0;
		public var velocityIterations:int = 20;
		public var positionIterations:int = 20;

		private var _space:Space;
		private var _gravity:Vec2;
		private var _config:BBConfig;
		//
		private var _hand:PivotJoint;
		private var _isHandEnable:Boolean = false;

		private var _onPickup:BBSignal;
		private var _onDrop:BBSignal;

		private var _mouseModule:BBMouseModule;
		private var _mouseX:Number = 0;
		private var _mouseY:Number = 0;

		/**
		 */
		public function BBPhysicsModule()
		{
			super();
			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			_config = (engine as BabyBox).config;
			_mouseModule = getModule(BBMouseModule) as BBMouseModule;

			if (_config.autoPhysicTimeStep) timeStep = 1 / Number(_config.frameRate);

			_gravity = _config.getGravity();
			_space = new Space(_gravity, (_config.broadphaseSweepAndPrune ? Broadphase.SWEEP_AND_PRUNE : Broadphase.DYNAMIC_AABB_TREE));
			_gravity = _space.gravity;
			BBConstraintFactory.space = _space;

			// any constraints which break should go through this handler
			var constraintListener:ConstraintListener = new ConstraintListener(CbEvent.BREAK, CbType.ANY_CONSTRAINT, function (cb:ConstraintCallback):void
			{
				var data:Object = cb.constraint.userData;
				if (data && data["bb_joint"]) (data["bb_joint"] as BBJoint).dispose();
			});

			_space.listeners.add(constraintListener);

			//
			handEnable = _config.handEnable;

			//
			isUpdate = true;
		}

		/**
		 */
		override public function update(p_deltaTime:Number):void
		{
			_space.step(timeStep, velocityIterations, positionIterations);
			if (_isHandEnable) _hand.anchor1.setxy(_mouseX, _mouseY);
		}

		/**
		 * Sets gravitation.
		 */
		public function setGravity(p_x:Number, p_y:Number):void
		{
			_gravity.setxy(p_x, p_y);
			_config.getGravity().setxy(p_x, p_y);
		}

		/**
		 */
		public function getGravity():Vec2
		{
			return _gravity;
		}

		/**
		 */
		public function get space():Space
		{
			return _space;
		}

		/**
		 */
		override public function dispose():void
		{
			_space.clear();
			_space = null;

			_gravity.dispose();
			_gravity = null;
			_config = null;

			super.dispose();
		}

		//*****************//
		//*** Init hand ***//
		//*****************//

		/**
		 */
		public function set handEnable(val:Boolean):void
		{
			if (_isHandEnable == val) return;

			_isHandEnable = val;
			if (_isHandEnable) initHand();
			else deInitHand();
		}

		public function get handEnable():Boolean
		{
			return _isHandEnable;
		}

		/**
		 */
		private function initHand():void
		{
			_hand = new PivotJoint(_space.world, _space.world, Vec2.weak(), Vec2.weak());
			_hand.space = _space;
			_hand.active = false;
			_hand.stiff = false;

			_mouseModule.onDown.add(mouseDownHandler);
			_mouseModule.onUp.add(mouseUpHandler);
		}

		/**
		 */
		private function deInitHand():void
		{
			_hand.active = false;
			_hand.space = null;
			_hand = null;

			_mouseModule.onDown.remove(mouseDownHandler);
			_mouseModule.onUp.remove(mouseUpHandler);
		}

		/**
		 */
		private function mouseDownHandler(p_signal:BBSignal):void
		{
			if (_space.bodies.length < 1) return;

			_mouseModule.onMove.add(mouseMoveHandler);

			var event:BBMouseEvent = p_signal.params as BBMouseEvent;
			_mouseX = event.cameraX;
			_mouseY = event.cameraY;

			var mp:Vec2 = Vec2.get(_mouseX, _mouseY);
			var bodies:BodyList = _space.bodiesUnderPoint(mp);
			var iterator:BodyIterator = bodies.iterator();
			var body:Body;

			while (iterator.hasNext())
			{
				body = iterator.next();

				if (body.isDynamic())
				{
					var physicsComp:BBPhysicsBody = body.userData.bb_component;
					if ((physicsComp && physicsComp.allowHand) || _config.debugMode)
					{
						if (_hand.space == null) _hand.space = _space;
						_hand.body2 = body;
						_hand.anchor2.set(body.worldPointToLocal(mp, true));
						_hand.anchor1.setxy(_mouseX, _mouseY);
						_hand.active = true;
						physicsComp.handJoint = _hand;

						if (_onPickup) _onPickup.dispatch(physicsComp);

						break;
					}
				}
			}

			mp.dispose();
		}

		/**
		 */
		private function mouseMoveHandler(p_signal:BBSignal):void
		{
			var event:BBMouseEvent = p_signal.params as BBMouseEvent;
			_mouseX = event.cameraX;
			_mouseY = event.cameraY;
		}

		/**
		 */
		private function mouseUpHandler(p_signal:BBSignal):void
		{
			_mouseModule.onMove.remove(mouseMoveHandler);

			var physicsComp:BBPhysicsBody = _hand.body2.userData.bb_component;
			if (physicsComp)
			{
				physicsComp.handJoint = null;
				if (_onDrop) _onDrop.dispatch(physicsComp);
			}

			_hand.active = false;
			_hand.body2 = _space.world;
		}

		/**
		 * Sends when some physical object was picked up.
		 * Returns physical component what was picked up.
		 */
		public function get onPickUp():BBSignal
		{
			if (!_onPickup) _onPickup = BBSignal.get(this);
			return _onPickup;
		}

		/**
		 * Sends when some physical object was dropped.
		 * Returns physical component what was dropped.
		 */
		public function get onDrop():BBSignal
		{
			if (!_onDrop) _onDrop = BBSignal.get(this);
			return _onDrop;
		}
	}
}
