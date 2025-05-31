package hscript;

class ScriptClassManager
{
	public static var scriptClasses:Map<String, ScriptClassRef> = new Map();

	public static function registerModule(content:String):ScriptClassRef
	{
		var parser = new Parser();
		parser.allowJSON = parser.allowTypes = parser.allowMetadata = true;

		var modules = parser.parseModule(content);

		var imports:Array<String> = [];
		var pack:Array<String> = [];
		for (decl in modules)
		{
			case DPackage(path):
                pack = path;
			case DImport(path, _):
                imports.push(path);
			case DClass(c):
				var extend = c.extend;
                if (extend != null)
					extend = Type.resolveClass(c.extend);
				
				scriptClasses.set(pack.join('.') != '' ? pack.join('.') + '.' : "" + c.name, {
					clsName: c.name,
					superClass: extend,
					imports: imports,
					staticFields: new Map()
				});

				/*
				for (field in c.fields)
				{
					switch(field)
					{
						case
					}
				}
				*/
		}



		return null;
	}
}

typedef ScriptClassRef = {
	var clsName:String,
	var superClass:Class<Dynamic>,
	var imports:Array<String>,
	var staticFields:Map<String, Dynamic>
}