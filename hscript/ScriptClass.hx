package hscript;

import hscript.Expr.FieldDecl;
import hscript.Expr.FunctionDecl;
import hscript.Expr.VarDecl;
import hscript.Expr.ClassDecl;
import hscript.Printer;

enum Param
{
	Unused;
}

class ScriptClass
{
	// class => [key => data]
	// public static var staticVariables:Map<String, Map<String, Dynamic>> = new Map<String, Map<String, Dynamic>>();

	private var _c:ClassDecl;
	private var _interp:Interp;

	public var superClass:Dynamic = null;

	public function new(c:ClassDecl, args:Array<Dynamic>)
	{
		_c = c;
		_interp = new Interp(this);
		if (_c.imports != null)
		{
			for (cls => path in _c.imports)
			{
				var fullPath = path.join(".");
				var c = Type.resolveClass(fullPath);
				if (cls != null)
					_interp.imports.set(cls, c);
			}
		}

		buildCaches();

		var ctorField = findField("new");
		if (ctorField != null)
		{
			callFunction("new", args);
			if (superClass == null && _c.extend != null)
			{
				@:privateAccess _interp.error(ENoSuperCall);
			}
		}
		else if (_c.extend != null)
		{
			createSuperClass(args);
		}
	}

	public var className(get, null):String;

	private function get_className():String
	{
		var name = "";
		if (_c.pkg != null)
		{
			name += _c.pkg.join(".") + ".";
		}
		name += _c.name;
		return name;
	}

	private function superConstructor(arg0:Dynamic = Unused, arg1:Dynamic = Unused, arg2:Dynamic = Unused, arg3:Dynamic = Unused)
	{
		var args = [];
		if (arg0 != Unused)
			args.push(arg0);
		if (arg1 != Unused)
			args.push(arg1);
		if (arg2 != Unused)
			args.push(arg2);
		if (arg3 != Unused)
			args.push(arg3);
		createSuperClass(args);
	}

	private function createSuperClass(args:Array<Dynamic> = null)
	{
		if (args == null)
		{
			args = [];
		}

		var extendString = new Printer().typeToString(_c.extend);
		if (_c.pkg != null && extendString.indexOf(".") == -1)
		{
			extendString = _c.pkg.join(".") + "." + extendString;
		}
		var classDescriptor = Interp.findScriptClassDescriptor(extendString);
		if (classDescriptor != null)
		{
			var abstractSuperClass:ScriptClass = new ScriptClass(classDescriptor, args);
			superClass = abstractSuperClass;
		}
		else
		{
			var c = Type.resolveClass(extendString);
			if (c == null)
			{
				@:privateAccess _interp.error(EUnknownClass(extendString));
			}
			superClass = Type.createInstance(c, args);
		}
	}

	private inline function callFunction0(name:String)
	{
		return callFunction(name);
	}

	private inline function callFunction1(name:String, arg0:Dynamic)
	{
		return callFunction(name, [arg0]);
	}

	private inline function callFunction2(name:String, arg0:Dynamic, arg1:Dynamic)
	{
		return callFunction(name, [arg0, arg1]);
	}

	private inline function callFunction3(name:String, arg0:Dynamic, arg1:Dynamic, arg2:Dynamic)
	{
		return callFunction(name, [arg0, arg1, arg2]);
	}

	private inline function callFunction4(name:String, arg0:Dynamic, arg1:Dynamic, arg2:Dynamic, arg3:Dynamic)
	{
		return callFunction(name, [arg0, arg1, arg2, arg3]);
	}

	public function callFunction(name:String, args:Array<Dynamic> = null)
	{
		var field = findField(name);
		var r:Dynamic = null;

		if (field != null)
		{
			var fn = findFunction(name);
			var previousValues:Map<String, Dynamic> = [];
			var i = 0;
			for (a in fn.args)
			{
				var value:Dynamic = null;

				if (args != null && i < args.length)
				{
					value = args[i];
				}
				else if (a.value != null)
				{
					value = _interp.expr(a.value);
				}

				if (_interp.variables.exists(a.name))
				{
					previousValues.set(a.name, _interp.variables.get(a.name));
				}
				_interp.variables.set(a.name, value);
				i++;
			}

			r = _interp.execute(fn.expr);

			for (a in fn.args)
			{
				if (previousValues.exists(a.name))
				{
					_interp.variables.set(a.name, previousValues.get(a.name));
				}
				else
				{
					_interp.variables.remove(a.name);
				}
			}
		}
		else
		{
			var fixedArgs = [];
			for (a in args)
			{
				if ((a is ScriptClass))
				{
					fixedArgs.push(cast(a, ScriptClass).superClass);
				}
				else
				{
					fixedArgs.push(a);
				}
			}
			r = Reflect.callMethod(superClass, Reflect.field(superClass, name), fixedArgs);
		}
		return r;
	}

