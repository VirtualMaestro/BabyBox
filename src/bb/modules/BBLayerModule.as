/**
 * User: VirtualMaestro
 * Date: 27.03.13
 * Time: 20:59
 */
package bb.modules
{
	import bb.bb_spaces.bb_private;
	import bb.common.BBLayer;
	import bb.core.BBNode;
	import bb.signals.BBSignal;
	import bb.tools.BBGroupMask;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Represents layer manager for manage layers - where actors are placed.
	 */
	public class BBLayerModule extends BBModule
	{
		private var _layersTable:Array;
		private var _graph:BBGraphModule;
		private var _root:BBNode;

		/**
		 */
		public function BBLayerModule()
		{
			super();
			onInit.add(onInitHandler);
			onReadyToUse.add(readyToUseHandler);
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_layersTable = [];
			_graph = getModule(BBGraphModule) as BBGraphModule;
			_root = _graph.root;
		}

		/**
		 */
		private function readyToUseHandler(p_signal:BBSignal):void
		{
			//
		}

		/**
		 * Adds layer to manager.
		 *
		 * @return - instance of BBLayer - adding p_layer
		 */
		public function add(p_layer:String, p_setOwnGroup:Boolean = false):BBLayer
		{
			var addingLayer:BBLayer = get(p_layer);
			CONFIG::debug
			{
				Assert.isTrue((addingLayer == null), "Layer with such name '" + p_layer + "' already exist. Layer name should be unique", "BBLayerModule.add");
			}

			addingLayer = new BBLayer(p_layer, p_setOwnGroup);
			_root.addChild(addingLayer.node);
			_layersTable[p_layer] = addingLayer;

			if (p_setOwnGroup) addingLayer.group = BBGroupMask.getGroup();

			return addingLayer;
		}

		/**
		 * Adds layer to another layer as child.
		 * p_layer - layer which should be added to another.
		 * p_layer - layer could be already added to manager, in this case it will re-add to the p_addToLayer layer.
		 * p_layer - if layer isn't exist yet it is created and add to p_addToLayer.
		 *
		 * p_addToLayer - layer which should contains p_layer.
		 * p_addToLayer should be already created and added to manager, in other case generates error.
		 *
		 * @return - instance of adding p_layer (BBLayer)
		 */
		public function addTo(p_layer:String, p_addToLayer:String):BBLayer
		{
			CONFIG::debug
			{
				Assert.isTrue((get(p_addToLayer) != null), "Layer  ('" + p_addToLayer + "') to which new layer is attached ('" + p_layer + "') is not exist. Layer ('" + p_addToLayer + "') have to already exist and added to layer module", "BBLayerModule.addTo");
			}

			var addingLayer:BBLayer = get(p_layer);
			if (!addingLayer) addingLayer = new BBLayer(p_layer);

			var parentLayer:BBLayer = get(p_addToLayer);
			parentLayer.addChild(addingLayer);

			if (!addingLayer.keepGroup) addingLayer.group = parentLayer.group;
			_layersTable[addingLayer.name] = addingLayer;

			return addingLayer;
		}

		/**
		 * Removes layer from manager and removes layer itself with all actors inside.
		 */
		public function remove(p_layerName:String):void
		{
			var layer:BBLayer = _layersTable[p_layerName];

			if (layer)
			{
				_layersTable[p_layerName] = null;
				if (layer.parent) layer.parent.removeChild(layer);
				layer.dispose();
			}
		}

		/**
		 * Removes all layers with all actors inside.
		 */
		public function clear():void
		{
			for each(var layer:BBLayer in _layersTable) layer.dispose();
			_layersTable = [];
		}

		/**
		 * Returns layer by given name.
		 * If such layer doesn't exist return null.
		 */
		public function get(p_layerName:String):BBLayer
		{
			return _layersTable[p_layerName];
		}

		/**
		 */
		override public function dispose():void
		{
			clear();
			_layersTable = null;
			_graph = null;
		}

		/**
		 */
		bb_private function get root():BBNode
		{
			return _root;
		}
	}
}
