package hscript;

@:autoBuild(hscript.macro.ScriptClassMacro.buildScriptable())
interface IScriptableClass
{
	private var _interp:Interp;

	public static function createInstance(path:String, args:Array<Dynamic>):IScriptableClass;
}