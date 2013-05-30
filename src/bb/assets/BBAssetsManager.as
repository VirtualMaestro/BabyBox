/**
 * User: VirtualMaestro
 * Date: 22.04.13
 * Time: 14:08
 */
package bb.assets
{
	import bb.signals.BBSignal;

	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	import bb.components.renderable.BBMovieClip;
	import bb.components.renderable.BBRenderable;
	import bb.components.renderable.BBSprite;
	import bb.textures.BBTexture;
	import bb.textures.BBTextureAtlas;
	import bb.textures.BBTextureBase;

	import vm.classes.ClassUtil;
	import vm.str.StringUtil;

	CONFIG::debug
	{
		import vm.debug.Assert;
	}

	/**
	 * Response for creating and storing assets.
	 */
	public class BBAssetsManager
	{
		static public var INITIALIZATION_TIME_STEP:int = 200;

		static private var _onComplete:BBSignal;
		static private var _onProgress:BBSignal;
		static private var _assetIdList:Dictionary;
		static private var _initList:Vector.<BBAsset>;
		static private var _stage:Stage;

		static private var _totalAssetsForInit:int = 0;

		/**
		 */
		static public function set stage(p_stage:Stage):void
		{
			if (p_stage == null || _stage) return;
			_stage = p_stage;

			_assetIdList = new Dictionary();
			_initList = new <BBAsset>[];
		}

		/**
		 * Adds asset to manager.
		 * p_assetXML - could be either XML class or XML instance.
		 * @return - assetId. If p_assetId wasn't set it generates id for asset and returns it.
		 */
		static public function add(p_assetClass:Class, p_assetId:String = "", p_assetXML:* = null):String
		{
			var assetXML:XML;
			if (p_assetXML != null && p_assetXML is Class) assetXML = XML(new p_assetXML());
			else assetXML = p_assetXML;

			p_assetId = StringUtil.trim(p_assetId);
			if (p_assetId == "") p_assetId = BBTextureBase.getId();

			_initList.push(new BBAsset(p_assetClass, p_assetId, assetXML));

			return p_assetId;
		}

		/**
		 * Initialize assets.
		 * p_immediately - mean all assets starts initialize immediately, doesn't wait next step,
		 * so initialization won't divided for steps and progress functionality isn't available.
		 */
		static public function initAssets(p_immediately:Boolean = false):void
		{
			if (isNeedInit())
			{
				if (_stage && !p_immediately)
				{
					_stage.addEventListener(Event.ENTER_FRAME, performInitialization);
					_totalAssetsForInit = _initList.length;
				}
				else
				{
					var numAssets:int = _initList.length;
					for (var i:int = 0; i < numAssets; i++)
					{
						initAsset(_initList[i]);
						_initList[i] = null;
					}

					_initList.length = 0;
					if (_onComplete) _onComplete.dispatch();
				}
			}
		}

		/**
		 */
		static private function performInitialization(event:Event):void
		{
			var time:int = getTimer();
			for (var i:int = _initList.length - 1; i >= 0; i--)
			{
				initAsset(_initList[i]);
				_initList[i] = null;
				if ((getTimer() - time) > INITIALIZATION_TIME_STEP) break;
			}

			//
			if (i < 0) // end initialization
			{
				_stage.removeEventListener(Event.ENTER_FRAME, performInitialization);
				_initList.length = 0;
				_totalAssetsForInit = 0;
				if (_onComplete) _onComplete.dispatch();
			}
			else    // continue
			{
				_initList.length = i;
				if (_onProgress) _onProgress.dispatch((1 - _initList.length / _totalAssetsForInit));
			}
		}

		/**
		 */
		static private function initAsset(p_asset:BBAsset):String
		{
			var assetClass:Class = p_asset.assetClass;
			var assetId:String = p_asset.assetId;
			var assetXML:XML = p_asset.assetXML;
			var textureBase:BBTextureBase;

			CONFIG::debug
			{
				Assert.isTrue(_assetIdList[assetClass] == null, "Asset with such class '" + assetClass + "' already exist", "BBAssetManager.initAsset");
				Assert.isTrue(!isAssetExist(assetId), "Asset with id '" + assetId + "' already exist. Choose another unique id", "BBAssetManager.initAsset");
			}

			var asset:Object = new assetClass();

			if (asset is Bitmap) // texture or atlas (if p_assetXML is exist)
			{
				if (assetXML) textureBase = BBTextureAtlas.createFromBitmapDataAndXML((asset as Bitmap).bitmapData, assetXML, assetId);
				else textureBase = BBTexture.createFromBitmapData((asset as Bitmap).bitmapData, assetId);
			}
			else if (asset is MovieClip) textureBase = BBTextureAtlas.createFromMovieClip(asset as MovieClip, assetId);
			else textureBase = BBTexture.createFromVector(asset as DisplayObject, assetId);

			_assetIdList[assetClass] = textureBase.id;

			return assetId;
		}

		/**
		 * Determines if need init some assets (if need to invoke initAsset method)
		 */
		static public function isNeedInit():Boolean
		{
			return _initList.length > 0;
		}

		/**
		 * Returns asset by given class (e.g. BBSprite or BBMovieClip).
		 * If asset isn't initialized yet, it init and then back.
		 * E.g. if asset is MovieClip before return it makes rasterization, creates and stores atlas, then creates BBMovieClip with that atlas and returns.
		 * p_assetXML - could be either XML class or XML instance.
		 * @return - instance of BBRenderable (e.g. BBSprite or BBMovieClip)
		 */
		static public function get(p_assetClass:Class, p_assetId:String = "", p_assetXML:* = null):BBTextureBase
		{
			var assetId:String = _assetIdList[p_assetClass];
			if (assetId == null || assetId == "")
			{
				var assetXML:XML;
				if (p_assetXML != null && p_assetXML is Class) assetXML = XML(new p_assetXML());
				else assetXML = p_assetXML;

				assetId = initAsset(new BBAsset(p_assetClass, p_assetId, assetXML));
			}

			return getById(assetId);
		}

		/**
		 * Returns asset by its id.
		 * If such id doesn't exist returns null.
		 * @return - BBRenderable (e.g. BBSprite, BBMovieClip)
		 */
		static public function getById(p_assetId:String):BBTextureBase
		{
			var textureBase:BBTextureBase = BBTexture.getTextureById(p_assetId);
			if (textureBase == null) textureBase = BBTextureAtlas.getTextureAtlasById(p_assetId);
			return textureBase;
		}

		/**
		 * Check if asset exist by given id.
		 */
		static public function isAssetExist(p_assetId:String):Boolean
		{
			return !(BBTexture.getTextureById(p_assetId) == null && BBTextureAtlas.getTextureAtlasById(p_assetId) == null);
		}

		/**
		 * Returns renderable component (e.g. BBSprite, BBMovieClip) with asset corresponds to given class.
		 */
		static public function getRenderable(p_assetClass:Class):BBRenderable
		{
			var textureBase:BBTextureBase = get(p_assetClass);
			if (textureBase == null) return null;
			return (textureBase.isTexture) ? BBSprite.get(textureBase as BBTexture) : BBMovieClip.get(textureBase as BBTextureAtlas);
		}

		/**
		 * Returns renderable component (e.g. BBSprite, BBMovieClip) with asset corresponds to given id.
		 */
		static public function getRenderableByName(p_assetId:String):BBRenderable
		{
			var textureBase:BBTextureBase = getById(p_assetId);
			if (textureBase == null) return null;
			return (textureBase.isTexture) ? BBSprite.get(textureBase as BBTexture) : BBMovieClip.get(textureBase as BBTextureAtlas);
		}

		/**
		 * Removes asset (texture or atlas) by its class.
		 * Returns 'true' if removing was successful.
		 */
		static public function removeByClass(p_assetClass:Class):Boolean
		{
			var assetId:String = _assetIdList[p_assetClass];
			if (assetId == null || assetId == "") return false;

			var textureBase:BBTextureBase = getById(assetId);
			textureBase.dispose();
			delete _assetIdList[p_assetClass];

			return true;
		}

		/**
		 * Removes asset by given id.
		 * Returns 'true' if removing was successful.
		 */
		static public function removeById(p_assetId:String):Boolean
		{
			var textureBase:BBTextureBase = getById(p_assetId);
			if (textureBase)
			{
				textureBase.dispose();
				var classDef:Class = ClassUtil.getDefinitionForInstance(textureBase);
				delete _assetIdList[classDef];

				return true;
			}

			return false;
		}

		/**
		 * Clear all assets.
		 */
		static public function clear():void
		{
			for(var classDef:Object in _assetIdList)
			{
				removeByClass(classDef as Class);
			}

			_assetIdList = new Dictionary();
		}

		/**
		 * Signal dispatches when all assets are initialized.
		 */
		static public function get onComplete():BBSignal
		{
			if (!_onComplete) _onComplete = BBSignal.get();
			return _onComplete;
		}

		/**
		 * Signal dispatches for initialization assets progress.
		 * Provided values from 0 to 1 which represents progress (0-100%)
		 */
		static public function get onProgress():BBSignal
		{
			if (!_onProgress) _onProgress = BBSignal.get();
			return _onProgress;
		}
	}
}

internal class BBAsset
{
	public var assetClass:Class;
	public var assetXML:XML;
	public var assetId:String;

	/**
	 */
	public function BBAsset(p_assetClass:Class, p_assetId:String = "", p_assetXML:XML = null)
	{
		assetClass = p_assetClass;
		assetId = p_assetId;
		assetXML = p_assetXML;
	}
}