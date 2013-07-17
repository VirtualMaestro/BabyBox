package bb.core
{
	import bb.tree.BBTreeModule;

	/**
	 * Value object which sends as parameter when node adds or removes from parent or stage.
	 */
	final public class BBNodeStatus
	{
		public var parent:BBNode = null;
		public var isOnStage:Boolean = false;
		public var core:BBTreeModule = null;

		/**
		 */
		public function dispose():void
		{
			parent = null;
			isOnStage = false;
			core = null;

			put(this);
		}

		///////////////////////
		///// POOL SYSTEM /////
		///////////////////////
		static private var _pool:Vector.<BBNodeStatus> = new <BBNodeStatus>[];
		static private var _size:int = 0;

		/**
		 * Returns instance of BBNodeStatus class.
		 * Use pool system. In order to back instance to pool use its 'dispose' method.
		 */
		static public function get(p_parent:BBNode = null, p_isOnStage:Boolean = false, p_core:BBTreeModule = null):BBNodeStatus
		{
			var status:BBNodeStatus;

			if (_size > 0)
			{
				 status = _pool[--_size];
				_pool[_size] = null;
			}
			else status = new BBNodeStatus();

			status.parent = p_parent;
			status.isOnStage = p_isOnStage;
			status.core = p_core;

			return status;
		}

		/**
		 */
		static private function put(p_nodeStatus:BBNodeStatus):void
		{
			_pool[_size++] = p_nodeStatus;
		}

		/**
		 * Clear pool.
		 */
		static public function rid():void
		{
			_size = _pool.length;
			for (var i:int = 0; i < _size; i++)
			{
				_pool[i] = null;
			}
			_pool.length = 0;
			_size = 0;
		}
	}
}
