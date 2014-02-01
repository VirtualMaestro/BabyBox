/**
 * User: VirtualMaestro
 * Date: 13.01.14
 * Time: 13:29
 */
package bb.gameobjects.weapons
{
	import bb.bb_spaces.bb_private;
	import bb.gameobjects.weapons.gun.BBBullet;
	import bb.layer.constants.BBLayerNames;
	import bb.modules.BBModule;
	import bb.physics.BBPhysicsModule;
	import bb.render.components.BBSprite;
	import bb.render.textures.BBTexture;
	import bb.signals.BBSignal;
	import bb.world.BBWorldModule;

	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.RayResultList;
	import nape.geom.Vec2;
	import nape.shape.Shape;

	use namespace bb_private;

	/**
	 * Module for handle bullets.
	 */
	public class BBWeaponModule extends BBModule
	{
		private var _physicsModule:BBPhysicsModule;

		private var _bulletHead:BBBullet;
		private var _bulletTail:BBBullet;

		private var _ray:Ray;
		private var _rayResultList:RayResultList;
		private var _fireResults:Vector.<BBFireResult>;
		private var _withoutOuter:Vector.<BBFireResult>;

		/**
		 */
		public function BBWeaponModule()
		{
			super();

			onInit.add(onInitHandler);
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_physicsModule = getModule(BBPhysicsModule) as BBPhysicsModule;
			_ray = new Ray(Vec2.get(), Vec2.get());
			_rayResultList = new RayResultList();
			_fireResults = new <BBFireResult>[];
			_withoutOuter = new <BBFireResult>[];
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

				// clear list of fire results
				clearFireResults();

				//
				if (currentBullet.shouldRemove)
				{
					currentBullet.dispose();
				}
			}
		}

		private function addLine(p_vec:Vec2):void
		{
			var sprite:BBSprite = BBSprite.getWithNode(BBTexture.createFromColorRect(4, 50, "line", 0xff00ff00));
			sprite.node.transform.setPosition(p_vec.x, p_vec.y);
			(getModule(BBWorldModule) as BBWorldModule).add(sprite.node, BBLayerNames.MIDDLEGROUND);
		}

		/**
		 */
		private function getFireResult(p_bullet:BBBullet, p_deltaTime:int):void
		{
			addLine(p_bullet.currentPosition);

			p_bullet.elapsedTime += p_deltaTime;

			var absoluteDistanceDelta:Number = (p_bullet.speed * 10) * (p_deltaTime / 1000.0);
			var distanceDelta:Number = absoluteDistanceDelta;
			var expectedPassedDistance:Number = p_bullet.passedDistance + distanceDelta;
			var fireDistance:Number = p_bullet.fireDistance;

			//
			if (!(expectedPassedDistance < fireDistance))
			{
				distanceDelta = expectedPassedDistance > fireDistance ? (fireDistance - p_bullet.passedDistance) : distanceDelta;
				p_bullet.shouldRemove = true;
			}

			//
			if (p_bullet.multiAims)
			{
				var findOuterPoints:Boolean = p_bullet.outputPosition || p_bullet.impactObstacles;
				var numCorrectResults:int = 0;
				var fartherFireResult:BBFireResult;
				var biggerDistance:Number = 0;
				var numResults:int;
				var breakLoop:Boolean = false;
				var fireResult:BBFireResult;

				while (!breakLoop)
				{
					multiAimsProcess(p_bullet.currentPosition, p_bullet.direction, distanceDelta, p_bullet);

					// need to find also points where bullet out from body
					numResults = _fireResults.length;
					if (findOuterPoints && numResults > 0)
					{
						// mean at least second iteration to find all outer points
						var numWithoutOuter:int = _withoutOuter.length;
						if (numWithoutOuter > 0)
						{
							for (var j:int = 0; j < numWithoutOuter; j++)
							{
								fireResult = _withoutOuter[j];

								//
								if (fireResult.outContact)
								{
									if (fireResult.outContactDistance > biggerDistance)
									{
										biggerDistance = fireResult.outContactDistance;
										fartherFireResult = fireResult;
									}

									_withoutOuter.splice(j, 1);
									j--;
									numWithoutOuter--;
								}
							}

							// if after additional raycast for some fire result wasn't find out contact, continue searching
							numWithoutOuter = _withoutOuter.length;
							if (numWithoutOuter == 0) // if every out contact were found, try to figure out for new contacts and try to filter them
							{
								// if there are new extra results
								if (numResults > numCorrectResults)
								{
									for (var k:int = numCorrectResults; k < numResults; k++)
									{
										fireResult = _fireResults[k];

										if (biggerDistance > fireResult.inContactDistance)
										{
											numCorrectResults++;

											if (!fireResult.outContact)
											{
												_withoutOuter[numWithoutOuter++] = fireResult;
												break;
											}
											else if (fireResult.outContactDistance > biggerDistance)
											{
												fartherFireResult = fireResult;
												biggerDistance = fireResult.outContactDistance;
											}
										}
										else
										{
											clearFireResults(numCorrectResults);
											breakLoop = true;
											break;
										}
									}
								}
								else breakLoop = true;
							}
						}
						else    // first iteration
						{
							numCorrectResults = numResults;

							for (var i:int = 0; i < numResults; i++)
							{
								fireResult = _fireResults[i];

								if (fireResult.outContact == null) _withoutOuter[numWithoutOuter++] = fireResult;
							}

							breakLoop = numWithoutOuter == 0;
						}
					}
					else breakLoop = true;

					//
					p_bullet.currentPosition.addeq(p_bullet.direction.mul(distanceDelta, true));
					p_bullet.passedDistance += distanceDelta;
					distanceDelta = absoluteDistanceDelta;
				}

				if (fartherFireResult)
				{
					p_bullet.currentPosition.set(fartherFireResult.outContact);
					p_bullet.passedDistance = fartherFireResult.outContactDistance;
				}

				if (!(p_bullet.passedDistance < fireDistance)) p_bullet.shouldRemove = true;

				addLine(p_bullet.currentPosition);
			}
			else
			{
				_ray.origin.set(p_bullet.currentPosition);
				_ray.direction.set(p_bullet.direction);
				_ray.maxDistance = distanceDelta;

				addFireResult(_physicsModule.space.rayCast(_ray, false, p_bullet.filter), p_bullet);
			}
		}

		/**
		 * Find results for multi aims.
		 */
		private function multiAimsProcess(p_bulletPosition:Vec2, p_bulletDirection:Vec2, p_distance:Number, p_bullet:BBBullet):void
		{
			_ray.origin.set(p_bulletPosition);
			_ray.direction.set(p_bulletDirection);
			_ray.maxDistance = p_distance;

			_physicsModule.space.rayMultiCast(_ray, p_bullet.outputPosition || p_bullet.impactObstacles, p_bullet.filter, _rayResultList);

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
		private function addFireResult(p_rayResult:RayResult, p_bullet:BBBullet):Boolean
		{
			var fireResult:BBFireResult;

			if (p_rayResult.inner)
			{
				var outerFireResult:BBFireResult = findOuterPart(p_rayResult.shape);

				if (outerFireResult)
				{
					outerFireResult.outContact = p_bullet.currentPosition.addMul(p_bullet.direction, p_rayResult.distance);
					outerFireResult.outContactDistance = p_bullet.passedDistance + p_rayResult.distance;
				}
			}
			else
			{
				fireResult = BBFireResult.get();
				fireResult.bullet = p_bullet;
				fireResult.rayResult = p_rayResult;
				fireResult.inContact = p_bullet.currentPosition.addMul(p_bullet.direction, p_rayResult.distance);
				fireResult.inContactDistance = p_bullet.passedDistance + p_rayResult.distance;

				_fireResults[_fireResults.length] = fireResult;
			}

			return false;
		}

		/**
		 */
		private function findOuterPart(p_shape:Shape):BBFireResult
		{
			var len:int = _fireResults.length;
			var fireResult:BBFireResult;

			for (var i:int = 0; i < len; i++)
			{
				fireResult = _fireResults[i];

				if (fireResult.rayResult.shape == p_shape) return fireResult;
			}

			return null;
		}

		/**
		 */
		private function clearFireResults(p_startClearFromIndex:int = 0):void
		{
			var len:int = _fireResults.length;
			for (var i:int = p_startClearFromIndex; i < len; i++)
			{
				_fireResults[i].dispose();
			}

			_fireResults.length = p_startClearFromIndex;
		}
	}
}
