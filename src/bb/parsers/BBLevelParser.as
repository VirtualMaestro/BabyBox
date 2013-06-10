/**
 * User: VirtualMaestro
 * Date: 10.06.13
 * Time: 13:51
 */
package bb.parsers
{
	import flash.display.MovieClip;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;

	/**
	 */
	public class BBLevelParser
	{
		public function BBLevelParser()
		{
		}

		/**
		 */
		static public function parseLevelSWF(p_levelSWF:MovieClip):void
		{
			var levelAlias:String = getQualifiedClassName(p_levelSWF);
			var numChildren:int = p_levelSWF.numChildren;

			var child:MovieClip;
			var childSuperClassName:String = "";

			for (var i:int = 0; i < numChildren; i++)
			{
				child = p_levelSWF.getChildAt(i) as MovieClip;
				childSuperClassName = getQualifiedSuperclassName(child);

				switch (childSuperClassName)
				{
					case "worlds::WorldScheme":
					{
//						parseWorld(child);
						trace("WorldScheme");
						break;
					}

					case "actors::ActorScheme":
					{
						trace("ActorScheme");

//						var actorScheme:BBActorScheme = parseActor(child);
//						if (child.isDynamicCreation == false) _levelScheme.addActor(actorScheme);

						break;
					}
				}
			}

		}
	}
}
