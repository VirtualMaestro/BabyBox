/**
 * User: VirtualMaestro
 * Date: 02.02.13
 * Time: 13:06
 */
package bb.pools
{
	import flash.geom.Matrix;
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
		static private var _rectPool:Vector.<Rectangle>;
		static private var _rectSize:int = 0;

		/**
		 * Returns instance of Rectangle class.
		 */
		static public function getRect(p_x:Number = 0, p_y:Number = 0, p_width:Number = 0, p_height:Number = 0):Rectangle
		{
			var rect:Rectangle;
			if (_rectSize > 0)
			{
				rect = _rectPool[--_rectSize];
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
			if (_rectPool == null) _rectPool = new <Rectangle>[];
			_rectPool[_rectSize++] = p_rect;
		}

		/**
		 * Returns number of Rectangle instances in pool.
		 */
		static public function sizeRects():int
		{
			return _rectSize;
		}

		/**
		 * Clear rect pool.
		 */
		static public function ridRectPool():void
		{
			if (_rectPool)
			{
				_rectSize = _rectPool.length;
				for (var i:int = 0; i < _rectSize; i++)
				{
					_rectPool[i] = null;
				}

				_rectPool.length = _rectSize = 0;
				_rectPool = null;
			}
		}

		////////////////////
		// POINT POOL //////
		////////////////////

		//
		static private var _pointPool:Vector.<Point>;
		static private var _pointSize:int = 0;

		/**
		 * Returns instance of Point class.
		 */
		static public function getPoint(p_x:Number = 0, p_y:Number = 0):Point
		{
			var point:Point;

			if (_pointSize > 0)
			{
				point = _pointPool[--_pointSize];
				point.setTo(p_x, p_y);
			}
			else point = new Point(p_x, p_y);

			return point;
		}

		/**
		 * Put Point instance to pool.
		 */
		static public function putPoint(p_point:Point):void
		{
			if (_pointPool == null) _pointPool = new <Point>[];
			_pointPool[_pointSize++] = p_point;
		}

		/**
		 * Returns number of Point instances in pool.
		 */
		static public function sizePoints():int
		{
			return _pointSize;
		}

		/**
		 * Clear Point pool.
		 */
		static public function ridPointPool():void
		{
			if (_pointPool)
			{
				_pointSize = _pointPool.length;
				for (var i:int = 0; i < _pointSize; i++)
				{
					_pointPool[i] = null;
				}

				_pointPool.length = _pointSize = 0;
				_pointPool = null;
			}
		}

		/////////////////
		// MATRIX POOL //
		/////////////////

		//
		static private var _matrixPool:Vector.<Matrix>;
		static private var _matrixSize:int = 0;

		/**
		 * Returns instance of Matrix class.
		 */
		static public function getMatrix():Matrix
		{
			var matrix:Matrix;

			if (_matrixSize > 0)
			{
				matrix = _matrixPool[--_matrixSize];
				matrix.identity();
			}
			else matrix = new Matrix();

			return matrix;
		}

		/**
		 * Put Matrix instance to pool.
		 */
		static public function putMatrix(p_matrix:Matrix):void
		{
			if (_matrixPool == null) _matrixPool = new <Matrix>[];
			_matrixPool[_matrixSize++] = p_matrix;
		}

		/**
		 * Returns number of Matrix instances in pool.
		 */
		static public function sizeMatrices():int
		{
			return _matrixSize;
		}

		/**
		 * Clear Matrix pool.
		 */
		static public function ridMatrixPool():void
		{
			if (_matrixPool)
			{
				_matrixSize = _matrixPool.length;
				for (var i:int = 0; i < _matrixSize; i++)
				{
					_matrixPool[i] = null;
				}

				_matrixPool.length = _matrixSize = 0;
				_matrixPool = null;
			}
		}

		/**
		 * Rid all pools.
		 */
		static public function rid():void
		{
			ridRectPool();
			ridPointPool();
			ridMatrixPool();
		}
	}
}
