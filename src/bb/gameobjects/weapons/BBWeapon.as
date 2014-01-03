/**
 * User: VirtualMaestro
 * Date: 24.12.13
 * Time: 23:20
 */
package bb.gameobjects.weapons
{
	import bb.core.BBComponent;
	import bb.core.BBTransform;
	import bb.physics.BBPhysicsModule;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	/**
	 * Base class for implementation different weapons.
	 */
	public class BBWeapon extends BBComponent
	{
		protected var physicsModule:BBPhysicsModule;
		protected var transform:BBTransform;

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
			physicsModule = null;
			transform = null;
		}

		/**
		 * Invokes when components on the stage and need to init weapon.
		 */
		private function initialize(p_signal:BBSignal = null):void
		{
			physicsModule = node.tree.getModule(BBPhysicsModule) as BBPhysicsModule;
			transform = node.transform;
		}

		/**
		 * When action happens.
		 */
		public function fire():void
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
	}
}
