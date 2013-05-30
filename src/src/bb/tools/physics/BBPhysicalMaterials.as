/**
 * User: VirtualMaestro
 * Date: 24.03.13
 * Time: 21:50
 */
package src.bb.tools.physics
{
	import nape.phys.Material;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	/**
	 * Material which is set to shape of physics body.
	 */
	public class BBPhysicalMaterials
	{
		static private var _tableMaterial:Array = [];

		{
			_tableMaterial["glass"] = glass;
			_tableMaterial["ice"] = ice;
			_tableMaterial["rubber"] = rubber;
			_tableMaterial["sand"] = sand;
			_tableMaterial["steel"] = steel;
			_tableMaterial["wood"] = wood;
			_tableMaterial["plastic"] = plastic;
			_tableMaterial["granite"] = granite;
			_tableMaterial["iridium"] = iridium;
			_tableMaterial["paper"] = paper;
			_tableMaterial["meat"] = meat;
		}

		/**
		 * Returns Material by given name (e.g. "glass", "ice", "paper" and so on).
		 * (material name should be in lower case)
		 */
		static public function getByName(materialName:String):Material
		{
			CONFIG::debug
			{
				Assert.isTrue(_tableMaterial[materialName], "material with name '" + materialName +"' doesn't exist", "BBPhysicalMaterials.getByName");
			}

			return _tableMaterial[materialName]();
		}

		/**
		 */
		static public function get glass():Material
		{
			return Material.glass();
		}

		/**
		 */
		static public function get ice():Material
		{
			return Material.ice();
		}

		/**
		 */
		static public function get rubber():Material
		{
			return Material.rubber();
		}

		/**
		 */
		static public function get sand():Material
		{
			return Material.sand();
		}

		/**
		 */
		static public function get steel():Material
		{
			return Material.steel();
		}

		/**
		 */
		static public function get wood():Material
		{
			return Material.wood();
		}

		/**
		 */
		static public function get plastic():Material
		{
			return new Material(0.68, 0.31, 0.45, 1.2, 0.002);
		}

		/**
		 */
		static public function get granite():Material
		{
			return new Material(0.59, 0.52, 0.83, 2.7, 0.0021);
		}

		/**
		 */
		static public function get iridium():Material
		{
			return new Material(0.15, 0.5, 0.7, 22.56, 0.001);
		}

		/**
		 */
		static public function get paper():Material
		{
			return new Material(0.5, 0.41, 0.45, 0.5, 0.015);
		}

		/**
		 */
		static public function get meat():Material
		{
			return new Material(0.1, 0.7, 0.9, 1.0, 100);
		}
	}
}
