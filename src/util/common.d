//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// written in D programming language
/**
*	Module provides many usefull functions to work with C-style strings, degree and radian angles, text parsing and generic programming.
*
*	Authors: Gushcha Anton (NCrashed)
*
*	$(BOOKTABLE ,
*		$(TR 
*			$(TH Category) 
*			$(TH Functions) 
*		)
*		$(TR 
*			$(TDNW Strings) 
*			$(TD 
*				$(MYREF fromStringz) 
*			) 
*		)
*		$(TR 
*			$(TDNW Angles) 
*			$(TD 
*				$(MYREF Degree) 
*				$(MYREF Radian) 
*				$(MYREF trimAng) 
*				$(MYREF deg2rad) 
*				$(MYREF rad2deg) 
*			) 
*		)
*		$(TR
*			$(TDNW Parsing) 
*			$(TD 
*				$(MYREF removeAfter) 
*				$(MYREF commutateByKey) 
*				$(MYREF findPos) 
*				$(MYREF findPosEscaped) 
*				$(MYREF findLastPos) 
*				$(MYREF countUntilEscaped) 
*			) 
*		)
*		$(TR 
*			$(TDNW Generic) 
*			$(TD 
*				$(MYREF getMemberType) 
*				$(MYREF getMemberType) 
*				$(MYREF FieldNameTuple) 
*				$(MYREF SatisfyFieldTuple)
*				$(MYREF StaticFind)
*				$(MYREF AssociativeArrayKeyType)
*				$(MYREF AssociativeArrayValueType)
*				$(MYREF ArrayElementType)
*			) 
*		)
*	)
*
*	Macros:
* 	MYREF = <font face='Consolas, "Bitstream Vera Sans Mono", "Andale Mono", Monaco, "DejaVu Sans Mono", "Lucida Console", monospace'><a href="#$1">$1</a>&nbsp;</font>
*/
module util.common;

import std.math;
import std.traits;
import std.algorithm : countUntil;
import std.typetuple;

/// fromStringz
/**
*	Returns new string formed from C-style (null-terminated) string $(D msg). Usefull
*	when interfacing with C libraries. For D-style to C-style convertion use std.string.toStringz
*
*	Example:
*	----------
*	char[] cstring = "some string".dup ~ cast(char)0;
*
*	assert(fromStringz(cstring.ptr) == "some string");
*	----------
*/
string fromStringz(const char* msg) nothrow
{
	try
	{
		if(msg is null) return "";

		auto buff = new char[0];
		uint i = 0;
			while(msg[i]!=cast(char)0)
				buff ~= msg[i++];
		return buff.idup;
	} catch(Exception e)
	{
		return "";
	}
}

unittest
{
	char[] cstring = "some string".dup ~ cast(char)0;

	assert(fromStringz(cstring.ptr) == "some string");
}

/// Degree
/**
*	Degree is 1/360 part of full angle.
*/
alias double Degree;

/// Radian
/**
*	Radian is central angle of circle sector with arc length equal to the circle radius.
*/
alias double Radian;

/// trimAng
/**
*	Сuts radian angle in range (-2*PI..2*PI).
*
*	Example:
*	--------
*	assert(approxEqual(trimAng(PI/6), PI/6));
*	assert(approxEqual(trimAng(-PI/3), -PI/3));
*	assert(approxEqual(trimAng(4*PI), 0));
*	assert(approxEqual(trimAng(-6*PI), 0));
*	assert(approxEqual(trimAng(8*PI/3), 2*PI/3));
*	assert(approxEqual(trimAng(-13*PI/6), -PI/6));
*	--------
*/
Radian trimAng(Radian angle)
{
	while( angle > 2*PI || approxEqual(angle, 2*PI))
		angle -= 2*PI;
	while( angle < -2*PI  || approxEqual(angle, -2*PI)) 
		angle += 2*PI;
	return angle;
}

unittest
{
	assert(approxEqual(trimAng(PI/6), PI/6));
	assert(approxEqual(trimAng(-PI/3), -PI/3));
	assert(approxEqual(trimAng(4*PI), 0));
	assert(approxEqual(trimAng(-6*PI), 0));
	assert(approxEqual(trimAng(8*PI/3), 2*PI/3));
	assert(approxEqual(trimAng(-13*PI/6), -PI/6));
}

