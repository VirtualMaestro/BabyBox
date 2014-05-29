/**
 * User: VirtualMaestro
 * Date: 01.02.13
 * Time: 14:10
 */
package bb.tree
{
	import bb.bb_spaces.bb_private;
	import bb.camera.BBCamerasModule;
	import bb.camera.components.BBCamera;
	import bb.config.BBConfig;
	import bb.core.BBNode;
	import bb.core.BabyBox;
	import bb.core.context.BBContext;
	import bb.modules.*;
	import bb.mouse.BBMouseModule;
	import bb.mouse.events.BBMouseEvent;
	import bb.signals.BBSignal;

	use namespace bb_private;

	/**
	 * Modules response for handling graph nodes.
	 * system module
	 */
	final public class BBTreeModule extends BBModule
	{
		private var _superDummyNode:BBNode = null;
		private var _rootNode:BBNode = null;
		private var _context:BBContext = null;
		private var _config:BBConfig = null;

		private var _mouseModule:BBMouseModule = null;
		private var _camerasModule:BBCamerasModule;

		/**
		 */
		public function BBTreeModule()
		{
			super();

			onInit.add(onInitHandler);
			onReadyToUse.add(readyToUseHandler);

			_superDummyNode = BBNode.get("superNode");
			_rootNode = BBNode.get("root");
			_superDummyNode.addChild(_rootNode);
			_rootNode._tree = this;
			_rootNode.markAsRoot();
			_rootNode.mouseChildren = true;
			_rootNode.group = -1;   // will displays for all possible values of camera masks
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_context = (engine as BabyBox).context;
			_config = (engine as BabyBox).config;

			_camerasModule = getModule(BBCamerasModule) as BBCamerasModule;
			_mouseModule = getModule(BBMouseModule) as BBMouseModule;
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			// init mouse handling
			if (_mouseModule) mouseSettings = _config.mouseNodeSettings;

			// start update
			updateEnable = true;
		}

		/**
		 * Config of dispatching mouse events. Configuration is done via BBMouseActions.
		 * E.g. if we want to enable dispatching click and move events - should to do:
		 * <code>
		 *     mouseSettings = BBMouseActions.CLICK | BBMouseActions.MOVE;
		 * </code>
		 */
		public function set mouseSettings(p_flags:uint):void
		{
			if ((p_flags & BBMouseEvent.CLICK) != 0)
			{
				_mouseModule.onUp.add(mouseHandler);
				_mouseModule.onDown.add(mouseHandler);
			}
			else
			{
				_mouseModule.onUp.remove(mouseHandler);
				_mouseModule.onDown.remove(mouseHandler);

				if ((p_flags & BBMouseEvent.UP) != 0) _mouseModule.onUp.add(mouseHandler);
				else _mouseModule.onUp.remove(mouseHandler);

				if ((p_flags & BBMouseEvent.DOWN) != 0) _mouseModule.onDown.add(mouseHandler);
				else _mouseModule.onDown.remove(mouseHandler);
			}

			if ((p_flags & BBMouseEvent.MOVE | p_flags & BBMouseEvent.OVER | p_flags & BBMouseEvent.OUT) != 0) _mouseModule.onMove.add(mouseHandler);
			else _mouseModule.onMove.remove(mouseHandler);
		}

		/**
		 */
		static private function mouseHandler(p_signal:BBSignal):void
		{
			var mouseEvent:BBMouseEvent = p_signal.params as BBMouseEvent;

			var camera:BBCamera = mouseEvent.capturedCamera;
			if (camera && mouseEvent.propagation)
			{
				camera.isCaptured = false;
				camera.captureMouseEvent(false, mouseEvent);
			}
		}

		/**
		 * Returns root node of render graph.
		 * So, you can to add your nodes to the tree.
		 */
		public function get root():BBNode
		{
			return _rootNode;
		}

		/**
		 * Update render graph.
		 */
		override public function update(p_deltaTime:int):void
		{
			// makes update render graph
			_rootNode.update(p_deltaTime, false, false);

			// makes render of graph
			_context.beginRender();

			var numCameras:int = _camerasModule.numCameras;
			var camerasList:Vector.<BBCamera> = _camerasModule.cameras;
			for (var i:int = 0; i < numCameras; i++)
			{
				camerasList[i].render(_context);
			}

			_context.endRender();
		}

		/**
		 * Disposes module.
		 */
		override public function dispose():void
		{
			// TODO: Add implementation of disposing this BBTreeModule
			super.dispose();
		}
	}
}
