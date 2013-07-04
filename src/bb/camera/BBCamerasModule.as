/**
 * User: VirtualMaestro
 * Date: 03.04.13
 * Time: 21:14
 */
package bb.camera
{
	import bb.modules.*;
	import bb.bb_spaces.bb_private;
	import bb.components.BBCamera;
	import bb.core.BBNode;
	import bb.signals.BBSignal;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Response for managing cameras.
	 */
	public class BBCamerasModule extends BBModule
	{
		private var _camerasList:Vector.<BBCamera> = null;
		private var _rootNode:BBNode;

		/**
		 */
		public function BBCamerasModule()
		{
			super();
			onInit.add(onInitHandler);

			_camerasList = new <BBCamera>[];
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_rootNode = (getModule(BBGraphModule) as BBGraphModule).root;
		}

		/**
		 * Adds camera to system.
		 * It is possible to add only instance which already added to node.
		 */
		public function addCamera(p_camera:BBCamera):void
		{
			CONFIG::debug
			{
				Assert.isTrue(!isCameraAlreadyAdded(p_camera), "This instance of camera already added to engine", "BBGraphModule.setCamera");
				Assert.isTrue(p_camera.node != null, "Instance of camera should be attached to node", "BBGraphModule.setCamera");
			}

			if (p_camera.node.parent)
			{
				if (p_camera.node.parent != _rootNode) _rootNode.addChild(p_camera.node);
			}
			else _rootNode.addChild(p_camera.node);

			if (!isCameraAlreadyAdded(p_camera)) _camerasList.push(p_camera);
		}

		/**
		 * Check if given instance of camera already added to system.
		 */
		private function isCameraAlreadyAdded(p_camera:BBCamera):Boolean
		{
			var len:int = _camerasList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (_camerasList[i] == p_camera) return true;
			}

			return false;
		}

		/**
		 * Gets camera by given index.
		 */
		public function getCameraByIndex(p_index:int):BBCamera
		{
			if (p_index > _camerasList.length - 1 || p_index < 0) return null;
			return _camerasList[p_index];
		}

		/**
		 * Gets camera by given name.
		 * If camera with given name doesn't exist returns null.
		 */
		public function getCameraByName(p_name:String):BBCamera
		{
			var camera:BBCamera = null;
			for (var i:int = 0; i < _camerasList.length; i++)
			{
				if (_camerasList[i].node.name == p_name)
				{
					camera = _camerasList[i];
					break;
				}
			}

			return camera;
		}

		/**
		 * Removes given camera.
		 */
		public function removeCamera(p_camera:BBCamera):void
		{
			var len:int = _camerasList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (_camerasList[i] == p_camera)
				{
					removeCameraByIndex(i);
					break;
				}
			}
		}

		/**
		 * Removes camera by given index.
		 */
		public function removeCameraByIndex(p_index:int):void
		{
			if (p_index > _camerasList.length - 1 || p_index < 0) return;

			var camera:BBCamera = _camerasList[p_index];
			_camerasList.splice(p_index, 1);
			camera.node.dispose();
		}

		/**
		 * Removes camera by given name.
		 */
		public function removeCameraByName(p_name:String):void
		{
			var len:int = _camerasList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (_camerasList[i].node.name == p_name)
				{
					removeCameraByIndex(i);
					break;
				}
			}
		}

		/**
		 * Removes all cameras.
		 */
		public function clearCameras():void
		{
			for (var i:int = _camerasList.length - 1; i >= 0; i--)
			{
				removeCameraByIndex(i);
			}
		}

		/**
		 * Returns number of cameras.
		 */
		public function get numCameras():int
		{
			return _camerasList.length;
		}

		/**
		 */
		bb_private function get cameras():Vector.<BBCamera>
		{
			return _camerasList;
		}

		/**
		 */
		override public function dispose():void
		{
			super.dispose();
		}
	}
}
