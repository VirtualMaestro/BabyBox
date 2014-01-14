/**
 * User: VirtualMaestro
 * Date: 25.01.13
 * Time: 21:11
 */
package bb.core
{
	import bb.bb_spaces.bb_private;
	import bb.pools.BBNativePool;

	import flash.geom.Matrix;
	import flash.geom.Point;

	import nape.geom.Vec2;

	use namespace bb_private;

	/**
	 * Represents all transformation like: translation, rotation, scale, skew.
	 * Also contain geometric data like: width, height.
	 */
	final public class BBTransform extends BBComponent
	{
		private const PI2_RAD:Number = Math.PI * 2;
		private const RAD_TO_DEG:Number = 180.0 / Math.PI;
		private const DEG_TO_RAD:Number = Math.PI / 180.0;

		//
		private var _localX:Number;
		private var _localY:Number;
		bb_private var worldX:Number;
		bb_private var worldY:Number;

		private var _localRotation:Number; // in radians
		bb_private var worldRotation:Number; // in radians

		private var _localScaleX:Number;
		private var _localScaleY:Number;
		bb_private var worldScaleX:Number;
		bb_private var worldScaleY:Number;

		private var _worldTransformMatrix:Matrix;
		private var _localTransformMatrix:Matrix;
		private var _isWorldTransformMatrixChanged:Boolean;

		bb_private var isTransformChanged:Boolean;
		bb_private var isPositionChanged:Boolean;
		bb_private var isRotationChanged:Boolean;
		bb_private var isScaleChanged:Boolean;
		bb_private var isColorChanged:Boolean;

		bb_private var COS:Number;
		bb_private var SIN:Number;

		// color //
		bb_private var isColorShouldBeDisplayed:Boolean;

		bb_private var worldRed:Number;
		private var _red:Number;

		bb_private var worldGreen:Number;
		private var _green:Number;

		bb_private var worldBlue:Number;
		private var _blue:Number;

		bb_private var worldAlpha:Number;
		private var _alpha:Number;

		/**
		 * Lock invalidation method, so world's parameters like worldX, worldRotation etc. won't not update (changed).
		 */
		public var lockInvalidation:Boolean;
		public var invalidateOnce:Boolean;

		/**
		 * Is transform changed and updated values.
		 */
		public var isInvalidated:Boolean;
		public var isPositionInvalidated:Boolean;
		public var isRotationInvalidated:Boolean;
		public var isScaleInvalidated:Boolean;
		public var isPRSInvalidated:Boolean;
		public var isColorInvalidated:Boolean;

		/**
		 */
		public function BBTransform()
		{
			super();
		}

		/**
		 */
		override protected function init():void
		{
			_localX = 0;
			_localY = 0;
			worldX = 0;
			worldY = 0;
			_localRotation = 0;
			worldRotation = 0;
			_localScaleX = 1;
			_localScaleY = 1;
			worldScaleX = 1;
			worldScaleY = 1;
			_alpha = 1;
			worldAlpha = 1;
			_red = 1;
			worldRed = 1;
			_green = 1;
			worldGreen = 1;
			_blue = 1;
			worldBlue = 1;
			COS = 1;
			SIN = 0;

			isScaleChanged = false;
			isRotationChanged = false;
			isPositionChanged = false;
			isTransformChanged = false;
			isColorChanged = false;
			isColorShouldBeDisplayed = false;
			_isWorldTransformMatrixChanged = true;
			isInvalidated = false;
			isScaleInvalidated = false;
			isColorInvalidated = false;
			isPositionInvalidated = false;
			isRotationInvalidated = false;
			isPRSInvalidated = false;
			lockInvalidation = false;
			invalidateOnce = false;
		}

		/**
		 * Sets given color in ARGB format.
		 */
		public function set color(p_value:uint):void
		{
			alpha = Number((p_value >> 24) & 0xFF) / 0xFF;
			red = Number((p_value >> 16) & 0xFF) / 0xFF;
			green = Number((p_value >> 8) & 0xFF) / 0xFF;
			blue = Number(p_value & 0xFF) / 0xFF;
		}

		/**
		 */
		public function get color():uint
		{
			var alpha:uint = uint(_alpha * 255) << 24;
			var red:uint = uint(_red * 255) << 16;
			var green:uint = uint(_green * 255) << 8;
			var blue:uint = uint(_blue * 255);

			return alpha + red + green + blue;
		}

		/**
		 *     @private
		 */
		public function get red():Number
		{
			return _red;
		}

		[Inline]
		final public function set red(p_red:Number):void
		{
			worldRed = _red = p_red > 1.0 ? 1.0 : p_red;
			isColorChanged = true;
			isColorInvalidated = true;
		}

		/**
		 *     @private
		 */
		public function get green():Number
		{
			return _green;
		}

		[Inline]
		final public function set green(p_green:Number):void
		{
			worldGreen = _green = p_green > 1.0 ? 1.0 : p_green;
			isColorChanged = true;
			isColorInvalidated = true;
		}

		/**
		 *     @private
		 */
		public function get blue():Number
		{
			return _blue;
		}

		[Inline]
		final public function set blue(p_blue:Number):void
		{
			worldBlue = _blue = p_blue > 1.0 ? 1.0 : p_blue;
			isColorChanged = true;
			isColorInvalidated = true;
		}

		/**
		 *     @private
		 */
		public function get alpha():Number
		{
			return _alpha;
		}

		[Inline]
		final public function set alpha(p_alpha:Number):void
		{
			worldAlpha = _alpha = p_alpha > 1.0 ? 1.0 : p_alpha;
			isColorChanged = true;
			isColorInvalidated = true;
		}

		/**
		 * Returns new instance of Matrix of transformed world matrix by given parameters.
		 * If after using instance is not need anymore there is possible to take back it to pool - BBNativePool.putMatrix(matrix);
		 * NOTICE: scale and rotation won't change the translation of matrix (tx/ty).
		 */
		public function getTransformedWorldMatrix(p_scaleX:Number = 1.0, p_scaleY:Number = 1.0, p_rotation:Number = 0.0, p_x:Number = 0, p_y:Number = 0,
		                                          p_invert:Boolean = false):Matrix
		{
			var worldMatrix:Matrix = worldTransformMatrix;
			var a:Number = worldMatrix.a;
			var b:Number = worldMatrix.b;
			var c:Number = worldMatrix.c;
			var d:Number = worldMatrix.d;
			var tx:Number = worldMatrix.tx + p_x;
			var ty:Number = worldMatrix.ty + p_y;

			if (p_scaleX != 1 && p_scaleY != 1)
			{
				a *= p_scaleX;
				b *= p_scaleY;
				c *= p_scaleX;
				d *= p_scaleY;
			}

			if (p_rotation != 0)
			{
				var cos:Number = Math.cos(p_rotation);
				var sin:Number = Math.sin(p_rotation);
				var aa:Number = cos * a - b * sin;
				var bb:Number = sin * a + b * cos;
				var cc:Number = cos * c - d * sin;
				var dd:Number = sin * c + d * cos;

				a = aa;
				b = bb;
				c = cc;
				d = dd;
			}

			var matrix:Matrix = BBNativePool.getMatrix(a, b, c, d, tx, ty);

			if (p_invert) matrix.invert();

			return matrix;
		}

		/**
		 * Returns world transform matrix.
		 */
		final public function get worldTransformMatrix():Matrix
		{
			if (isTransformChanged) invalidate(true, false);
			if (_isWorldTransformMatrixChanged)
			{
				var sX:Number = (worldScaleX == 0) ? 0.000001 : worldScaleX;
				var sY:Number = (worldScaleY == 0) ? 0.000001 : worldScaleY;

				if (_worldTransformMatrix == null) _worldTransformMatrix = BBNativePool.getMatrix();

				if (lockInvalidation && node.numChildren == 0)
				{
					COS = Math.cos(worldRotation);
					SIN = Math.sin(worldRotation);
				}

				var cos:Number = COS;
				var sin:Number = SIN;

				_worldTransformMatrix.a = cos * sX;
				_worldTransformMatrix.b = sin * sY;
				_worldTransformMatrix.c = -sin * sX;
				_worldTransformMatrix.d = cos * sY;
				_worldTransformMatrix.tx = worldX;
				_worldTransformMatrix.ty = worldY;

				_isWorldTransformMatrixChanged = false;
			}

			return _worldTransformMatrix;
		}

		/**
		 * Returns local transform matrix.
		 */
		public function get localTransformMatrix():Matrix
		{
			if (_localTransformMatrix == null) _localTransformMatrix = BBNativePool.getMatrix();
			_localTransformMatrix.createBox(_localScaleX, _localScaleY, _localRotation, _localX, _localY);
			return _localTransformMatrix;
		}

		/**
		 * Sets position.
		 * If node of this component has parent it is mean position sets in parent's coordinate system.
		 */
		[Inline]
		final public function setPosition(p_x:Number, p_y:Number):void
		{
			_localX = p_x;
			_localY = p_y;
			isTransformChanged = true;
			isPositionChanged = true;
			invalidateOnce = true;
		}

		//
		private var _localPos:Vec2;

		/**
		 * Returns Vec2 with position values.
		 * If you need to change returned vector, you should to make a copy from given,
		 * because current method doesn't creates new instance.
		 */
		final public function getPosition():Vec2
		{
			if (_localPos) _localPos.setxy(_localX, _localY);
			else _localPos = Vec2.get(_localX, _localY);

			return _localPos;
		}

		//
		private var _worldPos:Vec2;

		/**
		 * Returns Vec2 with world position.
		 * If you need to change returned vector, you should to make a copy from given,
		 * because current method doesn't creates new instance.
		 */
		final public function getPositionWorld():Vec2
		{
			if (_worldPos) _worldPos.setxy(worldX, worldY);
			else _worldPos = Vec2.get(worldX, worldY);

			return _worldPos;
		}

		/**
		 * Sets x position.
		 */
		[Inline]
		final public function set x(p_x:Number):void
		{
			setPosition(p_x, _localY);
		}

		/**
		 * Gets x position.
		 */
		public function get x():Number
		{
			return _localX;
		}

		/**
		 * Sets y position.
		 */
		[Inline]
		final public function set y(p_y:Number):void
		{
			setPosition(_localX, p_y);
		}

		/**
		 * Gets y position.
		 */
		public function get y():Number
		{
			return _localY;
		}

		/**
		 * p_angle - angle in radians.
		 */
		public function setPositionAndRotation(p_x:Number, p_y:Number, p_angle:Number):void
		{
			_localX = p_x;
			_localY = p_y;
			_localRotation = p_angle % PI2_RAD;

			isTransformChanged = true;
			isPositionChanged = true;
			isRotationChanged = true;
			invalidateOnce = true;
		}

		/**
		 * Sets rotation in radians.
		 */
		[Inline]
		final public function set rotation(p_angle:Number):void
		{
			_localRotation = p_angle % PI2_RAD;

			isTransformChanged = true;
			isRotationChanged = true;
			invalidateOnce = true;
		}

		/**
		 */
		public function get rotation():Number
		{
			return _localRotation;
		}

		/**
		 * Returns angle in degrees.
		 */
		public function get rotationDegree():Number
		{
			return Math.round(_localRotation * RAD_TO_DEG * 10) / 10;
		}

		/**
		 * Sets angle in degrees.
		 */
		public function set rotationDegree(p_angle:Number):void
		{
			rotation = (Math.round(p_angle * 10) / 10) * DEG_TO_RAD;
		}

		/**
		 * Returns rotation in world coordinates.
		 */
		public function get rotationWorld():Number
		{
			return worldRotation;
		}

		/**
		 */
		bb_private function setWorldPositionAndRotation(p_x:Number, p_y:Number, p_rotation:Number):void
		{
			worldX = p_x;
			worldY = p_y;
			worldRotation = p_rotation;

			var trans:BBTransform = node.parent.transform;
			_localX = worldX - trans.worldX;
			_localY = worldY - trans.worldY;
			_localRotation = worldRotation - trans.worldRotation;

			isTransformChanged = true;
			isPositionChanged = true;
			isRotationChanged = true;
			_isWorldTransformMatrixChanged = true;

			if (node.numChildren > 0)
			{
				COS = Math.cos(worldRotation);
				SIN = Math.sin(worldRotation);
			}
		}

		/**
		 * Sets scale.
		 */
		final public function setScale(p_scaleX:Number, p_scaleY:Number):void
		{
			_localScaleX = p_scaleX;
			_localScaleY = p_scaleY;

			isTransformChanged = true;
			isScaleChanged = true;
			invalidateOnce = true;
		}

		/**
		 */
		public function set scaleX(p_val:Number):void
		{
			setScale(p_val, _localScaleY);
		}

		/**
		 */
		public function get scaleX():Number
		{
			return _localScaleX;
		}

		/**
		 */
		public function set scaleY(p_val:Number):void
		{
			setScale(_localScaleX, p_val);
		}

		/**
		 */
		public function get scaleY():Number
		{
			return _localScaleY;
		}

		/**
		 * Gets scale in world.
		 * Return new non-weak Vec2 instance.
		 */
		public function getScaleWorld():Vec2
		{
			return Vec2.get(worldScaleX, worldScaleY);
		}

		/**
		 */
		public function shiftScale(p_shiftScaleX:Number, p_shiftScaleY:Number):void
		{
			setScale(_localScaleX + p_shiftScaleX, _localScaleY + p_shiftScaleY);
		}

		/**
		 * Shift position on given offset.
		 */
		public function shiftPosition(p_offsetX:Number, p_offsetY:Number):void
		{
			setPosition(_localX + p_offsetX, _localY + p_offsetY);
		}

		/**
		 * Shift rotation by given angel.
		 */
		public function set shiftRotation(p_offsetAngle:Number):void
		{
			rotation = _localRotation + p_offsetAngle;
		}

		/**
		 */
		public function shiftPositionAndRotation(p_offsetX:Number, p_offsetY:Number, p_offsetAngle:Number):void
		{
			shiftPosition(p_offsetX, p_offsetY);
			shiftRotation = p_offsetAngle;
		}

		/**
		 * Transform given point from local coordinate system to world.
		 * Returns new Point instance.
		 * After use if point instance not need it is possible back it to pool - BBNativePool.putPoint(point);
		 */
		public function localToWorld(p_x:Number, p_y:Number):Point
		{
			var resultPoint:Point = BBNativePool.getPoint(p_x, p_y);

			if (node)
			{
				var matrix:Matrix = worldTransformMatrix;
				resultPoint.x = p_x * matrix.a + p_y * matrix.c + matrix.tx;
				resultPoint.y = p_x * matrix.b + p_y * matrix.d + matrix.ty;
			}

			return resultPoint;
		}

		/**
		 * Transform given point from world coordinate system to local.
		 * Returns new Point instance.
		 * After use if point instance not need it is possible back it to pool - BBNativePool.putPoint(point);
		 */
		public function worldToLocal(p_x:Number, p_y:Number):Point
		{
			var resultPoint:Point = BBNativePool.getPoint(p_x, p_y);

			if (node)
			{
				var matrix:Matrix = BBNativePool.getMatrix();
				var worldMatrix:Matrix = worldTransformMatrix;
				matrix.a = worldMatrix.a;
				matrix.b = worldMatrix.b;
				matrix.c = worldMatrix.c;
				matrix.d = worldMatrix.d;
				matrix.tx = worldMatrix.tx;
				matrix.ty = worldMatrix.ty;
				matrix.invert();

				resultPoint.x = p_x * matrix.a + p_y * matrix.c + matrix.tx;
				resultPoint.y = p_x * matrix.b + p_y * matrix.d + matrix.ty;

				BBNativePool.putMatrix(matrix);
			}

			return resultPoint;
		}

		/**
		 * Invalidate transformation settings.
		 */
		[Inline]
		final bb_private function invalidate(p_updatedTransformation:Boolean, p_updateColor:Boolean):void
		{
			var parentTransform:BBTransform = node.parent.transform;

			// Update transformation
			if (p_updatedTransformation && !(lockInvalidation && !invalidateOnce && !parentTransform.isPRSInvalidated))
			{
				var parentWorldRotation:Number = parentTransform.worldRotation;
				var parentWorldScaleX:Number = parentTransform.worldScaleX;
				var parentWorldScaleY:Number = parentTransform.worldScaleY;
				var cos:Number = parentTransform.COS;
				var sin:Number = parentTransform.SIN;

				var newWorldX:Number = (_localX * cos - _localY * sin) * parentWorldScaleX + parentTransform.worldX;
				var newWorldY:Number = (_localX * sin + _localY * cos) * parentWorldScaleY + parentTransform.worldY;

				if (isPositionChanged || Math.abs(newWorldX - worldX) > 0.01 || Math.abs(newWorldY - worldY) > 0.01)
				{
					worldX = newWorldX;
					worldY = newWorldY;

					isPositionInvalidated = true;
				}

				var newScaleX:Number = _localScaleX * parentWorldScaleX;
				var newScaleY:Number = _localScaleY * parentWorldScaleY;

				if (isScaleChanged || Math.abs(newScaleX - worldScaleX) > 0.01 || Math.abs(newScaleY - worldScaleY) > 0.01)
				{
					worldScaleX = newScaleX;
					worldScaleY = newScaleY;

					isScaleInvalidated = true;
				}

				var newWorldRotation:Number = _localRotation + parentWorldRotation;
				if (isRotationChanged || Math.abs(newWorldRotation - worldRotation) > 0.01)
				{
					worldRotation = newWorldRotation;
					COS = Math.cos(worldRotation);
					SIN = Math.sin(worldRotation);

					isRotationInvalidated = true;
				}

				_isWorldTransformMatrixChanged = true;
				isPRSInvalidated = true;
			}

			// Update color
			if (p_updateColor)
			{
				worldAlpha = _alpha * parentTransform.worldAlpha;
				worldRed = _red * parentTransform.worldRed;
				worldGreen = _green * parentTransform.worldGreen;
				worldBlue = _blue * parentTransform.worldBlue;

				isColorShouldBeDisplayed = (4.0 - (worldRed + worldGreen + worldBlue + worldAlpha)) > 0.02 * 4;  // 0.02 - precise color
				isColorInvalidated = true;
			}

			//
			isInvalidated = true;
			invalidateOnce = false;
		}

		/**
		 */
		[Inline]
		final bb_private function resetInvalidationFlags():void
		{
			isInvalidated = false;
			isColorInvalidated = false;
			isPositionInvalidated = false;
			isRotationInvalidated = false;
			isScaleInvalidated = false;
			isPRSInvalidated = false;

			isTransformChanged = false;
			isPositionChanged = false;
			isRotationChanged = false;
			isScaleChanged = false;
			isColorChanged = false;
		}

		/**
		 */
		override protected function destroy():void
		{
			if (_localPos)
			{
				_localPos.dispose();
				_localPos = null;
			}

			if (_worldPos)
			{
				_worldPos.dispose();
				_worldPos = null;
			}

			if (_worldTransformMatrix)
			{
				BBNativePool.putMatrix(_worldTransformMatrix);
				_worldTransformMatrix = null;
			}

			if (_localTransformMatrix)
			{
				BBNativePool.putMatrix(_localTransformMatrix);
				_localTransformMatrix = null;
			}

			//
			super.destroy();
		}

		/**
		 */
		override public function copy():BBComponent
		{
			var component:BBTransform = super.copy() as BBTransform;
			component._localX = _localX;
			component._localY = _localY;
			component.worldX = worldX;
			component.worldY = worldY;
			component._localRotation = _localRotation;
			component.worldRotation = worldRotation;
			component._localScaleX = _localScaleX;
			component._localScaleY = _localScaleY;
			component.worldScaleX = worldScaleX;
			component.worldScaleY = worldScaleY;
			component._alpha = _alpha;
			component.worldAlpha = worldAlpha;
			component._red = _red;
			component.worldRed = worldRed;
			component._green = _green;
			component.worldGreen = worldGreen;
			component._blue = _blue;
			component.worldBlue = worldBlue;
			component.COS = COS;
			component.SIN = SIN;

			return component;
		}

		/**
		 */
		override public function toString():String
		{
			return  "------------------------------------------------------------------------------------------------------------------------\n" +
					"[BBTransform:\n" +
					super.toString() + "\n" +
					"{localX/localY: " + _localX + " / " + _localY + "}-{worldX/worldY: " + worldX + " / " + worldY + "}-{local/world rotation: " + _localRotation + " / " + worldRotation + "}-" +
					"{scale local: " + _localScaleX + " / " + _localScaleY + "}-{ scale world: " + worldScaleX + " / " + worldScaleY + "}" + "\n" +
					"{lockInvalidation: " + lockInvalidation + "}-{isTransformChanged: " + isTransformChanged + "}-{isScaleInvalidated: " + isScaleInvalidated + "}-{isColorChanged: " + isColorChanged + "}-" +
					"{local/world ARGB: " + _alpha + ";" + _red + ";" + _green + ";" + _blue + " / " + worldAlpha + ";" + worldRed + ";" + worldGreen + ";" + worldBlue + "}] \n" +
					"{COS: " + COS + "}-{SIN: " + SIN + "}" +
					"\n" + "------------------------------------------------------------------------------------------------------------------------\n";
		}
	}
}
