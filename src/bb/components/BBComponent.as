package bb.components
{
	import bb.bb_spaces.bb_private;
	import bb.core.*;
	import bb.signals.BBSignal;

	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	import vm.classes.ClassUtil;
	import vm.math.unique.UniqueId;

	use namespace bb_private;

	/**
	 * Base class for components.
	 */
	public class BBComponent
	{
		// Next/prev links for able to create dynamic linked list
		bb_private var next:BBComponent = null;
		bb_private var prev:BBComponent = null;

		/**
		 * Signal dispatches when component adds or removes from update list of node.
		 */
		bb_private var onUpdate:BBSignal = null;

		/**
		 * If this component should be cached.
		 */
		protected var cacheable:Boolean = true;

		//
		private var _id:int;
		private var _lookupClass:Class = null;
		protected var _componentClass:Class = null;

		// Dispatches when component was added to node.
		private var _onAdded:BBSignal = null;

		// Dispatches when component was unlinked from its node.
		private var _onRemoved:BBSignal = null;

		//
		bb_private var _node:BBNode = null;
		private var _updateEnable:Boolean = false;

		private var _userData:Object;

		//
		protected var _active:Boolean = true;

		private var _isDisposed:Boolean = false;
		private var _isRid:Boolean = false;

		/**
		 */
		public function BBComponent()
		{
			// System signal. Dispatches when component enable/disable to update
			onUpdate = BBSignal.get(this);

			_onAdded = BBSignal.get(this);
			_onAdded.add(onComponentAddedHandler);

			_onRemoved = BBSignal.get(this);

			_id = UniqueId.getId();
		}

		/**
		 */
		private function onComponentAddedHandler(p_signal:BBSignal):void
		{
			var params:Object = p_signal.params;
			_node = params.node;
			_lookupClass = params.lookupClass;
		}

		/**
		 * Component is removed from node.
		 * It is not dispose but just unlink from node, so it can be added to another node.
		 */
		public function removeFromNode():void
		{
			if (_node) _node.removeComponent(_lookupClass);
		}

		/**
		 * Returns node to which this component is assigned.
		 * If component isn't assigned to any node returns null.
		 */
		public function get node():BBNode
		{
			return _node;
		}

		/**
		 * Returns component's class.
		 */
		public function get componentClass():Class
		{
			return _componentClass ? _componentClass : (_componentClass = ClassUtil.getDefinitionForInstance(this));
		}

		/**
		 * Gets lookup class.
		 */
		public function get lookupClass():Class
		{
			return _lookupClass ? _lookupClass : componentClass;
		}

		/**
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Signal dispatches when component was added to the node.
		 */
		public function get onAdded():BBSignal
		{
			return _onAdded;
		}

		/**
		 * Signal dispatches when component was unlinked from its node.
		 */
		public function get onRemoved():BBSignal
		{
			return _onRemoved;
		}

		/**
		 * Container for any user data.
		 */
		public function get userData():Object
		{
			if (!_userData) _userData = {};
			return _userData;
		}

		/**
		 * Enable/disable invoke update method.
		 * By default false.
		 */
		public function set updateEnable(p_val:Boolean):void
		{
			if (_updateEnable == p_val) return;

			_updateEnable = p_val;
			if (_active) onUpdate.dispatch(_updateEnable);
		}

		/**
		 * Returns is whether component enabled to update.
		 */
		public function get updateEnable():Boolean
		{
			return _updateEnable;
		}

		/**
		 */
		public function get active():Boolean
		{
			return _active;
		}

		/**
		 * Activate/deactivate component.
		 * By default turn on/off update loop and render.
		 */
		public function set active(p_val:Boolean):void
		{
			if (_active == p_val) return;

			if (_updateEnable)
			{
				if (p_val) onUpdate.dispatch(true);
				else onUpdate.dispatch(false);
			}

			_active = p_val;
		}

		/**
		 * Method called every frame to make some logic update.
		 * It is should be override in children if need some logic update.
		 * If invoke of this method doesn't need it is possible to disable it by 'updateEnable = false' method.
		 */
		public function update(p_deltaTime:Number):void
		{
			// Should be override in children if need some updates.
		}

		/**
		 * Method check if this component disposed entirely.
		 * If yes this is mean that component can't reuse any more.
		 * Also this component can't be putted to pool.
		 */
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * Dispose component.
		 */
		public function dispose():void
		{
			if (_isDisposed) return;
			destroy();

			if (cacheable)
			{
				_onAdded.add(onComponentAddedHandler);
				put(this);
			}
			else rid();
		}

		/**
		 */
		private function destroy():void
		{
			_isDisposed = true;

			if (_node) _node.removeComponent(_lookupClass);

			onUpdate.removeAllListeners();
			_onAdded.removeAllListeners();
			_onRemoved.removeAllListeners();

			_node = null;
			_updateEnable = false;
			_lookupClass = null;
			next = null;
			prev = null;
			_userData = null;
		}

		/**
		 */
		protected function rid():void
		{
			if (!_isDisposed) destroy();
			if (!_isRid)
			{
				_isRid = true;
				onUpdate.dispose();
				_onAdded.dispose();
				_onRemoved.dispose();
				onUpdate = null;
				_onAdded = null;
				_onRemoved = null;
				_componentClass = null;
			}
		}

		/**
		 * Makes a copy of current component.
		 */
		public function copy():BBComponent
		{
			var component:BBComponent = get(componentClass);
			component.cacheable = cacheable;
			component._active = _active;
			component._updateEnable = _updateEnable;
			component._componentClass = _componentClass;
			component._lookupClass = _lookupClass;

			return component;
		}

		/**
		 */
		public function toString():String
		{
			return "{id: " + _id + "}-{lookup class: " + getQualifiedClassName(_lookupClass) + "}-{cacheable: " + cacheable + "}-{updateEnable: " + _updateEnable + "}";
		}

		/////////////////////////////
		//// PROTOTYPING ////////////
		/////////////////////////////

		//
		private var _prototype:XML;

		/**
		 */
		public function getPrototype():XML
		{
			_prototype = <component/>;
			_prototype.@id = _id;
			_prototype.@componentClass = getQualifiedClassName(this).split("::").join("-");
			_prototype.@componentLookupClass = getQualifiedClassName(_lookupClass).split("::").join("-");

			_prototype.properties = <properties/>;

			// add protected prop 'cacheable'
			addPrototypeProperty("cacheable", cacheable, "boolean");

			//
			var describe:XML = describeType(this);
			var variables:XMLList = describe.variable;
			var variable:XML;
			var i:int;
			var lenVars:int = variables.length();
			for (i = 0; i < lenVars; ++i)
			{
				variable = variables[i];
				addPrototypeProperty(variable.@name, this[variable.@name], variable.@type);
			}

			var accessors:XMLList = describe.accessor;
			var accessor:XML;
			var lenAccessors:int = accessors.length();
			for (i = 0; i < lenAccessors; ++i)
			{
				accessor = accessors[i];
				if (accessor.@access != "readwrite") continue;
				addPrototypeProperty(accessor.@name, this[accessor.@name], accessor.@type);
			}

			return _prototype;
		}

		/**
		 */
		protected function addPrototypeProperty(p_name:String, p_value:*, p_type:String, p_prototype:XML = null):void
		{
			var node:XML;
			p_type = p_type.toLowerCase();
			var valueType:String = typeof(p_value);
			// Discard complex types
			if (valueType == "object" && (p_type != "array" && p_type != "object")) return;
			if (valueType != "object")
			{
				node = <{p_name} type={p_type}>{p_value}</{p_name}>;
			}
			/* Creation of simple arrays and objects not implemented yet */
			else
			{
				node = <{p_name} type={p_type}/>;
				for (var it:String in  p_value)
				{
					if (p_value.hasOwnProperty(it)) addPrototypeProperty(it, p_value[it], typeof(p_value[it]), node);
				}
			}
			/**/

			if (p_prototype == null) _prototype.properties.appendChild(node);
			else p_prototype.appendChild(node);
		}

		/**
		 * Updates values of current component from given prototype XML.
		 */
		public function updateFromPrototype(p_prototype:XML):void
		{
			_id = p_prototype.@id;

			var properties:XMLList = p_prototype.properties;
			var children:XMLList = properties.children();
			var count:int = children.length();
			for (var i:int = 0; i < count; ++i)
			{
				bindPrototypeProperty(children[i], this);
			}
		}

		/**
		 */
		static public function bindPrototypeProperty(p_property:XML, p_object:Object):void
		{
			var value:* = null;

			if (p_property.@type == "object")
			{
				// Not implemented yet
			}

			if (p_property.@type == "array")
			{
				value = [];
				var children:XMLList = p_property.children();
				var count:int = children.length();
				for (var i:int = 0; i < count; ++i)
				{
					bindPrototypeProperty(children[i], value);
				}
			}

			if (p_property.@type == "boolean") value = p_property == "true";

			try
			{
				p_object[p_property.name()] = (value == null) ? p_property : value;
			}
			catch (error:Error)
			{
				trace("bindPrototypeProperty", error, getQualifiedClassName(p_object), p_property.name(), value);
			}
		}

		/**
		 */
		static public function createFromPrototype(p_prototype:XML):BBComponent
		{
			var componentClass:Class = getDefinitionByName(p_prototype.@componentClass.split("-").join("::")) as Class;
			var component:BBComponent = new componentClass();
			component.updateFromPrototype(p_prototype);

			return component;
		}

		///////////////////////////
		/// POOL FOR COMPONENTS ///
		///////////////////////////

		static private var _pool:Dictionary = new Dictionary();
		static private var _numInPool:int = 0;

		/**
		 * Adds component instance to pool of course of component isn't disposed.
		 */
		static private function put(p_component:BBComponent):void
		{
			p_component.next = null;
			p_component.prev = null;

			var componentClass:Class = p_component.componentClass;
			var head:BBComponent = _pool[componentClass];

			if (head) p_component.next = head;
			_pool[componentClass] = p_component;

			++_numInPool;
		}

		/**
		 * Returns instance of component by given class.
		 */
		static public function get(componentClass:Class):BBComponent
		{
			var component:BBComponent;
			var head:BBComponent = _pool[componentClass];

			if (head)
			{
				component = head;
				head = head.next;
				_pool[componentClass] = head;
				component.next = null;
				component._isDisposed = false;
				--_numInPool;
			}
			else component = new componentClass();

			return component;
		}

		/**
		 * Returns number of instances in pool.
		 */
		static public function get numInPool():int
		{
			return _numInPool;
		}

		/**
		 * Clear pool and disposes all components into it.
		 */
		static public function rid():void
		{
			var component:BBComponent;
			var head:BBComponent;
			for (var classDef:Object in _pool)
			{
				head = _pool[classDef];
				while (head)
				{
					component = head;
					head = head.next;

					component.rid();
				}

				delete _pool[classDef];
			}

			_numInPool = 0;
		}

		/**
		 * Returns component with node.
		 */
		static public function getWithNode(p_componentClass:Class, p_nodeName:String = ""):BBComponent
		{
			return BBNode.get(p_nodeName).addComponent(get(p_componentClass));
		}
	}
}
