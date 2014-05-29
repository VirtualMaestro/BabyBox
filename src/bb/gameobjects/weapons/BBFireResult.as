/**
 * User: VirtualMaestro
 * Date: 16.01.14
 * Time: 16:41
 */
package bb.gameobjects.weapons
{
	import bb.bb_spaces.bb_private;
	import bb.gameobjects.weapons.gun.BBBullet;
	import bb.physics.components.BBPhysicsBody;

	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import nape.shape.Shape;

	import vm.ds.api.BBNodeList;

	use namespace bb_private;

	/**
	 *
	 */
	public class BBFireResult
	{
		bb_private var rayResult:RayResult;
		bb_private var bullet:BBBullet;
		bb_private var stackNode:BBNodeList;

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
		 * Speed of the bullet when it exits the shape.
		 */
		public var outSpeed:Number = 0;

		/**
		 * Contact point of first intersection (e.g. point of input bullet in shape).
		 */
		public var inContact:Vec2;

		/**
		 * Distance from 'origin' to 'inContact' point.
		 */
		public var inContactDistance:Number = 0;

		/**
		 * Speed of the bullet when it enters the shape.
		 */
		public var inSpeed:Number = 0;

		/**
		 * Spent bullet's energy for that shape.
		 */
		public var energy:Number = 0;

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
		 * Returns shape name if it exist.
		 * If shape hasn't name returns empty string.
		 */
		public function get shapeName():String
		{
			return rayResult.shape.userData.shapeName;
		}

		/**
		 * Returns BBPhysicsBody component to which that shape belongs.
		 */
		public function get component():BBPhysicsBody
		{
			return rayResult.shape.body.userData.bb_component as BBPhysicsBody;
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
				stackNode = null;

				inContact.dispose();
				inContact = null;

				if (outContact)
				{
					outContact.dispose();
					outContact = null;
				}

				inContactDistance = 0;
				inSpeed = 0;
				outContactDistance = 0;
				outSpeed = 0;
				energy = 0;

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
