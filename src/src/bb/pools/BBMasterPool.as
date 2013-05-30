/**
 * User: VirtualMaestro
 * Date: 05.02.13
 * Time: 18:24
 */
package src.bb.pools
{
	/**
	 * Master pool contains rid methods for all pools.
	 * If need clear all existing pools jut call clearAllPools.
	 */
	public class BBMasterPool
	{
		// list of rid methods of pools
		static private var _ridMethodsList:Vector.<Function> = new <Function>[];

		/**
		 * Adds given rid method of some pool. Method shouldn't has any parameters.
		 */
		static public function addRidPoolMethod(p_ridMethod:Function):void
		{
			_ridMethodsList.push(p_ridMethod);
		}

		/**
		 * Invokes all added methods for rid pool.
		 */
		static public function clearAllPools():void
		{
			var len:int = _ridMethodsList.length;
			for (var i:int = 0; i < len; i++)
			{
				_ridMethodsList[i]();
			}
		}

		/**
		 * Disposes master pool, so after that it is impossible to use it.
		 * Also before dispose clears all pools.
		 */
		static public function dispose():void
		{
			var len:int = _ridMethodsList.length;
			for (var i:int = 0; i < len; i++)
			{
				_ridMethodsList[i]();
				_ridMethodsList[i] = null;
			}

			_ridMethodsList.length = 0;
			_ridMethodsList = null;
		}
	}
}
