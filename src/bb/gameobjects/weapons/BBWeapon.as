/**
 * User: VirtualMaestro
 * Date: 24.12.13
 * Time: 23:20
 */
package bb.gameobjects.weapons
{
	import bb.bb_spaces.bb_private;
	import bb.core.BBComponent;
	import bb.core.BBTransform;
	import bb.physics.BBPhysicsModule;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	use namespace bb_private;

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

			onAdded.add(addedToNodeHandler);
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			if (node.isOnStage) init();
			else node.onAdded.add(addedToNodeHandler);
		}

		/**
		 * Invokes when components on the stage and need to init weapon.
		 */
		private function init():void
		{
			physicsModule = node.z_core.getModule(BBPhysicsModule) as BBPhysicsModule;
			transform = node.transform;
		}

		/**
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
	}
}
