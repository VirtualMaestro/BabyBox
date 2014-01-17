/**
 * User: VirtualMaestro
 * Date: 13.01.14
 * Time: 13:29
 */
package bb.gameobjects.weapons
{
	import bb.gameobjects.weapons.gun.BBBullet;
	import bb.modules.BBModule;
	import bb.physics.BBPhysicsModule;
	import bb.signals.BBSignal;

	import nape.geom.Ray;
	import nape.geom.RayResultList;
	import nape.geom.Vec2;

	/**
	 * Module for handle bullets.
	 */
	public class BBWeaponModule extends BBModule
	{
		private var _physicsModule:BBPhysicsModule;

		private var _bulletHead:BBBullet;
		private var _bulletTail:BBBullet;

		private var _ray:Ray;

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

				if (currentBullet.influenceTime)
				{

				}
				else
				{

				}

				getFireResult(currentBullet);

				//if (!_rayResultList.empty() && currentBullet.callbackResult) currentBullet.callbackResult(_rayResultList);
			}
		}

		//
		private var _rayResultList:RayResultList;

		/**
		 */
		private function getFireResult(p_bullet:BBBullet):void
		{
			_ray.origin.set(p_bullet.origin);
			_ray.direction.set(p_bullet.direction);
			_ray.maxDistance = p_bullet.fireDistance;

			if (p_bullet.multiAims)
			{
				_physicsModule.space.rayMultiCast(_ray, false, p_bullet.filter, _rayResultList);
			}
			else
			{
				_rayResultList.push(_physicsModule.space.rayCast(_ray, false, p_bullet.filter));
			}
		}
	}
}