/// Degree -> Radian
/**
*	Converts $(D angle) measured in degrees to radian angle.
*
*	Example:
*	----------
*	assert(approxEqual(deg2rad(90.), cast(Radian)(PI/2)));
*	assert(approxEqual(deg2rad(60.), cast(Radian)(PI/3)));
*	assert(approxEqual(deg2rad(30.), cast(Radian)(PI/6)));
*	----------
*/
Radian deg2rad(Degree angle)
{
	return angle * (2*PI/360);
}

unittest
{
	assert(approxEqual(deg2rad(90.), cast(Radian)(PI/2)));
	assert(approxEqual(deg2rad(60.), cast(Radian)(PI/3)));
	assert(approxEqual(deg2rad(30.), cast(Radian)(PI/6)));
}

/// Radian -> Degree
/**
*	Converts $(D angle) measured in radians to degree angle.
*
*	Example:
*	---------
*	assert(approxEqual(rad2deg(PI/2), cast(Degree)90.));
*	assert(approxEqual(rad2deg(PI/3), cast(Degree)60.));
*	assert(approxEqual(rad2deg(PI/6), cast(Degree)30.));
*	---------
*/
Degree rad2deg(Radian angle)
{
	return angle * (360/(2*PI));
}

unittest
{
	assert(approxEqual(rad2deg(PI/2), cast(Degree)90.));
	assert(approxEqual(rad2deg(PI/3), cast(Degree)60.));
	assert(approxEqual(rad2deg(PI/6), cast(Degree)30.));
}

/// removeAfter
/**
*	Returns string $(D s) with removed symbols after first substring $(D key) including $(D key).
*
*	Example:
*	---------
*	assert(removeAfter("My string # comment", "#") == "My string ");
*	assert(removeAfter("My string// comment", "//") == "My string");
*	assert(removeAfter("My string// comment", "?") == "My string// comment");
*	assert(removeAfter("// comment", "//") == "");
*	---------
*/
string removeAfter(string s, string key)
{
	bool isEqual(string a, string b)
	{
		return a[0..b.length] == b;
	}

	for(uint i = 0; i<s.length; i++)
		if(isEqual(s[i..$], key))
			return s[0..i];
	return s;
}	

unittest
{
	import std.stdio;

	assert(removeAfter("My string # comment", "#") == "My string ", "Failed: "~removeAfter("My string # comment", "#"));
	assert(removeAfter("My string// comment", "//") == "My string", "Failed: "~removeAfter("My string// comment", "//"));
	assert(removeAfter("My string// comment", "?") == "My string// comment", "Failed: "~removeAfter("My string// comment", "?"));
	assert(removeAfter("// comment", "//") == "", "Failed: "~removeAfter("// comment", "//"));
}

/// commutateByKey
/**
*	Simplifies writing huge switches for text parsing. Function passed keys list $(D keys),
*	key $(D key), some string values $(D args) and lambdas list $(D ops) wich length must be 
*	equal $(D keys) one. If $(D key) is located in $(D keys), then corresponding lambda from 
*	$(D ops) is called with argument $(D args). Lambdas have to be $(D int function(string[]))
*	format. Returns one of lamda output, or -1 if no lamda wasn't called.
*	
*	Example:
*	----------
*	auto keys = ["a","b","c"];
*	auto key = "b";
*	auto pargs = ["arg1", "arg2"];
*
*	assert(
*		commutateByKey(key, keys, pargs,
*			(string[] args) //a
*			{
*				return 0;
*			},
*			(string[] args) //b
*			{
*				return 1;
*			},
*			(string[] args) //c
*			{
*				return 2;
*			}
*			) == 1
*		);
*	----------
*/
int commutateByKey(T...)(string key, string[] keys, string[] args, T ops)
in
{
	assert(keys.length == ops.length, "Keys count and operators count must be equal");
}
body
{
	import std.stdio;

    foreach( i, t1; T )
    {
        static assert( isFunctionPointer!t1 || isDelegate!t1, "Operator type must be delegate or function! "~t1.stringof~" doesn't suit!");
        alias ParameterTypeTuple!(t1) al;
        alias ReturnType!(t1) r1;

        static assert( al.length==1 && is(al[0] == string[]), "Operator "~t1.stringof~" must get only string[] argument type!");
        static assert( is(r1 == int), "Operator "~T.stringof~" must return int!");

        if( key == keys[i] )
        {
        	return ops[i](args);
        }
    }
    return -1;
}

