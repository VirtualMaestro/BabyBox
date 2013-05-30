/**
 * User: VirtualMaestro
 * Date: 01.04.13
 * Time: 20:39
 */
package bb.tools
{
//	CONFIG::debug
//	{
//		import vm.debug.Assert;
//	}

	/**
	 * Tool class for calculation and manage masks/groups.
	 */
	public class BBGroupMask
	{
		//
		static private var currentGroup:int = 1;

		/**
		 * Method returns new unique group.
		 * Number possible groups is 31.
		 * First group (1) by default have all entries, so generating groups begin from the second one.
		 *
		 * To make sure that free groups still exist use 'hasGroup' method.
		 */
		static public function getGroup():int
		{
			return (1 << (++currentGroup-1));
		}

		/**
		 * Check if next group exist.
		 */
		static public function hasGroup():Boolean
		{
			return (currentGroup+1) < 33;
		}

		/**
		 * Reset group's counter, so it is possible to get groups from the beginning.
		 */
		static public function resetGroupCounter():void
		{
			currentGroup = 1;
		}


		/**
		 * Returns the mask by given include or exclude groups.
		 * We shouldn't set include and exclude groups at the same time - hasn't sense.
		 *
		 * For avoiding incorrect values for groups use getGroup method for generating group's value.
		 * Returns number which represents mask for given include/exclude groups.
		 */
		static public function getMask(p_includeGroups:Array = null, p_excludeGroups:Array = null):int
		{
			if (p_includeGroups == null && p_excludeGroups == null) return 0xffffffff;

			var mask:int;
			var len:int;
			var i:int;

			//
			if (p_includeGroups)
			{
				len = p_includeGroups.length;

				if (len < 1) mask = 0xffffffff;
				else
				{
					mask = 0x00000000;
					for (i = 0; i < len; i++)
					{
//						CONFIG::debug
//						{
//							Assert.isTrue(BBGroupMask.isValidGroup(p_includeGroups[i]), "BBPhysicFilter.getMask, one group of includeGroups is incorrect (" + p_includeGroups[i] + ")");
//						}

//						mask |= (1 << (p_includeGroups[i] - 1));
						mask |= p_includeGroups[i];
					}
				}
			}
			else if (p_excludeGroups)
			{
				len = p_excludeGroups.length;

				if (len < 1) mask = 0x00000000;
				else
				{
					mask = 0xffffffff;

					for (i = 0; i < len; i++)
					{
//						CONFIG::debug
//						{
//							Assert.isTrue(BBGroupMask.isValidGroup(p_excludeGroups[i]), "BBPhysicFilter.getMask, one group of excludeGroups is incorrect (" + p_excludeGroups[i] + ")");
//						}

//						mask &= (~(1 << (p_excludeGroups[i] - 1)));
						mask &= (~(p_excludeGroups[i]));
					}
				}
			}

			return mask;
		}

		/**
		 * Returns new value with included new group.
		 */
		static public function includeGroup(p_filterMask:int, p_includingGroup:int):int
		{
//			return p_filterMask | (1 << (p_includingGroup-1));
			return p_filterMask | p_includingGroup;
		}

		/**
		 * Returns new value with excluded new group.
		 */
		static public function excludeGroup(p_filterMask:int, p_excludingGroup:int):int
		{
//			return p_filterMask & (~(1 << (p_excludingGroup-1)));
			return p_filterMask & (~p_excludingGroup);
		}

//		/**
//		 * Check if group lays in right range.
//		 * All possible groups 31.
//		 * For getting correct group use getGroup method.
//		 */
//		static public function isValidGroup(p_group:int):Boolean
//		{
//			return (p_group >= -1) && (p_group <= (1<<32));
//		}
	}
}
