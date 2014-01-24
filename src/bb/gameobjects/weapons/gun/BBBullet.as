/**
 * User: VirtualMaestro
 * Date: 09.01.14
 * Time: 15:54
 */
package bb.gameobjects.weapons.gun
{
	import bb.bb_spaces.bb_private;

	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;
	import nape.shape.Shape;

	use namespace bb_private;

	/**
	 * Bullet data holder for BBGun.
	 */
	public class BBBullet
	{
		static private const PI4:Number = 6.283185 * 2;

		bb_private var shouldRemove:Boolean = false;

		// for list
		bb_private var next:BBBullet;
		bb_private var prev:BBBullet;

		/**
		 */
		bb_private var passedDistance:Number = 0;

		/**
		 */
		bb_private var lastShape:Shape;

		/**
		 * Mass of bullet in grams.
		 * Must be greater then 0.
		 */
		public var mass:Number = 7.0;

		/**
		 * Speed of bullet - meter/second.
		 * If need to know how much it in pixels just multiply by 10.
		 * (so if speed is 500 meter/second in pixels it is 5000 pixels/second).
		 */
		public var speed:Number = 500;

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
		 * Bullet position at the moment.
		 */
		public var currentPosition:Vec2;

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
		 * If true impact make influence on the bullet. Bullet behaves more realistic but for that need more computation.
		 * Work if 'multiAims' is true.
		 */
		public var impactObstacles:Boolean = false;

		/**
		 * Filter for aims.
		 */
		public var filter:InteractionFilter = null;

		/**
		 * Callback of bullet action result.
		 * Callback should take as parameter Vector of BBFireResult instance (Vector.<BBFireResult>).
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
		public function BBBullet(p_mass:Number = 7.0, p_speed:Number = 500, p_radiusTip:Number = 3, p_multiAims:Boolean = false,
		                         p_impactObstacles:Boolean = false, p_filter:InteractionFilter = null)
		{
			mass = p_mass;
			speed = p_speed;
			radiusTip = p_radiusTip;
			multiAims = p_multiAims;
			impactObstacles = p_impactObstacles;
			filter = p_filter;
			origin = Vec2.get();
			direction = Vec2.get(1, 0);
			currentPosition = Vec2.get();
		}

		/**
		 */
		bb_private function get energy():Number
		{
			return (mass * speed * speed) / (PI4 * radiusTip);
		}

		/**
		 */
		bb_private function set energy(p_val:Number):void
		{
			speed = p_val > 0 ? Math.sqrt((p_val * PI4 * radiusTip) / mass) : 0;
		}

		/**
		 * Makes of copy of current bullet instance.
		 */
		public function copy():BBBullet
		{
			var bullet:BBBullet = BBBullet.get(mass, speed, radiusTip, multiAims, impactObstacles, filter);
			bullet.origin.set(origin);
			bullet.direction.set(direction);
			bullet.currentPosition.set(currentPosition);

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

			currentPosition.dispose();
			currentPosition = null;

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
		static public function get(p_mass:Number = 7.0, p_speed:Number = 500, p_radiusTip:Number = 3, p_multiAims:Boolean = false,
		                           p_impactObstacles:Boolean = false, p_filter:InteractionFilter = null):BBBullet
		{
			var bullet:BBBullet;

			if (_count > 0)
			{
				bullet = _pool[--_count];
				bullet.mass = p_mass;
				bullet.speed = p_speed;
				bullet.radiusTip = p_radiusTip;
				bullet.multiAims = p_multiAims;
				bullet.impactObstacles = p_impactObstacles;
				bullet.filter = p_filter;
				bullet.origin = Vec2.get();
				bullet.direction = Vec2.get(1, 0);
				bullet.currentPosition = Vec2.get();
				bullet.passedDistance = 0;
				bullet.elapsedTime = 0;

				bullet.shouldRemove = false;
				bullet._isDisposed = false;
			}
			else bullet = new BBBullet(p_mass, p_speed, p_radiusTip, p_multiAims, p_impactObstacles, p_filter);

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
