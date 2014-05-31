/**
 * User: VirtualMaestro
 * Date: 13.01.14
 * Time: 13:29
 */
package bb.gameobjects.weapons
{
	import bb.bb_spaces.bb_private;
	import bb.gameobjects.weapons.gun.BBBullet;
	import bb.modules.BBModule;
	import bb.physics.BBPhysicsModule;

	import flash.utils.Dictionary;

	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.RayResultList;
	import nape.geom.Vec2;
	import nape.shape.Shape;

	import vm.ds.stacks.BBStack;

	use namespace bb_private;

	/**
	 * Module for handle bullets.
	 */
	public class BBWeaponModule extends BBModule
	{
		private var _physicsModule:BBPhysicsModule;

		private var _bulletHead:BBBullet;
		private var _bulletTail:BBBullet;

		private var _minBulletSpeed:Number = 50;
		private var _ray:Ray;
		private var _rayResultList:RayResultList;
		private var _fireResults:Vector.<BBFireResult>;

		//
		private var _prevDistance:Number = 0;
		private var _numResultsWithoutOuters:int = 0;
		private var _tableWithoutOuters:Dictionary;
		private var _resultsStack:BBStack;

		/**
		 */
		public function BBWeaponModule()
		{
			super();
		}

		/**
		 */
		override protected function init():void
		{
			_physicsModule = getModule(BBPhysicsModule) as BBPhysicsModule;
			_ray = new Ray(Vec2.get(), Vec2.get());
			_rayResultList = new RayResultList();
			_fireResults = new <BBFireResult>[];
			_tableWithoutOuters = new Dictionary();
			_resultsStack = BBStack.get();
		}

		/**
		 * Adds bullet to handling.
		 */
		public function addBullet(p_bullet:BBBullet):void
		{
			if (_bulletTail)
			{
				_bulletTail.next = p_bullet;
				p_bullet.prev = _bulletTail;
			}
			else _bulletHead = p_bullet;

			_bulletTail = p_bullet;

			p_bullet.removeFromList = removeBullet;

			updateEnable = true;
		}

		/**
		 * Remove bullet from bullets list.
		 */
		private function removeBullet(p_bullet:BBBullet):void
		{
			if (p_bullet == _bulletHead)
			{
				_bulletHead = _bulletHead.next;

				if (_bulletHead == null) _bulletTail = null;
				else _bulletHead.prev = null;
			}
			else if (p_bullet == _bulletTail)
			{
				_bulletTail = _bulletTail.prev;

				if (_bulletTail == null) _bulletHead = null;
				else _bulletTail.next = null;
			}
			else
			{
				var prevBullet:BBBullet = p_bullet.prev;
				var nextBullet:BBBullet = p_bullet.next;
				prevBullet.next = nextBullet;
				nextBullet.prev = prevBullet;
			}

			if (_bulletTail == null) updateEnable = false;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			var bullet:BBBullet = _bulletHead;
			var currentBullet:BBBullet;

			while (bullet)
			{
				currentBullet = bullet;
				bullet = bullet.next;

				//
				getFireResult(currentBullet, p_deltaTime);

				// if have something to dispatch dispatching it
				if (_fireResults.length > 0 && currentBullet.callbackResult) currentBullet.callbackResult(_fireResults);

				//
				if (currentBullet.shouldRemove)
				{
					currentBullet.dispose();
				}

				//
				endBulletProcess();
			}
		}

		/**
		 */
		[Inline]
		final private function getDistanceDeltaAndCheckBulletStatus(p_bullet:BBBullet, p_deltaTime:int):Number
		{
			var distanceDelta:Number = (p_bullet.speed * 10.0) * (Number(p_deltaTime) * 0.001);
			var expectedPassedDistance:Number = p_bullet.passedDistance + distanceDelta;
			var fireDistance:Number = p_bullet.fireDistance;

			if (p_bullet.speed < _minBulletSpeed) p_bullet.shouldRemove = true;

			if (expectedPassedDistance >= fireDistance)
			{
				distanceDelta = expectedPassedDistance > fireDistance ? (fireDistance - p_bullet.passedDistance) : distanceDelta;
				p_bullet.shouldRemove = true;
			}

			return distanceDelta;
		}

		/**
		 */
		private function getFireResult(p_bullet:BBBullet, p_deltaTime:int):void
		{
			var distanceDelta:Number = 0;

			//
			if (p_bullet.multiAims)
			{
				distanceDelta = getDistanceDeltaAndCheckBulletStatus(p_bullet, p_deltaTime);
				multiAimsProcess(p_bullet.currentPosition, p_bullet.direction, distanceDelta, p_bullet);

				p_bullet.addDistance(distanceDelta);

				//
				if (p_bullet.findOutputPosition && _numResultsWithoutOuters > 0)
				{
					var numCorrectResults:int = _fireResults.length;
					var furtherDistance:int = p_bullet.passedDistance;
					var complete:Boolean = false;
					var fireResult:BBFireResult;
					var numResults:int;
					var startFrom:int = 0;

					while (!complete)
					{
						complete = true;

						multiAimsProcess(p_bullet.currentPosition, p_bullet.direction, distanceDelta, p_bullet);

						for (var i:int = startFrom; i < numCorrectResults; i++)
						{
							fireResult = _fireResults[i];

							if (fireResult.outContact == null)
							{
								furtherDistance = p_bullet.passedDistance + distanceDelta;
								complete = false;
								break;
							}
							else if (fireResult.outContactDistance > furtherDistance)
							{
								furtherDistance = fireResult.outContactDistance;
							}
						}

						startFrom = i;

						//
						if (complete)
						{
							numResults = _fireResults.length;

							if (numResults != numCorrectResults)
							{
								for (var j:int = numCorrectResults; j < numResults; j++)
								{
									fireResult = _fireResults[i];

									if (furtherDistance - 0.3 > fireResult.inContactDistance)
									{
										numCorrectResults++;

										if (fireResult.outContact == null)
										{
											complete = false;
											break;
										}
									}
								}
							}
						}

						p_bullet.setDistance(furtherDistance);
					}

					clearFireResults(numCorrectResults);
				}

				//
				if (p_bullet.passedDistance >= p_bullet.fireDistance || p_bullet.speed < _minBulletSpeed)
				{
					p_bullet.shouldRemove = true;

					// clear unneeded results which has spent energy 0
					if (p_bullet.impactObstacles)
					{
						var numFireResults:int = _fireResults.length;

						for (i = 0; i < numFireResults; i++)
						{
							if (_fireResults[i].energy == 0)
							{
								clearFireResults(i);
								break;
							}
						}
					}
				}
			}
			else
			{
				addFireResult(getSingleRayResult(p_bullet, p_deltaTime), p_bullet);
			}
		}

		/**
		 */
		[Inline]
		final private function getSingleRayResult(p_bullet:BBBullet, p_deltaTime:int):RayResult
		{
			_ray.origin.set(p_bullet.currentPosition);
			_ray.direction.set(p_bullet.direction);
			_ray.maxDistance = getDistanceDeltaAndCheckBulletStatus(p_bullet, p_deltaTime);

			return _physicsModule.space.rayCast(_ray, false, p_bullet.filter);
		}

		/**
		 * Find results for multi aims.
		 */
		private function multiAimsProcess(p_bulletPosition:Vec2, p_bulletDirection:Vec2, p_distance:Number, p_bullet:BBBullet):void
		{
			_ray.origin.set(p_bulletPosition);
			_ray.direction.set(p_bulletDirection);
			_ray.maxDistance = p_distance;

			_physicsModule.space.rayMultiCast(_ray, p_bullet.findOutputPosition || p_bullet.impactObstacles, p_bullet.filter, _rayResultList);

			var rayResultCount:int = _rayResultList.length;
			var rayResult:RayResult;

			while (rayResultCount > 0)
			{
				rayResult = _rayResultList.at(0);
				_rayResultList.remove(rayResult);
				rayResultCount--;

				//
				addFireResult(rayResult, p_bullet);
			}
		}

		/**
		 * Returns true if handling current bullet should stop.
		 */
		private function addFireResult(p_rayResult:RayResult, p_bullet:BBBullet):void
		{
			var exitFromShape:Boolean = p_rayResult.inner;
			var nShape:Shape = p_rayResult.shape;
			var nDistance:Number = p_rayResult.distance;
			var nTotalDistance:Number = nDistance + p_bullet.passedDistance;
			var insideShape:Boolean = _numResultsWithoutOuters > 0;
			var diffDistance:Number = nTotalDistance - _prevDistance;
			var energySpentForBody:Number = 0;
			var impactObstacles:Boolean = p_bullet.impactObstacles;
			var bulletEnergy:Number;
			var newBulletEnergy:Number;

			//
			if (exitFromShape)
			{
				if (insideShape)
				{
					var outerFireResult:BBFireResult = _tableWithoutOuters[nShape];

					if (outerFireResult)
					{
						outerFireResult.outContact = p_bullet.currentPosition.addMul(p_bullet.direction, nDistance);
						outerFireResult.outContactDistance = nTotalDistance;
						outerFireResult.outSpeed = p_bullet.speed;

						delete _tableWithoutOuters[nShape];
						_numResultsWithoutOuters--;

						if (impactObstacles)
						{
							if (_resultsStack.top.shape == nShape)
							{
								energySpentForBody = getSpentEnergy(nShape.material.density, diffDistance);

								bulletEnergy = p_bullet.energy;
								newBulletEnergy = bulletEnergy - energySpentForBody;

								if (newBulletEnergy <= 0)
								{
									newBulletEnergy = 0;
									energySpentForBody = bulletEnergy;
								}

								p_bullet.energy = newBulletEnergy;
								outerFireResult.energy += energySpentForBody;

								_prevDistance = nTotalDistance;
							}

							outerFireResult.stackNode.dispose();
						}
					}
				}
			}
			else
			{
				var fireResult:BBFireResult = BBFireResult.get();
				fireResult.bullet = p_bullet;
				fireResult.rayResult = p_rayResult;
				fireResult.inContact = p_bullet.currentPosition.addMul(p_bullet.direction, nDistance);
				fireResult.inContactDistance = nTotalDistance;
				fireResult.inSpeed = p_bullet.speed;

				_fireResults[_fireResults.length] = fireResult;

				_numResultsWithoutOuters++;

				//
				if (impactObstacles)
				{
					if (insideShape) // bullet enters the shape which is into some other shape
					{
						var lastFireResult:BBFireResult = _resultsStack.top as BBFireResult;
						energySpentForBody = getSpentEnergy(lastFireResult.shape.material.density, diffDistance);

						bulletEnergy = p_bullet.energy;
						newBulletEnergy = bulletEnergy - energySpentForBody;

						if (newBulletEnergy <= 0)
						{
							newBulletEnergy = 0;
							energySpentForBody = bulletEnergy;
						}

						p_bullet.energy = newBulletEnergy;
						lastFireResult.energy += energySpentForBody;
					}

					_prevDistance = nTotalDistance;

					fireResult.stackNode = _resultsStack.push(fireResult);
				}

				//
				if (p_bullet.findOutputPosition)
				{
					_tableWithoutOuters[nShape] = fireResult;
				}
			}
		}

		/**
		 */
		[Inline]
		final private function endBulletProcess():void
		{
			for (var key:Object in _tableWithoutOuters)
			{
				delete _tableWithoutOuters[key];
			}

			clearFireResults();
			_resultsStack.clear();
			_prevDistance = _numResultsWithoutOuters = 0;
		}

		/**
		 */
		final private function clearFireResults(p_startClearFromIndex:int = 0):void
		{
			var len:int = _fireResults.length;
			for (var i:int = p_startClearFromIndex; i < len; i++)
			{
				_fireResults[i].dispose();
			}

			_fireResults.length = p_startClearFromIndex;
		}

		/**
		 * Returns energy which spent during passing through material with specific density for given distance.
		 */
		[Inline]
		static private function getSpentEnergy(p_densityOfMaterial:Number, p_passedDistance:Number):Number
		{
			return (150 * p_densityOfMaterial * p_passedDistance * 100) / 30.0;
		}
	}
}
