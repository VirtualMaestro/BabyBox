/**
 * User: VirtualMaestro
 * Date: 17.01.14
 * Time: 23:58
 */
package bb.gameobjects
{
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.core.BBTransform;
	import bb.signals.BBSignal;

	import nape.geom.Vec2;

	/**
	 *
	 */
	public class BBRotatorComponent extends BBComponent
	{
		public var accurate:Number = 0;
		public var angularVelocity:Number = 30 * Math.PI / 180.0; // rad per sec

		private var _onStart:BBSignal;
		private var _onComplete:BBSignal;

		private var _transform:BBTransform;

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
			var selfRotation:Number = _transform.rotationWorld;
			var aimAngle:Number = Math.atan2(p_y - selfPosition.y, p_x - selfPosition.x);
//			_transform.rotation = aimAngle;

//			aimAngle -= _transform.rotationWorld;
//			_transform.shiftRotation = -aimAngle;

			trace("BEFORE rad: " + aimAngle + " grad: " + (aimAngle * 180.0 / Math.PI));

			aimAngle = aimAngle < 0 ? (2 * Math.PI + aimAngle) : aimAngle;
			selfRotation = selfRotation < 0 ? (2 * Math.PI + selfRotation) : selfRotation;
			trace("AFTER rad: " + aimAngle + " grad: " + (aimAngle * 180.0 / Math.PI));

			aimAngle -= selfRotation;

			trace("DIFF rad: " + aimAngle + " grad: " + (aimAngle * 180.0 / Math.PI));

			_transform.shiftRotation = aimAngle;

		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{

		}

		/**
		 */
		override protected function destroy():void
		{
			_transform = null;

			super.destroy();
		}
	}
}