unittest
{
	import std.stdio;

	assert( __traits( compiles,
							`commutateByKey("test", ["test","notest"], ["arg1","arg2"], (string[] args){return 0;}, (string[] args){return 1;})`
						), "Testing commutateByKey failed!");

	assert( commutateByKey("test", ["test","notest"], ["arg1","arg2"], (string[] args){return 0;}, (string[] args){return 1;}) == 0, "Testing commutateByKey failed!");

	auto keys = ["a","b","c"];
	auto key = "b";
	auto pargs = ["arg1", "arg2"];

	assert(
		commutateByKey(key, keys, pargs,
			(string[] args) //a
			{
				return 0;
			},
			(string[] args) //b
			{
				return 1;
			},
			(string[] args) //c
			{
				return 2;
			}
			) == 1
		);
}

// countUntilEscaped
/**
*	Same as countUntil, but don't track escaped strings with '\'.
*
*	Example:
*	----------
*	auto s = `word1 word2\[\] word3[]`;
*	assert(countUntilEscaped(s, " ") == 5);
*	assert(countUntilEscaped(s, "[") == 21);
*	assert(countUntilEscaped(s, "[]") == -1);
*	----------
*/
sizediff_t countUntilEscaped(string s, string what)
{
	import std.stdio;

	for(sizediff_t i = 0; i<s.length-what.length+1; i++)
	{
		if(s[i..i+what.length] == what)
			if(i == 0) 
				return 0;
			else
				if(s[i-1] == '\\')
					continue;
				else
					return i;
	}
	return -1;
}

unittest
{
	auto s = `word1 word2\[\]\ word3[]`;
	assert(countUntilEscaped(s, " ") == 5);
	assert(countUntilEscaped(s[6..$], " ") == -1);
	assert(countUntilEscaped(s, "[") == 22);
	assert(countUntilEscaped(s, "[]") == 22);
	assert(countUntilEscaped(`\word2\ word3`, " ") == -1);
}

/// findPos
/**
*	Search of substring $(D what) in string $(D s), begining at symbol
*	position $(D pos). It is port from STL. Returns substring begining 
*	position or -1 if not found.
*
*	Example:
*	----
*	auto s = "word1 word2 word3";
*	assert(findPos(s, 0, " ") == 5);
*	assert(findPos(s, 6, " ") == 11);
*	assert(findPos(s, 0, "word2") == 6);
*	assert(findPos(s, 7, "word") == 12);
*	----
*/
sizediff_t findPos(string s, size_t pos, string what)
{
	auto temp = countUntil(s[pos..$], what);
	if( temp == -1) return -1;
	return temp+pos;
}

unittest
{
	auto s = "word1 word2 word3";
	assert(findPos(s, 0, " ") == 5);
	assert(findPos(s, 6, " ") == 11);
	assert(findPos(s, 0, "word2") == 6);
	assert(findPos(s, 7, "word") == 12);
}

/// findPosEscaped
/**
*	Search of substring $(D what) in string $(D s), begining at symbol
*	position $(D pos). Returns substring begining position or -1 if not 
*	found. If substring followed after '\', doesn't track as match.
*
*	Example:
*	----
*	auto s = `word1 \word2\ word3`;
*	assert(findPos(s, 0, " ") == 5);
*	assert(findPos(s, 6, " ") == -1);
*	assert(findPos(s, 0, "word2") == -1);
*	assert(findPos(s, 2, "word") == 14);
*	----
*/
sizediff_t findPosEscaped(string s, size_t pos, string what)
{
	auto temp = countUntilEscaped(s[pos..$], what);
	if( temp == -1) return -1;
	return temp+pos;
}

unittest
{
	auto s = `word1 \word2\ word3`;
	assert(findPosEscaped(s, 0, " ") == 5);
	assert(findPosEscaped(s, 6, " ") == -1);
	assert(findPosEscaped(s, 0, "word2") == -1);
	assert(findPosEscaped(s, 2, "word") == 14);
}

