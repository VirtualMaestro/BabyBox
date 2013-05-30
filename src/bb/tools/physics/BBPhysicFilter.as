package bb.tools.physics
{
	import nape.dynamics.InteractionFilter;
	import nape.phys.Body;
	import nape.shape.Shape;
	import nape.shape.ShapeList;

	import bb.tools.BBGroupMask;

//	CONFIG::debug
//	{
//		import vm.debug.Assert;
//	}

	/**
	 */
	public class BBPhysicFilter
	{
		//
		static private var currentCollisionGroup:int = 1;
		static private var currentSensorGroup:int = 1;
		static private var currentFluidGroup:int = 1;

		/**
		 * Method returns new unique collision group.
		 * There is 31 possible groups (in real case 30 due to first group by default for all filters)
		 *
		 * To make sure that free collision groups still exist use 'hasCollisionGroup' method.
		 */
		static public function getCollisionGroup():int
		{
			return (1 << (++currentCollisionGroup-1));
		}

		/**
		 * Check whether there is free collision groups.
		 */
		static public function hasCollisionGroup():Boolean
		{
			return (currentCollisionGroup+1) < 33;
		}

		/**
		 * Reset collision group's counter, so it is possible to get groups from the beginning.
		 */
		static public function resetCollisionGroups():void
		{
			currentCollisionGroup = 1;
		}

		/**
		 * Method returns new unique sensor group.
		 * There is 31 possible groups (in real case 30 due to first group by default for all filters)
		 *
		 * To make sure that free sensor groups still exist use 'hasSensorGroup' method.
		 */
		static public function getSensorGroup():int
		{
			return (1 << (++currentSensorGroup-1));
		}

		/**
		 * Check whether there is free sensor groups.
		 */
		static public function hasSensorGroup():Boolean
		{
			return (currentSensorGroup+1) < 33;
		}

		/**
		 * Reset sensor group's counter, so it is possible to get groups from the beginning.
		 */
		static public function resetSensorGroup():void
		{
			currentSensorGroup = 1;
		}

		/**
		 * Method returns new unique fluid group.
		 * There is 31 possible groups (in real case 30 due to first group by default for all filters)
		 *
		 * To make sure that free fluid groups still exist use 'hasFluidGroup' method.
		 */
		static public function getFluidGroup():int
		{
			return (1 << (++currentFluidGroup-1));
		}

		/**
		 * Check whether there is free fluid groups.
		 */
		static public function hasFluidGroup():Boolean
		{
			return (currentFluidGroup+1) < 33;
		}

		/**
		 * Reset fluid group's counter, so it is possible to get groups from the beginning.
		 */
		static public function resetFluidGroup():void
		{
			currentFluidGroup = 1;
		}

		/**
		 * Creates and returns new filter with given group.
		 * There are 31 possible groups, but in real case there are 30 groups due to by default all filters have first group (1).
		 * For generating correct groups use methods: getCollisionGroup, getSensorGroup, getFluidGroup.
		 * By default creates filter with the first group (1).
		 *
		 * For every layer (collision, sensor, fluid) should to set only 'include' or 'exclude' list of groups.
		 * (Examples for collision layer but the same is true for sensor and fluid layers)
		 *
		 * For the next examples we prepare 5 collision groups:
		 * <code>
		 *     var group_1:int = BBPhysicFilter.getCollisionGroup();
		 *     var group_2:int = BBPhysicFilter.getCollisionGroup();
		 *     var group_3:int = BBPhysicFilter.getCollisionGroup();
		 *     var group_4:int = BBPhysicFilter.getCollisionGroup();
		 *     var group_5:int = BBPhysicFilter.getCollisionGroup();
		 * </code>
		 *
		 * Now let's create filter with first collision group which should collide only with group_4 and group_5.
		 * <code>
		 *     var filter:InteractionFilter = BBPhysicFilter.getFilter(group_1, [group_4, group_5]);
		 * </code>
		 *
		 * Now we will create filter with second collision group which should to collide with every groups except 'group_4' and 'group_5':
		 * <code>
		 *     var filter:InteractionFilter = BBPhysicFilter.getFilter(group_2, null, [4,5]);
		 * </code>
		 *
		 * Let's create filter (group doesn't matter, e.g. group_1) which should to collide with every groups (of course except zero)
		 * <code>
		 *     var filter:InteractionFilter = BBPhysicFilter.getFilter(group_1);
		 * </code>
		 *
		 * Now we want to create filter with some non-zero group (e.g. group_1) that shouldn't to collide with any groups (for that you should in the 3-rd param set empty array).
		 * <code>
		 *     var filter:InteractionFilter = BBPhysicFilter.getFilter(group_1, null, []);
		 * </code>
		 *
		 * If need default first group just call getFilter without any params.
		 * <code>
		 *     var filter:InteractionFilter = BBPhysicFilter.getFilter();
		 * </code>
		 */
		static public function getFilter(p_collisionGroup:int = 1, p_collisionGroupInclude:Array = null, p_collisionGroupExclude:Array = null,
		                                 p_sensorGroup:int = 1, p_sensorGroupInclude:Array = null, p_sensorGroupExclude:Array = null,
		                                 p_fluidGroup:int = 1, p_fluidGroupInclude:Array = null, p_fluidGroupExclude:Array = null):InteractionFilter
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_collisionGroup, "BBPhysicFilter.getFilter collisionGroup");
//				isValidGroup(p_sensorGroup, "BBPhysicFilter.getFilter sensorGroup");
//				isValidGroup(p_fluidGroup, "BBPhysicFilter.getFilter fluidGroup");
//			}
//
//			p_collisionGroup = 1 << (p_collisionGroup - 1);
//			p_sensorGroup = 1 << (p_sensorGroup - 1);
//			p_fluidGroup = 1 << (p_fluidGroup - 1);

			var collisionMask:int = BBGroupMask.getMask(p_collisionGroupInclude, p_collisionGroupExclude);
			var sensorMask:int = BBGroupMask.getMask(p_sensorGroupInclude, p_sensorGroupExclude);
			var fluidMask:int = BBGroupMask.getMask(p_fluidGroupInclude, p_fluidGroupExclude);

			return new InteractionFilter(p_collisionGroup, collisionMask, p_sensorGroup, sensorMask, p_fluidGroup, fluidMask);
		}

		/**
		 * Modify filter for shape.
		 */
		static public function modifyShapeFilter(p_shape:Shape,
		                                         p_collisionInclude:Array = null, p_collisionExclude:Array = null,
												 p_sensorInclude:Array = null, p_sensorExclude:Array = null,
												 p_fluidInclude:Array = null, p_fluidExclude:Array = null):void

		{
			modifyFilter(p_shape.filter, p_collisionInclude, p_collisionExclude, p_sensorInclude, p_sensorExclude, p_fluidInclude, p_fluidExclude);
		}

		/**
		 * Modify filter parameters for every shape of body.
		 */
		static public function modifyBodyFilter(p_body:Body,
		                                        p_collisionInclude:Array = null, p_collisionExclude:Array = null,
												p_sensorInclude:Array = null, p_sensorExclude:Array = null,
												p_fluidInclude:Array = null, p_fluidExclude:Array = null):void

		{
			var shapeList:ShapeList = p_body.shapes;
			var filter:InteractionFilter = shapeList.at(0).filter;
			modifyFilter(filter, p_collisionInclude, p_collisionExclude, p_sensorInclude, p_sensorExclude, p_fluidInclude, p_fluidExclude);

			shapeList.foreach(function(shape:Shape):void
			{
				shape.filter.collisionMask = filter.collisionMask;
				shape.filter.sensorMask = filter.sensorMask;
				shape.filter.fluidMask = filter.fluidMask;
			});
		}

		/**
		 * Change parameter for given filter.
		 * If pair of some layer are null this layer won't changed.
		 * E.g. if collisionInclude == null and collisionExclude == null parameters for collision layer won't changed.
		 */
		static public function modifyFilter(p_filter:InteractionFilter,
		                                  p_collisionInclude:Array = null, p_collisionExclude:Array = null,
										  p_sensorInclude:Array = null, p_sensorExclude:Array = null,
										  p_fluidInclude:Array = null, p_fluidExclude:Array = null):void
		{
			p_filter.collisionMask = (p_collisionInclude == null && p_collisionExclude == null) ? p_filter.collisionMask : BBGroupMask.getMask(p_collisionInclude, p_collisionExclude);
			p_filter.sensorMask = (p_sensorInclude == null && p_sensorExclude == null) ? p_filter.sensorMask : BBGroupMask.getMask(p_sensorInclude, p_sensorExclude);
			p_filter.fluidMask = (p_fluidInclude == null && p_fluidExclude == null) ? p_filter.fluidMask : BBGroupMask.getMask(p_fluidInclude, p_fluidExclude);
		}

		/**
		 * Includes one collision group to given filter.
		 */
		static public function includeCollisionGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.includeCollisionGroup (group is " + p_group + ")");
