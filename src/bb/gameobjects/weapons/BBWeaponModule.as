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
	import bb.signals.BBSignal;

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
				currentBullet.elapsedTime += p_deltaTime;

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

		/**
		 */
		private function getFireResult(p_bullet:BBBullet, p_deltaTime:int):void
		{
			var distanceMax:Number = (p_bullet.speed * 10) * (p_deltaTime / 1000.0);
			var passedDistance:Number = p_bullet.passedDistance + distanceMax;

			//
			if (!(passedDistance < p_bullet.fireDistance))
			{
				distanceMax = passedDistance > p_bullet.fireDistance ? (passedDistance - p_bullet.fireDistance) : distanceMax;
				p_bullet.shouldRemove = true;
			}

			//
			_ray.origin.set(p_bullet.currentPosition);
			_ray.direction.set(p_bullet.direction);
			_ray.maxDistance = p_bullet.impactObstacles ? (distanceMax + distanceMax * 0.1) : distanceMax;

			//
			if (p_bullet.multiAims)
			{
				_physicsModule.space.rayMultiCast(_ray, true, p_bullet.filter, _rayResultList);

				var len:int = _rayResultList.length;
				var rayResult:RayResult;

				while (len > 0)
				{
					rayResult = _rayResultList.at(0);
					_rayResultList.remove(rayResult);
					len--;

					//
					addFireResult(rayResult, p_bullet);
				}

				// if impact obstacles on bullet's energy
				if (p_bullet.impactObstacles)
				{
					var fireResult:BBFireResult;
					len = _fireResults.length;

					for (var i:int = 0; i < len; i++)
					{
						fireResult = _fireResults[i];

						// TODO:
//						Vec2.distance(p_bullet.origin, fireResult.)
					}
				}

				//
				p_bullet.currentPosition.addeq(p_bullet.direction.mul(distanceMax, true));
				p_bullet.passedDistance += distanceMax;
			}
			else
			{
				addFireResult(_physicsModule.space.rayCast(_ray, false, p_bullet.filter), p_bullet);
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

					// if obstacles should impact on bullet's energy
//					if (p_bullet.impactObstacles)
//					{
//						var distance:Number = Vec2.distance(outerFireResult.outContact, outerFireResult.contact);
//						var spentEnergy:Number = p_rayResult.shape.material.density * distance;
//						var bulletEnergy:Number = p_bullet.energy;
//
//						if (bulletEnergy < spentEnergy)
//						{
//							outerFireResult.penetration = bulletEnergy / spentEnergy;
//							p_bullet.shouldRemove = true;
//
//							return true;
//						}
//						else
//						{
//							p_bullet.energy = bulletEnergy - spentEnergy;
//						}
//					}
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
		private function clearFireResults():void
		{
			var len:int = _fireResults.length;
			for (var i:int = 0; i < len; i++)
			{
				_fireResults[i].dispose();
			}

			_fireResults.length = 0;
		}
	}
}
