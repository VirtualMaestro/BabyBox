/**
 * User: VirtualMaestro
 * Date: 25.12.13
 * Time: 20:34
 */
package bb.gameobjects.weapons.gun
{
	import bb.core.BBComponent;
	import bb.core.BBNode;
	import bb.gameobjects.weapons.BBWeapon;

	import nape.geom.Vec2;

	/**
	 * Implements gun functionality (gun, machine gun...).
	 */
	public class BBGun extends BBWeapon
	{
		public var callbackResult:Function = null;
		public var impactObstacles:Boolean = false;
		public var multiAims:Boolean = false;
		public var barrelLength:Number = 0;

		private var _fireDistance:Number = 1000;

		private var _etalonBullet:BBBullet;

		/**
		 */
		public function BBGun()
		{
			super();
		}

		/**
		 */
		override protected function init():void
		{
			super.init();

			setupBullet();
		}

		/**
		 * Implementation of fire action for gun.
		 */
		override protected function fireAction():void
		{
			var direction:Vec2 = transform.directionWorld;
			var position:Vec2 = transform.getPositionWorld();
			var bullet:BBBullet = _etalonBullet.copy();

			if (barrelLength > 0)
			{
				var x:Number = direction.x * barrelLength + position.x;
				var y:Number = direction.y * barrelLength + position.y;

				bullet.origin.setxy(x, y);
			}
			else bullet.origin.set(position);

			bullet.currentPosition.set(bullet.origin);
			bullet.direction.set(direction);
			bullet.fireDistance = _fireDistance;
			bullet.multiAims = multiAims;
			bullet.impactObstacles = impactObstacles;
			bullet.filter = filter;
			bullet.callbackResult = callbackResult;

			weaponModule.addBullet(bullet);
		}

		/**
		 * Init parameters which will has bullet that used by this gun.
		 * p_mass - mass of bullet (in grams).
		 * p_speed - speed of bullet (meter/second).
		 * p_radiusTip - radius of the tip of bullet (millimeters).
		 */
		public function setupBullet(p_mass:Number = 7.0, p_speed:Number = 400, p_radiusTip:Number = 3.0):void
		{
			if (!_etalonBullet) _etalonBullet = BBBullet.get(p_mass, p_speed, p_radiusTip);
			else
			{
				_etalonBullet.mass = p_mass;
				_etalonBullet.speed = p_speed;
				_etalonBullet.radiusTip = p_radiusTip;
			}
		}

		/**
		 */
		override protected function destroy():void
		{
			if (_etalonBullet)
			{
				_etalonBullet.dispose();
				_etalonBullet = null;
			}

			super.destroy();
		}

		/**
		 */
		public function get fireDistance():Number
		{
			return _fireDistance;
		}

		/**
		 * Max distance for fire range in pixels.
		 * Min possible value is 1. By default 1000.
		 */
		public function set fireDistance(p_value:Number):void
		{
			_fireDistance = p_value < 1 ? 1 : p_value;
		}

		///

		/**
		 * Return instance of gun.
		 */
		static public function get(p_barrelLength:int = 0, p_multiAims:Boolean = false, p_impactObstacles:Boolean = false,
		                           p_callbackFireResult:Function = null):BBGun
		{
			var gun:BBGun = BBComponent.get(BBGun) as BBGun;
			gun.barrelLength = p_barrelLength;
			gun.multiAims = p_multiAims;
			gun.impactObstacles = p_impactObstacles;
			gun.callbackResult = p_callbackFireResult;

			return gun;
		}

		/**
		 * Returns gun instance added to node.
		 */
		static public function getWithNode(p_nodeName:String = "", p_barrelLength:int = 0, p_multiAims:Boolean = false, p_impactObstacles:Boolean = false,
		                                   p_callbackFireResult:Function = null):BBGun
		{
			return BBNode.get(p_nodeName).addComponent(get(p_barrelLength, p_multiAims, p_impactObstacles, p_callbackFireResult)) as BBGun;
		}
	}
}
