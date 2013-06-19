/**
 * User: VirtualMaestro
 * Date: 30.04.13
 * Time: 13:40
 */
package bb.components.physics.joints
{
	import bb.bb_spaces.bb_private;
	import bb.components.physics.BBPhysicsBody;

	import nape.constraint.Constraint;
	import nape.geom.Vec2;
	import nape.phys.Body;

	import vm.math.unique.UniqueId;
	import vm.str.StringUtil;

	use namespace bb_private;

	/**
	 *
	 */
	public class BBJoint
	{
		private var _name:String = "";
		private var _id:int;

		public var ownerBody:Body;
		public var jointedBody:Body;

		public var jointedActorName:String = "";

		public var swapActors:Boolean = false;

		//
		private var _type:String = "";

		private var _ownerAnchor:Vec2;
		private var _jointedAnchor:Vec2;

		private var _joint:Constraint;

		private var _hasAnchors:Boolean = false;

		//
		private var _jointMax:Number = Number.POSITIVE_INFINITY;
		private var _jointMin:Number = Number.NEGATIVE_INFINITY;
		private var _ratio:Number = 1;
		private var _rate:Number = 0;
		private var _phase:Number = 0;
		private var _direction:Vec2;

		// common props
		private var _active:Boolean = true;
		private var _ignore:Boolean = true;
		private var _stiff:Boolean = true;
		private var _breakUnderError:Boolean = false;
		private var _breakUnderForce:Boolean = false;
		private var _removeOnBreak:Boolean = true;

		private var _damping:Number = 1;
		private var _frequency:Number = 10;
		private var _maxError:Number = Number.POSITIVE_INFINITY;
		private var _maxForce:Number = Number.POSITIVE_INFINITY;

		private var _isDisposed:Boolean = false;

		/**
		 */
		public function BBJoint(p_type:String)
		{
			_type = p_type;
			_name = getName();
			_id = UniqueId.getId();
		}

		/**
		 */
		public function get name():String
		{
			return _name;
		}

		/**
		 */
		public function set name(p_value:String):void
		{
			p_value = StringUtil.trim(p_value);
			_name = p_value == "" ? getName() : p_value;
		}

		/**
		 * Id of joint.
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 */
		public function get thisBodyComponent():BBPhysicsBody
		{
			return ownerBody ? ownerBody.userData.bb_component : null;
		}

		/**
		 */
		public function get jointedBodyComponent():BBPhysicsBody
		{
			return jointedBody ? jointedBody.userData.bb_component : null;
		}

		/**
		 * Returns strings describe type of joint e.g. "pivot".
		 */
		public function get type():String
		{
			return _type;
		}

		/**
		 */
		public function get ownerAnchor():Vec2
		{
			return _ownerAnchor;
		}

		/**
		 */
		public function get jointedAnchor():Vec2
		{
			return _jointedAnchor;
		}

		/**
		 */
		public function get joint():Constraint
		{
			return _joint;
		}

		/**
		 */
		public function set joint(p_val:Constraint):void
		{
			if (_joint) return;

			_joint = p_val;
			_joint.userData.bb_joint = this;

			if (_hasAnchors)
			{
				_ownerAnchor = _joint["anchor1"];
				_jointedAnchor = _joint["anchor2"];
			}

			if (_joint.hasOwnProperty("direction")) _direction = _joint["direction"];
		}

		/**
		 * Returns true if current joint has anchors (e.g. pivot joint has anchors, but angle joint hasn't).
		 */
		public function get hasAnchors():Boolean
		{
			return _hasAnchors;
		}

		/**
		 * Dispose joint and removes from both BBPhysicsBody components.
		 */
		public function dispose():void
		{
			if (!_isDisposed)
			{
				var physicsBody1:BBPhysicsBody = thisBodyComponent;
				var physicsBody2:BBPhysicsBody = jointedBodyComponent;

				if (physicsBody1) physicsBody1.removeJoint(this);
				if (physicsBody2) physicsBody2.removeJoint(this);

				if (_joint)
				{
					if (_joint.userData.bb_joint) _joint.userData.bb_joint = null;
					_joint.space = null;
//					thisBody.constraints.remove(_joint);       // ConstraintList is immutable
//					jointedBody.constraints.remove(_joint);    // ConstraintList is immutable
					_joint = null;
				}

				ownerBody = null;
				jointedBody = null;
				_hasAnchors = false;
				_ownerAnchor = null;
				_jointedAnchor = null;
				_direction = null;

				/// reset to default ///
				_name = "";
				jointedActorName = "";

				_jointMax = Number.POSITIVE_INFINITY;
				_jointMin = Number.NEGATIVE_INFINITY;
				_ratio = 1;
				_rate = 0;
				_phase = 0;

				// common props
				_active = true;
				_ignore = true;
				_stiff = true;
				_breakUnderError = false;
				_breakUnderForce = false;
				_removeOnBreak = true;

				_damping = 1;
				_frequency = 10;
				_maxError = Number.POSITIVE_INFINITY;
				_maxForce = Number.POSITIVE_INFINITY;

				_isDisposed = true;

				// adds to pool
				put(this);
			}
		}

		/**
		 * Makes copy of BBJoint.
		 */
		public function copy():BBJoint
		{
			var joint:BBJoint = get(type);
			joint._name = _name;
			joint.jointedActorName = jointedActorName;
			joint._ownerAnchor = _ownerAnchor ? _ownerAnchor.copy(true) : Vec2.weak();
			joint._jointedAnchor = _jointedAnchor ? _jointedAnchor.copy(true) : Vec2.weak();
			joint._hasAnchors = _hasAnchors;
			joint.jointMax = _jointMax;
			joint.jointMin = _jointMin;
			joint.ratio = _ratio;
			joint.rate = _rate;
			joint.phase = _phase;
			if (_direction) joint._direction = _direction.copy(true);

			// common
			joint.active = _active;
			joint.ignore = _ignore;
			joint.stiff = _stiff;
			joint.breakUnderError = _breakUnderError;
			joint.breakUnderForce = _breakUnderForce;
			joint.removeOnBreak = _removeOnBreak;
			joint.damping = _damping;
			joint.frequency = _frequency;
			joint.maxError = _maxError;
			joint.maxForce = _maxForce;

			return joint;
		}

		/**
		 */
		public function toString():String
		{
			var ownerAnchorTrace:String = "<" + (ownerAnchor ? ownerAnchor.x + ", " + ownerAnchor.y : "0, 0") + ">";
			var jointedAnchorTrace:String = "<" + (jointedAnchor ? jointedAnchor.x + ", " + jointedAnchor.y : "0, 0") + ">";
			var anchorsTrace:String = "{ownerAnchor: "+ownerAnchorTrace+"}-{jointedAnchor: "+jointedAnchorTrace+"}\n";
			var jointTrace:String = "";
			jointTrace += "[Joint {id: "+_id+"}-{type: "+type+"}-{name: "+_name+"}-{jointedActorName: "+jointedActorName+"}\n";

			switch (type)
			{
				case "pivot":
				{
					jointTrace += anchorsTrace;
					break;
				}

				case "distance":
				{
					jointTrace += anchorsTrace;
					jointTrace += "{jointMin: "+jointMin+"}-{jointMax: "+jointMax+"}\n";
					break;
				}

				case "line":
				{
					jointTrace += anchorsTrace;
					jointTrace += "{jointMin: "+jointMin+"}-{jointMax: "+jointMax+"}-{direction: "+direction.x+", "+direction.y+"}\n";
					break;
				}

				case "weld":
				{
					jointTrace += anchorsTrace;
					jointTrace += "{phase: "+phase+"}\n";
					break;
				}

				case "angle":
				{
					jointTrace += "{jointMin: "+jointMin+"}-{jointMax: "+jointMax+"}-{ratio: "+ratio+"}\n";
					break;
				}

				case "motor":
				{
					jointTrace += "{rate: "+rate+"}-{ratio: "+ratio+"}\n";
					break;
				}
			}

			jointTrace += "{active: "+active+"}-{ignore: "+ignore+"}-{stiff: "+stiff+"}\n" +
						  "{breakUnderError: "+breakUnderError+"}-{breakUnderForce: "+breakUnderForce+"}-{removeOnBreak: "+removeOnBreak+"}\n" +
						  "{damping: "+damping+"}-{frequency: "+frequency+"}-{maxError: "+maxError+"}-{maxForce: "+maxForce+"}\n";

			return jointTrace;
		}

		//
		private var _jointPrototype:XML;

		/**
		 * Returns XML prototype of joint.
		 * @return XML
		 */
		public function getPrototype():XML
		{
			_jointPrototype = <joint/>;

			// Adds attributes
			_jointPrototype.@name = _name;
			_jointPrototype.@type = _type;

			// Adds properties
			addProperty("jointedActorName", jointedActorName, "string");

			addProperty("active", _active, "boolean");
			addProperty("ignore", _ignore, "boolean");
			addProperty("stiff", _stiff, "boolean");
			addProperty("breakUnderError", _breakUnderError, "boolean");
			addProperty("breakUnderForce", _breakUnderForce, "boolean");
			addProperty("removeOnBreak", _removeOnBreak, "boolean");

			addProperty("damping", _damping, "number");
			addProperty("frequency", _frequency, "number");
			addProperty("maxError", _maxError, "number");
			addProperty("maxForce", _maxForce, "number");
			addProperty("swapActors", swapActors, "boolean");

			if (_type == "angle" || _type == "motor")
			{
				addProperty("ratio", _ratio, "number");

				if (_type == "angle")
				{
					addProperty("jointMin", _jointMin, "number");
					addProperty("jointMax", _jointMax, "number");
				}
				else addProperty("rate", _rate, "number");
			}
			else
			{
				addProperty("ownerAnchor", _ownerAnchor.x + "," + _ownerAnchor.y, "point");
				addProperty("jointedAnchor", _jointedAnchor.x + "," + _jointedAnchor.y, "point");

				switch (_type)
				{
					case "distance":
					{
						addProperty("jointMin", _jointMin, "number");
						addProperty("jointMax", _jointMax, "number");

						break;
					}

					case "line":
					{
						addProperty("jointMin", _jointMin, "number");
						addProperty("jointMax", _jointMax, "number");
						addProperty("direction", _direction.x + "," + _direction.y, "point");

						break;
					}

					case "weld":
					{
						addProperty("phase", _phase, "number");

						break;
					}
				}
			}

			return _jointPrototype;
		}

		/**
		 */
		private function addProperty(p_propName:String, p_propValue:*, p_propType:String = ""):void
		{
			_jointPrototype.appendChild(<{p_propName} type={p_propType}>{p_propValue}</{p_propName}>);
		}

		/**
		 * Creates joint from given XML prototype.
		 * @return BBJoint
		 */
		static public function getFromPrototype(p_jointPrototype:XML):BBJoint
		{
			return _jointFactories[p_jointPrototype.@type](p_jointPrototype);
		}

		//
		static private var _jointFactories:Array = [];

		{
			_jointFactories["pivot"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var position:Array;
				var ownerAnchor:Vec2;
				var jointedAnchor:Vec2;

				position = String(p_jointPrototype.elements("ownerAnchor")).split(",");
				ownerAnchor = Vec2.weak(position[0], position[1]);

				position = String(p_jointPrototype.elements("jointedAnchor")).split(",");
				jointedAnchor = Vec2.weak(position[0], position[1]);

				var joint:BBJoint = pivotJoint(String(p_jointPrototype.elements("jointedActorName")), ownerAnchor, jointedAnchor);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};

			_jointFactories["distance"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var position:Array;
				var ownerAnchor:Vec2;
				var jointedAnchor:Vec2;

				position = String(p_jointPrototype.elements("ownerAnchor")).split(",");
				ownerAnchor = Vec2.weak(position[0], position[1]);

				position = String(p_jointPrototype.elements("jointedAnchor")).split(",");
				jointedAnchor = Vec2.weak(position[0], position[1]);

				var jointMin:Number = p_jointPrototype.elements("jointMin");
				var jointMax:Number = p_jointPrototype.elements("jointMax");

				var joint:BBJoint = distanceJoint(String(p_jointPrototype.elements("jointedActorName")), ownerAnchor, jointedAnchor, jointMin, jointMax);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};

			_jointFactories["line"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var position:Array;
				var ownerAnchor:Vec2;
				var jointedAnchor:Vec2;

				position = String(p_jointPrototype.elements("ownerAnchor")).split(",");
				ownerAnchor = Vec2.weak(position[0], position[1]);

				position = String(p_jointPrototype.elements("jointedAnchor")).split(",");
				jointedAnchor = Vec2.weak(position[0], position[1]);

				var jointMin:Number = p_jointPrototype.elements("jointMin");
				var jointMax:Number = p_jointPrototype.elements("jointMax");

				position = String(p_jointPrototype.elements("direction")).split(",");
				var direction:Vec2 = Vec2.weak(position[0], position[1]);

				var joint:BBJoint = lineJoint(String(p_jointPrototype.elements("jointedActorName")), ownerAnchor, jointedAnchor, direction, jointMin, jointMax);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};

			_jointFactories["weld"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var position:Array;
				var ownerAnchor:Vec2;
				var jointedAnchor:Vec2;

				position = String(p_jointPrototype.elements("ownerAnchor")).split(",");
				ownerAnchor = Vec2.weak(position[0], position[1]);

				position = String(p_jointPrototype.elements("jointedAnchor")).split(",");
				jointedAnchor = Vec2.weak(position[0], position[1]);

				var phase:Number = p_jointPrototype.elements("phase");

				var joint:BBJoint = weldJoint(String(p_jointPrototype.elements("jointedActorName")), ownerAnchor, jointedAnchor, phase);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};

			_jointFactories["angle"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var jointMin:Number = p_jointPrototype.elements("jointMin");
				var jointMax:Number = p_jointPrototype.elements("jointMax");
				var ratio:Number = p_jointPrototype.elements("ratio");

				var joint:BBJoint = angleJoint(String(p_jointPrototype.elements("jointedActorName")), jointMin, jointMax, ratio);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};


			_jointFactories["motor"] =
			function(p_jointPrototype:XML):BBJoint
			{
				var rate:Number = p_jointPrototype.elements("rate");
				var ratio:Number = p_jointPrototype.elements("ratio");

				var joint:BBJoint = motorJoint(String(p_jointPrototype.elements("jointedActorName")), rate, ratio);
				setCommonProps(joint, p_jointPrototype);

				return joint;
			};
		}

		/**
		 */
		static private function setCommonProps(p_joint:BBJoint, p_prototype:XML):void
		{
			p_joint._name = p_prototype.@name;
			p_joint._active = p_prototype.elements("active") == "true";
			p_joint._ignore = p_prototype.elements("ignore") == "true";
			p_joint._stiff = p_prototype.elements("stiff") == "true";
			p_joint._breakUnderError = p_prototype.elements("breakUnderError") == "true";
			p_joint._breakUnderForce = p_prototype.elements("breakUnderForce") == "true";
			p_joint._removeOnBreak = p_prototype.elements("removeOnBreak") == "true";

			p_joint._damping = p_prototype.elements("damping");
			p_joint._frequency = p_prototype.elements("frequency");
			p_joint._maxError = p_prototype.elements("maxError");
			p_joint._maxForce = p_prototype.elements("maxForce");
			p_joint.swapActors = p_prototype.elements("swapActors") == "true";
		}

		/**
		 * Returns BBJoint with settings of pivot joint.
		 */
		static public function pivotJoint(p_jointedActorName:String = "", p_ownerAnchor:Vec2 = null, p_jointedAnchor:Vec2 = null):BBJoint
		{
			var pivotJoint:BBJoint = getBaseJointWithAnchors("pivot", p_jointedActorName, p_ownerAnchor, p_jointedAnchor);
			return pivotJoint;
		}

		/**
		 * Returns BBJoint with settings of distance joint.
		 */
		static public function distanceJoint(p_jointedActorName:String = "", p_ownerAnchor:Vec2 = null, p_jointedAnchor:Vec2 = null,
											 p_jointMin:Number = 0, p_jointMax:Number = 1):BBJoint
		{
			if (p_jointMin > p_jointMax) throw new Error("BBJoint.distanceJoint: jointMin should be less or equal jointMax");

			var distanceJoint:BBJoint = getBaseJointWithAnchors("distance", p_jointedActorName, p_ownerAnchor, p_jointedAnchor);
			distanceJoint._jointMin = p_jointMin;
			distanceJoint._jointMax = p_jointMax;

			return distanceJoint;
		}

		/**
		 * Returns BBJoint with settings of line joint.
		 */
		static public function lineJoint(p_jointedActorName:String = "", p_ownerAnchor:Vec2 = null, p_jointedAnchor:Vec2 = null,
										 p_direction:Vec2 = null, p_jointMin:Number = 0, p_jointMax:Number = 1):BBJoint
		{
			if (p_jointMin > p_jointMax) throw new Error("BBJoint.lineJoint: jointMin should be less or equal jointMax");
			if (p_direction && Math.abs(p_direction.length) > 1) throw new Error("BBJoint.lineJoint: direction should be normalize");

			var lineJoint:BBJoint = getBaseJointWithAnchors("line", p_jointedActorName, p_ownerAnchor, p_jointedAnchor);
			lineJoint._direction = p_direction ? p_direction : Vec2.weak(0,1);
			lineJoint._jointMin = p_jointMin;
			lineJoint._jointMax = p_jointMax;

			return lineJoint;
		}

		/**
		 * Returns BBJoint with settings of weld joint.
		 */
		static public function weldJoint(p_jointedActorName:String = "", p_ownerAnchor:Vec2 = null, p_jointedAnchor:Vec2 = null, p_phase:Number = 0):BBJoint
		{
			var weldJoint:BBJoint = getBaseJointWithAnchors("weld", p_jointedActorName, p_ownerAnchor, p_jointedAnchor);
			weldJoint._phase = p_phase;

			return weldJoint;
		}

		/**
		 */
		static private function getBaseJointWithAnchors(p_type:String, p_jointedActorName:String = "", p_ownerAnchor:Vec2 = null, p_jointedAnchor:Vec2 = null):BBJoint
		{
			var joint:BBJoint = get(p_type);
			joint.jointedActorName = StringUtil.trim(p_jointedActorName);
			joint._ownerAnchor = p_ownerAnchor ? p_ownerAnchor : Vec2.weak();
			joint._jointedAnchor = p_jointedAnchor ? p_jointedAnchor : Vec2.weak();
			joint._hasAnchors = true;

			return joint;
		}

		/**
		 */
		static public function angleJoint(p_jointedActorName:String = "", p_jointMin:Number = Number.NEGATIVE_INFINITY, p_jointMax:Number = Number.POSITIVE_INFINITY, p_ratio:Number = 1):BBJoint
		{
			var joint:BBJoint = get("angle");
			joint.jointedActorName = StringUtil.trim(p_jointedActorName);
			joint._jointMin = p_jointMin;
			joint._jointMax = p_jointMax;
			joint._ratio = p_ratio;

			return joint;
		}

		/**
		 */
		static public function motorJoint(p_jointedActorName:String = "", p_rate:Number = 0, p_ratio:Number = 1):BBJoint
		{
			var joint:BBJoint = get("motor");
			joint.jointedActorName = StringUtil.trim(p_jointedActorName);
			joint._rate = p_rate;
			joint._ratio = p_ratio;

			return joint;
		}

		/// COMMON ACCESSOR ///

		/**
		 */
		public function get active():Boolean
		{
			return _joint ? _joint.active : _active;
		}

		public function set active(p_val:Boolean):void
		{
			if (_active == p_val) return;

			if (_joint)
			{
				if (p_val) _active = ownerBody.space && jointedBody.space;
				_active = _active && p_val;
				_joint.active = _active;
			}
			else _active = p_val;
		}

		public function get ignore():Boolean
		{
			return _joint ? _joint.ignore : _ignore;
		}

		public function set ignore(value:Boolean):void
		{
			_ignore = value;
			if (_joint) _joint.ignore = _ignore;
		}

		public function get stiff():Boolean
		{
			return _joint ? _joint.stiff : _stiff;
		}

		public function set stiff(value:Boolean):void
		{
			_stiff = value;
			if (_joint) _joint.stiff = _stiff;
		}

		public function get breakUnderError():Boolean
		{
			return _joint ? _joint.breakUnderError : _breakUnderError;
		}

		public function set breakUnderError(value:Boolean):void
		{
			_breakUnderError = value;
			if (_joint) _joint.breakUnderError = _breakUnderError;
		}

		public function get breakUnderForce():Boolean
		{
			return _joint ? _joint.breakUnderForce : _breakUnderForce;
		}

		public function set breakUnderForce(value:Boolean):void
		{
			_breakUnderForce = value;
			if (_joint) _joint.breakUnderForce = _breakUnderForce;
		}

		public function get removeOnBreak():Boolean
		{
			return _joint ? _joint.removeOnBreak : _removeOnBreak;
		}

		public function set removeOnBreak(value:Boolean):void
		{
			_removeOnBreak = value;
			if (_joint) _joint.removeOnBreak = _removeOnBreak;
		}

		public function get damping():Number
		{
			return _joint ? _joint.damping : _damping;
		}

		public function set damping(value:Number):void
		{
			_damping = value;
			if (_joint) _joint.damping = _damping;
		}

		public function get frequency():Number
		{
			return _joint ? _joint.frequency : _frequency;
		}

		public function set frequency(value:Number):void
		{
			_frequency = value;
			if (_joint) _joint.frequency = _frequency;
		}

		public function get maxError():Number
		{
			return _joint ? _joint.maxError : _maxError;
		}

		public function set maxError(value:Number):void
		{
			_maxError = value;
			if (_joint) _joint.maxError = _maxError;
		}

		public function get maxForce():Number
		{
			return _joint ? _joint.maxForce : _maxForce;
		}

		public function set maxForce(value:Number):void
		{
			_maxForce = value;
			if (_joint) _joint.maxForce = _maxForce;
		}

		/////////////////////////

		public function get jointMax():Number
		{
			return _joint && _joint["jointMax"] ? _joint["jointMax"] : _jointMax;
		}

		public function set jointMax(value:Number):void
		{
			_jointMax = value;
			if (_joint && _joint["jointMax"]) _joint["jointMax"] = _jointMax;
		}

		public function get jointMin():Number
		{
			return _joint && _joint["jointMin"] ? _joint["jointMin"] : _jointMin;
		}

		public function set jointMin(value:Number):void
		{
			_jointMin = value;
			if (_joint && _joint["jointMin"]) _joint["jointMin"] = _jointMin;
		}

		public function get ratio():Number
		{
			return _joint && _joint["ratio"] ? _joint["ratio"] : _ratio;
		}

		public function set ratio(value:Number):void
		{
			_ratio = value;
			if (_joint && _joint["ratio"]) _joint["ratio"] = _ratio;
		}

		public function get rate():Number
		{
			return _joint && _joint["rate"] ? _joint["rate"] : _rate;
		}

		public function set rate(value:Number):void
		{
			_rate = value;
			if (_joint && _joint["rate"]) _joint["rate"] = _rate;
		}

		public function get phase():Number
		{
			return _joint && _joint["phase"] ? _joint["phase"] : _phase;
		}

		public function set phase(value:Number):void
		{
			_phase = value;
			if (_joint && _joint["phase"]) _joint["phase"] = _phase;
		}

		public function get direction():Vec2
		{
			return _direction;
		}

		////
		/**
		 * Returns unique name for joint.
		 */
		static private function getName():String
		{
			return UniqueId.getUniqueName("joint");
		}

		////////////////////
		///////  POOL //////
		////////////////////

		//
		static private var _pool:Vector.<BBJoint> = new <BBJoint>[];
		static private var _numInPool:int = 0;

		/**
		 * Returns instance of Point class.
		 */
		static public function get(p_type:String):BBJoint
		{
			var joint:BBJoint;

			if (_numInPool > 0)
			{
				joint = _pool[--_numInPool];
				_pool[_numInPool] = null;
				joint._type = p_type;
				joint._isDisposed = false;
			}
			else joint = new BBJoint(p_type);

			return joint;
		}

		/**
		 * Put Point instance to pool.
		 */
		static public function put(p_joint:BBJoint):void
		{
			_pool[_numInPool++] = p_joint;
		}

		/**
		 * Returns number of Point instances in pool.
		 */
		static public function numInPool():int
		{
			return _numInPool;
		}

		/**
		 * Clear Point pool.
		 */
		static public function rid():void
		{
			_numInPool = _pool.length;
			for (var i:int = 0; i < _numInPool; i++)
			{
				_pool[i] = null;
			}

			_pool.length = _numInPool = 0;
		}
	}
}
