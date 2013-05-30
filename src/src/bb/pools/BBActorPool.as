/**
 * User: VirtualMaestro
 * Date: 29.04.13
 * Time: 14:24
 */
package src.bb.pools
{
	import flash.utils.Dictionary;

	import src.bb.core.BBNode;

	/**
	 * Represents pool of actors.
	 * In this case actor is BBNode with sets of some components which could represents some entity.
	 */
	public class BBActorPool
	{
		//
		static private var _cacheTable:Dictionary = new Dictionary();

		/**
		 * Adds XML prototype of node to pool.
		 * @param p_actorClass - any value to identify needed actor (node with components).
		 * @param p_prototypeNode - XML prototype of BBNode.
		 * @param p_preCache - number of instance of current actor which should be pre creates.
		 */
		static public function add(p_prototypeNode:XML, p_actorClass:String = null, p_preCache:int = 0):void
		{
			var actorClass:String = p_actorClass;
			if (actorClass == null) actorClass = p_prototypeNode.@actorClass;
			if (actorClass == null || actorClass == "") throw new Error("BBActorPool.add: impossible value for 'actorClass' (" + actorClass + ")");

			if (_cacheTable[actorClass] == null) _cacheTable[actorClass] = new BBPool(p_prototypeNode, p_preCache);
		}

		/**
		 * Put instance of node to pool.
		 * @param p_actorClass - string value which corresponds to current type of actor.
		 * If p_actorClass is not null and not "" and if there is not registered in cacheTable there creates new cache for that actor.
		 * @param p_actor - instance of BBNode which contains components and represents some actor.
		 */
		static public function put(p_actor:BBNode, p_actorClass:String = null):void
		{
			var actorClass:String = (p_actorClass && p_actorClass != "") ? p_actorClass : p_actor.getProperty("bb_actorClass");
			if (actorClass == null || actorClass == "") return;

			var pool:BBPool = _cacheTable[actorClass] as BBPool;
			if (pool) pool.put(p_actor);
			else
			{
				add(p_actor.getPrototype(), actorClass);
				(_cacheTable[actorClass] as BBPool).put(p_actor);
			}
		}

		/**
		 * Returns BBNode instance which represents some actor by given key.
		 * @param p_actorClass - any value which represents actor in pool.
		 * @return - instance of BBNode.
		 */
		static public function get(p_actorClass:String):BBNode
		{
			var pool:BBPool = _cacheTable[p_actorClass];
			return pool ? pool.get() : null;
		}

		/**
		 * Returns actor if its instance exist in pool, else returns null.
		 * @return BBNode
		 */
		static public function getIfExist(p_key:String):BBNode
		{
			return (_cacheTable[p_key] as BBPool).getIfExist();
		}

		/**
		 * Fully clear pools and dispose nodes and components.
		 */
		static public function clear():void
		{
			var pool:BBPool;
			for(var key:String in _cacheTable)
			{
				pool = _cacheTable[key];
				pool.clear();
			}
		}

		/**
		 * Clear and dispose the pools.
		 */
		static public function rid():void
		{
			var pool:BBPool;
			for(var key:String in _cacheTable)
			{
				pool = _cacheTable[key];
				pool.dispose();
				delete _cacheTable[key];
			}
		}
	}
}

import src.bb.core.BBNode;

/**
 */
internal class BBPool
{
	private var _prototypeActor:XML;
	private var _pool:Vector.<BBNode>;
	private var _preCache:int = 0;
	private var _inPool:int = 0;

	/**
	 */
	public function BBPool(p_prototype:XML, p_preCache:int = 0)
	{
		_prototypeActor = p_prototype;
		_preCache = p_preCache;
		_pool = new <BBNode>[];

		 if (p_preCache > 0) preCache(_preCache);
	}

	/**
	 */
	public function preCache(p_preCacheNum:int):void
	{
		_preCache = p_preCacheNum;

		if (_preCache > _inPool)
		{
			var creationNum:int = _preCache - _inPool;
			for (var i:int = 0; i < creationNum; i++)
			{
				put(BBNode.getFromPrototype(_prototypeActor));
			}
		}
	}

	/**
	 */
	public function get():BBNode
	{
		var actor:BBNode = getIfExist();
		return actor ? actor : BBNode.getFromPrototype(_prototypeActor);
	}

	/**
	 * Returns actor if its instance exist in pool, else returns null.
	 * @return BBNode
	 */
	public function getIfExist():BBNode
	{
		var actor:BBNode;

		if (_inPool > 0)
		{
			actor = _pool[--_inPool];
			_pool[_inPool] = null;
		}

		return actor;
	}

	/**
	 */
	public function put(p_actor:BBNode):void
	{
		_pool[_inPool++] = p_actor;
	}

	/**
	 * Clear pool.
	 */
	public function clear():void
	{
		for (var i:int = 0; i < _inPool; i++)
		{
			_pool[i].dispose(true);
		}

		_pool.length = 0;
		_inPool = 0;
	}

	/**
	 * Completely removes the pool.
	 */
	public function dispose():void
	{
		clear();
		_pool = null;
		_prototypeActor = null;
	}
}