package src.bb.pools
{
	import flash.utils.Dictionary;

	import src.bb.bb_spaces.bb_private;
	import src.bb.components.BBComponent;
	import src.bb.core.BBNode;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}


	use namespace bb_private;

	/**
	 * Pool for component.
	 */
	public class BBComponentPool
	{
		//
		static private var _pool:Dictionary = new Dictionary();
		static private var _numInPool:int = 0;

		/**
		 * Adds component instance to pool of course of component isn't disposed.
		 */
		static public function put(p_component:BBComponent):void
		{
			CONFIG::debug
			{
				Assert.isTrue((!p_component.isDisposed), "you can't add disposed component to cache", "BBComponentPool.add");
				Assert.isTrue((p_component.node == null), "you can't add component which still used of some node", "BBComponentPool.add");
			}

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
				component.cacheable = BBComponent.CACHING_COMPONENT;
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

					component.cacheable = false;
					component.dispose();
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
