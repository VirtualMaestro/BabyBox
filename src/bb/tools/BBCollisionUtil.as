/**
 * Date: 13.10.2013
 * Author: VirtualMaestro
 */
package bb.tools
{
	import nape.geom.Vec2;
	import nape.geom.Vec2Iterator;
	import nape.geom.Vec2List;
	import nape.geom.Vec3;
	import nape.shape.Shape;

	/**
	 * Collision algorithms adapted for Nape's data structures.
	 */
	public class BBCollisionUtil
	{
		// ************************************* //
		// ******* GET INTERSECTION ************ //
		// ************************************* //

		/**
		 * Returns point of the intersection of two lines.
		 * If returned null mean lines overlap or parallel.
		 */
		static public function getIntersectionLineToLine(p_startLine1:Vec2, p_endLine1:Vec2, p_startLine2:Vec2, p_endLine2:Vec2):Vec2
		{
			var p1x:Number = p_startLine1.x;
			var p1y:Number = p_startLine1.y;
			var p2x:Number = p_endLine1.x;
			var p2y:Number = p_endLine1.y;
			var p3x:Number = p_startLine2.x;
			var p3y:Number = p_startLine2.y;
			var p4x:Number = p_endLine2.x;
			var p4y:Number = p_endLine2.y;

			var p1xSp2x:Number = p1x - p2x;
			var p1ySp2y:Number = p1y - p2y;
			var p1xSp3x:Number = p1x - p3x;
			var p1ySp3y:Number = p1y - p3y;
			var p4xSp3x:Number = p4x - p3x;
			var p4ySp3y:Number = p4y - p3y;

			var d:Number = p1xSp2x * p4ySp3y - p1ySp2y * p4xSp3x;
			var da:Number = p1xSp3x * p4ySp3y - p1ySp3y * p4xSp3x;
			var db:Number = p1xSp2x * p1ySp3y - p1ySp2y * p1xSp3x;

			if (da == 0 || db == 0 || d == 0) return null;  // lines overlap or parallel

			var ta:Number = da / d;
			var tb:Number = db / d;

			if (ta >= 0)
			{
				if (ta <= 1)
				{
					if (tb >= 0)
					{
						if (tb <= 1)
						{
							var dx:Number = p1x + ta * (p2x - p1x);
							var dy:Number = p1y + ta * (p2y - p1y);

							return Vec2.get(dx, dy);
						}
					}
				}
			}

			return null;
		}

		/**
		 * Returns array with points of intersection line with circle.
		 * There are possible two results:
		 *  - returns null if there is no intersection.
		 *  - returns array with one or two points. First point - first nearest intersection, second - farther second intersection.
		 *
		 * If 'isRay' is true, then line means ray. This is mean if line isn't reach the circle it is prolonged like a ray.
		 * If ray is touched the circle, result returns like two identical points.
		 * When 'isRay' false, method works faster.
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getIntersectionLineToCircle(p_startLine:Vec2, p_endLine:Vec2, p_circlePosition:Vec2, p_radius:Number,
		                                                   p_isRay:Boolean = false):Vector.<Vec2>
		{
			var slX:Number = p_startLine.x;
			var slY:Number = p_startLine.y;
			var elX:Number = p_endLine.x;
			var elY:Number = p_endLine.y;
			var cX:Number = p_circlePosition.x;
			var cY:Number = p_circlePosition.y;
			var x1:Number = slX - cX;
			var y1:Number = slY - cY;
			var x2:Number = elX - cX;
			var y2:Number = elY - cY;

			var result:Vector.<Vec2> = null;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			//
			var a:Number = dx * dx + dy * dy;
			var a2:Number = a * 2;
			var b:Number = (x1 * dx + y1 * dy) * 2;
			var c:Number = x1 * x1 + y1 * y1 - p_radius * p_radius;
			var discriminant:Number = b * b - 2 * a2 * c;

			if (discriminant >= 0)
			{
				if ((dx + dy) == 0) return new <Vec2>[Vec2.get(cX, cY)];

				var firstPoint:Vec2;
				var secondPoint:Vec2;
				var min:Number;
				var max:Number;

				discriminant = Math.sqrt(discriminant);

				var t1:Number = (-b + discriminant) / a2;
				var t2:Number = (-b - discriminant) / a2;

				//
				if (p_isRay)
				{
					if (t1 < t2)
					{
						min = t1;
						max = t2;
					}
					else
					{
						min = t2;
						max = t1;
					}

					firstPoint = Vec2.get(((elX - slX) * min + slX), ((elY - slY) * min + slY));
					secondPoint = Vec2.get(((elX - slX) * max + slX), ((elY - slY) * max + slY));
					result = new <Vec2>[firstPoint, secondPoint];
				}
				else
				{
					var isSolutionT1:Boolean = false;
					var isSolutionT2:Boolean = false;

					if (t1 >= 0)
					{
						if (t1 < 1.0000001) isSolutionT1 = true;
					}

					if (t2 >= 0)
					{
						if (t2 < 1.0000001) isSolutionT2 = true;
					}

					//
					if (isSolutionT1 || isSolutionT2)
					{
						if (isSolutionT1 && isSolutionT2)
						{
							if (t1 < t2)
							{
								min = t1;
								max = t2;
							}
							else
							{
								min = t2;
								max = t1;
							}

							firstPoint = Vec2.get(((elX - slX) * min + slX), ((elY - slY) * min + slY));
							secondPoint = Vec2.get(((elX - slX) * max + slX), ((elY - slY) * max + slY));
							result = new <Vec2>[firstPoint, secondPoint];
						}
						else
						{
							min = isSolutionT1 ? t1 : t2;
							firstPoint = Vec2.get(((elX - slX) * min + slX), ((elY - slY) * min + slY));
							result = new <Vec2>[firstPoint];
						}
					}
				}
			}

			return result;
		}

		/**
		 * Returns point of intersection ray with circle.
		 * Method works like 'getIntersectionLineToCircle' method with property 'isRay' set to true.
		 * Difference in that method determines and returns just first point of intersection,
		 * thanks to this method works in 2.5 times faster then 'getIntersectionLineToCircle'.
		 */
		static public function getIntersectionRayToCircle(p_startLine:Vec2, p_endLine:Vec2, p_circlePosition:Vec2, p_radius:Number):Vec2
		{
			var slX:Number = p_startLine.x;
			var slY:Number = p_startLine.y;
			var elX:Number = p_endLine.x;
			var elY:Number = p_endLine.y;
			var cX:Number = p_circlePosition.x;
			var cY:Number = p_circlePosition.y;
			var x1:Number = slX - cX;
			var y1:Number = slY - cY;
			var x2:Number = elX - cX;
			var y2:Number = elY - cY;

			var result:Vec2 = null;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			//
			var a:Number = dx * dx + dy * dy;
			var a2:Number = a * 2;
			var b:Number = (x1 * dx + y1 * dy) * 2;
			var c:Number = x1 * x1 + y1 * y1 - p_radius * p_radius;
			var discriminant:Number = b * b - 2 * a2 * c;

			if (discriminant >= 0)
			{
				if ((dx + dy) == 0) return Vec2.get(cX, cY);

				discriminant = Math.sqrt(discriminant);

				var t1:Number = (-b + discriminant) / a2;
				var t2:Number = (-b - discriminant) / a2;
				var min:Number = (t1 < t2) ? t1 : t2;

				result = Vec2.get(((elX - slX) * min + slX), ((elY - slY) * min + slY));
			}

			return result;
		}

		/**
		 * Returns point of intersection of two rays.
		 * If 'isBothWay' is true, mean that intersection searching not only in the way of ray but also in the opposite direction.
		 */
		static public function getIntersectionRayToRay(p_ray1Start:Vec2, p_ray1End:Vec2, p_ray2Start:Vec2, p_ray2End:Vec2, p_isBothWay:Boolean = false):Vec2
		{
			var r:Number, s:Number, d:Number;
			var x1:Number = p_ray1Start.x;
			var y1:Number = p_ray1Start.y;
			var x2:Number = p_ray1End.x;
			var y2:Number = p_ray1End.y;
			var x3:Number = p_ray2Start.x;
			var y3:Number = p_ray2Start.y;
			var x4:Number = p_ray2End.x;
			var y4:Number = p_ray2End.y;

			var y2Sy1:Number = y2 - y1;
			var x2Sx1:Number = x2 - x1;
			var y4Sy3:Number = y4 - y3;
			var x4Sx3:Number = x4 - x3;

			//Make sure the lines aren't parallel
			if (y2Sy1 / x2Sx1 != y4Sy3 / x4Sx3)
			{
				d = x2Sx1 * y4Sy3 - y2Sy1 * x4Sx3;

				if (d != 0)
				{
					var y1Sy3:Number = y1 - y3;
					var x1Sx3:Number = x1 - x3;

					r = (y1Sy3 * x4Sx3 - x1Sx3 * y4Sy3) / d;
					s = (y1Sy3 * x2Sx1 - x1Sx3 * y2Sy1) / d;

					if (p_isBothWay) return Vec2.get(x1 + r * x2Sx1, y1 + r * y2Sy1);
					else
					{
						if (r >= 0 && s >= 0) return Vec2.get(x1 + r * x2Sx1, y1 + r * y2Sy1);
					}
				}
			}

			return null;
		}

		/**
		 * Returns point of intersection ray with line.
		 */
		static public function getIntersectionRayToLine(p_ray1Start:Vec2, p_ray1End:Vec2, p_lineStart:Vec2, p_lineEnd:Vec2):Vec2
		{
			var r:Number, s:Number, d:Number;

			var x1:Number = p_ray1Start.x;
			var y1:Number = p_ray1Start.y;
			var x2:Number = p_ray1End.x;
			var y2:Number = p_ray1End.y;

			var x3:Number = p_lineStart.x;
			var y3:Number = p_lineStart.y;
			var x4:Number = p_lineEnd.x;
			var y4:Number = p_lineEnd.y;

			var y2Sy1:Number = y2 - y1;
			var x2Sx1:Number = x2 - x1;
			var y4Sy3:Number = y4 - y3;
			var x4Sx3:Number = x4 - x3;

			//Make sure the lines aren't parallel
			if (y2Sy1 / x2Sx1 != y4Sy3 / x4Sx3)
			{
				d = x2Sx1 * y4Sy3 - y2Sy1 * x4Sx3;

				if (d != 0)
				{
					var y1Sy3:Number = y1 - y3;
					var x1Sx3:Number = x1 - x3;

					r = (y1Sy3 * x4Sx3 - x1Sx3 * y4Sy3) / d;
					s = (y1Sy3 * x2Sx1 - x1Sx3 * y2Sy1) / d;

					if (r >= 0 && s >= 0 && s <= 1) return Vec2.get((x1 + r * x2Sx1), (y1 + r * y2Sy1));
				}
			}

			return null;
		}

		/**
		 * Returns point of intersection two circles.
		 * There are possible a few results:
		 * - empty array - mean two circles have the same radius and fully overlapped or contained in the other circle.
		 * - null - mean circles are not intersected.
		 * - array with one element (Vec2) - mean circles are touched.
		 * - array with two elements - circles are intersected and returns two points of intersection.
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getIntersectionCircleToCircle(p_circlePos1:Vec2, p_radius1:Number, p_circlePos2:Vec2, p_radius2:Number):Vector.<Vec2>
		{
			var cx1:Number = p_circlePos1.x;
			var cy1:Number = p_circlePos1.y;
			var cx2:Number = p_circlePos2.x;
			var cy2:Number = p_circlePos2.y;

			//dx/dy is the vertical and horizontal distances between the circle centers
			var dx:Number = cx2 - cx1;
			var dy:Number = cy2 - cy1;

			//distance between the circles
			var dist:Number = Math.sqrt(dx * dx + dy * dy);

			//Check for equality and infinite intersections exist
			if (dist == 0 && (p_radius1 == p_radius2)) return new <Vec2>[];

			var r1Ar2:Number = p_radius1 + p_radius2;

			//Check for solvability
			if (dist > r1Ar2) return null;  //no solution. circles do not intersect

			// one circle is contained in the other
			if (dist < Math.abs(p_radius1 - p_radius2)) return new <Vec2>[]; //no solution.

			// if true one solution
			if (dist == r1Ar2)
			{
				var r1Ar2Mr1:Number = r1Ar2 * p_radius1;
				return new <Vec2>[Vec2.get((cx1 - cx2) / r1Ar2Mr1 + cx2, (cy1 - cy2) / r1Ar2Mr1 + cy2)];
			}

			/* 'point 2' is the point where the line through the circle
			 * intersection points crosses the line between the circle
			 * centers.
			 */

			// Determine the distance from point 0 to point 2
			var a:Number = ((p_radius1 * p_radius1) - (p_radius2 * p_radius2) + (dist * dist)) / (2.0 * dist);
			var aDdist:Number = a / dist;

			// Determine the coordinates of point 2
			var v2x:Number = cx1 + dx * aDdist;
			var v2y:Number = cy1 + dy * aDdist;

			// Determine the distance from point 2 to either of the intersection points
			var h:Number = Math.sqrt((p_radius1 * p_radius1) - (a * a));
			var hDdist:Number = h / dist;

			// Now determine the offsets of the intersection points from point 2
			var rx:Number = -dy * hDdist;
			var ry:Number = dx * hDdist;

			// Determine the absolute intersection points
			var point1:Vec2 = Vec2.get(v2x + rx, v2y + ry);
			var point2:Vec2 = Vec2.get(v2x - rx, v2y - ry);

			return new <Vec2>[point1, point2];
		}

		// ********************************** //
		// ******* IS INTERSECT ************ //
		// ********************************* //

		/**
		 * Checks whether lines are intersected
		 */
		static public function isIntersectLineToLine(p_startLine1:Vec2, p_endLine1:Vec2, p_startLine2:Vec2, p_endLine2:Vec2):Boolean
		{
			var p1x:Number = p_startLine1.x;
			var p1y:Number = p_startLine1.y;
			var p2x:Number = p_endLine1.x;
			var p2y:Number = p_endLine1.y;
			var p3x:Number = p_startLine2.x;
			var p3y:Number = p_startLine2.y;
			var p4x:Number = p_endLine2.x;
			var p4y:Number = p_endLine2.y;

			var p1xSp2x:Number = p1x - p2x;
			var p1ySp2y:Number = p1y - p2y;
			var p1xSp3x:Number = p1x - p3x;
			var p1ySp3y:Number = p1y - p3y;
			var p4xSp3x:Number = p4x - p3x;
			var p4ySp3y:Number = p4y - p3y;

			var d:Number = p1xSp2x * p4ySp3y - p1ySp2y * p4xSp3x;
			var da:Number = p1xSp3x * p4ySp3y - p1ySp3y * p4xSp3x;
			var db:Number = p1xSp2x * p1ySp3y - p1ySp2y * p1xSp3x;

			if (da == 0 || db == 0) // lines are overlapped
			{
				return (p1x >= p3x && p1x <= p4x || p3x >= p1x && p4x <= p2x);
			}

			if (d == 0) return false; // lines are parallel

			var ta:Number = da / d;
			var tb:Number = db / d;

			if (ta >= 0)
			{
				if (ta <= 1)
				{
					if (tb >= 0)
					{
						if (tb <= 1) return true;
					}
				}
			}

			return false;
		}

		/**
		 * Checks whether rectangles are intersected.
		 */
		static public function isIntersectRectangleToRectangle(p_topLeft1:Vec2, p_bottomRight1:Vec2, p_topLeft2:Vec2, p_bottomRight2:Vec2):Boolean
		{
			var ltx1:Number = p_topLeft1.x;
			var lty1:Number = p_topLeft1.y;
			var rbx1:Number = p_bottomRight1.x;
			var rby1:Number = p_bottomRight1.y;

			var ltx2:Number = p_topLeft2.x;
			var lty2:Number = p_topLeft2.y;
			var rbx2:Number = p_bottomRight2.x;
			var rby2:Number = p_bottomRight2.y;

			var exp:Boolean = false;

			if (ltx2 >= ltx1)
			{
				if (ltx2 <= rbx1) exp = true;
			}

			if (!exp)
			{
				if (ltx1 >= ltx2)
				{
					if (!(ltx1 <= rbx2)) return false;
				}
				else return false;
			}

			if (lty2 >= lty1)
			{
				if (lty2 <= rby1) return true;
			}

			if (lty1 >= lty2)
			{
				if (lty1 <= rby2) return true;
			}

			return false;
		}

		/**
		 * Checks whether line and circle are intersected.
		 */
		static public function isIntersectLineToCircle(p_startLine:Vec2, p_endLine:Vec2, p_circlePosition:Vec2, p_radius:Number):Boolean
		{
			var cpX:Number = p_circlePosition.x;
			var cpY:Number = p_circlePosition.y;
			var x1:Number = p_startLine.x - cpX;
			var y1:Number = p_startLine.y - cpY;
			var x2:Number = p_endLine.x - cpX;
			var y2:Number = p_endLine.y - cpY;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			var a:Number = dx * dx + dy * dy;
			var b:Number = 2.0 * (x1 * dx + y1 * dy);
			var c:Number = x1 * x1 + y1 * y1 - p_radius * p_radius;

			if (-b < 0) return (c < 0);
			if (-b < (2.0 * a)) return (((4.0 * a * c) - b * b) < 0);

			return ((a + b + c) < 0);
		}

		/**
		 * Checks whether ray and circle are intersected.
		 */
		static public function isIntersectRayToCircle(p_startLine:Vec2, p_endLine:Vec2, p_circlePosition:Vec2, p_radius:Number):Boolean
		{
			var cX:Number = p_circlePosition.x;
			var cY:Number = p_circlePosition.y;

			var x1:Number = p_startLine.x - cX;
			var y1:Number = p_startLine.y - cY;
			var x2:Number = p_endLine.x - cX;
			var y2:Number = p_endLine.y - cY;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			var a:Number = dx * dx + dy * dy;
			var a2:Number = a * 2;
			var b:Number = (x1 * dx + y1 * dy) * 2;
			var c:Number = x1 * x1 + y1 * y1 - p_radius * p_radius;

			return (b * b - 2 * a2 * c) >= 0;
		}

		/**
		 * Checks whether polygons are intersected.
		 * (vertices of polygons should be sorted by clockwise)
		 */
		static public function isIntersectPolygonToPolygon(p_polygon1:Vec2List, p_polygon2:Vec2List):Boolean
		{
			var iterator1:Vec2Iterator = p_polygon1.iterator();
			var iterator2:Vec2Iterator = p_polygon2.iterator();

			var startPoint1:Vec2 = iterator1.next();
			var firstPoint1:Vec2 = startPoint1;
			var endPoint1:Vec2;

			var startPoint2:Vec2 = iterator2.next();
			var firstPoint2:Vec2 = startPoint2;
			var endPoint2:Vec2;

			while (iterator1.hasNext())
			{
				endPoint1 = iterator1.next();

				startPoint2 = iterator2.next();
				while (iterator2.hasNext())
				{
					endPoint2 = iterator2.next();

					if (isIntersectLineToLine(startPoint1, endPoint1, startPoint2, endPoint2)) return true;

					startPoint2 = endPoint2;
				}

				if (isIntersectLineToLine(startPoint1, endPoint1, startPoint2, firstPoint2)) return true;

				iterator2 = p_polygon2.iterator();

				startPoint1 = endPoint1;
			}

			startPoint2 = iterator2.next();
			while (iterator2.hasNext())
			{
				endPoint2 = iterator2.next();

				if (isIntersectLineToLine(startPoint1, firstPoint1, startPoint2, endPoint2)) return true;

				startPoint2 = endPoint2;
			}

			return isIntersectLineToLine(startPoint1, firstPoint1, startPoint2, firstPoint2);
		}

		/**
		 * Check whether point belongs to triangle.
		 * triangle - array with Vec2 instances - vertices of triangle.
		 */
		static public function isIntersectPointToTriangle(p_point:Vec2, p_triangle:Vector.<Vec2>):Boolean
		{
			var pl1:Number, pl2:Number, pl3:Number;

			var vert0:Vec2 = p_triangle[0];
			var vert0X:Number = vert0.x;
			var vert0Y:Number = vert0.y;

			var vert1:Vec2 = p_triangle[1];
			var vert1X:Number = vert1.x;
			var vert1Y:Number = vert1.y;

			var vert2:Vec2 = p_triangle[2];
			var vert2X:Number = vert2.x;
			var vert2Y:Number = vert2.y;

			var pointX:Number = p_point.x;
			var pointY:Number = p_point.y;

			pl1 = (vert0X - pointX) * (vert1Y - vert0Y) - (vert1X - vert0X) * (vert0Y - pointY);
			pl2 = (vert1X - pointX) * (vert2Y - vert1Y) - (vert2X - vert1X) * (vert1Y - pointY);
			pl3 = (vert2X - pointX) * (vert0Y - vert2Y) - (vert0X - vert2X) * (vert2Y - pointY);

			return ((pl1 >= 0 && pl2 >= 0 && pl3 >= 0) || (pl1 <= 0 && pl2 <= 0 && pl3 <= 0));
		}

		/**
		 * Check whether point belongs to circle.
		 */
		[Inline]
		static public function isIntersectPointToCircle(p_point:Vec2, p_circlePos:Vec2, p_circleRadius:Number):Boolean
		{
			var x:Number = p_point.x - p_circlePos.x;
			var y:Number = p_point.y - p_circlePos.y;

			return (x * x + y * y) <= (p_circleRadius * p_circleRadius);
		}

		/**
		 * Check whether circle and triangle are intersected.
		 * triangle - array with Vec2 instances - vertices of triangle.
		 */
		static public function isIntersectCircleToTriangle(p_circlePos:Vec2, p_circleRadius:Number, p_triangle:Vector.<Vec2>):Boolean
		{
			var triangle_0:Vec2 = p_triangle[0];
			var triangle_1:Vec2 = p_triangle[1];
			var triangle_2:Vec2 = p_triangle[2];

			return (
					isIntersectPointToCircle(triangle_0, p_circlePos, p_circleRadius) ||
							isIntersectPointToCircle(triangle_1, p_circlePos, p_circleRadius) ||
							isIntersectPointToCircle(triangle_2, p_circlePos, p_circleRadius) ||
							isIntersectPointToTriangle(p_circlePos, p_triangle) ||
							isIntersectLineToCircle(triangle_0, triangle_1, p_circlePos, p_circleRadius) ||
							isIntersectLineToCircle(triangle_1, triangle_2, p_circlePos, p_circleRadius) ||
							isIntersectLineToCircle(triangle_2, triangle_0, p_circlePos, p_circleRadius)
					);
		}

		/**
		 * Check whether circle and polygon are intersected.
		 *
		 * TODO: Need to implement
		 */
		static public function isIntersectCircleToPolygon(p_circlePos:Vec2, p_circleRadius:Number, p_polygon:Vector.<Vec2>):Boolean
		{
			return true;
		}

		/**
		 * Determines of intersection of two rays.
		 */
		static public function isIntersectRayToRay(p_ray1Start:Vec2, p_ray1End:Vec2, p_ray2Start:Vec2, p_ray2End:Vec2):Boolean
		{
			var r:Number, s:Number, d:Number;
			var x1:Number = p_ray1Start.x;
			var y1:Number = p_ray1Start.y;
			var x2:Number = p_ray1End.x;
			var y2:Number = p_ray1End.y;
			var x3:Number = p_ray2Start.x;
			var y3:Number = p_ray2Start.y;
			var x4:Number = p_ray2End.x;
			var y4:Number = p_ray2End.y;

			var y2Sy1:Number = y2 - y1;
			var x2Sx1:Number = x2 - x1;
			var y4Sy3:Number = y4 - y3;
			var x4Sx3:Number = x4 - x3;

			//Make sure the lines aren't parallel
			if (y2Sy1 / x2Sx1 != y4Sy3 / x4Sx3)
			{
				d = x2Sx1 * y4Sy3 - y2Sy1 * x4Sx3;

				if (d != 0)
				{
					var y1Sy3:Number = y1 - y3;
					var x1Sx3:Number = x1 - x3;

					r = (y1Sy3 * x4Sx3 - x1Sx3 * y4Sy3) / d;
					s = (y1Sy3 * x2Sx1 - x1Sx3 * y2Sy1) / d;

					return r >= 0 && s >= 0;
				}
			}

			return false;
		}

		/**
		 * Determines if rays are parallel.
		 * (Possible use this for lines too)
		 */
		[Inline]
		static public function isRaysParallel(p_ray1Start:Vec2, p_ray1End:Vec2, p_ray2Start:Vec2, p_ray2End:Vec2):Boolean
		{
			return (p_ray1End.y - p_ray1Start.y) / (p_ray1End.x - p_ray1Start.x) == (p_ray2End.y - p_ray2Start.y) / (p_ray2End.x - p_ray2Start.x);
		}

		/**
		 * Determines intersection ray with line.
		 */
		static public function isIntersectRayToLine(p_ray1Start:Vec2, p_ray1End:Vec2, p_lineStart:Vec2, p_lineEnd:Vec2):Boolean
		{
			var r:Number, s:Number, d:Number;

			var x1:Number = p_ray1Start.x;
			var y1:Number = p_ray1Start.y;
			var x2:Number = p_ray1End.x;
			var y2:Number = p_ray1End.y;

			var x3:Number = p_lineStart.x;
			var y3:Number = p_lineStart.y;
			var x4:Number = p_lineEnd.x;
			var y4:Number = p_lineEnd.y;

			var y2Sy1:Number = y2 - y1;
			var x2Sx1:Number = x2 - x1;
			var y4Sy3:Number = y4 - y3;
			var x4Sx3:Number = x4 - x3;

			//Make sure the lines aren't parallel
			if (y2Sy1 / x2Sx1 != y4Sy3 / x4Sx3)
			{
				d = x2Sx1 * y4Sy3 - y2Sy1 * x4Sx3;

				if (d != 0)
				{
					var y1Sy3:Number = y1 - y3;
					var x1Sx3:Number = x1 - x3;

					r = (y1Sy3 * x4Sx3 - x1Sx3 * y4Sy3) / d;
					s = (y1Sy3 * x2Sx1 - x1Sx3 * y2Sy1) / d;

					return r >= 0 && s >= 0 && s <= 1;
				}
			}

			return false;
		}

		/**
		 * Determines whether circles are intersected.
		 */
		[Inline]
		static public function isIntersectCircleToCircle(p_circlePos1:Vec2, p_circleRadius1:Number, p_circlePos2:Vec2, p_circleRadius2:Number):Boolean
		{
			var x:Number = p_circlePos1.x - p_circlePos2.x;
			var y:Number = p_circlePos1.y - p_circlePos2.y;
			var sLen:Number = x * x + y * y;
			var crs:Number = p_circleRadius1 + p_circleRadius2;

			return sLen <= crs * crs;
		}

		/**
		 * Check whether point belongs to polygon.
		 * polygon - vertices of polygon as Vec2 instances.
		 */
		static public function isIntersectPointToPolygon(p_point:Vec2, p_polygon:Vector.<Vec2>):Boolean
		{
			var n1:Number, n2:Number, isIntersect:Boolean = false;
			var len:int = p_polygon.length;
			var limit:int = len - 1;
			var rayEnd:Vec2 = Vec2.get(p_point.x + 1, p_point.y + 1);

			for (n1 = 0, n2 = 1; n1 < limit; n1++, n2++)
			{
				if (isIntersectRayToLine(p_point, rayEnd, p_polygon[n1], p_polygon[n2])) isIntersect = !isIntersect;
			}

			if (isIntersectRayToLine(p_point, rayEnd, p_polygon[limit], p_polygon[0])) isIntersect = !isIntersect;
			rayEnd.dispose();

			return isIntersect;
		}

		/**
		 * Check for intersection of line and polygon.
		 */
		static public function isIntersectLineToPolygon(p_startLine:Vec2, p_endLine:Vec2, p_polygon:Vec2List):Boolean
		{
			var iterator:Vec2Iterator = p_polygon.iterator();
			var startVertex:Vec2 = iterator.next();
			var firstVertex:Vec2 = startVertex;
			var endVertex:Vec2;

			while (iterator.hasNext())
			{
				endVertex = iterator.next();
				if (isIntersectLineToLine(p_startLine, p_endLine, startVertex, endVertex)) return true;
				startVertex = endVertex;
			}

			return isIntersectLineToLine(p_startLine, p_endLine, startVertex, firstVertex);
		}

		/**
		 * Checks for intersection of ray and polygon.
		 */
		static public function isIntersectRayToPolygon(p_startRay:Vec2, p_endRay:Vec2, p_polygon:Vec2List):Boolean
		{
			var iterator:Vec2Iterator = p_polygon.iterator();
			var startVertex:Vec2 = iterator.next();
			var firstVertex:Vec2 = startVertex;
			var endVertex:Vec2;

			while (iterator.hasNext())
			{
				endVertex = iterator.next();
				if (isIntersectRayToLine(p_startRay, p_endRay, startVertex, endVertex)) return true;
				startVertex = endVertex;
			}

			return isIntersectRayToLine(p_startRay, p_endRay, startVertex, firstVertex);
		}

		// ******************************** //
		// ******* GET NEAREST ************ //
		// ******************************** //

		/**
		 * Determines nearest point from given list to measuring given point.
		 */
		static public function getNearestPointToPoint(p_listPoints:Vec2List, p_measuringPoint:Vec2):Vec2
		{
			var nearestPoint:Vec2;
			var point:Vec2;
			var minLen:Number = Number.POSITIVE_INFINITY;
			var lsq:Number;
			var tx:Number;
			var ty:Number;
			var iterator:Vec2Iterator = p_listPoints.iterator();

			while (iterator.hasNext())
			{
				point = iterator.next();
				tx = point.x - p_measuringPoint.x;
				ty = point.y - p_measuringPoint.y;
				lsq = tx * tx + ty * ty;

				if (minLen > lsq)
				{
					minLen = lsq;
					nearestPoint = point;
				}
			}

			return nearestPoint;
		}

		/**
		 * Returns nearest point of the line to given measuring point.
		 * limitLineSegment - if 'true' searching limited by line border, if 'false' searching goes out line (line looks like a ray).
		 */
		static public function getNearestPointOnLine(p_startLine:Vec2, p_endLine:Vec2, p_measuringPoint:Vec2, p_limitLineSegment:Boolean = true):Vec2
		{
			var x1:Number = p_startLine.x;
			var y1:Number = p_startLine.y;
			var x2:Number = p_endLine.x;
			var y2:Number = p_endLine.y;
			var x3:Number = p_measuringPoint.x;
			var y3:Number = p_measuringPoint.y;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			var x0:Number;
			var y0:Number;

			if ((dx == 0) && (dy == 0))
			{
				x0 = x1;
				y0 = y1;
			}
			else
			{
				var t:Number = ((x3 - x1) * dx + (y3 - y1) * dy) / (dx * dx + dy * dy);
				if (p_limitLineSegment) t = min(max(0, t), 1);
				x0 = x1 + t * dx;
				y0 = y1 + t * dy;
			}

			return Vec2.get(x0, y0);
		}

		/**
		 * Returns nearest point on polygon to given point.
		 * Method returns instance of Vec3 where 'x' and 'y' coordinates of found point,
		 * 'z' - depends on 'p_distance', if it 'false' - 'z' contains square of distance between found and given point, if 'true' - contains distance.
		 */
		static public function getNearestPointOnPolygon(p_vertexList:Vec2List, p_measuringPoint:Vec2, p_distance:Boolean = false):Vec3
		{
			var nearestOnPolygon:Vec2;
			var distanceToPolygon:Number = Number.POSITIVE_INFINITY;
			var nearestOnLine:Vec2;
			var distanceToLine:Number;

			var curPoint:Vec2;
			var prevPoint:Vec2;
			var firstPoint:Vec2;

			var mx:Number = p_measuringPoint.x;
			var my:Number = p_measuringPoint.y;
			var tx:Number;
			var ty:Number;

			var iterator:Vec2Iterator = p_vertexList.iterator();
			firstPoint = iterator.next();
			prevPoint = firstPoint;

			while (iterator.hasNext())
			{
				curPoint = iterator.next();
				nearestOnLine = getNearestPointOnLine(prevPoint, curPoint, p_measuringPoint);
				tx = nearestOnLine.x - mx;
				ty = nearestOnLine.y - my;
				distanceToLine = tx * tx + ty * ty;

				if (distanceToLine < distanceToPolygon)
				{
					nearestOnPolygon = nearestOnLine;
					distanceToPolygon = distanceToLine;
				}

				prevPoint = curPoint;
			}

			nearestOnLine = getNearestPointOnLine(curPoint, firstPoint, p_measuringPoint);
			tx = nearestOnLine.x - mx;
			ty = nearestOnLine.y - my;
			distanceToLine = tx * tx + ty * ty;

			if (distanceToLine < distanceToPolygon)
			{
				nearestOnPolygon = nearestOnLine;
				distanceToPolygon = distanceToLine;
			}

			return Vec3.get(nearestOnPolygon.x, nearestOnPolygon.y, p_distance ? Math.sqrt(distanceToPolygon) : distanceToPolygon);
		}

		/**
		 * Returns nearest point on circle to given point.
		 * Method returns instance of Vec3 where 'x' and 'y' coordinates of found point,
		 * 'z' - depends on 'p_squareDistance' - if "false" 'z' contains distance, if "true" - contains square distance.
		 * (distance calculate in any case, so set 'p_squareDistance' parameter to true doesn't make any optimization).
		 */
		static public function getNearestPointOnCircle(p_circlePosition:Vec2, p_radius:Number, p_measuringPoint:Vec2, p_squareDistance:Boolean = false):Vec3
		{
			var mx:Number = p_measuringPoint.x;
			var my:Number = p_measuringPoint.y;
			var dx:Number = p_circlePosition.x - mx;
			var dy:Number = p_circlePosition.y - my;

			if (dx == 0 || dy == 0) dx = dy = p_radius;

			var distanceToCircle:Number = Math.sqrt(dx * dx + dy * dy);

			var dirX:Number = dx / distanceToCircle;
			var dirY:Number = dy / distanceToCircle;

			distanceToCircle -= p_radius;

			var npX:Number = mx + dirX * distanceToCircle;
			var npY:Number = my + dirY * distanceToCircle;

			return Vec3.get(npX, npY, p_squareDistance ? distanceToCircle * distanceToCircle : distanceToCircle);
		}

		// ************************** //
		// ******* GET DISTANCE ***** //
		// ************************** //

		/**
		 * Returns distance between given point and polygon (nearest point on borders of polygon to given point).
		 * isSquareLength - if 'true' method return square of distance (sqrt will not calculate).
		 */
		static public function getDistanceToPolygon(p_vertexList:Vec2List, p_measuringPoint:Vec2, p_isSquareLength:Boolean = false):Number
		{
			var distanceToPolygon:Number = Number.POSITIVE_INFINITY;
			var distanceToLine:Number;

			var curPoint:Vec2;
			var prevPoint:Vec2;
			var firstPoint:Vec2;

			var iterator:Vec2Iterator = p_vertexList.iterator();
			firstPoint = iterator.next();
			prevPoint = firstPoint;

			while (iterator.hasNext())
			{
				curPoint = iterator.next();

				distanceToLine = getDistanceToLine(prevPoint, curPoint, p_measuringPoint, true, true);

				if (distanceToLine < distanceToPolygon) distanceToPolygon = distanceToLine;

				prevPoint = curPoint;
			}

			distanceToLine = getDistanceToLine(curPoint, firstPoint, p_measuringPoint, true, true);

			if (distanceToLine < distanceToPolygon) distanceToPolygon = distanceToLine;

			return p_isSquareLength ? distanceToPolygon : Math.sqrt(distanceToPolygon);
		}

		/**
		 * Returns distance between given point and circle (nearest point on borders of circle to given point, not to center).
		 * (if the point inside the circle method returns 0)
		 */
		static public function getDistanceToCircle(p_circlePosition:Vec2, p_radius:Number, p_measuringPoint:Vec2):Number
		{
			var dx:Number = p_circlePosition.x - p_measuringPoint.x;
			var dy:Number = p_circlePosition.y - p_measuringPoint.y;

			if (dx < p_radius && dy < p_radius) return 0;

			return Math.sqrt(dx * dx + dy * dy) - p_radius;
		}

		/**
		 * Returns distance between given point and line.
		 * limitLineSegment - if 'true' searching limited by line border, if 'false' searching goes out line (line looks like a ray).
		 * isSquareLength - if 'true' method return square of distance (sqrt will not calculate).
		 */
		static public function getDistanceToLine(p_startLine:Vec2, p_endLine:Vec2, p_measuringPoint:Vec2, p_limitLineSegment:Boolean = true,
		                                         p_squareLength:Boolean = false):Number
		{
			var x1:Number = p_startLine.x;
			var y1:Number = p_startLine.y;
			var x2:Number = p_endLine.x;
			var y2:Number = p_endLine.y;
			var x3:Number = p_measuringPoint.x;
			var y3:Number = p_measuringPoint.y;

			var dx:Number = x2 - x1;
			var dy:Number = y2 - y1;

			var x0:Number;
			var y0:Number;

			if ((dx == 0) && (dy == 0))
			{
				x0 = x1;
				y0 = y1;
			}
			else
			{
				var t:Number = ((x3 - x1) * dx + (y3 - y1) * dy) / (dx * dx + dy * dy);
				if (p_limitLineSegment) t = min(max(0, t), 1);
				x0 = x1 + t * dx;
				y0 = y1 + t * dy;
			}

			dx = x3 - x0;
			dy = y3 - y0;

			return p_squareLength ? (dx * dx + dy * dy) : Math.sqrt(dx * dx + dy * dy);
		}

		// ************************** //
		// ******* OTHER ************ //
		// ************************** //

		/**
		 * Returns two vertices from given vertices, which are extreme vertices for given measuring point.
		 * Return array with two objects of Vec2 type.
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getExtremePointsOnPolygon_Vector(p_vertices:Vector.<Vec2>, p_measuring:Vec2):Vector.<Vec2>
		{
			var biggestAngel:Number = Number.POSITIVE_INFINITY;
			var tAngel:Number = 0;
			var bigVertex1:Vec2;
			var bigVertex2:Vec2;
			var vertex_i:Vec2;
			var vertex_j:Vec2;

			var len:int = p_vertices.length;
			for (var i:int = 0; i < len - 1; i++)
			{
				vertex_i = p_vertices[i];
				for (var j:int = i + 1; j < len; j++)
				{
					vertex_j = p_vertices[j];
					tAngel = getCosALines(p_measuring, vertex_i, p_measuring, vertex_j);

					if (tAngel < biggestAngel)
					{
						biggestAngel = tAngel;
						bigVertex1 = vertex_i;
						bigVertex2 = vertex_j;
					}
				}
			}

			return new <Vec2>[bigVertex1.copy(), bigVertex2.copy()];
		}

		/**
		 * Returns two vertices from given vertices, which are extreme vertices for given measuring point.
		 * Return array with two objects of Vec2 type.
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getExtremePointsOnPolygon(p_vertices:Vec2List, p_measuring:Vec2):Vector.<Vec2>
		{
			var biggestAngel:Number = Number.POSITIVE_INFINITY;
			var tAngel:Number = 0;
			var bigVertex1:Vec2;
			var bigVertex2:Vec2;
			var vertex_i:Vec2;
			var vertex_j:Vec2;
			var iterator:Vec2Iterator = p_vertices.iterator();

			var len:int = p_vertices.length;
			for (var i:int = 0; i < len - 1; i++)
			{
				vertex_i = iterator.next();

				for (var j:int = i + 1; j < len; j++)
				{
					vertex_j = p_vertices.at(j);
					tAngel = getCosALines(p_measuring, vertex_i, p_measuring, vertex_j);

					if (tAngel < biggestAngel)
					{
						biggestAngel = tAngel;
						bigVertex1 = vertex_i;
						bigVertex2 = vertex_j;
					}
				}
			}

			return new <Vec2>[bigVertex1.copy(), bigVertex2.copy()];
		}

		/**
		 * Return perpendicular vector to given.
		 * If normalize = true, vector is normalized.
		 */
		[Inline]
		static private function getPerpendicular(p_vecStart:Vec2, p_vecEnd:Vec2, p_isNormalize:Boolean = false):Vec2
		{
			var perpX:Number = -(p_vecEnd.y - p_vecStart.y);
			var perpY:Number = p_vecEnd.x - p_vecStart.x;

			if (p_isNormalize && (perpX + perpY) != 0)
			{
				var len:Number = Math.sqrt(perpX * perpX + perpY * perpY);
				perpX /= len;
				perpY /= len;
			}

			return Vec2.get(perpX, perpY);
		}

		/**
		 * Returns projection of given point on the circle edges.
		 * Returns array with two points - first the most left, second - right.
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getExtremePointsOnCircle(p_circlePos:Vec2, p_circleRadius:Number, p_measuringPoint:Vec2):Vector.<Vec2>
		{
			var perpLine:Vec2 = getPerpendicular(p_measuringPoint, p_circlePos, true);

			var point1:Vec2 = perpLine.mul(-p_circleRadius).addeq(p_circlePos);
			var point2:Vec2 = perpLine.mul(p_circleRadius).addeq(p_circlePos);

			var intersectPoint1:Vec2 = getIntersectionRayToCircle(p_measuringPoint, point1, p_circlePos, p_circleRadius);
			var intersectPoint2:Vec2 = getIntersectionRayToCircle(p_measuringPoint, point2, p_circlePos, p_circleRadius);

			point1.dispose();
			point2.dispose();

			return new <Vec2>[intersectPoint1, intersectPoint2];
		}

		/**
		 * Method looks like 'getAngleLines' except it doesn't calculate arccos, and not returns angle in radians.
		 * This method can be helpful when no need to know angles but need to know, e.g., is one angle greater/smaller then another.
		 * Less value than angle greater.
		 */
		static private function getCosALines(p_startLine1:Vec2, p_endLine1:Vec2, p_startLine2:Vec2, p_endLine2:Vec2):Number
		{
			var x1:Number = p_endLine1.x - p_startLine1.x;
			var y1:Number = p_endLine1.y - p_startLine1.y;
			var x2:Number = p_endLine2.x - p_startLine2.x;
			var y2:Number = p_endLine2.y - p_startLine2.y;

			return (x1 * x2 + y1 * y2) / Math.sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2));
		}

		/**
		 * Calculate bounding box for given vertices.
		 * Returns array with two vertices - instances of Vec2 - left top vertex and right bottom vertex.
		 * (creates two new points)
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getBoundingBox_Vector(p_vertices:Vector.<Vec2>):Vector.<Vec2>
		{
			var vertex:Vec2 = p_vertices[0];
			var tx:Number = vertex.x;
			var ty:Number = vertex.y;
			var top:Number = ty;
			var left:Number = tx;
			var right:Number = tx;
			var bottom:Number = ty;
			var len:int = p_vertices.length;

			for (var i:int = 1; i < len; i++)
			{
				vertex = p_vertices[i];
				tx = vertex.x;
				ty = vertex.y;

				if (top > ty) top = ty;
				else if (bottom < ty) bottom = ty;

				if (left > tx) left = tx;
				else if (right < tx) right = tx;
			}

			return new <Vec2>[Vec2.get(left, top), Vec2.get(right, bottom)];
		}

		/**
		 * Calculate bounding box for given vertices.
		 * Returns array with two vertices - instances of Vec2 - left top vertex and right bottom vertex.
		 * (creates two new points)
		 *
		 * @return Vector.<Vec2>
		 */
		static public function getBoundingBox(p_vertices:Vec2List):Vector.<Vec2>
		{
			var iterator:Vec2Iterator = p_vertices.iterator();
			var vertex:Vec2 = iterator.next();
			var tx:Number = vertex.x;
			var ty:Number = vertex.y;
			var top:Number = ty;
			var left:Number = tx;
			var right:Number = tx;
			var bottom:Number = ty;
			var len:int = p_vertices.length;

			for (var i:int = 1; i < len; i++)
			{
				vertex = iterator.next();
				tx = vertex.x;
				ty = vertex.y;

				if (top > ty) top = ty;
				else if (bottom < ty) bottom = ty;

				if (left > tx) left = tx;
				else if (right < tx) right = tx;
			}

			return new <Vec2>[Vec2.get(left, top), Vec2.get(right, bottom)];
		}

		// ***********************
		// *** RELATED TO NAPE ***
		// ***********************

		/**
		 * Check whether intersects given shape (Circle or Polygon) with line.
		 */
		static public function isIntersectShapeToLine(p_shape:Shape, p_startLine:Vec2, p_endLine:Vec2):Boolean
		{
			return p_shape.isCircle() ? isIntersectLineToCircle(p_startLine, p_endLine, p_shape.castCircle.worldCOM, p_shape.castCircle.radius) :
					isIntersectLineToPolygon(p_startLine, p_endLine, p_shape.castPolygon.worldVerts);
		}

		/**
		 * Checks whether shape (Circle or Polygon) and triangle are intersected.
		 */
		static public function isIntersectShapeToTriangle(p_shape:Shape, p_triangle:Vector.<Vec2>):Boolean
		{
			return p_shape.isCircle() ? isIntersectCircleToTriangle(p_shape.castCircle.worldCOM, p_shape.castCircle.radius, p_triangle) :
					isIntersectPolygonToPolygon(p_shape.castPolygon.worldVerts, Vec2List.fromVector(p_triangle));
		}

		/**
		 * Returns extreme points on given shape relates on measuring point.
		 * Returns array with two points - first the most left, second - right.
		 */
		static public function getExtremePointsOnShape(p_shape:Shape, p_measuringPoint:Vec2):Vector.<Vec2>
		{
			return p_shape.isCircle() ? getExtremePointsOnCircle(p_shape.worldCOM, p_shape.castCircle.radius, p_measuringPoint) :
					getExtremePointsOnPolygon(p_shape.castPolygon.worldVerts, p_measuringPoint);
		}

		/**
		 * Returns nearest point on borders of the shape to given point (Circle or Polygon).
		 * if 'p_distance' true - 'z' param contains distance between points, if 'false' 'z' contains square distance.
		 */
		static public function getNearestPointOnShape(p_shape:Shape, p_measuringPoint:Vec2, p_distance:Boolean = false):Vec3
		{
			return p_shape.isCircle() ? getNearestPointOnCircle(p_shape.worldCOM, p_shape.castCircle.radius, p_measuringPoint, !p_distance) :
					getNearestPointOnPolygon(p_shape.castPolygon.worldVerts, p_measuringPoint, p_distance);
		}

		/**
		 * Returns distance from given measuringPoint to nearest point on the borders of the shape (Circle or Polygon).
		 */
		static public function getDistanceToShape(p_shape:Shape, p_measuringPoint:Vec2):Number
		{
			return p_shape.isCircle() ? getDistanceToCircle(p_shape.worldCOM, p_shape.castCircle.radius, p_measuringPoint) :
					getDistanceToPolygon(p_shape.castPolygon.worldVerts, p_measuringPoint);
		}

		/////////////////////
		/// INTERNAL ////////
		/////////////////////

		[Inline]
		static public function min(p_val1:Number, p_val2:Number):Number
		{
			return p_val1 < p_val2 ? p_val1 : p_val2;
		}

		[Inline]
		static public function max(p_val1:Number, p_val2:Number):Number
		{
			return (p_val1 > p_val2) ? p_val1 : p_val2;
		}
	}
}
