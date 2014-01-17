/**
 * User: VirtualMaestro
 * Date: 01.03.13
 * Time: 17:54
 */
package bb.physics
{
	import bb.bb_spaces.bb_private;
	import bb.config.BBConfig;
	import bb.core.BabyBox;
	import bb.modules.BBModule;
	import bb.mouse.BBMouseModule;
	import bb.mouse.events.BBMouseEvent;
	import bb.physics.components.BBPhysicsBody;
	import bb.physics.joints.BBJoint;
	import bb.physics.joints.BBJointFactory;
	import bb.signals.BBSignal;

	import nape.callbacks.BodyCallback;
	import nape.callbacks.BodyListener;
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

		private var _constraintListener:ConstraintListener;
		private var _sleepListener:BodyListener;
		private var _wakeListener:BodyListener;

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
			BBJointFactory.space = _space;

			// any constraints which break should go through this handler
			_space.listeners.add(getConstraintListener());

			// add event for sleep and wake up
			if (_config.canSleep)
			{
				_space.listeners.add(getSleepListener());
				_space.listeners.add(getWakeListener());
			}

			//
			handEnable = _config.handEnable;

			//
			updateEnable = true;
		}

		/**
		 */
		private function getConstraintListener():ConstraintListener
		{
			if (_constraintListener == null) _constraintListener = new ConstraintListener(CbEvent.BREAK, CbType.ANY_CONSTRAINT, constraintHandler);
			return _constraintListener;
		}

		/**
		 */
		static private function constraintHandler(cb:ConstraintCallback):void
		{
			var data:Object = cb.constraint.userData;
			if (data && data["bb_joint"])
			{
				(data["bb_joint"] as BBJoint).dispose();
			}
		}

		/**
		 */
		private function getSleepListener():BodyListener
		{
			if (_sleepListener == null) _sleepListener = new BodyListener(CbEvent.SLEEP, CbType.ANY_BODY, sleepHandler);
			return _sleepListener;
		}

		/**
		 */
		static private function sleepHandler(cb:BodyCallback):void
		{
			var physComponent:BBPhysicsBody = cb.body.userData.bb_component;
			if (physComponent) physComponent.sleep = true;
		}

		/**
		 */
		private function getWakeListener():BodyListener
		{
			if (_wakeListener == null) _wakeListener = new BodyListener(CbEvent.WAKE, CbType.ANY_BODY, wakeHandler);
			return _wakeListener;
		}

		/**
		 */
		static private function wakeHandler(cb:BodyCallback):void
		{
			var physComponent:BBPhysicsBody = cb.body.userData.bb_component;
			if (physComponent) physComponent.sleep = false;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			_space.step(timeStep, velocityIterations, positionIterations);

			if (_isHandEnable)
			{
				_hand.anchor1.setxy(_mouseX, _mouseY);
			}
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
			_mouseX = event.worldX;
			_mouseY = event.worldY;

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
			_mouseX = event.worldX;
			_mouseY = event.worldY;
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
