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
	import nape.geom.RayResult;

	/**
	 * Module for handle bullets.
	 */
	public class BBWeaponModule extends BBModule
	{
		private var _physicsModule:BBPhysicsModule;

		private var _bulletHead:BBBullet;
		private var _bulletTail:BBBullet;

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
					if (currentBullet.multiAims)
					{

					}
					else
					{

					}
				}
			}
		}

		/**
		 */
		private function getFireResult(p_bullet:BBBullet):void
		{
			if (p_bullet.multiAims)
			{
//				var result:RayResult = _physicsModule.space.rayMultiCast(Ray.fromSegment(startPos, endPos));
			}
			else
			{
				var result:RayResult = _physicsModule.space.rayCast(Ray.fromSegment(p_bullet.start, p_bullet.end));
//				result.
			}
		}
	}
}
