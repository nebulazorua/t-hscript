package hscript.macro;

#if macro
import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

class ScriptClassMacro
{
	public static function buildScriptable():Array<Field>
	{
		var cls:ClassType = Context.getLocalClass().get();
		var superCls = cls.superClass.t.get();

		var fields:Array<Field> = Context.getBuildFields();
		var pos:Position = Context.currentPos();

		var superClasPack:String = superCls.pack.join('.') != '' ? superCls.pack.join('.') + '.' + superCls.name : superCls.name;

		fields.push({
			name: "_interp",
			kind: FVar(macro:hscript.Interp),
			pos: pos
		});
		fields.push({
			name: "createInstance",
			kind: FFun({
				args: [{name: "clsName", type: Context.toComplexType(Context.getType('String'))}, {name: "args", type: Context.toComplexType(Context.getType('Array'))}],
				params: null,
				ret: Context.toComplexType(Context.getType(superClasPack)),
				expr: macro
				{
					for (clsRef in hscript.ScriptClassManager.scriptClasses)
					{
						if (clsRef.superClass == $v{superClsTypeName})
						{
							return clsRef.createInstance(args);
						}
					}
					return null;
				},
			}),
			pos: pos
		});

		return fields;
	}
}
#end