package bb.localization
{
	import bb.signals.BBSignal;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	/**
	 * Use for string localization.
	 * Using XML which should be in the next format:
	 *
	 * <localization>
	 *     <string id='play'><![CDATA[PLAY GAME]]></string>
	 *     <string id='moreGames'><![CDATA[MORE GAMES]]></string>
	 *     <string id='credits'><![CDATA[CREDITS]]></string>
	 * </localization>
	 */
	public class BBLocalization
	{
		static private var _localizationXML:XML = null;
		static private var _xmlLoader:URLLoader = null;
		static private var _onReadyToUse:BBSignal = null;

		/**
		 * Load localization file.
		 * If localization file should be downloaded before use. (Dot not use with method 'setLocalizationFile').
		 */
		static public function loadLocalizationFile(filePath:String):void
		{
			_xmlLoader = new URLLoader();
			_xmlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			_xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			_xmlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_xmlLoader.load(new URLRequest(filePath));
		}

		/**
		 */
		static private function xmlLoaded(evt:Event):void
		{
			_localizationXML = XML(evt.currentTarget.data);

			_xmlLoader.removeEventListener(Event.COMPLETE, xmlLoaded);
			_xmlLoader.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			_xmlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_xmlLoader = null;

			dispatchOnReadyToUse();
		}

		/**
		 */
		static private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("ERROR! Localization.ioErrorHandler: " + event.text);
		}

		/**
		 */
		static private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace("ERROR! Localization.securityErrorHandler: " + event.text);
		}

		/**
		 * Set localization file. (Dot not use with method 'loadLocalizationFile').
		 */
		static public function setLocalizationFile(localFile:XML):void
		{
			_localizationXML = localFile;
			dispatchOnReadyToUse();
		}

		/**
		 * Returns string bu its id.
		 */
		static public function getString(id:String):String
		{
			var str:String = "";
			if (_localizationXML && _localizationXML.string)
			{
				str = _localizationXML.string.(@id == id);
			}

			return str;
		}

		/**
		 * Dispatches when localization file was set and ready to use.
		 */
		static public function get onReadyToUse():BBSignal
		{
			if (_onReadyToUse == null) _onReadyToUse = BBSignal.get();
			return _onReadyToUse;
		}

		/**
		 */
		static private function dispatchOnReadyToUse():void
		{
			if (_onReadyToUse) _onReadyToUse.dispatch();
		}

		/**
		 * Clears all internal data.
		 * After invoking this method current class could be used.
		 */
		static public function dispose():void
		{
			if (_onReadyToUse) _onReadyToUse.dispose();
			_onReadyToUse = null;
			_localizationXML = null;
			if (_xmlLoader) _xmlLoader.close();
			_xmlLoader = null;
		}
	}
}
