/**
 * User: VirtualMaestro
 * Date: 01.05.13
 * Time: 15:09
 */
package bb.prototyping
{
	import bb.components.physics.BBPhysicsBody;
	import bb.components.physics.joints.BBJoint;
	import bb.components.renderable.BBSprite;
	import bb.core.BBNode;
	import bb.textures.BBTexture;
	import bb.tools.physics.BBPhysicalMaterials;
	import bb.vo.BBColor;

	import nape.geom.Vec2;
	import nape.phys.BodyType;
	import nape.phys.Material;

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
			var physics:BBPhysicsBody = BBPhysicsBody.get(p_type);
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addBox(p_width, p_height);
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

		/**
		 * Creates cart.
		 */
		static public function getCart(p_width:Number = 200, p_height:Number = 50, p_radius:Number = 25, p_wheelPosition:Vec2 = null):BBNode
		{
			var leftWheelX:Number = -70;
			var leftWheelY:Number = 20;
			var rightWheelX:Number = 70;
			var rightWheelY:Number = 20;

			if (p_wheelPosition)
			{
				leftWheelX = -p_wheelPosition.x;
				leftWheelY = p_wheelPosition.y;
				rightWheelX = p_wheelPosition.x;
				rightWheelY = p_wheelPosition.y;
			}

			var cart:BBNode = BBNode.get("cart");
			var physics:BBPhysicsBody = BBPhysicsBody.get(BodyType.DYNAMIC);
			physics.addBox(p_width, p_height);
			cart.addComponent(physics);

			var skin:BBSprite = BBSprite.get(BBTexture.createFromColorRect(p_width, p_height));
			cart.addComponent(skin);

			// left wheel
			var wheel:BBNode = BBNode.get("leftWheel");
			physics = BBPhysicsBody.get(BodyType.DYNAMIC);
			physics.addCircle(p_radius);
			wheel.addComponent(physics);

			skin = BBSprite.get(BBTexture.createFromColorCircle(p_radius));
			wheel.addComponent(skin);
			wheel.transform.setPosition(leftWheelX, leftWheelY);

			var pivotJoint:BBJoint = BBJoint.pivotJoint(wheel.name, Vec2.weak(leftWheelX, leftWheelY));
			(cart.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(pivotJoint);
			cart.addChild(wheel);

			// right wheel
			wheel = BBNode.get("rightWheel");
			physics = BBPhysicsBody.get(BodyType.DYNAMIC);
			physics.addCircle(p_radius);
			wheel.addComponent(physics);

			skin = BBSprite.get(BBTexture.createFromColorCircle(p_radius));
			wheel.addComponent(skin);
			wheel.transform.setPosition(rightWheelX, rightWheelY);

			pivotJoint = BBJoint.pivotJoint(wheel.name, Vec2.weak(rightWheelX, rightWheelY));
			(cart.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(pivotJoint);
			cart.addChild(wheel);

			return cart;
		}
	}
}
