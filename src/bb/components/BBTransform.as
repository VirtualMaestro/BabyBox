/**
 * User: VirtualMaestro
 * Date: 25.01.13
 * Time: 21:11
 */
package bb.components
{
	import bb.bb_spaces.bb_private;

	import flash.geom.Matrix;
	import flash.geom.Point;

	use namespace bb_private;

	/**
	 * Represents all transformation like: translation, rotation, scale, skew.
	 * Also contain geometric data like: width, height.
	 */
	public class BBTransform extends BBComponent
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

		/**
		 * Determines if scale of transform was changed.
		 */
		public var isScaleChanged:Boolean = false;
		private var _isScaledCurrentStep:Boolean = false;

		// TODO: Add able to skew
		private var _localSkewX:Number = 0;
		private var _localSkewY:Number = 0;
		bb_private var worldSkewX:Number = 0;
		bb_private var worldSkewY:Number = 0;

		private var _worldTransformMatrix:Matrix = null;
		private var _localTransformMatrix:Matrix = null;
		private var _isWorldTransformMatrixChanged:Boolean = true;

		bb_private var isTransformChanged:Boolean = false;
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
		 */
		public function BBTransform()
		{
			super();

			_componentClass = BBTransform;
		}

		/**
		 * Sets given color in ARGB format.
		 */
		public function set color(p_value:int):void
		{
			alpha = Number((p_value >> 24) & 0xFF) / 0xFF;
			red = Number((p_value >> 16) & 0xFF) / 0xFF;
			green = Number((p_value >> 8) & 0xFF) / 0xFF;
			blue = Number(p_value & 0xFF) / 0xFF;
		}

		/**
		 *     @private
		 */
		public function get red():Number
		{
			return _red;
		}

		public function set red(p_red:Number):void
		{
			worldRed = _red = p_red > 1.0 ? 1.0 : p_red;
			isColorChanged = true;
		}

		/**
		 *     @private
		 */
		public function get green():Number
		{
			return _green;
		}

		public function set green(p_green:Number):void
		{
			worldGreen = _green = p_green > 1.0 ? 1.0 : p_green;
			isColorChanged = true;
		}

		/**
		 *     @private
		 */
		public function get blue():Number
		{
			return _blue;
		}

		public function set blue(p_blue:Number):void
		{
			worldBlue = _blue = p_blue > 1.0 ? 1.0 : p_blue;
			isColorChanged = true;
		}

		/**
		 *     @private
		 */
		public function get alpha():Number
		{
			return _alpha;
		}

		public function set alpha(p_alpha:Number):void
		{
			worldAlpha = _alpha = p_alpha > 1.0 ? 1.0 : p_alpha;
			isColorChanged = true;
		}

		/**
		 */
		public function getTransformedWorldTransformMatrix(p_scaleX:Number, p_scaleY:Number, p_rotation:Number, p_invert:Boolean):Matrix
		{
			var matrix:Matrix = worldTransformMatrix.clone();

			if (p_scaleX != 1 && p_scaleY != 1) matrix.scale(p_scaleX, p_scaleY);
			if (p_rotation != 0) matrix.rotate(p_rotation);
			if (p_invert) matrix.invert();

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
				if (_worldTransformMatrix == null) _worldTransformMatrix = new Matrix();
				_worldTransformMatrix.createBox(worldScaleX, worldScaleY, worldRotation, worldX, worldY);
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
		public function setPosition(p_x:Number, p_y:Number):void
		{
			worldX = _localX = p_x;
			worldY = _localY = p_y;
			isTransformChanged = true;
		}

		/**
		 * Sets x position.
		 */
		public function set x(p_x:Number):void
		{
			worldX = _localX = p_x;
			isTransformChanged = true;
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
		public function set y(p_y:Number):void
		{
			worldY = _localY = p_y;
			isTransformChanged = true;
		}

		/**
		 * Gets y position.
		 */
		public function get y():Number
		{
			return _localY;
		}

		/**
		 */
		private function scaleChanged():void
		{
			isScaleChanged = true;
			_isScaledCurrentStep = true;
		}

		/**
		 * Sets scale.
		 */
		public function setScale(p_scaleX:Number, p_scaleY:Number):void
		{
			worldScaleX = _localScaleX = p_scaleX;
			worldScaleY = _localScaleY = p_scaleY;
			isTransformChanged = true;
			scaleChanged();
		}

		/**
		 */
		public function set scaleX(val:Number):void
		{
			worldScaleX = _localScaleX = val;
			isTransformChanged = true;
			scaleChanged();
		}

		/**
		 */
		public function get scaleX():Number
		{
			return _localScaleX;
		}

		/**
		 */
		public function set scaleY(val:Number):void
		{
			worldScaleY = _localScaleY = val;
			isTransformChanged = true;
			scaleChanged();
		}

		/**
		 */
		public function get scaleY():Number
		{
			return _localScaleY;
		}

		/**
		 * Sets rotation in radians.
		 */
		public function set rotation(p_angle:Number):void
		{
			p_angle %= PI2;
			if (Math.abs(p_angle) < PRECISE_ROTATION) p_angle = 0;
			worldRotation = _localRotation = p_angle;
			isTransformChanged = true;
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
			worldRotation = _localRotation = (Math.round(p_angle * 10) / 10) * DEG_TO_RAD;
			isTransformChanged = true;
		}

		/**
		 * p_angle - angle in radians.
		 */
		public function setPositionAndRotation(p_x:Number, p_y:Number, p_angle:Number):void
		{
			worldX = _localX = p_x;
			worldY = _localY = p_y;

			p_angle %= PI2;
			if (Math.abs(p_angle) < PRECISE_ROTATION) p_angle = 0;
			worldRotation = _localRotation = p_angle;

			isTransformChanged = true;
		}

		/**
		 * Shift position on given offset.
		 */
		public function shiftPosition(p_offsetX:Number, p_offsetY:Number):void
		{
			_localX += p_offsetX;
			_localY += p_offsetY;
			setPosition(_localX, _localY);
		}

		/**
		 * Shift rotation by given angel.
		 */
		public function set shiftRotation(p_offsetAngle:Number):void
		{
			_localRotation += p_offsetAngle;
			rotation = _localRotation;
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
		bb_private function invalidate(p_updateTransformation:Boolean, p_updateColor:Boolean):void
		{
			var parentTransform:BBTransform = node.parent.transform;

			// Update transformation
			if (p_updateTransformation)
			{
				var parentWorldRotation:Number = parentTransform.worldRotation;
				var parentWorldScaleX:Number = parentTransform.worldScaleX;
				var parentWorldScaleY:Number = parentTransform.worldScaleY;
				var cos:Number = parentTransform.COS;
				var sin:Number = parentTransform.SIN;

				worldX = (_localX * cos - _localY * sin) * parentWorldScaleX + parentTransform.worldX;
				worldY = (_localX * sin + _localY * cos) * parentWorldScaleY + parentTransform.worldY;

				worldScaleX = _localScaleX * parentWorldScaleX;
				worldScaleY = _localScaleY * parentWorldScaleY;

				var newWorldRotation:Number = _localRotation + parentWorldRotation;
				if (newWorldRotation != worldRotation)
				{
					worldRotation = newWorldRotation;
					COS = Math.cos(worldRotation);
					SIN = Math.sin(worldRotation);
				}

				_isWorldTransformMatrixChanged = true;

				// mark transform as updated
				isTransformChanged = false;

				if (_isScaledCurrentStep) _isScaledCurrentStep = false;
				else isScaleChanged = false;
			}

			// Update color
			if (p_updateColor)
			{
				worldAlpha = _alpha * parentTransform.worldAlpha;
				worldRed = _red * parentTransform.worldRed;
				worldGreen = _green * parentTransform.worldGreen;
				worldBlue = _blue * parentTransform.worldBlue;

				isColorChanged = false;
				isColorShouldBeDisplayed = (4.0 - (worldRed + worldGreen + worldBlue + worldAlpha)) > 0.02*4;  // 0.02 - precise color
			}
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
			_isScaledCurrentStep = false;
			isTransformChanged = false;
			isColorChanged = false;
			isColorShouldBeDisplayed = false;
			_isWorldTransformMatrixChanged = true;
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
			component.isTransformChanged = isTransformChanged;
			component.isColorChanged = isColorChanged;
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
					super.toString() +"\n"+
					"{localX/localY: " + _localX+" / "+_localY + "}-{worldX/worldY: " + worldX+" / "+worldY + "}-{local/world rotation: " + _localRotation +" / "+ worldRotation + "}-"+
					"{scale local: " + _localScaleX+" / " + _localScaleY + "}-{ scale world: " + worldScaleX+" / " + worldScaleY + "}" + "\n" +
					"{isTransformChanged: " + isTransformChanged + "}-{isColorChanged: " + isColorChanged + "}-" +
					"{local/world ARGB: " + _alpha+";"+_red+";"+_green+";"+_blue+" / "+ worldAlpha+";"+worldRed+";"+worldGreen+";"+worldBlue+"}]" +
					"\n" + "------------------------------------------------------------------------------------------------------------------------\n";
		}
	}
}
