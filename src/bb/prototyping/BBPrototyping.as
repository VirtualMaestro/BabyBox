/**
 * User: VirtualMaestro
 * Date: 01.05.13
 * Time: 15:09
 */
package bb.prototyping
{
	import bb.core.BBNode;
	import bb.gameobjects.BBRotatorComponent;
	import bb.gameobjects.weapons.gun.BBGun;
	import bb.physics.components.BBPhysicsBody;
	import bb.physics.joints.BBJoint;
	import bb.physics.utils.BBPhysicalMaterials;
	import bb.render.components.BBSprite;
	import bb.render.textures.BBTexture;
	import bb.ui.BBButton;
	import bb.ui.BBLabel;
	import bb.vo.BBColor;

	import nape.dynamics.InteractionFilter;
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
		static public function getBox(p_width:Number = 100, p_height:Number = 100, p_name:String = "", p_color:uint = BBColor.SKY, p_type:BodyType = null,
		                              p_material:Material = null, p_filter:InteractionFilter = null):BBNode
		{
			var box:BBNode = BBNode.get(p_name);
			var physics:BBPhysicsBody = BBPhysicsBody.get((p_type == null ? BodyType.DYNAMIC : p_type));
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addBox(p_width, p_height, "", 0, null, material, p_filter);
			box.addComponent(physics);

			var view:BBSprite = BBSprite.get(BBTexture.createFromColorRect(p_width, p_height, "", p_color));
			box.addComponent(view);

			return box;
		}

		/**
		 * Creates and returns circle with physical and graphical components.
		 * If bodyType is null mean DYNAMIC.
		 */
		static public function getCircle(p_radius:Number = 50, p_name:String = "", p_color:uint = BBColor.GRASS, p_type:BodyType = null,
		                                 p_material:Material = null, p_filter:InteractionFilter = null):BBNode
		{
			var circle:BBNode = BBNode.get(p_name);
			var physics:BBPhysicsBody = BBPhysicsBody.get((p_type == null ? BodyType.DYNAMIC : p_type));
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addCircle(p_radius, "", null, material, p_filter);
			circle.addComponent(physics);

			var view:BBSprite = BBSprite.get(BBTexture.createFromColorCircle(p_radius, "", [p_color]));
			circle.addComponent(view);

			return circle;
		}

		/**
		 * Creates and returns circle with physical and graphical components.
		 */
		static public function getEllipse(p_radiusX:Number = 100, p_radiusY:Number = 50, p_name:String = "", p_color:uint = BBColor.GRASS,
		                                  p_type:BodyType = null, p_material:Material = null, p_filter:InteractionFilter = null):BBNode
		{
			var ellipse:BBNode = BBNode.get(p_name);
			var physics:BBPhysicsBody = BBPhysicsBody.get((p_type == null ? BodyType.DYNAMIC : p_type));
			var material:Material = p_material ? p_material : BBPhysicalMaterials.wood;
			physics.addEllipse(p_radiusX, p_radiusY, "", 0, null, material, p_filter);
			ellipse.addComponent(physics);

			var view:BBSprite = BBSprite.get(BBTexture.createFromColorEllipse(p_radiusX, p_radiusY, "", p_color));
			ellipse.addComponent(view);

			return ellipse;
		}

		/**
		 * Creates cart.
		 * Wheels have names - leftWheel and rightWheel accordingly, so you can get wheel by its name.
		 */
		static public function getCart(p_width:Number = 200, p_height:Number = 50, p_radius:Number = 25, p_wheelPosition:Vec2 = null,
		                               p_allowHand:Boolean = true):BBNode
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
			physics.allowHand = p_allowHand;
			cart.addComponent(physics);

			var skin:BBSprite = BBSprite.get(BBTexture.createFromColorRect(p_width, p_height));
			cart.addComponent(skin);

			// left wheel
			var wheel:BBNode = BBNode.get("leftWheel");
			physics = BBPhysicsBody.get(BodyType.DYNAMIC);
			physics.addCircle(p_radius);
			physics.allowHand = p_allowHand;
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
			physics.allowHand = p_allowHand;
			wheel.addComponent(physics);

			//
			skin = BBSprite.get(BBTexture.createFromColorCircle(p_radius));
			wheel.addComponent(skin);
			wheel.transform.setPosition(rightWheelX, rightWheelY);

			pivotJoint = BBJoint.pivotJoint(wheel.name, Vec2.weak(rightWheelX, rightWheelY));
			(cart.getComponent(BBPhysicsBody) as BBPhysicsBody).addJoint(pivotJoint);
			cart.addChild(wheel);

			return cart;
		}

		/**
		 * Returns weapon - gun.
		 */
		static public function getCannon(p_baseSize:int = 100, p_barrelLength:int = 100, p_angVel:Number = 500 * Math.PI / 180.0,
		                                 p_accurate:Number = 2 * Math.PI / 180.0, p_acceleration:Number = 360 * Math.PI / 180.0,
		                                 p_followMouse:Boolean = true):BBNode
		{
			var turretBase:BBNode = BBNode.get("turretBase");
			var turretBaseTextureName:String = "turretBase_s" + p_baseSize / 2 + "_c_" + BBColor.BLUE + "_co_" + BBColor.WHITE;
			turretBase.addComponent(BBSprite.get(BBTexture.createFromColorCircle(p_baseSize / 2, turretBaseTextureName, [BBColor.SKY], BBColor.WHITE, 2)));
			turretBase.addComponent(BBGun.get(p_barrelLength));

			var rotator:BBRotatorComponent = turretBase.addComponent(BBRotatorComponent) as BBRotatorComponent;
			rotator.angularVelocity = p_angVel;
			rotator.accurate = p_accurate;
			rotator.acceleration = p_acceleration;
			rotator.followMouse = p_followMouse;

			var turretHeadTextureName:String = "turretHead_s" + p_baseSize / 2 + "_c_" + BBColor.YELLOW;
			var turretHead:BBNode = BBSprite.getWithNode(BBTexture.createFromColorRect(p_baseSize / 2, p_baseSize / 2, turretHeadTextureName, BBColor.YELLOW),
			                                             "turretHead").node;
			turretBase.addChild(turretHead);

			var barrel:BBNode = BBNode.get("turretBarrel");
			var turretBarrelTextureName:String = "turretBarrel_s" + p_baseSize / 4 + "_c_" + BBColor.GRASS;
			var barrelSprite:BBSprite = BBSprite.get(BBTexture.createFromColorRect(p_barrelLength, p_baseSize / 8, turretBarrelTextureName, BBColor.GRASS));
			barrel.addComponent(barrelSprite);
			barrel.transform.setPosition(p_barrelLength / 2, 0);

			turretBase.addChild(barrel);

			var turretHood:BBNode = BBNode.get("turretHood");
			var turretHoodTextureName:String = "turretHood_s" + p_baseSize / 4 + "_c_" + BBColor.BLOOD + "_co_" + BBColor.BLACK;
			turretHood.addComponent(BBSprite.get(BBTexture.createFromColorCircle(p_baseSize / 6, turretHoodTextureName, [BBColor.BLOOD], BBColor.BLACK, 2)));
			turretBase.addChild(turretHood);

			var turretTip:BBNode = BBNode.get("turretTip");
			var turretTipTextureName:String = "turretTip_s" + p_baseSize / 4 + "_c_" + BBColor.SKY;
			turretTip.addComponent(BBSprite.get(BBTexture.createFromColorRect(p_barrelLength / 6, p_baseSize / 6, turretTipTextureName, BBColor.SKY)));
			turretTip.transform.setPosition(p_barrelLength - p_barrelLength / 12, 0);
			turretBase.addChild(turretTip);

			return turretBase;
		}

		/**
		 */
		static public function getButton(p_text:String):BBButton
		{
			var upState:BBTexture = BBTexture.createFromColorRect(100, 25, "");
			var downState:BBTexture = BBTexture.createFromColorRect(100, 25, "", 0xffff0000);
			var overState:BBTexture = BBTexture.createFromColorRect(100, 25, "", 0xffa3d5ba);
			var button:BBButton = BBButton.get(upState, downState, overState);
			var label:BBLabel = BBLabel.getWithNode(p_text);
			button.node.addChild(label.node);

			label.node.name = "label";
			button.node.name = "button";

			return button;
		}
	}
}
