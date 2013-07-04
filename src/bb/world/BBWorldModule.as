/**
 * User: VirtualMaestro
 * Date: 27.03.13
 * Time: 20:50
 */
package bb.world
{
	import bb.modules.*;
	import bb.bb_spaces.bb_private;
	import bb.camera.components.BBCamera;
	import bb.config.BBConfig;
	import bb.layer.constants.BBLayerNames;
	import bb.constants.profiles.BBGameType;
	import bb.core.BBNode;
	import bb.core.BabyBox;
	import bb.layer.BBLayerModule;
	import bb.signals.BBSignal;

	use namespace bb_private;

	/**
	 * Module represent world - main point to add actors (nodes) to world (scene).
	 */
	public class BBWorldModule extends BBModule
	{
		//
		private var _config:BBConfig;
		private var _layerManager:BBLayerModule;

		/**
		 */
		public function BBWorldModule()
		{
			super();
			onInit.add(onInitHandler);
			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_config = (engine as BabyBox).config;
			_layerManager = getModule(BBLayerModule) as BBLayerModule;
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			setupGameType(_config.gameType);
		}

		/**
		 * Adds actors (nodes) to world (scene).
		 * p_layerName - name of layer that actor should be added to it.
		 */
		public function add(p_actor:BBNode, p_layerName:String):void
		{
			CONFIG::debug
			{
				if (p_actor.isDisposed) return;
			}

			_layerManager.get(p_layerName).add(p_actor);
		}

		/**
		 * Removes actors from world.
		 */
		public function remove(p_actor:BBNode):void
		{
			// TODO:
		}

		/**
		 */
		public function getActorByName(p_actorName:String, p_layerName:String = ""):BBNode
		{
			var node:BBNode = p_layerName == "" ? _layerManager.root : _layerManager.get(p_layerName).node;
			return node.getChildByName(p_actorName);
		}

		/**
		 */
		private function setupGameType(p_gameType:int):void
		{
			switch (p_gameType)
			{
				case BBGameType.PLATFORMER:
				{
					var cameraMain:BBCamera = BBCamera.get(BBLayerNames.MAIN);
					var cameraBack:BBCamera = BBCamera.get(BBLayerNames.BACKEND);
					var cameraFront:BBCamera = BBCamera.get(BBLayerNames.FRONTEND);
					var cameraMenu:BBCamera = BBCamera.get(BBLayerNames.MENU);

					cameraMain.mouseEnable = true;
					cameraMain.node.transform.setPosition(_config.appWidth / 2, _config.appHeight / 2);
					cameraBack.node.transform.setPosition(_config.appWidth / 2, _config.appHeight / 2);
					cameraFront.node.transform.setPosition(_config.appWidth / 2, _config.appHeight / 2);
					cameraMenu.node.transform.setPosition(_config.appWidth / 2, _config.appHeight / 2);

					cameraBack.dependOnCamera(cameraMain, 0.5, 0.5);
					cameraFront.dependOnCamera(cameraMain, 1.5, 1.5);

					_layerManager.add(BBLayerNames.BACKEND, true).attachCamera(cameraBack);
					_layerManager.add(BBLayerNames.MAIN, true).attachCamera(cameraMain);
					_layerManager.add(BBLayerNames.FRONTEND, true).attachCamera(cameraFront);
					_layerManager.add(BBLayerNames.MENU, true).attachCamera(cameraMenu);

					// setup additional layers for main layer
					_layerManager.addTo(BBLayerNames.BACKGROUND, BBLayerNames.MAIN);
					_layerManager.addTo(BBLayerNames.MIDDLEGROUND, BBLayerNames.MAIN);
					_layerManager.addTo(BBLayerNames.FOREGROUND, BBLayerNames.MAIN);

					break;
				}
			}
		}
	}
}
