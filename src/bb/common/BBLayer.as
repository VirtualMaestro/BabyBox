/**
 * User: VirtualMaestro
 * Date: 27.03.13
 * Time: 21:10
 */
package bb.common
{
	import bb.bb_spaces.bb_private;
	import bb.components.BBCamera;
	import bb.core.BBNode;
	import bb.tools.BBGroupMask;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	use namespace bb_private;

	/**
	 * Layer for layer manager.
	 * Layer could contains actors.
	 */
	public class BBLayer
	{
		public var keepGroup:Boolean = false;

		//
		private var _name:String;
		private var _node:BBNode;
		private var _camera:BBCamera;

		private var _children:Vector.<BBLayer>;

		bb_private var parent:BBLayer = null;

		/**
		 */
		public function BBLayer(p_uniqueName:String, p_setOwnGroup:Boolean = false)
		{
			_name = p_uniqueName;
			_node = BBNode.get(_name);

			if (p_setOwnGroup)
			{
				CONFIG::debug
				{
					Assert.isTrue(BBGroupMask.hasGroup(), "no free groups. You can reset groups and start from the beginning (all possible groups 32)", "Constructor BBLayer");
				}

				_node.group = BBGroupMask.getGroup();
			}
		}

		/**
		 * Adds actor (node) to layer.
		 */
		public function add(p_actor:BBNode):void
		{
			var layer:BBLayer = p_actor.getProperty("bb_layer");
			if (layer) p_actor.removeFromParent();

			_node.addChild(p_actor);
			p_actor.addProperty("bb_layer", this);

			if (!p_actor.keepGroup) p_actor.group = _node.group;
		}

		/**
		 * Clear layer from any actors.
		 */
		public function clear():void
		{
			_node.disposeChildren();
		}

		/**
		 * Returns layer's name.
		 */
		public function get name():String
		{
			return _name;
		}

		/**
		 */
		bb_private function get node():BBNode
		{
			return _node;
		}

		/**
		 * Attach camera to layer in order to render objects which belongs to this layer.
		 * p_displayGroups - array with groups which should be displayed by this camera.
		 * If p_displayGroups is 'null' (by default) camera displays only one current layer group.
		 * If need remove camera just set null.
		 *
		 * Method returns camera which was attached before new camera.
		 * If wasn't camera before new attachment, method returns null.
		 * If new camera is null (you want detach camera from current layer) method returns detached camera.
		 */
		public function attachCamera(p_camera:BBCamera, p_displayGroups:Array = null):BBCamera
		{
			var prevCamera:BBCamera = _camera;

			if (_camera != p_camera)
			{
				if (_camera != null) _camera.mask = BBGroupMask.getMask([_camera.mask]);

				if (p_camera != null)
				{
					if (!p_camera.node.parent) _node.addChild(p_camera.node);

					if (p_displayGroups) p_camera.mask = BBGroupMask.getMask(p_displayGroups);
					else p_camera.mask = BBGroupMask.getMask([group]);
				}

				_camera = p_camera;
			}

			return prevCamera;
		}

		/**
		 * Returns attached camera (if some camera was attached at all).
		 */
		public function get camera():BBCamera
		{
			return _camera;
		}

		/**
		 * Sets group for all nested objects.
		 */
		public function set group(p_group:int):void
		{
			if (_node.group == p_group) return;
			_node.group = p_group;
			_node.updateChildrenGroups();

			if (_children)
			{
				var len:int = _children.length;
				for (var i:int = 0; i < len; i++)
				{
					_children[i].group = p_group;
				}
			}
		}

		/**
		 */
		public function get group():int
		{
			return _node.group;
		}

		/**
		 */
		public function set visible(p_val:Boolean):void
		{
			if (_node.visible == p_val) return;
			_node.visible = p_val;
		}

		/**
		 */
		public function get visible():Boolean
		{
			return _node.visible;
		}

		/**
		 * @private
		 */
		bb_private function addChild(p_layer:BBLayer):void
		{
			if (!_children) _children = new <BBLayer>[];
			if (_children.indexOf(p_layer) != -1) return;
			if (p_layer.parent) p_layer.parent.removeChild(p_layer);

			_children.push(p_layer);
			_node.addChild(p_layer.node);
			p_layer.parent = this;
		}

		/**
		 * @private
		 */
		bb_private function removeChild(p_layer:BBLayer):void
		{
			if (_children)
			{
				var index:int = _children.indexOf(p_layer);
				if (index != -1)
				{
					_children.splice(index, 1);
					_node.removeChild(p_layer.node);
				}

				p_layer.parent = null;
			}
		}

		/**
		 */
		public function dispose():void
		{
			_node.dispose();
			_node = null;
			_name = null;
		}
	}
}
