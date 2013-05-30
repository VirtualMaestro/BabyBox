package src.bb.core
{
	import bb.signals.BBSignal;

	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	import src.bb.bb_spaces.bb_private;
	import src.bb.components.BBComponent;
	import src.bb.components.BBTransform;
	import src.bb.components.renderable.BBRenderable;
	import src.bb.constants.mouse.BBMouseFlags;
	import src.bb.core.context.BBContext;
	import src.bb.events.BBMouseEvent;
	import src.bb.modules.BBGraphModule;
	import src.bb.pools.BBActorPool;
	import src.bb.pools.BBComponentPool;

	import vm.math.unique.UniqueId;
	import vm.str.StringUtil;

	CONFIG::debug
	{
		import flash.utils.getQualifiedClassName;

		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Container for components. Node of tree.
	 */
	final public class BBNode
	{
		// Is should caching node with its components by default.
		static public var CACHING_NODE:Boolean = false;

		// Next/prev links to be able to create dynamic linked list
		public var next:BBNode = null;
		public var prev:BBNode = null;

		// Node's children
		public var childrenHead:BBNode = null;
		public var childrenTail:BBNode = null;

		// Node's components for updating
		bb_private var z_upt_head:BBComponent = null;
		bb_private var z_upt_tail:BBComponent = null;

		// Node's components for rendering
		bb_private var z_renderComponent:BBRenderable = null;

		// Show if node in pool now
		bb_private var z_inPool:Boolean = false;

		// root of tree
		bb_private var z_core:BBGraphModule = null;

		//
		bb_private var mouseOver:BBNode = null;
		bb_private var mouseDown:BBNode = null;

		/**
		 * Name of node. Nothing special just name for node. Not using internal.
		 */
		private var _name:String = "";

		// id of node
		private var _id:int = 0;

		/**
		 * Group which is used to determine whether current node should be rendered with current camera or not.
		 */
		public var group:int = 1;

		/**
		 * If 'true' disallow to change group by layer (BBLayer).
		 */
		public var keepGroup:Boolean = false;

		/**
		 * Property determine if node active - updating/rendering.
		 * If active false this node and all children nodes with components are not update and render, but they still in the tree.
		 */
		private var _active:Boolean = true;

		/**
		 * Mean that transformation won't change if changed parent transformation.
		 * It will not takes into account parent transformation.
		 * Need for components which need own independent transformation (e.g. Camera, BBPhysicsBody).
		 */
		public var independentTransformation:Boolean = false;

		/**
		 * Transform component of node.
		 * (as public member for faster access, so read-only)
		 */
		public var transform:BBTransform = null;

		/**
		 */
		public var mouseChildren:Boolean = false;

		/**
		 */
		public var mouseEnabled:Boolean = false;

		/**
		 * Table where stored all components related to this node.
		 * key is class of component, value is component itself.
		 */
		private var _lookupComponentTable:Dictionary = null;

		//
		private var _numChildren:int = 0;
		private var _numComponents:int = 0;

		private var _parent:BBNode = null;
		private var _isOnStage:Boolean = false;

		//
		private var _visible:Boolean = true;

		// This ref contain z_renderComponent until _visible == false
		private var _backupRenderComponent:BBRenderable = null;

		// Tags
		private var _tags:Array = null;

		// dynamics properties
		private var _properties:Dictionary;

		// Helper fields to prevent crash iterations by removing next element
		private var _nextComponentUpdList:BBComponent = null;
		private var _nextChildNode:BBNode = null;

		///////////////////
		///// Signals /////
		///////////////////

		private var _onAdded:BBSignal = null;
		private var _onRemoved:BBSignal = null;
		// Signal dispatches when node was fully updated, with all components and children
		private var _onUpdated:BBSignal;
		private var _onRendered:BBSignal;
		private var _onActive:BBSignal = null;

		// Mouse signals
		private var _onMouseClick:BBSignal = null;
		private var _onMouseUp:BBSignal = null;
		private var _onMouseDown:BBSignal = null;
		private var _onMouseOver:BBSignal = null;
		private var _onMouseOut:BBSignal = null;
		private var _onMouseMove:BBSignal = null;

		//////////////////////////////////

		/**
		 * p_name - nothing special just name for node.
		 */
		public function BBNode(p_name:String = "")
		{
			name = p_name;
			_id = UniqueId.getId();
			_tags = [];
			_lookupComponentTable = new Dictionary();
			_properties = new Dictionary();
			_onAdded = BBSignal.get(this);
			_onRemoved = BBSignal.get(this);

			//
			_onAdded.add(onAddedHandler);
			_onRemoved.add(onRemovedHandler);

			//
			transform = addComponent(BBTransform) as BBTransform;
			cacheable = CACHING_NODE;
		}

		/**
		 */
		private function onAddedHandler(p_signal:BBSignal):void
		{
			var status:BBNodeStatus = p_signal.params as BBNodeStatus;
			_parent = status.parent;
			_isOnStage = status.isOnStage;
			z_core = status.core;

			// Sends new status to children
			dispatchAddedToChildren();
		}

		/**
		 */
		private function dispatchAddedToChildren():void
		{
			if (childrenHead != null)
			{
				var status:BBNodeStatus = BBNodeStatus.get(this, _isOnStage, z_core);
				var node:BBNode = childrenHead;
				var curNode:BBNode;

				while (node)
				{
					curNode = node;
					node = node.next;
					curNode.onAdded.dispatch(status);
				}

				status.dispose();
			}
		}

		/**
		 */
		private function onRemovedHandler(p_signal:BBSignal):void
		{
			var nodeStatus:BBNodeStatus = p_signal.params as BBNodeStatus;
			_parent = nodeStatus.parent;
			_isOnStage = nodeStatus.isOnStage;
			z_core = nodeStatus.core;

			// Sends new status to children
			dispatchOnRemovedToChildren();
		}

		/**
		 */
		private function dispatchOnRemovedToChildren():void
		{
			if (childrenHead != null)
			{
				var status:BBNodeStatus = BBNodeStatus.get(this, _isOnStage, z_core);
				var node:BBNode = childrenHead;
				var curNode:BBNode;

				while (node)
				{
					curNode = node;
					node = node.next;
					curNode.onRemoved.dispatch(status);
				}

				status.dispose();
			}
		}

		/**
		 * Adds component to node.
		 * p_component - could be either instance or Class of BBComponent class.
		 * p_lookupClass - is assigned component to this class in table.
		 */
		public function addComponent(p_component:*, p_lookupClass:Class = null):BBComponent
		{
			CONFIG::debug
			{
				Assert.isTrue((p_component != null), "component can't be null", "BBNode.addComponent");
			}

			var isClass:Boolean = p_component is Class;
			var lookup:Class;
			var component:BBComponent;

			if (isClass)
			{
				lookup = p_lookupClass ? p_lookupClass : p_component;
				component = BBComponentPool.get(p_component);
			}
			else
			{
				component = p_component;
				var _node:BBNode = component.node;
				if (_node)
				{
					if (_node != this) component.removeFromNode();
				}

				lookup = p_lookupClass ? p_lookupClass : component.componentClass;
			}

			CONFIG::debug
			{
				Assert.isTrue((_lookupComponentTable[lookup] == null), "component with lookup class '" + getQualifiedClassName(lookup) + "' already exist in this node. Node can has only one component is assigned to specify lookup class", "BBNode.addComponent");
				Assert.isTrue(!component.isDisposed, "component is disposed. You can't use disposed node anymore", "BBNode.addComponent");
			}

			_lookupComponentTable[lookup] = component;
			component.onAdded.dispatch({node: this, lookupClass: lookup});
			component.onUpdate.add(onUpdateComponentHandler);

			// If component need to update add it to update list
			if (component.active && component.updateEnable) addComponentToUpdateList(component);

			// If component renderable set to render component ref
			if (component is BBRenderable)
			{
				_backupRenderComponent = component as BBRenderable;
				if (component.active && _visible) z_renderComponent = _backupRenderComponent;
			}

			++_numComponents;

			return component;
		}

		/**
		 */
		private function onUpdateComponentHandler(signal:BBSignal):void
		{
			var component:BBComponent = signal.dispatcher as BBComponent;
			var isNeedAdd:Boolean = signal.params;

			if (isNeedAdd) addComponentToUpdateList(component);
			else unlinkComponentFromUpdateList(component);
		}

		/**
		 */
		private function addComponentToUpdateList(p_component:BBComponent):void
		{
			if (z_upt_tail)
			{
				z_upt_tail.next = p_component;
				p_component.prev = z_upt_tail;
			}
			else z_upt_head = p_component;

			z_upt_tail = p_component;
		}

		/**
		 */
		private function unlinkComponentFromUpdateList(p_component:BBComponent):void
		{
			if (p_component == z_upt_head)
			{
				z_upt_head = z_upt_head.next;
				if (z_upt_head == null) z_upt_tail = null;
				else z_upt_head.prev = null;
			}
			else if (p_component == z_upt_tail)
			{
				z_upt_tail = z_upt_tail.prev;
				if (z_upt_tail == null) z_upt_head = null;
				else z_upt_tail.next = null;
			}
			else
			{
				var prevComponent:BBComponent = p_component.prev;
				var nextComponent:BBComponent = p_component.next;
				prevComponent.next = nextComponent;
				nextComponent.prev = prevComponent;
			}

			if (_nextComponentUpdList == p_component) _nextComponentUpdList = p_component.next;

			p_component.next = null;
			p_component.prev = null;
		}

		/**
		 * Returns component by given class.
		 * If it doesn't exist returns null.
		 */
		public function getComponent(p_componentLookupClass:Class):BBComponent
		{
			CONFIG::debug
			{
				Assert.isTrue((_lookupComponentTable[p_componentLookupClass] != null), "component with such class '" + getQualifiedClassName(p_componentLookupClass) + "' doesn't exist", "BBNode.getComponent");
			}

			return _lookupComponentTable[p_componentLookupClass];
		}

		/**
		 * Unlink component from this node.
		 * p_componentLookupClass - lookup class that is looking component in table.
		 */
		public function removeComponent(p_componentLookupClass:Class):void
		{
			var component:BBComponent = _lookupComponentTable[p_componentLookupClass];
			CONFIG::debug
			{
				Assert.isTrue((component != null), "component with such lookup class '" + getQualifiedClassName(p_componentLookupClass) + "' doesn't exist", "BBNode.removeComponent")
			}

			// If it is not render component
			if (component == z_renderComponent || component == _backupRenderComponent) z_renderComponent = _backupRenderComponent = null;

			// if it into update list
			if (component.updateEnable) unlinkComponentFromUpdateList(component);

			// remove it from lookup table
			delete _lookupComponentTable[p_componentLookupClass];

			// send signal to component that it was unlinked
			component.onRemoved.dispatch();

			//
			component._node = null;

			--_numComponents;
		}

		/**
		 * Adds child node.
		 */
		public function addChild(p_node:BBNode):void
		{
			// If node already attached to another node it is detached from previous node and attached to this
			if (p_node.parent != null) p_node.parent.removeChild(p_node);

			// add to list
			if (childrenTail)
			{
				childrenTail.next = p_node;
				p_node.prev = childrenTail;
			}
			else childrenHead = p_node;

			childrenTail = p_node;

			_numChildren++;

			// update group
			if (!p_node.keepGroup)
			{
				p_node.group = group;
				p_node.updateChildrenGroups();
			}

			// dispatch to node that it was added to parent
			var status:BBNodeStatus = BBNodeStatus.get(this, _isOnStage, z_core);
			p_node.onAdded.dispatch(status);
			status.dispose();
		}

		/**
		 * Unlink given child node from this parent node.
		 */
		public function removeChild(p_node:BBNode):void
		{
			if (p_node == childrenHead)
			{
				childrenHead = childrenHead.next;
				if (childrenHead == null) childrenTail = null;
				else childrenHead.prev = null;
			}
			else if (p_node == childrenTail)
			{
				childrenTail = childrenTail.prev;
				if (childrenTail == null) childrenHead = null;
				else childrenTail.next = null;
			}
			else
			{
				var prevNode:BBNode = p_node.prev;
				var nextNode:BBNode = p_node.next;
				prevNode.next = nextNode;
				nextNode.prev = prevNode;
			}

			if (_nextChildNode == p_node) _nextChildNode = p_node.next;

			p_node.next = null;
			p_node.prev = null;

			_numChildren--;

			if (p_node.onRemoved.numListeners > 0)
			{
				// dispatch to node that it was removed from parent
				var status:BBNodeStatus = BBNodeStatus.get(null, false, z_core);
				p_node.onRemoved.dispatch(status);
				status.dispose();
			}
		}

		/**
		 * Searches child node with name equal to given.
		 * If child wasn't found returns null.
		 * @return BBNode
		 */
		public function getChildByName(p_childName:String):BBNode
		{
			var child:BBNode;
			if (_numChildren > 0)
			{
				var node:BBNode = childrenHead;
				while(node)
				{
					if (node._name == p_childName)
					{
						child = node;
						break;
					}

					child = node.getChildByName(p_childName);

					node = node.next;
				}
			}

			return child;
		}

		/**
		 * Just unlink current node from its parent.
		 */
		public function removeFromParent():void
		{
			if (_parent)
			{
				_parent.removeChild(this);
				removeProperty("bb_layer");
			}
		}

		/**
		 * Returns parent if it exist.
		 */
		public function get parent():BBNode
		{
			return _parent;
		}

		/**
		 * If this node already on the stage.
		 */
		public function get isOnStage():Boolean
		{
			return _isOnStage;
		}

		/**
		 * Signal dispatches when node was added to another node as child or was added to stage.
		 * As parameter sends BBNodeStatus object.
		 */
		public function get onAdded():BBSignal
		{
			return _onAdded;
		}

		/**
		 * Signal dispatches when node was removed from another node or stage.
		 */
		public function get onRemoved():BBSignal
		{
			return _onRemoved;
		}

		/**
		 * Signal dispatches when node was fully updated, with all components and children.
		 */
		public function get onUpdated():BBSignal
		{
			if (!_onUpdated) _onUpdated = BBSignal.get(this);
			return _onUpdated;
		}

		/**
		 * Signal dispatches when node was fully rendered - its render component and all render components of nested children.
		 */
		public function get onRendered():BBSignal
		{
			if (!_onRendered) _onRendered = BBSignal.get(this);
			return _onRendered;
		}

		/**
		 * Signal dispatches when active state of node was changed.
		 */
		public function get onActive():BBSignal
		{
			if (!_onActive) _onActive = BBSignal.get(this);
			return _onActive;
		}

		/**
		 * Visibility of node. If false renderable component isn't render and children nodes also not render.
		 */
		public function set visible(p_val:Boolean):void
		{
			_visible = p_val;

			if (_visible && _backupRenderComponent && _backupRenderComponent.active)
			{
				z_renderComponent = _backupRenderComponent;
			}
			else z_renderComponent = null;
		}

		/**
		 * @private
		 */
		public function get visible():Boolean
		{
			return _visible;
		}

		/**
		 */
		public function get active():Boolean
		{
			return _active;
		}

		/**
		 * Property determine if node active - updating/rendering.
		 * If active 'false' this node and all children nodes with components are not update and render, but they still in the tree.
		 */
		public function set active(p_value:Boolean):void
		{
			if (_active == p_value) return;
			_active = p_value;

			// dispatches to listeners
			if (_onActive) _onActive.dispatch(_active);

			// send to children
			var child:BBNode = childrenHead;
			var currentChild:BBNode;
			while(child)
			{
				currentChild = child;
				child = child.next;

				currentChild.active = _active;
			}
		}

		/**
		 * Adds tag.
		 */
		public function addTag(p_tag:String):void
		{
			_tags[p_tag] = p_tag;
		}

		/**
		 * Removes tag.
		 */
		public function removeTag(p_tag:String):void
		{
			_tags[p_tag] = null;
		}

		/**
		 * Check if given tag exist.
		 */
		public function hasTag(p_tag:String):Boolean
		{
			return _tags[p_tag] != null;
		}

		/**
		 * Adds new dynamic property to node.
		 * @param p_propKey
		 * @param p_propValue
		 */
		public function addProperty(p_propKey:*, p_propValue:*):void
		{
			_properties[p_propKey] = p_propValue;
		}

		/**
		 * Gets dynamic property from node by given property's name (key).
		 * @return
		 */
		public function getProperty(p_propKey:*):*
		{
			return _properties[p_propKey];
		}

		/**
		 * Removes dynamic property by its name (key).
		 * @param p_propKey
		 */
		public function removeProperty(p_propKey:*):void
		{
			delete _properties[p_propKey];
		}

		/**
		 * Using for change group for all nested children to given group, except those who has 'keepGroup' set to true.
		 * @private
		 */
		bb_private function updateChildrenGroups():void
		{
			var node:BBNode = childrenHead;
			while (node)
			{
				if (!node.keepGroup)
				{
					node.group = group;
					node.updateChildrenGroups();
				}

				node = node.next;
			}
		}

		/**
		 * Invokes by engine to update node and all nested nodes.
		 */
		bb_private function update(p_deltaTime:Number, p_parentTransformUpdate:Boolean, p_parentColorUpdate:Boolean):void
		{
			if (!_active) return;

			// Update transform if need
			var updateTransform:Boolean = !independentTransformation && (p_parentTransformUpdate || transform.isTransformChanged);
			var updateColor:Boolean = p_parentColorUpdate || transform.isColorChanged;

			if (updateTransform || updateColor) transform.invalidate(updateTransform, updateColor);

			// invokes update method of components (which were added to update list)
			var component:BBComponent = z_upt_head;
			var currentComponent:BBComponent;
			while (component)
			{
				currentComponent = component;
				component = component.next;
				_nextComponentUpdList = component;

				currentComponent.update(p_deltaTime);

				component = _nextComponentUpdList;
			}

			// iterate nested nodes and invokes their update method
			var childNode:BBNode = childrenHead;
			var currentNode:BBNode;
			while (childNode)
			{
				currentNode = childNode;
				childNode = childNode.next;
				_nextChildNode = childNode;

				currentNode.update(p_deltaTime, updateTransform, updateColor);

				childNode = _nextChildNode;
			}

			// dispatch onUpdated signal, after node was completely updated
			if (_onUpdated) _onUpdated.dispatch();
		}

		/**
		 * Renders node and its children nodes.
		 */
		bb_private function render(p_context:BBContext):void
		{
			if (!_active || !_visible || (p_context.currentCamera.mask & group) == 0) return;

			// render current renderable component if exist
			if (z_renderComponent) z_renderComponent.render(p_context);

			// render children
			var child:BBNode = childrenHead;
			var currentNode:BBNode;
			while (child)
			{
				currentNode = child;
				child = child.next;

				currentNode.render(p_context);
			}

			// dispatch onRendered signal, after node was completely rendered - with all nested children
			if (_onRendered) _onRendered.dispatch();
		}

		/**
		 */
		bb_private function processMouseEvent(p_captured:Boolean, p_event:BBMouseEvent):Boolean
		{
			if (!_active || !visible || (group & p_event.capturedCamera.mask) == 0 && group != 0) return false;

			if (mouseChildren)
			{
				var lastChild:BBNode = childrenTail;
				while (lastChild)
				{
					p_captured = lastChild.processMouseEvent(p_captured, p_event) || p_captured;
					lastChild = lastChild.prev;
				}
			}

			if (mouseEnabled && z_renderComponent)
			{
				p_captured = z_renderComponent.processMouseEvent(p_captured, p_event) || p_captured;
			}

			return p_captured;
		}

		/**
		 */
		bb_private function handleMouseEvent(p_event:BBMouseEvent, p_mouseEventName:String/*, p_dispatcherNode:BBNode, , p_localX:int, p_localY:int, p_buttonDown:Boolean, p_ctrlDown:Boolean*/):void
		{
			if (mouseEnabled)
			{
				p_event.target = this;

				var mouseEvent:BBMouseEvent = p_event.clone();
				mouseEvent.type = p_mouseEventName;

				//
				if (p_mouseEventName == BBMouseEvent.DOWN)
				{
					mouseDown = p_event.dispatcher;
					if (_onMouseDown && (p_event.z_nodeMouseSettings & BBMouseFlags.DOWN) != 0) _onMouseDown.dispatch(mouseEvent);
				}
				else if (p_mouseEventName == BBMouseEvent.MOVE && _onMouseMove
						&& (p_event.z_nodeMouseSettings & BBMouseFlags.MOVE) != 0) _onMouseMove.dispatch(mouseEvent);
				else if (p_mouseEventName == BBMouseEvent.UP)
				{
					if (mouseDown == p_event.dispatcher && _onMouseClick && (p_event.z_nodeMouseSettings & BBMouseFlags.CLICK) != 0)
					{
						var mouseClickEvent:BBMouseEvent = mouseEvent.clone();
						mouseClickEvent.type = BBMouseEvent.CLICK;
						_onMouseClick.dispatch(mouseClickEvent);
						mouseClickEvent.dispose();
					}

					mouseDown = null;

					if (_onMouseUp && (p_event.z_nodeMouseSettings & BBMouseFlags.UP) != 0) _onMouseUp.dispatch(mouseEvent);
				}
				else if (p_mouseEventName == BBMouseEvent.OVER)
				{
					mouseOver = p_event.dispatcher;
					if (_onMouseOver && (p_event.z_nodeMouseSettings & BBMouseFlags.OVER) != 0) _onMouseOver.dispatch(mouseEvent);
				}
				else if (p_mouseEventName == BBMouseEvent.OUT)
				{
					mouseOver = null;
					if (_onMouseOut && (p_event.z_nodeMouseSettings & BBMouseFlags.OUT) != 0) _onMouseOut.dispatch(mouseEvent);
				}

				mouseEvent.dispose();
			}

			//
			if (parent) parent.handleMouseEvent(p_event, p_mouseEventName);
		}

		/**
		 */
		public function get name():String
		{
			return _name;
		}

		/**
		 * Name of node. Nothing special just name for node. Not using internal.
		 */
		public function set name(p_value:String):void
		{
			p_value = StringUtil.trim(p_value);
			_name = p_value == "" ? getName() : p_value;
		}

		/**
		 * Id of node.
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Returns number of nested nodes.
		 */
		public function get numChildren():int
		{
			return _numChildren;
		}

		/**
		 * Returns number of components inside.
		 */
		public function get numComponents():int
		{
			return _numComponents;
		}

		/**
		 * Mark current node as root of tree.
		 */
		bb_private function markAsRoot():void
		{
			_isOnStage = true;
		}

		/**
		 * Detaches children from this parent node and disposes them.
		 */
		bb_private function disposeChildren(p_rid:Boolean = false):void
		{
			if (childrenHead)
			{
				var curNode:BBNode;
				while (childrenHead)
				{
					curNode = childrenHead;
					childrenHead = childrenHead.next;
					curNode.dispose(p_rid);
				}
			}
		}

		/**
		 * Unlink and disposes all components attached to this node.
		 * p_rid - if 'true' components disposed independent on component.cacheable value.
		 */
		private function disposeComponents(p_rid:Boolean = false):void
		{
			var component:BBComponent;
			for (var componentClass:Object in _lookupComponentTable)
			{
				component = _lookupComponentTable[componentClass];
				if (p_rid) component.cacheable = false;

				removeComponent(componentClass as Class);
				component.dispose();
			}
		}

		/**
		 * Disposes dynamic properties.
		 */
		private function clearProperties():void
		{
			for (var prop:* in _properties)
			{
				delete _properties[prop];
			}
		}

		//
		private var _isDisposed:Boolean = false;

		/**
		 * Returns state of node.
		 * If true node entirely disposed, if false it could be used for pooling and reusing.
		 */
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * If 'true' mean node with all children and components caches in pool.
		 */
		public var cacheable:Boolean = false;

		/**
		 * Removes node with all children and their components.
		 * If p_rid is 'true' node with components and all children is disposed entirely and doesn't matter 'cacheable' property is 'true' or 'false'.
		 * After that impossible to use it.
		 */
		public function dispose(p_rid:Boolean = false):void
		{
			if (_isDisposed) return;
			_isDisposed = true;

			// Remove from parent list if it exist
			if (_parent) _parent.removeChild(this);
			removeProperty("bb_layer");

			if (_onActive) _onActive.dispose();
			_onActive = null;

			if (_onUpdated) _onUpdated.dispose();
			_onUpdated = null;

			_nextComponentUpdList = null;
			_nextChildNode = null;
			_parent = null;
			prev = null;
			next = null;
			_isOnStage = false;
			_active = true;

			// TODO: Переделать пул актера. Как такового BBActorPool класса не будет

			var actorClass:String = getProperty("bb_actorClass");
			if (!p_rid && cacheable && actorClass) BBActorPool.put(this, actorClass);
			else
			{
				keepGroup = false;

				// Remove all listeners to prevent dispatching 'onUnlinked' signal for better performance due to avoiding issues which lie behind it
				_onAdded.removeAllListeners();
				_onRemoved.removeAllListeners();

				// Remove all components
				disposeComponents(p_rid);
				transform = null;

				// Remove all children
				disposeChildren(p_rid);

				// clear properties
				clearProperties();

				//
				if (p_rid)
				{
					// Remove all signals
					_onAdded.dispose();
					_onRemoved.dispose();

					_onAdded = null;
					_onRemoved = null;
					_properties = null;

					_lookupComponentTable = null;
					z_inPool = false;
					z_core = null;
				}
				else
				{
					_onAdded.add(onAddedHandler);
					_onRemoved.add(onRemovedHandler);

					put(this);
				}
			}
		}

		/**
		 * Returns copy of BBNode instance.
		 * Copying all children and components.
		 */
		public function copy():BBNode
		{
			var copyNode:BBNode = get(_name);
			copyNode.cacheable = cacheable;
			copyNode.independentTransformation = independentTransformation;
			copyNode.group = group;
			copyNode.keepGroup = keepGroup;
			copyNode.mouseChildren = mouseChildren;
			copyNode.mouseEnabled = mouseEnabled;
			copyNode._active = _active;
			copyNode._visible = _visible;

			// copy tags
			for each (var tag:String in _tags)
			{
				copyNode.addTag(tag);
			}

			// partially copy  of properties
			if (getProperty("bb_actorClass")) copyNode.addProperty("bb_actorClass", getProperty("bb_actorClass"));

			// components
			copyNode.transform.dispose();
			var copyComponent:BBComponent;
			for each(var component:BBComponent in _lookupComponentTable)
			{
				copyComponent = component.copy();
				copyNode.addComponent(copyComponent, copyComponent.lookupClass);

				if (copyComponent.componentClass == BBTransform)
				{
					copyNode.transform = copyComponent as BBTransform;
				}
			}

			// children
			var child:BBNode = childrenHead;
			while(child)
			{
				copyNode.addChild(child.copy());
				child = child.next;
			}

			return copyNode;
		}

		/**
		 */
		public function toString():String
		{
			var componentsStr:String = "";
			for each(var component:BBComponent in _lookupComponentTable)
			{
				componentsStr += component.toString() + "\n";
			}

			var actorClass:String = getProperty("bb_actorClass") ? getProperty("bb_actorClass") : "";

			return  "===========================================================================================================================================\n" +
					"[BBNode: {id: "+_id+"}"+(actorClass ? "-{actorClass: "+actorClass+"}" : "")+"\n" +
					"{name: "+_name+"}-{group: "+group+"}-{keepGroup: "+keepGroup+"}-{active: "+_active+"}-{independentTransformation: "+independentTransformation+"}-" +
					"{mouseChildren: "+mouseChildren+"}-{mouseEnabled: "+mouseEnabled+"}\n" +
					"{numChildren: "+_numChildren+"}-{numComponents: "+_numComponents+"}-{has parent: "+(_parent != null)+"}-{isOnStage: "+_isOnStage+"}-{visible: "+_visible+"}\n" +
					"{Components:\n "+componentsStr+"}]\n" +
					"===========================================================================================================================================";
		}

		/**
		 */
		public function get onMouseClick():BBSignal
		{
			if (!_onMouseClick) _onMouseClick = BBSignal.get(this);
			return _onMouseClick;
		}

		public function get onMouseUp():BBSignal
		{
			if (!_onMouseUp) _onMouseUp = BBSignal.get(this);
			return _onMouseUp;
		}

		public function get onMouseDown():BBSignal
		{
			if (!_onMouseDown) _onMouseDown = BBSignal.get(this);
			return _onMouseDown;
		}

		public function get onMouseOver():BBSignal
		{
			if (!_onMouseOver) _onMouseOver = BBSignal.get(this);
			return _onMouseOver;
		}

		public function get onMouseOut():BBSignal
		{
			if (!_onMouseOut) _onMouseOut = BBSignal.get(this);
			return _onMouseOut;
		}

		public function get onMouseMove():BBSignal
		{
			if (!_onMouseMove) _onMouseMove = BBSignal.get(this);
			return _onMouseMove;
		}

		/**
		 * Returns prototype of node.
		 */
		public function getPrototype():XML
		{
			CONFIG::debug
			{
				Assert.isTrue(!isDisposed, "Node is already disposed", "BBNode.getPrototype");
			}

			var nodePrototype:XML = <node/>;
			nodePrototype.@name = _name;
			nodePrototype.@mouseEnabled = mouseEnabled;
			nodePrototype.@mouseChildren = mouseChildren;
			nodePrototype.@group = group;
			nodePrototype.@keepGroup = keepGroup;
			nodePrototype.@independentTransformation = independentTransformation;
			var actorClass:String = getProperty("bb_actorClass");
			nodePrototype.@actorClass = actorClass == null ? "" : actorClass;

			// parse tags and combine them into one string
			var tagsResult:String = "";
			for each(var val:String in _tags)
			{
				tagsResult += val + ",";
			}
			nodePrototype.@tags = tagsResult.substr(0, tagsResult.length - 1);

			// parse components
			nodePrototype.components = <components/>;

			if (_numComponents > 0)
			{
				var componentsXML:XMLList = nodePrototype.components;
				for each (var component:BBComponent in _lookupComponentTable)
				{
					if (component is BBTransform) componentsXML.prependChild(component.getPrototype());
					else componentsXML.appendChild(component.getPrototype());
				}
			}

			// parse children nodes
			nodePrototype.children = <children/>;

			if (_numChildren)
			{
				var child:BBNode = childrenHead;
				while (child)
				{
					nodePrototype.children.appendChild(child.getPrototype());
					child = child.next;
				}
			}

			return nodePrototype;
		}

		/**
		 * Adds component to node from given prototype (XML description of component)
		 */
		public function addComponentFromPrototype(p_prototype:XML):BBComponent
		{
			var lookupClassName:String = p_prototype.@componentLookupClass;
			var componentLookupClass:Class = getDefinitionByName(lookupClassName.split("-").join("::")) as Class;
			var component:BBComponent = BBComponent.createFromPrototype(p_prototype);
			addComponent(component, componentLookupClass);

			return component;
		}

		///////////////////////
		/// PROTOTYPE /////////
		///////////////////////

		/**
		 * Returns node with all components and children which were described in prototype xml.
		 */
		static public function getFromPrototype(p_prototype:XML):BBNode
		{
			var node:BBNode;
			var actorClass:String = p_prototype.@actorClass;
			if (actorClass != "") node = BBActorPool.getIfExist(actorClass);

			if (node == null)
			{
				node = BBNode.get();

				// parse attributes
				node._name = p_prototype.@name;
				node.mouseEnabled = p_prototype.@mouseEnabled == "true";
				node.mouseChildren = p_prototype.@mouseChildren == "true";
				node.keepGroup = p_prototype.@keepGroup == "true";
				node.independentTransformation = p_prototype.@independentTransformation == "true";
				node.group = parseInt(p_prototype.@group);

				if (actorClass != "") node.addProperty("bb_actorClass", actorClass);

				var tags:Array = p_prototype.@tags.split(",");
				var tagsLen:int = tags.length;
				var i:int;
				for (i = 0; i < tagsLen; i++)
				{
					node.addTag(tags[i]);
				}

				// parse components
				var components:XMLList = p_prototype.components.children();
				var componentXML:XML;
				var numComponents:int = components.length();
				for (i = 0; i < numComponents; i++)
				{
					componentXML = components[i];
					var componentClassName:String = componentXML.@componentClass;
					if (componentClassName.split("-")[1] == "BBTransform") node.transform.updateFromPrototype(componentXML);
					else node.addComponentFromPrototype(componentXML);
				}

				// parse children
				var children:XMLList = p_prototype.children.children();
				var numChildren:int = children.length();
				for (i = 0; i < numChildren; i++)
				{
					node.addChild(getFromPrototype(children[i]));
				}
			}

			return node;
		}

		////////

		/**
		 * Returns unique name for node.
		 */
		static private function getName():String
		{
			return UniqueId.getUniqueName("node");
		}


		///////////////////////
		//*** Pool system ***//
		///////////////////////

		// pool
		static private var _headPool:BBNode = null;
		static private var _numInPool:int = 0;

		/**
		 * Returns BBNode instance.
		 * Uses pool, so in order to put it back to pool need to call method 'dispose'.
		 */
		static public function get(p_name:String = ""):BBNode
		{
			var node:BBNode;
			if (_headPool)
			{
				node = _headPool;
				_headPool = _headPool.next;
				node.next = null;
				node._name = p_name;
				node.transform = BBComponentPool.get(BBTransform) as BBTransform;
				node.z_inPool = false;
				node.cacheable = CACHING_NODE;
				node._isDisposed = false;
				--_numInPool;
			}
			else node = new BBNode(p_name);

			return node;
		}

		/**
		 */
		static private function put(p_node:BBNode):void
		{
			if (!p_node.z_inPool)
			{
				if (_headPool) p_node.next = _headPool;
				else p_node.next = null;

				_headPool = p_node;
				++_numInPool;
			}
		}

		/**
		 * Returns number of instances in pool.
		 */
		static public function get numInPool():int
		{
			return _numInPool;
		}

		/**
		 * Remove pool with all components in it.
		 */
		static public function rid():void
		{
			var node:BBNode;
			while (_headPool)
			{
				node = _headPool;
				_headPool = _headPool.next;
				node.next = null;
				node.prev = null;
				node.dispose(true);
			}

			_numInPool = 0;
		}

		/////////////////////////////////////
	}
}
