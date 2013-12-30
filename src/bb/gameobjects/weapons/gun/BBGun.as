/**
 * User: VirtualMaestro
 * Date: 25.12.13
 * Time: 20:34
 */
package bb.gameobjects.weapons.gun
{
	import bb.gameobjects.weapons.BBWeapon;

	import flash.utils.getTimer;

	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.Vec2;

	/**
	 * Implements gun functionality (gun, machine gun...).
	 */
	public class BBGun extends BBWeapon
	{
		protected var fireDistance:Number = 300;
		protected var fireRate:Number = 1; // num bullets per second

		private var _multiAims:Boolean = false;

		private var _fireRateTimeCollector:int = 0;
		private var _prevTime:int = 0;

		/**
		 */
		public function BBGun()
		{
			super();
		}

		/**
		 */
		override public function fire():void
		{
			var currentTime:int = getTimer();
			_fireRateTimeCollector = currentTime - _prevTime;

			// can fire
			if (_fireRateTimeCollector >= 1000 / fireRate)
			{
				_fireRateTimeCollector = 0;

				//
				if (_multiAims)
				{

				}
				else
				{
					var startPos:Vec2 = transform.getPositionWorld();
					var endPos:Vec2 = direction.muleq(fireDistance).addeq(startPos);
					var result:RayResult = physicsModule.space.rayCast(Ray.fromSegment(startPos, endPos));
//					result.
				}
			}

			_prevTime = currentTime;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{

		}
	}
}
