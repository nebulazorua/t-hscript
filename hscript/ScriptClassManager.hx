package hscript;

class ScriptClassManager
{
	public static var scriptClasses:Map<String, ScriptClassRef> = new Map();

	public static function registerModule(path:String):ScriptClassRef
	{
		var parser = new Parser();
		parser.allowJSON = parser.allowTypes = parser.allowMetadata = true;

		var module = parser.parseModule(sys.io.File.getContent(path));
		// trace(module);
		scriptClasses.set("sys.io.File", null);
		return null;
	}
}