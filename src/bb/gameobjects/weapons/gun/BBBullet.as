/**
 * User: VirtualMaestro
 * Date: 09.01.14
 * Time: 15:54
 */
package bb.gameobjects.weapons.gun
{
	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;

	/**
	 * Bullet data holder for BBGun.
	 */
	public class BBBullet
	{
		static private const PI2:Number = 6.283185;

		// for list
		public var next:BBBullet;
		public var prev:BBBullet;

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
		 * Start bullet position.
		 * Sets by engine.
		 */
		public var origin:Vec2;

		/**
		 * Vector of direction of bullet.
		 */
		public var direction:Vec2;

		/**
		 * Max distance of fire.
		 */
		public var fireDistance:Number;

		/**
		 * If bullet should impact multi aims.
		 */
		public var multiAims:Boolean = false;

		/**
		 * Bullet impact dependent from time.
		 */
		public var influenceTime:Boolean = false;

		/**
		 * Filter for aims.
		 */
		public var filter:InteractionFilter = null;

		/**
		 * Callback of bullet action result.
		 * TODO: What have to set as parameter.
		 */
		public var callbackResult:Function = null;

		/**
		 * Sets by engine. Need when disposing.
		 */
		public var removeFromList:Function;

		/**
		 * Time what elapsed when bullet started (in milliseconds).
		 */
		public var elapsedTime:int = 0;

		/**
		 */
		private var _isDisposed:Boolean = false;

		/**
		 */
		public function BBBullet(p_mass:Number = 7.0, p_speed:Number = 400, p_radiusTip:Number = 3, p_multiAims:Boolean = false,
		                         p_influenceTime:Boolean = false, p_filter:InteractionFilter = null)
		{
			mass = p_mass;
			speed = p_speed;
			radiusTip = p_radiusTip;
			multiAims = p_multiAims;
			influenceTime = p_influenceTime;
			filter = p_filter;
			origin = Vec2.get();
			direction = Vec2.get(1, 0);
		}

		/**
		 */
		public function get energy():Number
		{
			return ((mass * speed * speed) / 2) / (PI2 * radiusTip);
		}

		/**
		 * Makes of copy of current bullet instance.
		 */
		public function copy():BBBullet
		{
			var bullet:BBBullet = BBBullet.get(mass, speed, radiusTip, multiAims, influenceTime, filter);
			bullet.origin.set(origin);
			bullet.direction.set(direction);

			return bullet;
		}

		/**
		 * Dispose the bullet.
		 */
		public function dispose():void
		{
			if (_isDisposed) return;
			_isDisposed = true;

			if (removeFromList)
			{
				removeFromList(this);
				removeFromList = null;
			}

			origin.dispose();
			origin = null;

			direction.dispose();
			direction = null;

			filter = null;

			next = prev = null;

			put(this);
		}

		/////////////////
		/// POOL ////////
		/////////////////

		static private var _pool:Vector.<BBBullet>;
		static private var _count:int = 0;

		/**
		 */
		static public function get(p_mass:Number = 7.0, p_speed:Number = 400, p_radiusTip:Number = 3, p_multiAims:Boolean = false,
		                           p_influenceTime:Boolean = false, p_filter:InteractionFilter = null):BBBullet
		{
			var bullet:BBBullet;

			if (_count > 0)
			{
				bullet = _pool[--_count];
				bullet.mass = p_mass;
				bullet.speed = p_speed;
				bullet.radiusTip = p_radiusTip;
				bullet.multiAims = p_multiAims;
				bullet.influenceTime = p_influenceTime;
				bullet.filter = p_filter;
				bullet.origin = Vec2.get();
				bullet.direction = Vec2.get();
				bullet.elapsedTime = 0;

				bullet._isDisposed = false;
			}
			else bullet = new BBBullet(p_mass, p_speed, p_radiusTip, p_multiAims, p_influenceTime, p_filter);

			return bullet;
		}

		/**
		 */
		static private function put(p_bullet:BBBullet):void
		{
			if (!_pool) _pool = new <BBBullet>[];

			_pool[_count++] = p_bullet;
		}

		/**
		 * Clear pool.
		 */
		static public function rid():void
		{
			if (_pool)
			{
				var num:int = _pool.length;

				for (var i:int = 0; i < num; i++)
				{
					_pool[i] = null;
				}

				_pool.length = 0;
				_pool = null;
			}
		}
	}
}