	private function findFunction(name:String):FunctionDecl
	{
		if (_cachedFunctionDecls != null)
		{
			return _cachedFunctionDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				switch (f.kind)
				{
					case KFunction(fn):
						return fn;
					case _:
				}
			}
		}

		return null;
	}

	private function findVar(name:String):VarDecl
	{
		if (_cachedVarDecls != null)
		{
			_cachedVarDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				switch (f.kind)
				{
					case KVar(v):
						return v;
					case _:
				}
			}
		}

		return null;
	}

	private function findField(name:String):FieldDecl
	{
		if (_cachedFieldDecls != null)
		{
			return _cachedFieldDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				return f;
			}
		}
		return null;
	}

	public function listFunctions():Map<String, FunctionDecl>
	{
		return _cachedFunctionDecls;
	}

	private var _cachedFieldDecls:Map<String, FieldDecl> = null;
	private var _cachedFunctionDecls:Map<String, FunctionDecl> = null;
	private var _cachedVarDecls:Map<String, VarDecl> = null;

	private function buildCaches()
	{
		_cachedFieldDecls = [];
		_cachedFunctionDecls = [];
		_cachedVarDecls = [];

		for (f in _c.fields)
		{
			_cachedFieldDecls.set(f.name, f);
			switch (f.kind)
			{
				case KFunction(fn):
					_cachedFunctionDecls.set(f.name, fn);
				case KVar(v):
					_cachedVarDecls.set(f.name, v);
					if (v.expr != null)
					{
						var varValue = this._interp.expr(v.expr);
						this._interp.variables.set(f.name, varValue);
					}
			}
		}
	}

	private function resolveField(name:String):Dynamic
	{
		switch (name)
		{
			case "superClass":
				return this.superClass;
			case "createSuperClass":
				return this.createSuperClass;
			case "findFunction":
				return this.findFunction;
			case "callFunction":
				return this.callFunction;
			case _:
				if (this.findFunction(name) != null)
				{
					var fn = this.findFunction(name);
					var nargs = 0;
					if (fn.args != null)
					{
						nargs = fn.args.length;
					}
					switch (nargs)
					{
						case 0: return this.callFunction0.bind(name);
						case 1: return this.callFunction1.bind(name, _);
						case 2: return this.callFunction2.bind(name, _, _);
						case 3: return this.callFunction3.bind(name, _, _, _);
						case 4: return this.callFunction4.bind(name, _, _, _, _);
						case _: @:privateAccess this._interp.error(EParamLimit);
					}
				}
				else if (this.findVar(name) != null)
				{
					var v = this.findVar(name);

					var varValue:Dynamic = null;
					if (this._interp.variables.exists(name) == false)
					{
						if (v.expr != null)
						{
							varValue = this._interp.expr(v.expr);
							this._interp.variables.set(name, varValue);
						}
					}
					else
					{
						varValue = this._interp.variables.get(name);
					}
					return varValue;
				}
				else if (Reflect.isFunction(Reflect.getProperty(this.superClass, name)))
				{
					return Reflect.getProperty(this.superClass, name);
				}
				else if (Reflect.hasField(this.superClass, name))
				{
					return Reflect.field(this.superClass, name);
				}
				else if (this.superClass != null && (this.superClass is ScriptClass))
				{
					var superScriptClass:ScriptClass = cast(this.superClass, ScriptClass);
					try
					{
						return superScriptClass.resolveField(name);
					}
					catch (e:Dynamic)
					{
					}
				}
		}

		if (this.superClass == null)
		{
			throw "field '" + name + "' does not exist in script class '" + this.className + "'";
		}
		else
		{
			throw "field '" + name + "' does not exist in script class '" + this.className + "' or super class '"
				+ Type.getClassName(Type.getClass(this.superClass)) + "'";
		}
	}

	public function fieldWrite(name:String, value:Dynamic)
	{
		switch (name)
		{
			case _:
				if (this.findVar(name) != null)
				{
					this._interp.variables.set(name, value);
					return value;
				}
				else if (Reflect.hasField(this.superClass, name))
				{
					Reflect.setProperty(this.superClass, name, value);
					return value;
				}
				else if (this.superClass != null && (this.superClass is ScriptClass))
				{
					var superScriptClass:ScriptClass = cast(this.superClass, ScriptClass);
					try
					{
						return superScriptClass.fieldWrite(name, value);
					}
					catch (e:Dynamic)
					{
					}
				}
		}

		if (this.superClass == null)
		{
			throw "field '" + name + "' does not exist in script class '" + this.className + "'";
		}
		else
		{
			throw "field '" + name + "' does not exist in script class '" + this.className + "' or super class '"
				+ Type.getClassName(Type.getClass(this.superClass)) + "'";
		}
	}
}
