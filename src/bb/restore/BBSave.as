package bb.restore
{
	import flash.net.SharedObject;

	/**
	 * Represents manager for saving game.
	 *
	 * @author VirtualMaestro
	 */
	public class BBSave
	{
		static private var _lso:SharedObject = null;
		static private var _privateData:Object = {};
		static private var _saveName:String = "default";

		/**
		 * Restores data from save.
		 */
		static public function restore(saveName:String):Object
		{
			_lso = getLSO(saveName);
			return _lso.data;
		}

		/**
		 * Save game.
		 * saveObj - object packed data for storing
		 * saveName - name of save.
		 * privateData - private data stores temporary which lives during life-time of app and can't be restore.
		 */
		static public function save(saveObj:Object, saveName:String, saveSize:int = 0, privateData:Object = null):void
		{
			_lso = getLSO(saveName);

			// Fill data for storing
			for (var key:String in saveObj)
			{
				_lso.data[key] = saveObj[key];
			}

			// If private data is try to save them
			if (privateData != null)
			{
				savePrivate(privateData, saveName);
			}

			// Try to write data
			try
			{
				if (saveSize > 0) _lso.flush(saveSize);
				else _lso.flush();
			}
			catch (error:Error)
			{
				trace("Error: SaveSystem.save: error during flush: " + error);
			}

			_lso = null;
		}

		/**
		 * Removes save by its name.
		 */
		static public function clear(saveName:String):void
		{
			_lso = SharedObject.getLocal(saveName, "/", false);
			_lso.clear();
		}

		/**
		 * Removes from saved object specific field by given field name.
		 */
		static public function removeLSOField(saveName:String, field:String):void
		{
			_lso = getLSO(saveName);

			if (_lso.data.hasOwnProperty(field))
			{
				delete _lso.data[field];
			}
		}

		/**
		 * Removes from private data specific field by given field name.
		 */
		static public function removePrivateField(saveName:String, field:String):void
		{
			if (_privateData.hasOwnProperty(saveName) && _privateData[saveName].hasOwnProperty(field))
			{
				delete _privateData[saveName][field];
			}
		}

		/**
		 * Returns object SharedObject by given name of saved game.
		 */
		static private function getLSO(saveName:String):SharedObject
		{
			_saveName = saveName != "" ? saveName : "default";
			return SharedObject.getLocal(_saveName, "/", false);
		}

		/**
		 * Stores private (temp) data.
		 * These data lives during app instance.
		 */
		static public function savePrivate(privateData:Object, saveName:String):void
		{
			_saveName = saveName != "" ? saveName : "default";

			if (!_privateData.hasOwnProperty(_saveName))
			{
				_privateData[_saveName] = {};
			}

			//
			for (var tempKey:String in privateData)
			{
				_privateData[_saveName][tempKey] = privateData[tempKey];
			}
		}

		/**
		 * Returns temporary private data.
		 */
		static public function getPrivateData(saveName:String):Object
		{
			if ((saveName == "") || (_privateData.hasOwnProperty(saveName) == false)) return null;

			return _privateData[_saveName];
		}
	}
}