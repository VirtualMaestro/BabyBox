/**
 * User: VirtualMaestro
 * Date: 16.01.14
 * Time: 16:41
 */
package bb.gameobjects.weapons
{
	import bb.bb_spaces.bb_private;
	import bb.gameobjects.weapons.gun.BBBullet;

	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import nape.shape.Shape;

	use namespace bb_private;

	/**
	 *
	 */
	public class BBFireResult
	{
		bb_private var rayResult:RayResult;
		bb_private var bullet:BBBullet;

		/**
		 * Second output contact if it exist (e.g. point output from shape).
		 * Could be null;
		 */
		public var outContact:Vec2;

		/**
		 * Distance from 'origin' to 'outContact' point.
		 */
		public var outContactDistance:Number = 0;

		/**
		 * How deep bullet penetrate in body.
		 * Works if bullet's prop 'impactObstacles' is true.
		 * Range from 0 to 1, 1 - bullet fully went through body.
		 * If 'impactObstacles' is false value always is 1.
		 */
		public var penetration:Number = 1;

		/**
		 * Contact point of first intersection (e.g. point of input bullet in shape).
		 */
		public var inContact:Vec2;

		/**
		 * Distance from 'origin' to 'inContact' point.
		 */
		public var inContactDistance:Number = 0;

		//
		private var _isDisposed:Boolean = false;

		/**
		 * Intersected shape.
		 */
		public function get shape():Shape
		{
			return rayResult.shape;
		}

		/**
		 * Disposes instance.
		 */
		public function dispose():void
		{
			if (!_isDisposed)
			{
				_isDisposed = true;

				rayResult.dispose();
				rayResult = null;

				bullet = null;

				inContact.dispose();
				inContact = null;

				if (outContact)
				{
					outContact.dispose();
					outContact = null;
				}

				inContactDistance = 0;
				outContactDistance = 0;
				penetration = 1;

				put(this);
			}
		}

		/////////////////
		/// POOL ////////
		/////////////////

		static private var _pool:Vector.<BBFireResult>;
		static private var _count:int = 0;

		/**
		 */
		static public function get():BBFireResult
		{
			var result:BBFireResult;

			if (_count > 0)
			{
				result = _pool[--_count];
				result._isDisposed = false;
			}
			else result = new BBFireResult();

			return result;
		}

		/**
		 */
		static private function put(p_fireResult:BBFireResult):void
		{
			if (!_pool) _pool = new <BBFireResult>[];

			_pool[_count++] = p_fireResult;
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