/// findLastPos
/**
*	Search of last substring $(D what) in string $(D s), begining at
*	sympol position $(D pos). It is port from STL find_last. Returns
*	substring begining position or -1 if not found.
*	
*	Example:
*	----
*	assert(findLastPos("word1 word2 word3", 0, " ") == 11);
*	assert(findLastPos("hello World!"), 0, "World") == 6);
*	assert(findLastPos("hello World!"), 7, "World") == -1);
*	----
*/
sizediff_t findLastPos(string s, size_t pos, string what)
{
	for(size_t i = s.length-1-what.length; i>pos; --i)
		if(s[i..i+what.length] == what)
			return i;
	return -1;
}

unittest
{
	assert(findLastPos("word1 word2 word3", 0, " ") == 11);
	assert(findLastPos("hello World!", 0, "World") == 6);
	assert(findLastPos("hello World!", 7, "World") == -1);
}

/// getMemberType
/**
*	Retrieves member type with $(D name) of class $(D Class). If member is agregate 
*	type declaration or simply doesn't exist, retrieves no type. You can check it with
*	$(D is) operator.
*
*	Example:
*	-----------
*	class A 
*	{
*		int aField;
*		string b;
*		bool c;
*		
*		class B {}
*		struct C {}
*		union D {}
*		interface E {}
*	}
*
*	static assert(is(getMemberType!(A, "aField") == int));
*	static assert(is(getMemberType!(A, "b") == string));
*	static assert(is(getMemberType!(A, "c") == bool));
*
*	static assert(!is(getMemberType!(A, "B")));
*	static assert(!is(getMemberType!(A, "C")));
*	static assert(!is(getMemberType!(A, "D")));
*	static assert(!is(getMemberType!(A, "E")));
*	-----------
*/
template getMemberType(Class, string name)
{
	static if(hasMember!(Class, name))
		alias typeof(__traits(getMember, Class, name)) getMemberType;
}

unittest
{
	class A 
	{
		int a;
		string b;
		bool c;

		class B {}
		struct C {}
		union D {}
		interface E {}
	}

	static assert(is(getMemberType!(A, "a") == int));
	static assert(is(getMemberType!(A, "b") == string));
	static assert(is(getMemberType!(A, "c") == bool));

	static assert(!is(getMemberType!(A, "B")));
	static assert(!is(getMemberType!(A, "C")));
	static assert(!is(getMemberType!(A, "D")));
	static assert(!is(getMemberType!(A, "E")));
}

/// FieldNameTuple
/**
*	Retrieves names of all class/struct/union $(D Class) fields excluding technical ones like this, Monitor.
*
*	Example:
*	---------
*	class A 
*	{
*		int aField;
*
*		void func1() {}
*		static void func2() {}
*
*		string b;
*
*		final func3() {}
*		abstract void func4();
*
*		bool c;
*	}
*
*	static assert(FieldNameTuple!A == ["aField","b","c"]);
*	---------
*/
template FieldNameTuple(Class)
{
	template removeFuncs(funcs...)
	{
		static if(funcs.length > 0)
		{
			// if member is class/struct/interface declaration second part getMemberType returns no type
			static if( is(getMemberType!(Class, funcs[0]) == function) ||
				!is(getMemberType!(Class, funcs[0])) ||
				funcs[0] == "this" || funcs[0] == "Monitor" )
			{
				enum removeFuncs = removeFuncs!(funcs[1..$]);
			}
			else
				enum removeFuncs = [funcs[0]]~removeFuncs!(funcs[1..$]);
		}
		else
			enum removeFuncs = [];
	}

	enum temp = removeFuncs!(__traits(allMembers, Class));
	static if(temp.length > 0)
		enum FieldNameTuple = temp[0..$-1];
	else
		enum FieldNameTuple = [];
}