//			}

			p_filter.collisionMask = BBGroupMask.includeGroup(p_filter.collisionMask, p_group);
		}

		/**
		 * Excludes one collision group from given filter.
		 */
		static public function excludeCollisionGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.excludeCollisionGroup (group is " + p_group + ")");
//			}

			p_filter.collisionMask = BBGroupMask.excludeGroup(p_filter.collisionMask, p_group);
		}

		/**
		 * Includes one sensor group to given filter.
		 */
		static public function includeSensorGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.includeSensorGroup (group is " + p_group + ")");
//			}

			p_filter.sensorMask = BBGroupMask.includeGroup(p_filter.sensorMask, p_group);
		}

		/**
		 * Excludes one sensor group from given filter.
		 */
		static public function excludeSensorGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.excludeSensorGroup (group is " + p_group + ")");
//			}

			p_filter.sensorMask = BBGroupMask.excludeGroup(p_filter.sensorMask, p_group);
		}

		/**
		 * Includes one fluid group to given filter.
		 */
		static public function includeFluidGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.includeFluidGroup (group is " + p_group + ")");
//			}

			p_filter.fluidMask = BBGroupMask.includeGroup(p_filter.fluidMask, p_group);
		}

		/**
		 * Excludes one fluid group from given filter.
		 */
		static public function excludeFluidGroup(p_filter:InteractionFilter, p_group:int):void
		{
//			CONFIG::debug
//			{
//				isValidGroup(p_group, "BBPhysicFilter.excludeFluidGroup (group is " + p_group + ")");
//			}

			p_filter.fluidMask = BBGroupMask.excludeGroup(p_filter.fluidMask, p_group);
		}

//		CONFIG::debug
//		static private function isValidGroup(p_group:int, p_whereOccur:String=""):void
//		{
//			Assert.isTrue(BBGroupMask.isValidGroup(p_group), "invalid group. Group have to be in range [1 - 32]", p_whereOccur);
//		}
	}
}

