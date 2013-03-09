//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// Written in the D programming language.
/**
*	Version: 1.1
*	License: Boost 1.0
*	Authors: Gushcha Anton (NCrashed)
*
*	This module provides multiply dispatch support, also called multimethods. With $(D dispatch) you 
*	can choose function overload during runtime with minimal cost.
*	
*	Example:
*	---------
*	module testmodule;
*
*	import util.dispatching;
*
*	// injecting dispatcher code here
*	mixin Dispatching!(testmodule);
*
*	interface Collidable {}
*	class Body : Collidable {}
*	class Ship : Body {}
*	class Asteroid : Body {}
*
*	string func(Ship a, Asteroid b)
*	{
*		return "Colliding ship and asteroid";
*	}
*
*	string func(Asteroid a, Ship b)
*	{
*		return "Colliding asteroid and ship";
*	}
*
*	string func(Body a, Body b)
*	{
*		return "Colliding two bodies";
*	}
*
*	string foo(Asteroid a, Asteroid b, Asteroid c)
*	{
*		return "Colliding 3x asteroids";
*	}
*
*	string foo(Asteroid a, Asteroid b, Ship c)
*	{
*		return "Colliding 2xasteroids and ship";
*	}
*
*	string foo(Ship a, Ship b, Ship c)
*	{
*		return "Colliding 3xships";
*	}
*
*	int main(string[] args)
*	{
*		Collidable a = new Ship();
*		Collidable b = new Asteroid();
*
*		assert(dispatch!"func"(b,a) == "Colliding asteroid and ship");
*		assert(dispatch!"foo"(a,a,a) == "Colliding 3xships");
*
*		return 0;
*	}
*	---------
*/
module util.dispatching;

/// Dispatching
/**
*	Template injects code to dispatch functions. $(B Node) is a module where dispatching functions located.
*	
*	Example:
*	--------
*	mixin Dispatching!MyModule;
*	--------
*/
mixin template Dispatching(alias Node)
{
	import std.traits;
	import std.typetuple;
	import std.conv;

	/// ConstructCall
	/**
	*	Function helper to construct string like: 'return funcname(cast(typesMassName[0])argsMassName[0], ... );'
	*/
	template ConstructCall(string funcname, string typesMassName, string argsMassName, parsTypeTuple...)
	{
		template constructArgs(size_t i, pars...)
		{
			static if(pars.length == 0)
				enum constructArgs = "";
			else 
				static if(pars.length == 1)
					enum constructArgs = "cast("~typesMassName~"["~to!string(i)~"])"~argsMassName~"["~to!string(i)~"]";
				else
					enum constructArgs = "cast("~typesMassName~"["~to!string(i)~"])"~argsMassName~"["~to!string(i)~"], "~constructArgs!(i+1,pars[1..$]);
		}
		enum ConstructCall = "return "~funcname~"("~constructArgs!(0,parsTypeTuple)~");";
	}

	/// dispatch
	/**
	*	Detects at compile-time function $(D func2Disp) overloads at module or class ($D Node) and dispatch call at runtime based on dynamic arguments types. 
	*	All overloads must have same return type and arguments count. Function is lazy and takes first overload, thats why most derived overloads should be
	*	declared higher then generic ones. 
	*
	*	Example:
	*	-----
	*	dispatch!"func"(a,b);
	*	-----
	*/
	ReturnType!(mixin(func2Disp)) dispatch(string func2Disp, BaseClass)(BaseClass[] args...)
	{
		alias typeof(__traits(getOverloads, Node, func2Disp)) overloads;
		alias ReturnType!(mixin(func2Disp)) returntype;

		foreach (t; overloads) 
		{
			alias ParameterTypeTuple!t overloadPars;

			bool castRes = true;

			static assert(is(ReturnType!t == returntype), "Dispatching functions must return same type!");
			assert(overloadPars.length == args.length, "Overload "~t.stringof~" arguments count and dispatch args count doesn't match!");

			foreach(i,arg; overloadPars)
			{
				static assert(is(arg : BaseClass), "Argument "~arg.stringof~" must inherits from "~BaseClass.stringof);
				castRes = castRes && cast(arg)args[i] !is null;
			}
			
			if(castRes)
			{
				mixin(ConstructCall!(func2Disp, "overloadPars", "args", overloadPars));
			}
		}
		throw new Exception("Cannot find overload function '"~func2Disp~"' to dispatch! Release all cases or add dummy generic function.");
	}
}

version(unittest)
{
	interface Collidable {}
	class Body : Collidable {}
	class Ship : Body {}
	class Asteroid : Body {}

	string func(Ship a, Asteroid b)
	{
		return "Colliding ship and asteroid";
	}

	string func(Asteroid a, Ship b)
	{
		return "Colliding asteroid and ship";
	}

	string func(Body a, Body b)
	{
		return "Colliding two bodies";
	}

	string foo(Asteroid a, Asteroid b, Asteroid c)
	{
		return "Colliding 3x asteroids";
	}

	string foo(Asteroid a, Asteroid b, Ship c)
	{
		return "Colliding 2xasteroids and ship";
	}

	string foo(Ship a, Ship b, Ship c)
	{
		return "Colliding 3xships";
	}

	mixin Dispatching!(util.dispatching);
}
unittest
{
	Collidable a = new Ship();
	Collidable b = new Asteroid();

	assert(dispatch!"func"(b,a) == "Colliding asteroid and ship");
	assert(dispatch!"foo"(a,a,a) == "Colliding 3xships");
}