// ddoc example
unittest
{
	class A 
	{
		int a;

		void func1() {}
		static void func2() {}

		string b;

		final func3() {}
		abstract void func4();

		bool c;
	}

	static assert(FieldNameTuple!A == ["a","b","c"]);
}
unittest
{
	class P 
	{
		void foo() {}

		real p;
	}

	class A : P
	{
		int aField;

		void func1() {}
		static void func2() {}

		string b;

		final void func3() {}
		abstract void func4();

		bool c;

		void function(int,int) da;
		void delegate(int, int) db;

		class B {} 
		B mB;

		struct C {}
		C mC;

		interface D {}
	}

	static assert(FieldNameTuple!A == ["aField","b","c","da","db","mB","mC","p"]);
	static assert(is(getMemberType!(A, "aField") == int));
	static assert(is(getMemberType!(A, "b") == string));
	static assert(is(getMemberType!(A, "c") == bool));

	struct S1
	{
		int a;
		bool b;

		void foo() {}

		real c;
	}

	static assert(FieldNameTuple!S1 == ["a","b","c"]);

	union S2
	{
		size_t index;
		void*	pointer;
	}

	static assert(FieldNameTuple!S2 == ["index", "pointer"]);

	class S3
	{

	}
	static assert(FieldNameTuple!S3 == []);

	// Properties detected as field. To fix.
	struct S4
	{
		@property S4 dup()
		{
			return S4();
		}
	}
	static assert(FieldNameTuple!S4 == ["dup"]);
}

/// SatisfyFieldTuple
/**
*	Returns array of aggragate type $(D Class) field names which types satisfy predecate $(D Predicate).
*
*	Example:
*	----------
*	class A 
*	{
*		bool a;
*		string b;
*		int c;
*		double d;
*
*		class B {}
*		B mB;
*		A mA;
*
*		struct C {}
*		C mC;
*
*		union D {}
*		D mD;
*	}
*
*	static assert(SatisfyFieldTuple!(A, isAggregateType) == ["mB","mA","mC","mD"]);
*	static assert(SatisfyFieldTuple!(A, isBasicType) == ["a","c","d"]);
*	static assert(SatisfyFieldTuple!(A, isArray) == ["b"]);
*	----------
*/
template SatisfyFieldTuple(Class, alias Predicate)
{
	enum clfields = FieldNameTuple!Class;

	template Shrink(pfields...)
	{
		enum fields = pfields[0];
		static if(fields.length > 0)
		{
			static if(Predicate!(getMemberType!(Class, fields[0])))
				enum Shrink = [fields[0]]~Shrink!(fields[1..$]);
			else
				enum Shrink = Shrink!(fields[1..$]);
		}
		else
			enum Shrink = "";
	}

	enum temp = Shrink!(clfields);
	static if(temp.length>0)
		enum SatisfyFieldTuple = temp[0..$-1];
	else
		enum SatisfyFieldTuple = [];
}

unittest
{
	class A 
	{
		bool a;
		string b;
		int c;
		double d;

		class B {}
		B mB;
		A mA;

		struct C {}
		C mC;

		union D {}
		D mD;
	}

	static assert(SatisfyFieldTuple!(A, isAggregateType) == ["mB","mA","mC","mD"]);
	static assert(SatisfyFieldTuple!(A, isBasicType) == ["a","c","d"]);
	static assert(SatisfyFieldTuple!(A, isArray) == ["b"]);

	class S1
	{
		bool a;
	}
	static assert(SatisfyFieldTuple!(S1, isAggregateType) == []);
}

template TypeTupleFrom(Class, names...)
{
	template innerLoop(tms...)
	{
		enum ms = tms[0];
		static if(ms.length > 0)
		{
			alias TypeTuple!(getMemberType!(Class, ms[0]), innerLoop!(ms[1..$])) innerLoop;
		}
		else
			alias TypeTuple!() innerLoop;
	}
	alias innerLoop!(names) TypeTupleFrom;
}

unittest
{
	class A 
	{
		bool a;
		string b;
		int c;
		double d;

		class B {}
		B mB;
		A mA;

		struct C {}
		C mC;

		union D {}
		D mD;
	}

	alias FieldNameTuple!(A) fields;
	alias TypeTupleFrom!(A, fields) types;

	static assert(is( types == TypeTuple!(bool, string, int, double, A.B, A, A.C, A.D)));
}

