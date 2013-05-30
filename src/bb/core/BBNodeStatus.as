package bb.core
{
	import bb.modules.BBGraphModule;

	/**
	 * Value object which sends as parameter when node adds or removes from parent or stage.
	 */
	public class BBNodeStatus
	{
		/**
		 * Returns instance of BBNodeStatus class.
		 * Use pool system. In order to back instance to pool use its 'dispose' method.
		 */
		static public function get(p_parent:BBNode = null, p_isOnStage:Boolean = false, p_core:BBGraphModule = null):BBNodeStatus
		{
			var status:BBNodeStatus = getFromPool();
			status.parent = p_parent;
			status.isOnStage = p_isOnStage;
			status.core = p_core;

			return status;
		}

		///////////////////////
		//*** Pool system ***//
		///////////////////////
		static private var _pool:Array = [];
		static private var _available:int = 0;

		/**
		 */
		static private function addToPool(p_nodeStatus:BBNodeStatus):void
		{
			_pool[_available++] = p_nodeStatus;
		}

		/**
		 */
		static private function getFromPool():BBNodeStatus
		{
			var nodeStatus:BBNodeStatus;

			if (_available > 0) nodeStatus = _pool[--_available];
			else nodeStatus = new BBNodeStatus();

			return nodeStatus;
		}

		/**
		 * Clear pool.
		 */
		static public function rid():void
		{
			_available = _pool.length;
			for (var i:int = 0; i < _available; i++) _pool[i] = null;
			_pool.length = 0;
			_available = 0;
		}

		/////////////////////////////////////

		//
		public var parent:BBNode = null;
		public var isOnStage:Boolean = false;
		public var core:BBGraphModule = null;

		/**
		 */
		public function dispose():void
		{
			parent = null;
			isOnStage = false;
			core = null;
			addToPool(this);
		}
	}
}
