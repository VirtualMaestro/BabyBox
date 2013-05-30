/**
 * User: VirtualMaestro
 * Date: 02.02.13
 * Time: 13:06
 */
package src.bb.pools
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Class represents pool for native structures like Rectangle, Point...
	 */
	public class BBNativePool
	{
		////////////////////
		// RECT POOL ///////
		////////////////////

		//
		static private var _rectPool:Vector.<Rectangle> = new <Rectangle>[];
		static private var _rectPoolCounter:int = 0;

		/**
		 * Returns instance of Rectangle class.
		 */
		static public function getRect(p_x:Number = 0, p_y:Number = 0, p_width:Number = 0, p_height:Number = 0):Rectangle
		{
			var rect:Rectangle;
			if (_rectPoolCounter > 0)
			{
				rect = _rectPool[--_rectPoolCounter];
				rect.setTo(p_x, p_y, p_width, p_height);
			}
			else rect = new Rectangle(p_x, p_y, p_width, p_height);

			return rect;
		}

		/**
		 * Put Rectangle instance to pool.
		 */
		static public function putRect(p_rect:Rectangle):void
		{
			_rectPool[_rectPoolCounter++] = p_rect;
		}

		/**
		 * Clear rect pool.
		 */
		static public function ridRectPool():void
		{
			_rectPoolCounter = _rectPool.length;
			for (var i:int = 0; i < _rectPoolCounter; i++)
			{
				_rectPool[i] = null;
			}

			_rectPool.length = _rectPoolCounter = 0;
		}

		////////////////////
		// POINT POOL //////
		////////////////////

		//
		static private var _pointPool:Vector.<Point> = new <Point>[];
		static private var _pointPoolCounter:int = 0;

		/**
		 * Returns instance of Point class.
		 */
		static public function getPoint(p_x:Number = 0, p_y:Number = 0):Point
		{
			var point:Point;

			if (_pointPoolCounter > 0)
			{
				point = _pointPool[--_pointPoolCounter];
				point.setTo(p_x,  p_y);
			}
			else point = new Point(p_x, p_y);

			return point;
		}

		/**
		 * Put Point instance to pool.
		 */
		static public function putPoint(p_point:Point):void
		{
			_pointPool[_pointPoolCounter++] = p_point;
		}

		/**
		 * Returns number of Point instances in pool.
		 */
		static public function numPointsInPool():int
		{
			return _pointPoolCounter;
		}

		/**
		 * Clear Point pool.
		 */
		static public function ridPointPool():void
		{
			_pointPoolCounter = _pointPool.length;
			for (var i:int = 0; i < _pointPoolCounter; i++)
			{
				_pointPool[i] = null;
			}

			_pointPool.length = _pointPoolCounter = 0;
		}

		/**
		 * Rid all pools.
		 */
		static public function rid():void
		{
			ridRectPool();
			ridPointPool();
		}
	}
}
