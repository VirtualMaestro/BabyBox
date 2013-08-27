/**
 * User: VirtualMaestro
 * Date: 25.01.13
 * Time: 21:11
 */
package bb.core
{
	import bb.bb_spaces.bb_private;

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
		private const PI2:Number = Math.PI * 2;
		private const RAD_TO_DEG:Number = 180.0 / Math.PI;
		private const DEG_TO_RAD:Number = Math.PI / 180.0;

		//
		private var PRECISE_ROTATION:Number = (Math.PI / 180.0) / 10;

		private var _localX:Number = 0;
		private var _localY:Number = 0;
		bb_private var worldX:Number = 0;
		bb_private var worldY:Number = 0;

		private var _localRotation:Number = 0; // in radians
		bb_private var worldRotation:Number = 0; // in radians

		private var _localScaleX:Number = 1;
		private var _localScaleY:Number = 1;
		bb_private var worldScaleX:Number = 1;
		bb_private var worldScaleY:Number = 1;

		// TODO: Add able to skew
		private var _localSkewX:Number = 0;
		private var _localSkewY:Number = 0;
		bb_private var worldSkewX:Number = 0;
		bb_private var worldSkewY:Number = 0;

		private var _worldTransformMatrix:Matrix = null;
		private var _localTransformMatrix:Matrix = null;
		private var _isWorldTransformMatrixChanged:Boolean = true;

		bb_private var isTransformChanged:Boolean = false;
		bb_private var isPositionChanged:Boolean = false;
		bb_private var isRotationChanged:Boolean = false;
		bb_private var isScaleChanged:Boolean = false;
		bb_private var isColorChanged:Boolean = false;

		bb_private var COS:Number = 1.0;
		bb_private var SIN:Number = 0.0;

		// color //
		bb_private var isColorShouldBeDisplayed:Boolean = false;

		bb_private var worldRed:Number = 1;
		private var _red:Number = 1;

		bb_private var worldGreen:Number = 1;
		private var _green:Number = 1;

		bb_private var worldBlue:Number = 1;
		private var _blue:Number = 1;

		bb_private var worldAlpha:Number = 1;
		private var _alpha:Number = 1;

		/**
		 * Flag need when world transforms (like worldX, worldY etc.) updates directly, avoid update pipeline. E.g. updates by physic component.
		 * This mean every time when need to get local params like worldX/Y, worldRotation etc. related local params will calculates every time.
		 */
		bb_private var independentUpdateWorldParameters:Boolean = false;

		/**
		 * Lock invalidation method, so world's parameters like worldX, worldRotation etc. won't not update (changed).
		 */
		public var lockInvalidation:Boolean = false;

		/**
		 * Is transform changed and updated values.
		 */
		public var isInvalidated:Boolean = false;
		public var isPositionInvalidated:Boolean = false;
		public var isRotationInvalidated:Boolean = false;
		public var isScaleInvalidated:Boolean = false;
		public var isColorInvalidated:Boolean = false;

		/**
		 */
		public function BBTransform()
		{
			super();
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
		 * Transforms world matrix and return new one by given parameters.
		 * Almost the same as transformWorldMatrix but changes translation (tx/ty) and there is possible to invert.
		 */
		public function getTransformedWorldTransformMatrix(p_scaleX:Number, p_scaleY:Number, p_rotation:Number, p_invert:Boolean = false):Matrix
		{
			var matrix:Matrix = worldTransformMatrix.clone();

			if (p_scaleX != 1 && p_scaleY != 1) matrix.scale(p_scaleX, p_scaleY);
			if (p_rotation != 0) matrix.rotate(p_rotation);
			if (p_invert) matrix.invert();

			return matrix;
		}

		/**
		 * Returns new transformed world matrix by given parameters.
		 * NOTICE: scale and rotation won't change the translation of matrix (tx/ty).
		 */
		public function transformWorldMatrix(p_scaleX:Number = 1.0, p_scaleY:Number = 1.0, p_rotation:Number = 0.0, p_x:Number = 0, p_y:Number = 0):Matrix
		{
			var matrix:Matrix = worldTransformMatrix.clone();
			var tx:Number = matrix.tx + p_x;
			var ty:Number = matrix.ty + p_y;

			if (p_scaleX != 1 && p_scaleY != 1) matrix.scale(p_scaleX, p_scaleY);
			if (p_rotation != 0) matrix.rotate(p_rotation);

			matrix.tx = tx;
			matrix.ty = ty;

			return matrix;
		}

		/**
		 * Returns world transform matrix.
		 */
		public function get worldTransformMatrix():Matrix
		{
			if (isTransformChanged) invalidate(true, false);
			if (_isWorldTransformMatrixChanged)
			{
				var sX:Number = (worldScaleX == 0) ? 0.000001 : worldScaleX;
				var sY:Number = (worldScaleY == 0) ? 0.000001 : worldScaleY;

				if (_worldTransformMatrix == null) _worldTransformMatrix = new Matrix();
				_worldTransformMatrix.createBox(sX, sY, worldRotation, worldX, worldY);
				_isWorldTransformMatrixChanged = false;
			}

			return _worldTransformMatrix;
		}

		/**
		 * Returns local transform matrix.
		 */
		public function get localTransformMatrix():Matrix
		{
			if (_localTransformMatrix == null) _localTransformMatrix = new Matrix();
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

			if (independentUpdateWorldParameters && node.parent) invalidate(true, false);
		}

		/**
		 * Returns instance of Vec2 with position values.
		 * Creates new Vec2 non-weak instance.
		 */
		final public function getPosition():Vec2
		{
			return Vec2.get(x, y);
		}

		/**
		 * Returns point with world position.
		 * Returns new Vec2 instance non-weak.
		 */
		final public function getPositionWorld():Vec2
		{
			return Vec2.get(worldX, worldY);
		}

		/**
		 * Sets x position.
		 */
		[Inline]
		final public function set x(p_x:Number):void
		{
			/*worldX = */
			_localX = p_x;
			isTransformChanged = true;
			isPositionChanged = true;

			if (independentUpdateWorldParameters && node.parent) invalidate(true, false);
		}

		/**
		 * Gets x position.
		 */
		public function get x():Number
		{
			if (independentUpdateWorldParameters)
			{
				var parentNode:BBNode = node.parent;
				if (parentNode) _localX = worldX - parentNode.transform.worldX;
			}

			return _localX;
		}

		/**
		 * Sets y position.
		 */
		[Inline]
		final public function set y(p_y:Number):void
		{
			/*worldY = */
			_localY = p_y;
			isTransformChanged = true;
			isPositionChanged = true;

			if (independentUpdateWorldParameters && node.parent) invalidate(true, false);
		}

		/**
		 * Gets y position.
		 */
		public function get y():Number
		{
			if (independentUpdateWorldParameters)
			{
				var parentNode:BBNode = node.parent;
				if (parentNode) _localY = worldY - parentNode.transform.worldY;
			}

			return _localY;
		}

		/**
		 * p_angle - angle in radians.
		 */
		public function setPositionAndRotation(p_x:Number, p_y:Number, p_angle:Number):void
		{
			setPosition(p_x, p_y);
			rotation = p_angle;
		}

		/**
		 * Sets rotation in radians.
		 */
		[Inline]
		final public function set rotation(p_angle:Number):void
		{
			p_angle %= PI2;
			if (Math.abs(p_angle) < PRECISE_ROTATION) p_angle = 0;

			/*worldRotation = */
			_localRotation = p_angle;

			isTransformChanged = true;
			isRotationChanged = true;

			if (independentUpdateWorldParameters && node.parent) invalidate(true, false);
		}

		/**
		 */
		public function get rotation():Number
		{
			if (independentUpdateWorldParameters)
			{
				var parentNode:BBNode = node.parent;
				if (parentNode) _localRotation = worldRotation - parentNode.transform.worldRotation;
			}

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
		 * Sets scale.
		 */
		[Inline]
		final public function setScale(p_scaleX:Number, p_scaleY:Number):void
		{
			_localScaleX = p_scaleX;
			_localScaleY = p_scaleY;
			isTransformChanged = true;
			isScaleChanged = true;

			keepSamePositionWhenScaled();
		}

		/**
		 */
		public function set scaleX(p_val:Number):void
		{
			_localScaleX = p_val;
			isTransformChanged = true;
			isScaleChanged = true;

			keepSamePositionWhenScaled();
		}

		/**
		 */
		public function get scaleX():Number
		{
			calcLocalScaleWhenIndependentUpdate();
			return _localScaleX;
		}

		/**
		 */
		public function set scaleY(p_val:Number):void
		{
			_localScaleY = p_val;
			isTransformChanged = true;
			isScaleChanged = true;

			keepSamePositionWhenScaled();
		}

		/**
		 */
		public function get scaleY():Number
		{
			calcLocalScaleWhenIndependentUpdate();
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
		 * if 'independentUpdateWorldParameters' is true (mostly it is related to physics component) and doing scaling, need to keep position at the same place.
		 */
		[Inline]
		private function keepSamePositionWhenScaled():void
		{
			if (independentUpdateWorldParameters)
			{
				var parentNode:BBNode = node.parent;
				if (parentNode)
				{
					_localX = worldX - parentNode.transform.worldX;
					_localY = worldY - parentNode.transform.worldY;
				}
			}
		}

		/**
		 * if 'independentUpdateWorldParameters' is true (mostly it is related to physics component) and trying to get scaleX or scaleY.
		 */
		[Inline]
		private function calcLocalScaleWhenIndependentUpdate():void
		{
			if (independentUpdateWorldParameters)
			{
				var parentNode:BBNode = node.parent;
				if (parentNode)
				{
					_localScaleX = worldScaleX - parentNode.transform.worldScaleX;
					_localScaleY = worldScaleY - parentNode.transform.worldScaleY;
				}
			}
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
		 */
		public function localToWorld(p_point:Point):Point
		{
			if (node) p_point = worldTransformMatrix.transformPoint(p_point);
			return p_point;
		}

		/**
		 * Transform given point from world coordinate system to local.
		 */
		public function worldToLocal(p_point:Point):Point
		{
			if (node)
			{
				var matrix:Matrix = worldTransformMatrix.clone();
				matrix.invert();
				p_point = matrix.transformPoint(p_point);
			}

			return p_point;
		}

		/**
		 * Invalidate transformation settings.
		 */
		[Inline]
		final bb_private function invalidate(p_updateTransformation:Boolean, p_updateColor:Boolean):void
		{
			if (lockInvalidation) return;

			var parentTransform:BBTransform = node.parent.transform;

			// Update transformation
			if (p_updateTransformation)
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

				// mark transform as updated
				isTransformChanged = false;
				isPositionChanged = false;
				isRotationChanged = false;
				isScaleChanged = false;
			}

			// Update color
			if (p_updateColor)
			{
				worldAlpha = _alpha * parentTransform.worldAlpha;
				worldRed = _red * parentTransform.worldRed;
				worldGreen = _green * parentTransform.worldGreen;
				worldBlue = _blue * parentTransform.worldBlue;

				isColorChanged = false;
				isColorShouldBeDisplayed = (4.0 - (worldRed + worldGreen + worldBlue + worldAlpha)) > 0.02 * 4;  // 0.02 - precise color
				isColorInvalidated = true;
			}

			//
			isInvalidated = true;
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
		}

		/**
		 */
		override public function dispose():void
		{
			super.dispose();

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
			_localSkewX = 0;
			_localSkewY = 0;
			worldSkewX = 0;
			worldSkewY = 0;
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

			PRECISE_ROTATION = (Math.PI / 180.0) / 10;

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
			independentUpdateWorldParameters = false;
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
			component._localSkewX = _localSkewX;
			component._localSkewY = _localSkewY;
			component.worldSkewX = worldSkewX;
			component.worldSkewY = worldSkewY;
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
			component.PRECISE_ROTATION = PRECISE_ROTATION;

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
					"{isTransformChanged: " + isTransformChanged + "}-{isScaleInvalidated: " + isScaleInvalidated + "}-{isColorChanged: " + isColorChanged + "}-" +
					"{local/world ARGB: " + _alpha + ";" + _red + ";" + _green + ";" + _blue + " / " + worldAlpha + ";" + worldRed + ";" + worldGreen + ";" + worldBlue + "}] \n" +
					"{COS: " + COS + "}-{SIN: " + SIN + "}-{PRECISE_ROTATION: " + PRECISE_ROTATION + "}" +
					"\n" + "------------------------------------------------------------------------------------------------------------------------\n";
		}
	}
}
