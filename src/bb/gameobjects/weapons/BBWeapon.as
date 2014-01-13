/**
 * User: VirtualMaestro
 * Date: 24.12.13
 * Time: 23:20
 */
package bb.gameobjects.weapons
{
	import bb.core.BBComponent;
	import bb.core.BBTransform;
	import bb.signals.BBSignal;

	import flash.utils.getTimer;

	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;

	/**
	 * Base class for implementation different weapons.
	 */
	public class BBWeapon extends BBComponent
	{
		public var filter:InteractionFilter;

		protected var weaponModule:BBWeaponModule;
		protected var transform:BBTransform;

		private var _fireRate:Number = 1; // num fires per second

		private var _fireRateTimeCollector:int = 0;
		private var _prevTime:int = 0;

		/**
		 */
		public function BBWeapon()
		{
			super();
		}

		/**
		 */
		override protected function init():void
		{
			onAdded.add(addedToNodeHandler);
			onRemoved.add(removedFromNodeHandler);
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			if (node.isOnStage) initialize();
			else node.onAddedToStage.add(initialize);
		}

		/**
		 */
		private function removedFromNodeHandler(p_signal:BBSignal):void
		{
			node.onAddedToStage.remove(initialize);
			weaponModule = null;
			transform = null;
		}

		/**
		 * Invokes when components on the stage and need to init weapon.
		 */
		private function initialize(p_signal:BBSignal = null):void
		{
			weaponModule = node.tree.getModule(BBWeaponModule) as BBWeaponModule;
			if (!weaponModule) weaponModule = node.tree.addModule(BBWeaponModule, true) as BBWeaponModule;

			transform = node.transform;
		}

		/**
		 * Weapon starts shooting.
		 * For implementation specific fire logic should to override of fireAction method.
		 */
		final public function fire():void
		{
			var currentTime:int = getTimer();
			_fireRateTimeCollector += currentTime - _prevTime;

			// can fire
			if (_fireRateTimeCollector > 999 / _fireRate)
			{
				_fireRateTimeCollector = 0;

				fireAction();
			}

			_prevTime = currentTime;
		}

		/**
		 * Where happens concrete implementation of fire action.
		 * That logic should be override in children.
		 */
		protected function fireAction():void
		{
			// override in children
		}

		/**
		 * Returns direction of current gun.
		 */
		[Inline]
		final protected function get direction():Vec2
		{
			var parentPos:Vec2 = node.parent.transform.getPositionWorld();
			var pos:Vec2 = transform.getPositionWorld();
			var dir:Vec2 = pos.sub(parentPos);
			dir.length = 1;

			return dir;
		}

		/**
		 */
		override protected function destroy():void
		{
			// my code

			//
			super.destroy();
		}

		/**
		 */
		override protected function rid():void
		{
			// my code

			//
			super.rid();
		}

		/**
		 */
		public function get fireRate():Number
		{
			return _fireRate;
		}

		public function set fireRate(p_value:Number):void
		{
			_fireRate = p_value < 1 ? 1 : p_value;
		}
	}
}
