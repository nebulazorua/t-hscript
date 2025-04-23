package hscript;

import sys.FileSystem;
import sys.io.File;

import hscript.Interp;

using StringTools;

@:generic
class ScriptedClass<Cls:Dynamic>
{
	private var _interp = new Interp();

	public function new()
	{
		for (file in FileSystem.readDirectory("test/notetypes"))
			if (file.endsWith(".hxc"))
				_interp.addModule(File.getContent("test/notetypes/" + file)/*, Type.resolveClass(Cls)*/);
	}

	public function instantiate(id:String, ?args:Array<Dynamic>):Dynamic
	{
		var instance = _interp.createScriptClassInstance(id, args);
		return instance;
	}
}