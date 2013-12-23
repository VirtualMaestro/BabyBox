/**
 * User: VirtualMaestro
 * Date: 27.03.13
 * Time: 20:59
 */
package bb.layer
{
	import bb.bb_spaces.bb_private;
	import bb.core.BBNode;
	import bb.modules.*;
	import bb.signals.BBSignal;
	import bb.tree.BBTreeModule;

	import flash.utils.Dictionary;

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
		private var _layersTable:Dictionary;
		private var _graph:BBTreeModule;
		private var _root:BBNode;

		/**
		 */
		public function BBLayerModule()
		{
			super();
			onInit.add(onInitHandler);
		}

		/**
		 */
		private function onInitHandler(p_signal:BBSignal):void
		{
			_layersTable = new Dictionary();
			_graph = getModule(BBTreeModule) as BBTreeModule;
			_root = _graph.root;
		}

		/**
		 * Adds layer to manager.
		 * Layer name should be unique
		 *
		 * @return - instance of BBLayer - adding p_layer
		 */
		public function add(p_layer:String):BBLayer
		{
			CONFIG::debug
			{
				Assert.isTrue(!isExist(p_layer), "Layer with such name '" + p_layer + "' already exist. Layer name should be unique", "BBLayerModule.add");
			}

			var addingLayer:BBLayer = new BBLayer(p_layer, true);
			_root.addChild(addingLayer.node);
			_layersTable[p_layer] = addingLayer;

			return addingLayer;
		}

		/**
		 * Adds layer to another layer as child.
		 * p_layer - layer which should be added to another.
		 * p_layer - layer could be already added to manager, in this case it will re-add to the p_addToLayer layer.
		 * p_layer - if layer isn't exist yet it is created and add to p_addToLayer.
		 * Layer name should be unique
		 * p_addToLayer - layer which should contains p_layer.
		 * p_addToLayer should be already created and added to manager, in other case generates error.
		 *
		 * @return - instance of adding p_layer (BBLayer)
		 */
		public function addTo(p_layer:String, p_addToLayer:String):BBLayer
		{
			CONFIG::debug
			{
				Assert.isTrue(isExist(p_addToLayer), "Layer  ('" + p_addToLayer + "') to which new layer is attached ('" + p_layer + "') is not exist. Layer ('" + p_addToLayer + "') have to already exist and added to layer module", "BBLayerModule.addTo");
			}

			var addingLayer:BBLayer;
			if (isExist(p_layer)) addingLayer = get(p_layer);
			else addingLayer = new BBLayer(p_layer);

			var parentLayer:BBLayer = get(p_addToLayer);
			parentLayer.addChild(addingLayer);

			if (!addingLayer.node.keepGroup) addingLayer.group = parentLayer.group;
			_layersTable[addingLayer.name] = addingLayer;

			return addingLayer;
		}

		/**
		 * If p_layer is specify clears all actors on that layer.
		 * If not clear all actors on all layers.
		 */
		public function clear(p_layer:String = null):void
		{
			if (p_layer && get(p_layer)) get(p_layer).clear();
			else
			{
				for each (var layer:BBLayer in _layersTable)
				{
					layer.clear();
				}
			}
		}

		/**
		 * Removes layer from manager and removes layer itself with all actors inside.
		 */
		public function remove(p_layerName:String):void
		{
			var layer:BBLayer = _layersTable[p_layerName];

			if (layer)
			{
				delete _layersTable[p_layerName];
				if (layer.parent) layer.parent.removeChild(layer);
				layer.dispose();
			}
		}

		/**
		 * Removes all layers with all actors inside.
		 */
		public function removeAll():void
		{
			for each(var layer:BBLayer in _layersTable)
			{
				layer.dispose();
			}

			_layersTable = new Dictionary();
		}

		/**
		 * Returns layer by given name.
		 * If such layer doesn't exist generates exception.
		 */
		public function get(p_layerName:String):BBLayer
		{
			CONFIG::debug
			{
				Assert.isTrue(isExist(p_layerName), "Layer with name '" + p_layerName + "' doesn't exist", "BBLayerModule.get");
			}

			return _layersTable[p_layerName];
		}

		/**
		 * Check if given name of layer exist.
		 */
		public function isExist(p_layerName:String):Boolean
		{
			return _layersTable[p_layerName] != null;
		}

		/**
		 */
		override public function dispose():void
		{
			removeAll();
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
