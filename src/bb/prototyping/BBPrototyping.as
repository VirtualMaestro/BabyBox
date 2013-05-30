/**
 * User: VirtualMaestro
 * Date: 01.05.13
 * Time: 15:09
 */
package bb.prototyping
{
	import nape.phys.BodyType;
	import nape.phys.Material;

	import bb.components.physics.BBPhysicsBody;
	import bb.components.renderable.BBSprite;
	import bb.core.BBNode;
	import bb.textures.BBTexture;
	import bb.tools.physics.BBPhysicalMaterials;
	import bb.vo.BBColor;

	/**
	 * Class for rapid prototyping and tests.
	 */
	public class BBPrototyping
	{
		/**
		 * Creates and returns box with physical and graphical components.
		 */
		static public function getBox(p_width:Number = 100, p_height:Number = 100, p_name:String = "", p_color:uint = BBColor.SKY, p_type:BodyType = null, p_material:Material = null):BBNode
		{
			var box:BBNode = BBNode.get(p_name);
			var physics:BBPhysicsBody = BBPhysicsBody.get(p_type/* ? p_type : BodyType.DYNAMIC*/);
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addBox(p_width, p_height, "", null, material);
			box.addComponent(physics);

			var view:BBSprite = BBSprite.get(BBTexture.createFromColorRect(p_width, p_height, "", p_color));
			box.addComponent(view);

			return box;
		}

		/**
		 * Creates and returns circle with physical and graphical components.
		 */
		static public function getCircle(p_radius:Number = 50, p_name:String = "", p_color:uint = BBColor.GRASS, p_type:BodyType = null, p_material:Material = null):BBNode
		{
			var circle:BBNode = BBNode.get(p_name);
			var physics:BBPhysicsBody = BBPhysicsBody.get(p_type);
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addCircle(p_radius, "", null, material);
			circle.addComponent(physics);

			var view:BBSprite = BBSprite.get(BBTexture.createFromColorCircle(p_radius, "", p_color));
			circle.addComponent(view);

			return circle;
		}


	}
}
