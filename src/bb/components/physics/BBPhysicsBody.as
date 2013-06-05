/**
 * User: VirtualMaestro
 * Date: 14.03.13
 * Time: 22:43
 */
package bb.components.physics
{
	import bb.bb_spaces.bb_private;
	import bb.components.BBComponent;
	import bb.components.BBTransform;
	import bb.components.physics.joints.BBConstraintFactory;
	import bb.components.physics.joints.BBJoint;
	import bb.core.BBNode;
	import bb.core.BabyBox;
	import bb.modules.BBPhysicsModule;
	import bb.signals.BBSignal;
	import bb.tools.physics.BBPhysicalMaterials;

	import nape.dynamics.InteractionFilter;
	import nape.geom.Vec2;
	import nape.geom.Vec2Iterator;
	import nape.geom.Vec2List;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.FluidProperties;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	import nape.shape.ShapeIterator;
	import nape.shape.ShapeList;
	import nape.shape.ShapeType;
	import nape.space.Space;

	import vm.math.numbers.NumberUtil;
	import vm.str.StringUtil;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Represents physic component.
	 * Need for physic simulation.
	 */
	public class BBPhysicsBody extends BBComponent
	{
		static private const SCALE_PRECISE:Number = 0.01;

		/**
		 * Allow to use hand for this object.
		 */
		public var allowHand:Boolean = false;

		/**
		 * Lock physic body. If 'true' mean node's transform does update physic body, in other case vise versa.
		 */
		private var _lock:Boolean = true;

		// Assoc. table with names of shapes
		private var _shapeNames:Array;
		private var _space:Space = null;
		private var _body:Body = null;
		private var _bodyPosition:Vec2 = null;
		private var _transform:BBTransform = null;
		private var _scale:Number = 1.0;

		//
		private var _isNeedInitJoints:Boolean = false;

		//
		private var _thisJoints:Vector.<BBJoint>;
		private var _attachedJoints:Vector.<BBJoint>;
		private var _initJointList:Vector.<BBJoint>;

		/**
		 */
		public function BBPhysicsBody()
		{
			super();

			_body = new Body();
			_body.userData.bb_component = this;
			_bodyPosition = _body.position;

			//
			_thisJoints = new <BBJoint>[];
			_attachedJoints = new <BBJoint>[];

			//
			onAdded.add(addedToNodeHandler);
			onRemoved.add(unlinkedFromNodeHandler);
		}

		/**
		 */
		private function addedToNodeHandler(p_signal:BBSignal):void
		{
			_transform = node.transform;
			_transform.independentUpdateWorldParameters = true;

			if (!_space) _space = (BabyBox.getInstance().getModule(BBPhysicsModule) as BBPhysicsModule).space;

			if (node.isOnStage) addToStage();

			node.onAdded.add(addedToStageHandler);
			node.onRemoved.add(unlinkedFromStageHandler);
			node.onActive.add(onNodeActiveHandler);

			//
			updateEnable = false;
		}

		/**
		 */
		private function addedToStageHandler(p_signal:BBSignal):void
		{
			if (node.isOnStage)
			{
				addToStage();
			}
		}

		/**
		 */
		private function addToStage():void
		{
			node.onUpdated.add(initBody);
			node.onUpdated.add(initJoints);
		}

		/**
		 */
		private function initBody(p_signal:BBSignal):void
		{
			if (_active)
			{
				p_signal.removeCurrentListener();

				updateEnable = _body.type != BodyType.STATIC;

				scale = _transform.worldScaleX < _transform.worldScaleY ? _transform.worldScaleX : _transform.worldScaleY;
				_body.position.setxy(_transform.worldX, _transform.worldY);
				_body.rotation = _transform.worldRotation;
				_body.space = _space;
				_lock = false;
			}
		}

		/**
		 */
		private function unlinkedFromStageHandler(p_signal:BBSignal):void
		{
			node.onRemoved.remove(unlinkedFromStageHandler);
			node.onUpdated.remove(initBody);
			node.onUpdated.remove(initJoints);

			////
			activateJoints = false;
			_body.space = null;
		}

		/**
		 */
		private function unlinkedFromNodeHandler(p_signal:BBSignal):void
		{
			node.onAdded.remove(addedToStageHandler);
			node.onRemoved.remove(unlinkedFromStageHandler);
			node.onActive.remove(onNodeActiveHandler);

			_lock = true;
		}

		/**
		 */
		private function onNodeActiveHandler(p_signal:BBSignal):void
		{
			active = p_signal.params;
		}

		/**
		 */
		public function addShape(p_shape:Shape, p_shapeName:String = "", p_position:Vec2 = null, p_material:Material = null, p_filter:InteractionFilter = null):Shape
		{
			CONFIG::debug
			{
				var cutShapeName:String = StringUtil.trim(p_shapeName);
				Assert.isTrue(cutShapeName == p_shapeName, "Incorrect shape name. It should be without any spaces characters", "BBPhysicsBody.addShape");
				if (_shapeNames) Assert.isTrue(_shapeNames[p_shapeName] == null, "Shape with given name '" + p_shapeName + "' already exist. Can't exist shapes with the same names", "BBPhysicsBody.addShape");
			}

			//
			addShapeName(p_shapeName, p_shape);

			//
			if (p_position) p_shape.localCOM.set(p_position);
			_body.shapes.add(p_shape);

			if (p_material) p_shape.material = p_material;
			if (p_filter) p_shape.filter = p_filter;

			//
			if (Math.abs(_scale - 1.0) > 0.01) p_shape.scale(_scale, _scale);

			return p_shape;
		}

		/**
		 * Adds shape name to list.
		 */
		private function addShapeName(p_shapeName:String, p_shape:Shape):void
		{
			if (p_shapeName && p_shapeName != "")
			{
				if (_shapeNames == null) _shapeNames = [];
				_shapeNames[p_shapeName] = p_shape;
				p_shape.userData.shapeName = p_shapeName;
			}
		}

		/**
		 * Adds circle shape to body.
		 */
		public function addCircle(p_radius:int, p_shapeName:String = "", p_position:Vec2 = null, p_material:Material = null, p_filter:InteractionFilter = null):Circle
		{
			var circle:Circle = new Circle(p_radius, p_position, p_material, p_filter);
			addShape(circle, p_shapeName);

			return circle;
		}

		/**
		 * Adds box shape to body.
		 */
		public function addBox(p_width:int, p_height:int, p_shapeName:String = "", p_position:Vec2 = null, p_material:Material = null, p_filter:InteractionFilter = null):Polygon
		{
			var box:Polygon = new Polygon(Polygon.box(p_width, p_height, true), p_material, p_filter);
			addShape(box, p_shapeName, p_position);

			return box;
		}

		/**
		 * Adds joint to physic body.
		 */
		public function addJoint(p_joint:BBJoint):void
		{
			if (!_initJointList) _initJointList = new <BBJoint>[];

			_initJointList.push(p_joint);

			if (!_isNeedInitJoints)
			{
				_isNeedInitJoints = true;
				if (node && node.isOnStage) node.onUpdated.add(initJoints);
			}
		}

		/**
		 */
		private function initJoints(p_signal:BBSignal):void
		{
			if (_active)
			{
				p_signal.removeCurrentListener();

				// activate exist joints
				activateJoints = true;

				// creates new joints if need
				if (_initJointList)
				{
					var isNeedToScale:Boolean = Math.abs(1 - _scale) >= SCALE_PRECISE;
					var currentNodeName:String = node.name;
					var jointsNum:int = _initJointList.length;
					var joint:BBJoint;
					for (var i:int = 0; i < jointsNum; i++)
					{
						joint = _initJointList[i];
						_initJointList[i] = null;

						if (joint.jointedActorName != currentNodeName)
						{
							if (isNeedToScale)
							{
								joint.thisAnchor.muleq(_scale);
								joint.jointedAnchor.muleq(_scale);
							}

							//
							createJoint(joint);
							_thisJoints.push(joint);
							if (joint.jointedBodyComponent) joint.jointedBodyComponent._attachedJoints.push(joint);
						}
					}

					_initJointList.length = 0;
					_initJointList = null;
				}

				_isNeedInitJoints = false;
			}
		}

		/**
		 */
		private function createJoint(p_joint:BBJoint):void
		{
			var jointedActorName:String = p_joint.jointedActorName;

			CONFIG::debug
			{
				Assert.isTrue(jointedActorName != node.name, "actor can't to connect to itself (actor name '" + jointedActorName + "'). " +
						"You should to choose another actor to have possible connect through joint", "BBPhysicsBody.createJoint");
			}

			var jointedBody:Body;

			if (jointedActorName == "") jointedBody = _space.world;
			else jointedBody = findBody(jointedActorName);

			CONFIG::debug
			{
				Assert.isTrue(jointedBody != null, "jointed actor wasn't found ('" + jointedActorName +"')", "BBPhysicsBody.createJoint");
			}

			p_joint.thisBody = _body;
			p_joint.jointedBody = jointedBody;

			BBConstraintFactory.createJoint(p_joint).space = _space;
		}

		/**
		 */
		private function findBody(p_jointedActorName:String):Body
		{
			var body:Body;
			var parentActor:BBNode = node.parent;

			if (parentActor.name == p_jointedActorName)
			{
				var physics:BBPhysicsBody = parentActor.getComponent(BBPhysicsBody) as BBPhysicsBody;
				if (physics == null) throw new Error("BBPhysicsBody.findBody: Actor with name '" + p_jointedActorName + "' hasn't physics component, so you can't connected with it through joint");

				body = physics.body;
			}
			else
			{
				body = findInChildren(node, p_jointedActorName);

				if (body == null) body = findInChildren(parentActor, p_jointedActorName, node);
			}

			return body;
		}

		/**
		 * Search node with given name in given children.
		 */
		static private function findInChildren(p_actor:BBNode, p_actorName:String, p_exceptActor:BBNode = null):Body
		{
			var body:Body;
			var child:BBNode = p_actor.childrenHead;

			while (child && !body)
			{
				if (child != p_exceptActor)
				{
					if (child.name == p_actorName)
					{
						CONFIG::debug
						{
							Assert.isTrue(child.getComponent(BBPhysicsBody) != null, "can't create joint due to actor with name '" + p_actorName + "' hasn't BBPhysicsBody component",
									"BBPhysicsBody.findInChildren");
						}

						body = (child.getComponent(BBPhysicsBody) as BBPhysicsBody).body;
					}
					else body = findInChildren(child, p_actorName);
				}

				child = child.next;
			}

			return body;
		}

		/**
		 * Removes joint from body (used only in BBJoint).
		 */
		bb_private function removeJoint(p_joint:BBJoint):void
		{
			if (p_joint.joint)
			{
				var wasFound:Boolean = false;
				var numJoints:int = _thisJoints.length;
				for (var i:int = numJoints-1; i >= 0; i--)
				{
					if (_thisJoints[i] == p_joint)
					{
						wasFound = true;
						_thisJoints[i] = null;
						_thisJoints.splice(i, 1);
						break;
					}
				}

				if (!wasFound)
				{
					numJoints = _attachedJoints.length;
					for (i = numJoints-1; i >= 0; i--)
					{
						if (_attachedJoints[i] == p_joint)
						{
							wasFound = true;
							_attachedJoints[i] = null;
							_attachedJoints.splice(i, 1);
							break;
						}
					}
				}
			}
			else if (_initJointList)
			{
				numJoints = _initJointList.length;
				for (i = numJoints-1; i >= 0; i--)
				{
					if (_initJointList[i] == p_joint)
					{
						_initJointList[i] = null;
						_initJointList.splice(i, 1);
						break;
					}
				}
			}
		}

		/**
		 * Removes all joints which this component own.
		 * if 'p_removeAttached' == true - mean removes also joints which were attached by another component (this component isn't owns these components).
		 */
		public function removeAllJoints(p_removeAttached:Boolean = false):void
		{
			var numJoints:int;
			while((numJoints = _thisJoints.length) > 0)
			{
				_thisJoints[numJoints-1].dispose();
			}

			if (p_removeAttached)
			{
				while((numJoints = _attachedJoints.length) > 0)
				{
					_attachedJoints[numJoints-1].dispose();
				}
			}

			if (_initJointList)
			{
				while((numJoints = _initJointList.length) > 0)
				{
					_initJointList[numJoints-1].dispose();
				}

				_initJointList = null;
			}
		}

		/**
		 * Returns joint by given name.
		 * p_includeAttached - will search  in attached joints too.
		 */
		public function getJointByName(p_jointName:String, p_includeAttached:Boolean = true):BBJoint
		{
			var numJoints:int = _thisJoints.length;
			for (var i:int = 0; i < numJoints; i++)
			{
				if (_thisJoints[i].name == p_jointName) return _thisJoints[i];
			}

			//
			if (p_includeAttached)
			{
				numJoints = _attachedJoints.length;
				for (i = 0; i < numJoints; i++)
				{
					if (_thisJoints[i].name == p_jointName) return _thisJoints[i];
				}
			}

			//
			if (_initJointList && _initJointList.length > 0)
			{
				var numInitJoints:int = _initJointList.length;
				for (var j:int = 0; j < numInitJoints; j++)
				{
					if (_initJointList[i].name == p_jointName) return _initJointList[i];
				}
			}

			return null;
		}

		/**
		 * Returns shape by its name.
		 * If shape with given name doesn't exist returns null.
		 */
		public function getShapeByName(p_shapeName:String):Shape
		{
			if (_shapeNames == null) return null;
			return _shapeNames[p_shapeName];
		}

		/**
		 * Removes shape from body by given name.
		 * If shape with given name doesn't exist returns null.
		 */
		public function removeShapeByName(p_shapeName:String):void
		{
			if (_shapeNames)
			{
				for (var shapeName:String in _shapeNames)
				{
					if (shapeName == p_shapeName)
					{
						var shape:Shape = _shapeNames[p_shapeName];
						delete _shapeNames[p_shapeName];

						_body.shapes.remove(shape);

						break;
					}
				}
			}
		}

		/**
		 * Removes given shape.
		 */
		public function removeShape(p_shape:Shape):void
		{
			_body.shapes.remove(p_shape);
		}

		/**
		 * Removes all shapes.
		 */
		public function removeShapes():void
		{
			_body.shapes.clear();
		}

		/**
		 * Set scale for physics body.
		 */
		private function set scale(p_scale:Number):void
		{
			if (Math.abs(p_scale - _scale) >= SCALE_PRECISE)
			{
				var nScale:Number = NumberUtil.round(1.0 / _scale) * p_scale;
				_body.scaleShapes(nScale, nScale);
				_scale = p_scale;

				// change joints position
				var joint:BBJoint;
				if (_thisJoints && _thisJoints.length > 0)
				{
					var _jointsNum:int = _thisJoints.length;
					for (var i:int = 0; i < _jointsNum; i++)
					{
						joint = _thisJoints[i];

						if (joint.hasAnchors)
						{
							joint.thisAnchor.muleq(nScale);
							joint.jointedAnchor.muleq(nScale);
						}
					}
				}
			}
		}

		/**
		 */
		public function getScale():Number
		{
			return _scale;
		}

		/**
		 * Sets body type via BodyType: BodyType.DYNAMIC, BodyType.KINEMATIC, BodyType.STATIC
		 */
		public function set type(p_val:BodyType):void
		{
			p_val = p_val ? p_val : BodyType.STATIC;

			if (_body.type == p_val) return;
			_body.type = p_val;

			// mean we change type at runtime
			if (node && node.isOnStage)
			{
				if (_body.type == BodyType.STATIC) updateEnable = false;
				else if (_body.type == BodyType.KINEMATIC) _lock = true;
				else
				{
					updateEnable = true;
					_lock = false;
				}
			}
		}

		/**
		 */
		public function get type():BodyType
		{
			return _body.type;
		}

		/**
		 */
		public function get body():Body
		{
			return _body;
		}

		/**
		 */
		override public function set active(p_val:Boolean):void
		{
			if (_active == p_val) return;
			super.active = p_val;

			if (_active)
			{
				if (node && node.isOnStage)
				{
					_body.space = _space;
					activateJoints = true;
				}
			}
			else
			{
				_body.space = null;
				activateJoints = false;
			}
		}

		/**
		 */
		private function set activateJoints(p_val:Boolean):void
		{
			var numJoints:int = _thisJoints.length;
			for (var i:int = 0; i < numJoints; i++) _thisJoints[i].active = p_val;
		}

		/**
		 */
		override public function update(p_deltaTime:Number):void
		{
			if (_transform.isInvalidated || _lock)
			{
				if (_transform.isScaleInvalidated) scale = _transform.worldScaleX < _transform.worldScaleY ? _transform.worldScaleX : _transform.worldScaleY;
				if (_transform.isPositionInvalidated) _bodyPosition.setxy(_transform.worldX, _transform.worldY);
				if (_transform.isRotationInvalidated) _body.rotation = _transform.worldRotation;
			}
			else
			{
				_transform.worldX = _bodyPosition.x;
				_transform.worldY = _bodyPosition.y;
				_transform.worldRotation = _body.rotation;
			}
		}

		/**
		 */
		override public function dispose():void
		{
			removeAllJoints(true);
			removeShapes();

			_transform = null;
			_scale = 1.0;
			_lock = true;
			_isNeedInitJoints = false;

			if (cacheable)
			{
				onAdded.add(addedToNodeHandler);
				onRemoved.add(unlinkedFromNodeHandler);

				_body.rotation = 0;
				_body.position.setxy(0,0);
				_body.velocity.setxy(0,0);
				_body.kinematicVel.setxy(0,0);
				_body.surfaceVel.setxy(0,0);
				_body.angularVel = 0;
				_body.kinAngVel = 0;
			}

			super.dispose();
		}

		/**
		 */
		override protected function rid():void
		{
			super.rid();

			_thisJoints = null;
			_attachedJoints = null;
			_initJointList = null;
			_space = null;
			_body = null;
			_bodyPosition = null;
		}

		/**
		 * Makes copy of BBPhysicsBody component.
		 */
		override public function copy():BBComponent
		{
			var component:BBPhysicsBody = super.copy() as BBPhysicsBody;
			component.allowHand = allowHand;
			component._body = _body.copy();
			component._body.userData.bb_component = component;
			component._bodyPosition = component._body.position;
			component._scale = _scale;

			// copy shape names
			var originList:ShapeList = _body.shapes;
			var copiedList:ShapeList = component._body.shapes;
			var shapesNum:int = originList.length;
			var originShape:Shape;
			var copiedShape:Shape;

			for (var i:int = 0; i < shapesNum; i++)
			{
				originShape = originList.at(i);
				copiedShape = copiedList.at(i);

				component.addShapeName(originShape.userData.shapeName, copiedShape);
			}

			// copy joints
			var numJoints:int = _thisJoints.length;
			if (numJoints > 0)
			{
				for (i = 0; i < numJoints; i++)
				{
					component.addJoint(_thisJoints[i].copy());
				}
			}

			if (_initJointList && (numJoints = _initJointList.length) > 0)
			{
				for (i = 0; i < numJoints; i++)
				{
					component.addJoint(_initJointList[i].copy());
				}
			}

			return component;
		}

		/**
		 */
		override public function toString():String
		{
			var shapeTrace:String = "";
			var numShapes:int = _body.shapes.length;
			var iterator:ShapeIterator = _body.shapes.iterator();
			var shape:Shape;
			var material:Material;
			var filter:InteractionFilter;

			if (numShapes > 0)
			{
				while(iterator.hasNext())
				{
					shape = iterator.next();
					material = shape.material;
					filter = shape.filter;

					if (shape.isCircle())
					{
						shapeTrace += "{shape type: circle}-{radius: "+shape.castCircle.radius+"}\n";
					}
					else
					{
						shapeTrace += "{shape type: polygon}\n{local vertices:\n";
						var vertexIterator:Vec2Iterator = shape.castPolygon.localVerts.iterator();
						var vertex:Vec2;

						while(vertexIterator.hasNext())
						{
							vertex = vertexIterator.next();
							shapeTrace += "   <"+vertex.x+" / "+vertex.y+">\n";
						}

						shapeTrace += "}\n";
					}

					shapeTrace += "{localCOM: "+shape.localCOM.x + " / "+ shape.localCOM.y + "}-{worldCOM: "+shape.worldCOM.x + " / "+ shape.worldCOM.y + "}\n" +
							"{angDrag: "+shape.angDrag+"}-{area: "+shape.area+"}-{bounds: "+shape.bounds.x+"; "+shape.bounds.y+"; "+ shape.bounds.width+"; "+ shape.bounds.height+"}-{inertia: "+shape.inertia+"}\n" +
							"{sensorEnabled: "+shape.sensorEnabled+"}-{fluidEnabled: "+shape.fluidEnabled+"}\n" +
							"{material: [density: "+shape.material.density+"] [elasticity: "+shape.material.elasticity+"] [staticFriction: "+shape.material.staticFriction+
							"] [dynamicFriction: "+shape.material.dynamicFriction+"] [rollingFriction: "+shape.material.rollingFriction+"]}\n" +
							"{filter:\n" +
							"   [collisionGroup:"+shape.filter.collisionGroup+" collisionMask:"+shape.filter.collisionMask+"]\n" +
							"   [sensorGroup:"+shape.filter.sensorGroup+" sensorMask:"+shape.filter.sensorMask+"]\n" +
							"   [fluidGroup:"+shape.filter.fluidGroup+" fluidMask:"+shape.filter.fluidMask+"]\n}\n";
					if (shape.fluidProperties)
					{
						var gravity:Vec2 = shape.fluidProperties.gravity;
						shapeTrace += "{fluidProperties: [viscosity:"+shape.fluidProperties.viscosity+"] [density: "+shape.fluidProperties.density+
								(gravity ? ("] [gravity: " + gravity.x + " / " + gravity.y) : "") + "]}\n";
					}

					shapeTrace += "==========\n";
				}
			}

			var jointsTrace:String = "";
			var numJoints:int = (_initJointList) ? _thisJoints.length + _initJointList.length : _thisJoints.length;

			if (numJoints > 0)
			{
				jointsTrace += "-----\n";

				for (var i:int = 0; i < _thisJoints.length; i++)
				{
					jointsTrace += _thisJoints[i].toString();
					jointsTrace += "-----\n";
				}

				if (_initJointList)
				{
					for (var j:int = 0; j < _initJointList.length; j++)
					{
						jointsTrace += _initJointList[j].toString();
						jointsTrace += "-----\n";
					}
				}

				jointsTrace += "==========\n";
			}

			return  "------------------------------------------------------------------------------------------------------------------------\n" +
					"[BBPhysicsBody:\n" +
					super.toString() + "\n" +
					"{Added to space: " + (_body.space != null) + "}\n" +
					"{position: " + _bodyPosition.x +" / "+ _bodyPosition.y+"}-{rotation: " + _body.rotation + "}-{scale: " + _scale + "}\n" +
					"{lock: " + _lock + "}-{allowHand: " + allowHand +"}-{isNeedInitJoints: " + _isNeedInitJoints + "}]\n" +
					"{Shapes num: " + numShapes + "}:\n" + shapeTrace + "\n" +
					"{Joints num: " + numJoints + "}:\n" + jointsTrace + "\n" +
					"------------------------------------------------------------------------------------------------------------------------";
		}

		/**
		 */
		override public function getPrototype():XML
		{
			var physicsPrototype:XML = super.getPrototype();

			addPrototypeProperty("x", _bodyPosition.x, "Number");
			addPrototypeProperty("y", _bodyPosition.y, "Number");
			addPrototypeProperty("rotation", _body.rotation, "Number");
			addPrototypeProperty("allowRotation", _body.allowRotation, "Boolean");
			addPrototypeProperty("allowMovement", _body.allowMovement, "Boolean");
			addPrototypeProperty("angularVel", _body.angularVel, "Number");
			addPrototypeProperty("disableCCD", _body.disableCCD, "Boolean");
			addPrototypeProperty("gravMass", _body.gravMass, "Number");
			addPrototypeProperty("kinAngVel", _body.kinAngVel, "Number");
			addPrototypeProperty("kinematicVel", _body.kinematicVel.x + "," + _body.kinematicVel.y, "point");
			addPrototypeProperty("mass", _body.mass, "Number");
			addPrototypeProperty("surfaceVel", _body.surfaceVel.x + "," + _body.surfaceVel.y, "point");
			addPrototypeProperty("torque", _body.torque, "Number");
			addPrototypeProperty("velocity", _body.velocity.x + "," + _body.velocity.y, "point");
			var bodyType:String = (_body.type == BodyType.DYNAMIC) ? "DYNAMIC" : ((_body.type == BodyType.STATIC) ? "STATIC" : "KINEMATIC");
			addPrototypeProperty("type", bodyType, "String");

			// parse shapes
			physicsPrototype.shapes = <shapes/>;
			var shapeXML:XML;
			var shape:Shape;
			var shapeMaterial:Material;
			var filter:InteractionFilter;
			var fluidProperties:FluidProperties;
			var shapeIterator:ShapeIterator = _body.shapes.iterator();

			while (shapeIterator.hasNext())
			{
				shape = shapeIterator.next();
				shapeXML = <shape/>;

				// Attributes
				shapeXML.@name = (shape.userData.hasOwnProperty("shapeName")) ? shape.userData.shapeName : "";
				shapeXML.@type = (shape.type == ShapeType.CIRCLE) ? "CIRCLE" : "POLYGON";
				shapeXML.@predefineMaterial = "NONE";

				//
				addPrototypeProperty("angDrag", shape.angDrag, "number", shapeXML);

				if (shape.type == ShapeType.CIRCLE)
				{
					addPrototypeProperty("radius", (shape as Circle).radius, "number", shapeXML);
				}
				else
				{
					var vertices:XML = <vertices/>;
					var localVerts:Vec2List = (shape as Polygon).localVerts;
					var iterator:Vec2Iterator = localVerts.iterator();
					var vertex:Vec2;
					while (iterator.hasNext())
					{
						vertex = iterator.next();
						addPrototypeProperty("vertex", vertex.x + "," + vertex.y, "point", vertices);
					}

					shapeXML.vertices = vertices;
				}

				addPrototypeProperty("position", shape.localCOM.x + "," + shape.localCOM.y, "point", shapeXML);

				shapeMaterial = shape.material;
				var material:XML = <material/>;

				addPrototypeProperty("density", shapeMaterial.density, "number", material);
				addPrototypeProperty("elasticity", shapeMaterial.elasticity, "number", material);
				addPrototypeProperty("staticFriction", shapeMaterial.staticFriction, "number", material);
				addPrototypeProperty("dynamicFriction", shapeMaterial.dynamicFriction, "number", material);
				addPrototypeProperty("rollingFriction", shapeMaterial.rollingFriction, "number", material);

				shapeXML.material = material;

				// parse interaction filter
				filter = shape.filter;
				var filterXML:XML = <filter/>;

				addPrototypeProperty("collisionGroup", filter.collisionGroup, "number", filterXML);
				addPrototypeProperty("collisionMask", filter.collisionMask, "number", filterXML);
				addPrototypeProperty("sensorGroup", filter.sensorGroup, "number", filterXML);
				addPrototypeProperty("sensorMask", filter.sensorMask, "number", filterXML);
				addPrototypeProperty("fluidGroup", filter.fluidGroup, "number", filterXML);
				addPrototypeProperty("fluidMask", filter.fluidMask, "number", filterXML);

				shapeXML.filter = filterXML;

				// parse fluid properties
				fluidProperties = shape.fluidProperties;
				var fluidPropsXML:XML = <fluidProperties/>;

				addPrototypeProperty("enabled", shape.fluidEnabled, "boolean", fluidPropsXML);
				addPrototypeProperty("density", fluidProperties.density, "number", fluidPropsXML);
				addPrototypeProperty("viscosity", fluidProperties.viscosity, "number", fluidPropsXML);


				if (fluidProperties.gravity && fluidProperties.gravity.length > 1)
				{
					addPrototypeProperty("gravity", fluidProperties.gravity.x + "," + fluidProperties.gravity.y, "point", fluidPropsXML);
				}

				shapeXML.fluidProperties = fluidPropsXML;

				physicsPrototype.shapes.appendChild(shapeXML);
			}

			// parse joints
			if (_thisJoints.length > 0 || (_initJointList && _initJointList.length > 0))
			{
				var jointsXML:XML = <joints/>;
				var numJoints:int = _thisJoints ? _thisJoints.length : 0;
				var joint:BBJoint;
				var currentNodeName:String = node.name;

				for (var i:int = 0; i < numJoints; i++)
				{
					joint = _thisJoints[i];
					if (joint.jointedActorName != currentNodeName)
					{
						jointsXML.appendChild(joint.getPrototype());
					}
				}

				numJoints = _initJointList ? _initJointList.length : 0;

				for (i = 0; i < numJoints; i++)
				{
					joint = _initJointList[i];
					if (joint.jointedActorName != currentNodeName)
					{
						jointsXML.appendChild(joint.getPrototype());
					}
				}

				physicsPrototype.appendChild(jointsXML);
			}

			return physicsPrototype;
		}

		/**
		 */
		override public function updateFromPrototype(p_prototype:XML):void
		{
			super.updateFromPrototype(p_prototype);

			var properties:XMLList = p_prototype.properties;
			var x:Number = properties.elements("x");
			var y:Number = properties.elements("y");
			_bodyPosition.setxy(x, y);
			_body.rotation = properties.elements("rotation");
			_body.allowMovement = properties.elements("allowMovement") == "true";
			_body.allowRotation = properties.elements("allowRotation") == "true";
			_body.angularVel = properties.elements("angularVel");
			_body.disableCCD = properties.elements("disableCCD") == "true";
			_body.gravMass = properties.elements("gravMass");
			_body.mass = properties.elements("mass");
			_body.kinAngVel = properties.elements("kinAngVel");
			var kinemVel:Array = String(properties.elements("kinematicVel")).split(",");
			_body.kinematicVel.setxy(kinemVel[0], kinemVel[1]);
			var surfaceVel:Array = String(properties.elements("surfaceVel")).split(",");
			_body.surfaceVel.setxy(surfaceVel[0], surfaceVel[1]);
			_body.torque = properties.elements("torque");
			var velocity:Array = String(properties.elements("velocity")).split(",");
			_body.velocity.setxy(velocity[0], velocity[1]);
			var typeBody:String = properties.elements("type");
			type = (typeBody == "STATIC") ? BodyType.STATIC : ((typeBody == "DYNAMIC") ? BodyType.DYNAMIC : BodyType.KINEMATIC);

			// parse and creates shapes
			var shapes:XMLList = p_prototype.shapes.children();
			var shapeXML:XML;
			var numShapes:int = shapes.length();
			for (var i:int = 0; i < numShapes; i++)
			{
				shapeXML = shapes[i];

				// Attributes
				var shapeName:String = shapeXML.@name;
				var shapeType:String = shapeXML.@type;//"POLYGON"
				var predefineMaterial:String = shapeXML.@predefineMaterial;
				predefineMaterial = StringUtil.trim(predefineMaterial.toLowerCase());

				//
				var positionVals:Array = shapeXML.position.split(",");
				var position:Vec2 = Vec2.weak(positionVals[0], positionVals[1]);

				var currentShape:Shape;
				var currentMaterial:Material;
				var currentFilter:InteractionFilter;

				// parse and create material
				if (predefineMaterial != "none") currentMaterial = BBPhysicalMaterials.getByName(predefineMaterial);
				else
				{
					var materialXML:XMLList = shapeXML.material;
					var density:Number = materialXML.elements("density");
					var elasticity:Number = materialXML.elements("elasticity");
					var staticFriction:Number = materialXML.elements("staticFriction");
					var dynamicFriction:Number = materialXML.elements("dynamicFriction");
					var rollingFriction:Number = materialXML.elements("rollingFriction");
					currentMaterial = new Material(elasticity, dynamicFriction, staticFriction, density, rollingFriction);
				}

				// parse and create interaction filter
				var filterXML:XMLList = shapeXML.filter;
				var collisionGroup:int = filterXML.collisionGroup;
				var collisionMask:int = filterXML.collisionMask;
				var sensorGroup:int = filterXML.sensorGroup;
				var sensorMask:int = filterXML.sensorMask;
				var fluidGroup:int = filterXML.fluidGroup;
				var fluidMask:int = filterXML.fluidMask;

				if ((collisionGroup + sensorGroup + fluidGroup) != 3 || (collisionMask + sensorMask + fluidMask) != -3)
				{
					currentFilter = new InteractionFilter(collisionGroup, collisionMask, sensorGroup, sensorMask, fluidGroup, fluidMask);
				}

				var scaleFactor:Number = 1 / _scale;
				position.muleq(scaleFactor);

				// create and add shape
				if (shapeType == "CIRCLE")
				{
					currentShape = addCircle(Number(shapeXML.radius) * scaleFactor, shapeName, position, currentMaterial, currentFilter);
				}
				else
				{
					var verticesXML:XMLList = shapeXML.vertices.children();
					var vertexData:Array;
					var vertex:Vec2;
					var verticesList:Array = [];
					var numVertices:int = verticesXML.length();

					for (var j:int = 0; j < numVertices; j++)
					{
						vertexData = verticesXML[j].split(",");
						vertex = Vec2.get(Number(vertexData[0]) * scaleFactor, Number(vertexData[1]) * scaleFactor);
						verticesList.push(vertex);
					}

					currentShape = new Polygon(verticesList, currentMaterial, currentFilter);
					addShape(currentShape, shapeName, position);
				}

				// parse fluid props
				var fluidPropertiesXML:XMLList = shapeXML.fluidProperties;
				currentShape.fluidEnabled = fluidPropertiesXML.enabled == "true";
				if (currentShape.fluidEnabled)
				{
					var fluidProperties:FluidProperties = new FluidProperties(fluidPropertiesXML.density, fluidPropertiesXML.viscosity);
					if (fluidPropertiesXML.gravity)
					{
						var gravityXY:Array = fluidPropertiesXML.gravity.split(",");
						fluidProperties.gravity = Vec2.weak(gravityXY[0], gravityXY[1]);
					}
				}
			}

			// parse and creates joints
			var joints:XMLList = p_prototype.joints.children();
			var numJoints:int = joints.length();
			for (j = 0; j < numJoints; j++)
			{
				addJoint(BBJoint.getFromPrototype(joints[j]));
			}
		}

		////////////////////
		/// FACTORY ////////
		////////////////////

		/**
		 * Returns instance of BBPhysicsBody.
		 */
		static public function get(p_type:BodyType = null):BBPhysicsBody
		{
			var body:BBPhysicsBody = BBComponent.get(BBPhysicsBody) as BBPhysicsBody;
			body.type = p_type;
			return body;
		}

		/**
		 * Returns instance of BBPhysicsBody added to node.
		 */
		static public function getWithNode(p_type:BodyType = null, p_nodeName:String = ""):BBPhysicsBody
		{
			var body:BBPhysicsBody = get(p_type);
			var node:BBNode = BBNode.get(p_nodeName);
			node.addComponent(body);
			return body;
		}

		/**
		 * Creates physics from given prototype xml.
		 */
		static public function getFromPrototype(p_prototype:XML):BBPhysicsBody
		{
			var physics:BBPhysicsBody = get();
			physics.updateFromPrototype(p_prototype);
			return physics;
		}
	}
}
