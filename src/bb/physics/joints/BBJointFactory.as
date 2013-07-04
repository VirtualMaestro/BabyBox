/**
 * User: VirtualMaestro
 * Date: 01.05.13
 * Time: 12:12
 */
package bb.physics.joints
{
	import nape.constraint.AngleJoint;
	import nape.constraint.Constraint;
	import nape.constraint.DistanceJoint;
	import nape.constraint.LineJoint;
	import nape.constraint.MotorJoint;
	import nape.constraint.PivotJoint;
	import nape.constraint.WeldJoint;
	import nape.space.Space;

	/**
	 * For internal use.
	 */
	public class BBJointFactory
	{
		static public var space:Space;

		static private var _jointFactories:Array = [];

		{
			_jointFactories["pivot"] = pivotJoint;
			_jointFactories["distance"] = distanceJoint;
			_jointFactories["line"] = lineJoint;
			_jointFactories["weld"] = weldJoint;
			_jointFactories["angle"] = angleJoint;
			_jointFactories["motor"] = motorJoint;
		}

		/**
		 */
		static public function createJoint(p_joint:BBJoint):Constraint
		{
			return _jointFactories[p_joint.type](p_joint);
		}

		/**
		 */
		static private function pivotJoint(p_joint:BBJoint):PivotJoint
		{
			var pivotJoint:PivotJoint = new PivotJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.ownerAnchor, p_joint.jointedAnchor);
			setBaseSettings(pivotJoint, p_joint);
			p_joint.joint = pivotJoint;

			return pivotJoint;
		}

		/**
		 */
		static private function distanceJoint(p_joint:BBJoint):DistanceJoint
		{
			var distanceJoint:DistanceJoint = new DistanceJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.ownerAnchor, p_joint.jointedAnchor, p_joint.jointMin, p_joint.jointMax);
//			distanceJoint.jointMin = p_joint.jointMin;
//			distanceJoint.jointMax = p_joint.jointMax;
			setBaseSettings(distanceJoint, p_joint);
			p_joint.joint = distanceJoint;

			return distanceJoint;
		}

		/**
		 */
		static private function lineJoint(p_joint:BBJoint):LineJoint
		{
			var lineJoint:LineJoint = new LineJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.ownerAnchor, p_joint.jointedAnchor, p_joint.direction, p_joint.jointMin, p_joint.jointMax);
//			lineJoint.jointMin = p_joint.jointMin;
//			lineJoint.jointMax = p_joint.jointMax;
//			lineJoint.direction = p_joint.direction;
			setBaseSettings(lineJoint, p_joint);
			p_joint.joint = lineJoint;

			return lineJoint;
		}

		/**
		 */
		static private function weldJoint(p_joint:BBJoint):WeldJoint
		{
			var weldJoint:WeldJoint = new WeldJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.ownerAnchor, p_joint.jointedAnchor, p_joint.phase);
//			weldJoint.phase = p_joint.phase;
			setBaseSettings(weldJoint, p_joint);
			p_joint.joint = weldJoint;

			return weldJoint;
		}

		/**
		 */
		static private function angleJoint(p_joint:BBJoint):AngleJoint
		{
			var angleJoint:AngleJoint = new AngleJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.jointMin, p_joint.jointMax, p_joint.ratio);
//			angleJoint.jointMin = p_joint.jointMin;
//			angleJoint.jointMax = p_joint.jointMax;
//			angleJoint.ratio = p_joint.ratio;
			setBaseSettings(angleJoint, p_joint);
			p_joint.joint = angleJoint;

			return angleJoint;
		}

		/**
		 */
		static private function motorJoint(p_joint:BBJoint):MotorJoint
		{
			var motorJoint:MotorJoint = new MotorJoint(p_joint.ownerBody, p_joint.jointedBody, p_joint.rate, p_joint.ratio);
//			motorJoint.rate = p_joint.rate;
//			motorJoint.ratio = p_joint.ratio;
			setBaseSettings(motorJoint, p_joint);
			p_joint.joint = motorJoint;

			return motorJoint;
		}

		/**
		 */
		static private function setBaseSettings(p_constraint:Constraint, p_joint:BBJoint):void
		{
			p_constraint.active = p_joint.active;
			p_constraint.ignore = p_joint.ignore;
			p_constraint.breakUnderError = p_joint.breakUnderError;
			p_constraint.breakUnderForce = p_joint.breakUnderForce;
			p_constraint.removeOnBreak = p_joint.removeOnBreak;
			p_constraint.stiff = p_joint.stiff;

			p_constraint.damping = p_joint.damping;
			p_constraint.frequency = p_joint.frequency;
			p_constraint.maxError = p_joint.maxError;
			p_constraint.maxForce = p_joint.maxForce;
		}
	}
}