/// StaticFind
/**
*	Finds first occurrence position of string $(D what) in string $(D where). If cannot find substring
*	returns -1.
*
*	Example:
*	----------
*	static assert(StaticFind!("some string", "str") == 5);
*	static assert(StaticFind!("some string", "world") == -1);
*	static assert(StaticFind!("str", "string") == -1);
*	static assert(StaticFind!("string", "string") == 0);
*	----------
*/
template StaticFind(string where, string what)
{
	template innerLoop(string s)
	{
		static if(s.length < what.length || s.length == 0)
		{
			enum innerLoop = -1;
		} 
		else
			static if(s[0..what.length] == what)
			{
				enum innerLoop = 0;
			}
			else
			{
				enum temp = innerLoop!(s[1..$]);
				static if(temp == -1)
					enum innerLoop = -1;
				else
					enum innerLoop = 1+temp;
			}
	}

	enum StaticFind = innerLoop!(where);
}

unittest
{
	static assert(StaticFind!("some string", "str") == 5);
	static assert(StaticFind!("some string", "world") == -1);
	static assert(StaticFind!("str", "string") == -1);
	static assert(StaticFind!("string", "string") == 0);
}

/// AssociativeArrayKeyType
/**
*	Retrieves associative array $(D T) key type. If T is not associative array, retrieves nothing, which can be
*	checked with $(D is) operator.
*
*	Example:
*	---------
*	static assert(is(AssociativeArrayKeyType!(string[float]) == float));
*	static assert(is(AssociativeArrayKeyType!(shared bool[double]) == double));
*	static assert(is(AssociativeArrayKeyType!(bool[shared double]) == shared double));
*	---------
*/
template AssociativeArrayKeyType(T)
{
	static if(isAssociativeArray!T)
	{
		enum obraket = StaticFind!(T.stringof, "[");
		enum cbraket = StaticFind!(T.stringof, "]");

		static if(obraket > 0 && cbraket > 0 && cbraket > obraket)
			mixin("alias "~T.stringof[obraket+1..cbraket]~" AssociativeArrayKeyType;");
	}
}

unittest
{
	static assert(is(AssociativeArrayKeyType!(string[float]) == float));
	static assert(is(AssociativeArrayKeyType!(shared bool[double]) == double));
	static assert(is(AssociativeArrayKeyType!(bool[shared double]) == shared double));
}

/// AssociativeArrayValueType
/**
*	Retrieves associative array $(D T) value type. If T is not associative array, retrieves nothing, which can be
*	checked with $(D is) operator.
*
*	Example:
*	---------
*	static assert(is(AssociativeArrayValueType!(string[float]) == string));
*	static assert(is(AssociativeArrayValueType!(shared bool[double]) == shared bool));
*	static assert(is(AssociativeArrayValueType!(bool[shared double]) == bool));
*	---------
*/
template AssociativeArrayValueType(T)
{
	static if(isAssociativeArray!T)
	{
		enum obraket = StaticFind!(T.stringof, "[");
		enum cbraket = StaticFind!(T.stringof, "]");

		static if(obraket > 0 && cbraket > 0 && cbraket > obraket)
			mixin("alias "~T.stringof[0..obraket]~T.stringof[cbraket+1..$]~" AssociativeArrayValueType;");
	}
}

unittest
{
	static assert(is(AssociativeArrayValueType!(string[float]) == string));
	static assert(is(AssociativeArrayValueType!(shared bool[double]) == shared bool));
	static assert(is(AssociativeArrayValueType!(bool[shared double]) == bool));
}

/// ArrayElementType
/**
*	Retrieves array $(D T) element type.f T is not array, retrieves nothing, which can be
*	checked with $(D is) operator.
*
*	Example:
*	---------
*	static assert(is(AssociativeArrayValueType!(string[]) == string));
*	static assert(is(AssociativeArrayValueType!(shared bool[]) == shared bool));
*	static assert(is(AssociativeArrayValueType!(bool[]) == bool));
*	---------
*/
template ArrayElementType(T)
{
	static if(isArray!T)
	{
		/*enum obraket = StaticFind!(T.stringof, "[");
		enum cbraket = StaticFind!(T.stringof, "]");

		static if(obraket > 0 && cbraket > 0 && cbraket > obraket)
			mixin("alias "~T.stringof[0..obraket]~T.stringof[cbraket+1..$]~" ArrayElementType;");*/

		static if(is(T U: U[]))
		{		
			alias U ArrayElementType;
		}
	}
}

unittest
{
	static assert(is(ArrayElementType!(string[]) == string));
	static assert(is(ArrayElementType!(shared bool[]) == shared bool));
	static assert(is(ArrayElementType!(bool[]) == bool));
}
