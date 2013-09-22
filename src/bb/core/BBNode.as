package bb.core
{
	import bb.bb_spaces.bb_private;
	import bb.core.context.BBContext;
	import bb.mouse.events.BBMouseEvent;
	import bb.render.components.BBRenderable;
	import bb.signals.BBSignal;
	import bb.tree.BBTreeModule;

	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

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

		// root of tree
		bb_private var z_core:BBTreeModule = null;

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
		 * Group which is used to determine whether current node should be rendered with current camera or not (camera has a mask).
		 */
		public var group:int = 1;

		/**
		 * If 'true' disallow to change group by layer (BBLayer).
		 */
		public var keepGroup:Boolean = false;

		/**
		 * Transform component of node.
		 * (as public member for faster access, so read-only)
		 */
		public var transform:BBTransform = null;

		/**
		 * Allows to handle of mouse events for children nodes.
		 */
		public var mouseChildren:Boolean = false;

		/**
		 * Allows to handle of mouse events.
		 * There is possible tune which mouse events should node dispatch.
		 * E.g. mouseSettings = BBMouseEvent.UP | BBMouseEvent.OVER | BBMouseEvent.OUT
		 * By default node can't dispatch any events. Value by default 0 or BBMouseEvent.NONE.
		 */
		public var mouseSettings:uint = 0;

		/**
		 * Property determine if node active - updating/rendering.
		 * If active false this node and all children nodes with components are not update and render, but they still in the tree.
		 */
		private var _active:Boolean = true;

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

		//
		private var _isDisposed:Boolean = false;

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
				component = BBComponent.get(p_component);
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
		 */
		public function isComponentExist(p_componentLookupClass:Class):Boolean
		{
			return _lookupComponentTable[p_componentLookupClass] != null;
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

			// send signal to component when it was unlinked
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
			if (p_node.parent != null)
			{
				if (p_node.parent == this) return;
				p_node.parent.removeChild(p_node);
			}

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
			if (_numChildren > 0)
			{
				var child:BBNode;
				var node:BBNode = childrenHead;
				while (node)
				{
					if (node._name == p_childName) return node;

					// find in children
					child = node.getChildByName(p_childName);
					if (child) return child;

					node = node.next;
				}
			}

			return null;
		}

		/**
		 * Just unlink current node from its parent.
		 */
		[Inline]
		final public function removeFromParent():void
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
			while (child)
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
		bb_private function update(p_deltaTime:int, p_parentTransformUpdate:Boolean, p_parentColorUpdate:Boolean):void
		{
			if (!_active) return;

			// Update transform if need
			var updateTransform:Boolean = !transform.lockInvalidation && (p_parentTransformUpdate || transform.isTransformChanged);
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

			///
			transform.resetInvalidationFlags();
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
			if (!_active || !visible || (group & p_event.capturedCamera.mask) == 0 && group != 0 || !p_event.propagation) return false;

			if (mouseChildren)
			{
				var lastChild:BBNode = childrenTail;
				while (lastChild)
				{
					p_captured = lastChild.processMouseEvent(p_captured, p_event) || p_captured;
					lastChild = p_event.propagation ? lastChild.prev : null;
				}
			}

			if (mouseSettings > 0 && z_renderComponent && p_event.propagation)
			{
				p_captured = z_renderComponent.processMouseEvent(p_captured, p_event) || p_captured;
			}

			return p_captured;
		}

		/**
		 */
		bb_private function handleMouseEvent(p_event:BBMouseEvent, p_mouseEventName:uint):void
		{
			if (mouseSettings > 0 && p_event.propagation)
			{
				p_event.target = this;

				var mouseEvent:BBMouseEvent = p_event.clone();
				mouseEvent.type = p_mouseEventName;

				switch (p_mouseEventName)
				{
					case BBMouseEvent.DOWN:
					{
						mouseDown = p_event.dispatcher;
						if (_onMouseDown && (mouseSettings & BBMouseEvent.DOWN) != 0) _onMouseDown.dispatch(mouseEvent);
						break;
					}

					case BBMouseEvent.MOVE:
					{
						if (_onMouseMove && (mouseSettings & BBMouseEvent.MOVE) != 0) _onMouseMove.dispatch(mouseEvent);
						break;
					}

					case BBMouseEvent.UP:
					{
						if (mouseDown == p_event.dispatcher && _onMouseClick && (mouseSettings & BBMouseEvent.CLICK) != 0)
						{
							var mouseClickEvent:BBMouseEvent = mouseEvent.clone();
							mouseClickEvent.type = BBMouseEvent.CLICK;
							_onMouseClick.dispatch(mouseClickEvent);
							mouseClickEvent.dispose();
						}

						mouseDown = null;

						if (_onMouseUp && (mouseSettings & BBMouseEvent.UP) != 0) _onMouseUp.dispatch(mouseEvent);
						break;
					}
					case BBMouseEvent.OVER:
					{
						mouseOver = p_event.dispatcher;
						if (_onMouseOver && (mouseSettings & BBMouseEvent.OVER) != 0) _onMouseOver.dispatch(mouseEvent);
						break;
					}
					case BBMouseEvent.OUT:
					{
						mouseOver = null;
						if (_onMouseOut && (mouseSettings & BBMouseEvent.OUT) != 0) _onMouseOut.dispatch(mouseEvent);
						break;
					}
				}

				p_event.stopPropagationAfterHandling = mouseEvent.stopPropagationAfterHandling;
				mouseEvent.dispose();
			}

			//
			if (parent && !p_event.stopPropagationAfterHandling) parent.handleMouseEvent(p_event, p_mouseEventName);
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
		bb_private function disposeChildren():void
		{
			if (childrenHead)
			{
				var node:BBNode = childrenHead;
				var curNode:BBNode;
				while (node)
				{
					curNode = node;
					node = node.next;
					_nextChildNode = node;
					curNode.dispose();
					node = _nextChildNode;
				}

				_nextChildNode = null;
			}
		}

		/**
		 * Unlink and disposes all components attached to this node.
		 */
		private function disposeComponents():void
		{
			var component:BBComponent;
			for (var componentClass:Object in _lookupComponentTable)
			{
				component = _lookupComponentTable[componentClass];

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

		/**
		 * Returns state of node.
		 * If true node entirely disposed, if false it could be used for pooling and reusing.
		 */
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * Removes node with all children and their components.
		 * After that impossible to use it.
		 */
		public function dispose():void
		{
			if (_isDisposed) return;
			destroy();
			put(this);
		}

		/**
		 */
		private function destroy():void
		{
			_isDisposed = true;

			// Remove from parent list if it exist
			if (_parent) _parent.removeChild(this);
			removeProperty("bb_layer");

			if (_onActive) _onActive.dispose();
			_onActive = null;

			if (_onUpdated) _onUpdated.dispose();
			_onUpdated = null;

			if (_onMouseClick) _onMouseClick.dispose();
			_onMouseClick = null;

			if (_onMouseDown) _onMouseDown.dispose();
			_onMouseDown = null;

			if (_onMouseMove) _onMouseMove.dispose();
			_onMouseMove = null;

			if (_onMouseOut) _onMouseOut.dispose();
			_onMouseOut = null;

			if (_onMouseOver) _onMouseOver.dispose();
			_onMouseOver = null;

			if (_onMouseUp) _onMouseUp.dispose();
			_onMouseUp = null;

			_nextComponentUpdList = null;
			_nextChildNode = null;
			_parent = null;
			prev = null;
			next = null;
			_isOnStage = false;
			_active = true;
			keepGroup = false;
			mouseChildren = false;
			mouseSettings = 0;

			// Remove all listeners to prevent dispatching 'onUnlinked' signal for better performance due to avoiding issues which lie behind it
			_onAdded.removeAllListeners();
			_onRemoved.removeAllListeners();
			_onAdded.add(onAddedHandler);
			_onRemoved.add(onRemovedHandler);

			// Remove all components
			disposeComponents();
			transform = null;

			// Remove all children
			disposeChildren();

			// clear properties
			clearProperties();
		}

		/**
		 * Completely destroy node without possible to add to pool.
		 */
		private function rid():void
		{
			if (!_isDisposed) destroy();

			_onAdded.dispose();
			_onRemoved.dispose();

			_onAdded = null;
			_onRemoved = null;
			_properties = null;

			_lookupComponentTable = null;
			z_core = null;
		}

		/**
		 * Returns copy of BBNode instance.
		 * Copying all children and components.
		 */
		public function copy():BBNode
		{
			var copyNode:BBNode = get(_name);
			copyNode.group = group;
			copyNode.keepGroup = keepGroup;
			copyNode.mouseChildren = mouseChildren;
			copyNode.mouseSettings = mouseSettings;
			copyNode._active = _active;
			copyNode._visible = _visible;

			// copy tags
			for each (var tag:String in _tags)
			{
				copyNode.addTag(tag);
			}

			// partially copy  of properties
			if (getProperty("bb_alias")) copyNode.addProperty("bb_alias", getProperty("bb_alias"));

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
			while (child)
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

			var alias:String = getProperty("bb_alias") ? getProperty("bb_alias") : "";

			return  "===========================================================================================================================================\n" +
					"[BBNode: {id: " + _id + "}" + (alias ? "-{alias: " + alias + "}" : "") + "\n" +
					"{name: " + _name + "}-{group: " + group + "}-{keepGroup: " + keepGroup + "}-{active: " + _active + "}-" +
					"{mouseChildren: " + mouseChildren + "}-{mouseSettings: " + mouseSettings + "}\n" +
					"{numChildren: " + _numChildren + "}-{numComponents: " + _numComponents + "}-{has parent: " + (_parent != null) + "}-{isOnStage: " + _isOnStage + "}-{visible: " + _visible + "}\n" +
					"{Components:\n " + componentsStr + "}]\n" +
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
			nodePrototype.@mouseSettings = mouseSettings;
			nodePrototype.@mouseChildren = mouseChildren;
			nodePrototype.@group = group;
			nodePrototype.@keepGroup = keepGroup;
			var alias:String = getProperty("bb_alias");
			nodePrototype.@alias = alias == null ? "" : alias;

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
			var alias:String = p_prototype.@alias;
			if (alias != "") node = BBNode.getFromCache(alias);

			if (node == null)
			{
				node = BBNode.get();

				// parse attributes
				node._name = p_prototype.@name;
				node.mouseSettings = parseInt(p_prototype.@mouseSettings);
				node.mouseChildren = p_prototype.@mouseChildren == "true";
				node.keepGroup = p_prototype.@keepGroup == "true";
				node.group = parseInt(p_prototype.@group);

				if (alias != "") node.addProperty("bb_alias", alias);

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

		/////////////////////////
		//*** Pool for node ***//
		/////////////////////////

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
				node.transform = node.addComponent(BBTransform) as BBTransform;
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
			if (_headPool) p_node.next = _headPool;
			else p_node.next = null;

			_headPool = p_node;
			++_numInPool;
		}

		/**
		 * Returns number of instances in pool.
		 */
		static bb_private function get numInPool():int
		{
			return _numInPool;
		}

		/**
		 * Remove pool of nodes.
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
				node.rid();
			}

			_numInPool = 0;
		}

		/////////////////////////////////////

		/////////////////////
		// CACHE FOR ACTOR //
		/////////////////////

		static private var _cache:Array = [];

		/**
		 * Adds cache with given alias which stores pattern of node (with all components and children) and instances copied from it.
		 * To get instance of given pattern need to invoke getFromCache method.
		 * There is possible to pre cache some number of instances by setting third parameter 'preCache'.
		 */
		static public function addCache(p_pattern:BBNode, p_alias:String, p_preCache:int = 0):void
		{
			CONFIG::debug
			{
				Assert.isTrue(_cache[p_alias] == null, "Cache with given alias '" + p_alias + "' already added", "BBNode.addToCache");
				Assert.isTrue(p_pattern != null, "Pattern can't be null. Pattern alias '" + p_alias + "'", "BBNode.addToCache");
			}

			_cache[p_alias] = new BBCache(p_pattern, p_alias, p_preCache);
		}

		/**
		 * Returns instance of BBNode by give alias.
		 */
		static public function getFromCache(p_alias:String):BBNode
		{
			CONFIG::debug
			{
				Assert.isTrue(_cache[p_alias] != null, "Cache with given alias '" + p_alias + "' doesn't exist", "BBNode.getFromCache");
			}

			var pool:BBCache = _cache[p_alias];

			return pool.get();
		}

		/**
		 * Pre-cache given number of instances of BBNode by given alias.
		 */
		static public function preCache(p_alias:String, p_preCache:int):void
		{
			CONFIG::debug
			{
				Assert.isTrue(_cache[p_alias] != null, "Cache with given alias '" + p_alias + "' doesn't exist", "BBNode.preCache");
			}

			var cache:BBCache = _cache[p_alias];
			cache.preCache(p_preCache);
		}

		/**
		 */
		static public function isCacheExist(p_alias:String):Boolean
		{
			return _cache[p_alias] != null;
		}

		/**
		 * Number of actors related to given alias in cache.
		 */
		static public function numInCache(p_alias:String):int
		{
			CONFIG::debug
			{
				Assert.isTrue(_cache[p_alias] != null, "Cache with given alias '" + p_alias + "' doesn't exist", "BBNode.numInCache");
			}

			var cache:BBCache = _cache[p_alias];
			return cache.numInCache;
		}

		/**
		 * Removes specified cache by its alias.
		 */
		static public function removeCache(p_alias:String):void
		{
			CONFIG::debug
			{
				Assert.isTrue(_cache[p_alias] != null, "Cache with given alias '" + p_alias + "' doesn't exist", "BBNode.removeCache");
			}

			var cache:BBCache = _cache[p_alias];
			cache.dispose();
			delete _cache[p_alias];
		}

		/**
		 * Clears and removes all caches.
		 */
		static public function ridCaches():void
		{
			for each (var cache:BBCache in _cache)
			{
				cache.dispose();
			}

			for (var alias:String in _cache)
			{
				_cache[alias] = null;
			}

			_cache = [];
		}
	}
}

import bb.core.BBNode;

/**
 */
internal class BBCache
{
	private var _pattern:BBNode;
	private var _cache:Vector.<BBNode>;
	private var _alias:String;
	private var _preCache:int = 0;
	private var _inCache:int = 0;

	/**
	 */
	public function BBCache(p_pattern:BBNode, p_alias:String, p_preCache:int = 0)
	{
		_alias = p_alias;
		_pattern = p_pattern;
		_preCache = p_preCache;
		_cache = new <BBNode>[];

		if (p_preCache > 0) preCache(_preCache);
	}

	/**
	 */
	public function preCache(p_preCacheNum:int):void
	{
		_preCache = p_preCacheNum;

		if (_preCache > _inCache)
		{
			var creationNum:int = _preCache - _inCache;
			for (var i:int = 0; i < creationNum; i++)
			{
				put(_pattern.copy());
			}
		}
	}

	/**
	 */
	public function get():BBNode
	{
		var actor:BBNode = getIfExist();
		return actor ? actor : _pattern.copy();
	}

	/**
	 * Returns actor if its instance exist in cache, else returns null.
	 * @return BBNode
	 */
	[Inline]
	final private function getIfExist():BBNode
	{
		var actor:BBNode;

		if (_inCache > 0)
		{
			actor = _cache[--_inCache];
			_cache[_inCache] = null;
		}

		return actor;
	}

	/**
	 */
	private function put(p_actor:BBNode):void
	{
		_cache[_inCache++] = p_actor;
	}

	/**
	 * Clear cache.
	 */
	private function clear():void
	{
		for (var i:int = 0; i < _inCache; i++)
		{
			_cache[i].dispose();
		}

		_cache.length = 0;
		_inCache = 0;
	}

	/**
	 */
	public function get numInCache():int
	{
		return _inCache;
	}

	/**
	 * Completely removes the cache.
	 */
	public function dispose():void
	{
		clear();
		_cache = null;
		_pattern.dispose();
		_pattern = null;
		_alias = null;
		_preCache = 0;
		_inCache = 0;
	}
}