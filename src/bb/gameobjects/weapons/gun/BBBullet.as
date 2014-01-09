/**
 * User: VirtualMaestro
 * Date: 09.01.14
 * Time: 15:54
 */
package bb.gameobjects.weapons.gun
{
	/**
	 * Bullet data holder for BBGun.
	 */
	public class BBBullet
	{
		static private const PI2:Number = 6.283185;

		/**
		 * Mass of bullet in grams.
		 * Must be greater then 0.
		 */
		public var mass:Number = 7.0;

		/**
		 * Speed of bullet - meter/second.
		 */
		public var speed:Number = 400;

		/**
		 * Radius of tip of bullet.
		 * Less radius greater power.
		 */
		public var radiusTip:Number = 3;

		/**
		 */
		public function BBBullet()
		{
		}

		/**
		 */
		public function update(p_timeStep:Number):void
		{
			var energy:Number = ((mass * speed * speed) / 2) / (PI2 * radiusTip);
		}
	}
}
