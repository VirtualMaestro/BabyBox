/**
 * User: VirtualMaestro
 * Date: 27.03.13
 * Time: 20:50
 */
package bb.modules
{
	import bb.common.BBLayer;
	import bb.components.BBCamera;
	import bb.constants.layers.BBLayerNames;
	import bb.constants.profiles.BBGameType;
	import bb.core.BBConfig;
	import bb.core.BBNode;
	import bb.core.BabyBox;
	import bb.signals.BBSignal;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

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
		private function setupGameType(p_gameType:int):void
		{
			switch (p_gameType)
			{
				case BBGameType.PLATFORMER:
				{
					var main:BBCamera = BBCamera.get(BBLayerNames.MAIN);
					var cameraBack:BBCamera = BBCamera.get(BBLayerNames.BACKEND);
					var cameraFront:BBCamera = BBCamera.get(BBLayerNames.FRONTEND);

					main.mouseEnable = true;
					main.node.transform.setPosition(_config.appWidth/2, _config.appHeight/2);
					cameraBack.node.transform.setPosition(_config.appWidth/2, _config.appHeight/2);
					cameraFront.node.transform.setPosition(_config.appWidth/2, _config.appHeight/2);

					cameraBack.dependOnCamera(main, 0.5, 0.5, 0.5);
					cameraFront.dependOnCamera(main, 1.5, 1.5, 0.8);

					_layerManager.add(BBLayerNames.BACKEND, true).attachCamera(cameraBack);
					_layerManager.add(BBLayerNames.FRONTEND, true).attachCamera(cameraFront);

					// main layers
					var mainLayer:BBLayer = _layerManager.add(BBLayerNames.MAIN, true);
					mainLayer.attachCamera(main);
					_layerManager.addTo(BBLayerNames.BACKGROUND, BBLayerNames.MAIN);
					_layerManager.addTo(BBLayerNames.MIDDLEGROUND, BBLayerNames.MAIN);
					_layerManager.addTo(BBLayerNames.FOREGROUND, BBLayerNames.MAIN);

					break;
				}
			}
		}
	}
}
