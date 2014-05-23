// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Описание векторов для размерностей 2,3,4
*
*	Описание векторов. Для каждой размерности свой класс, кардинально различаются
*	только 4х мерные векторы, так как 2х мерные вектора являются упрощенными 3х мерными. Заданы
*	методы для трансформации одного типа вектора в другой.
*/
module util.vector;

import std.math;
import std.traits;
import std.array;
import std.conv;

alias Vector!(float,4) vec4;
alias Vector!(float,3) vec3;
alias Vector!(float,2) vec2;

alias Vector!(int, 4) vec4i;
alias Vector!(int, 3) vec3i;
alias Vector!(int, 2) vec2i;

alias Vector!(uint, 4) vec4ui;
alias Vector!(uint, 3) vec3ui;
alias Vector!(uint, 2) vec2ui;

alias Vector!(long, 4) vec4l;
alias Vector!(long, 3) vec3l;
alias Vector!(long, 2) vec2l;

alias Vector!(ulong, 4) vec4ul;
alias Vector!(ulong, 3) vec3ul;
alias Vector!(ulong, 2) vec2ul;

alias Vector!(size_t, 4) vec4st;
alias Vector!(size_t, 3) vec3st;
alias Vector!(size_t, 2) vec2st;

const vec3 ZUNIT = vec3(0,0,1);
const vec3 XUNIT = vec3(1,0,0);
const vec3 YUNIT = vec3(0,1,0);

private T[size] initArray(T,int size)(T value)
{
	T ret[size];
	foreach(ref a; ret)
		a = value;
	return ret;
}

/// Шаблонный вектор
/**
*	Вектор заданной размерности и типа хранения
*	@par StType Тип данных, который хранится в векторе
*	@par size Размерность вектора
*	@note Для вектора определены операторы каста к другим размерностям
*	@note Операция векторного умножения определена только для трехмерных векторов.
*	Для двумерных она преобразует вектора в трехмерные.
*/
struct Vector(StType, uint size)
{
	/**
	*	Хранимый тип
	*/
	alias StType StorageType;
	
	/**
	*	Количество компонент
	*/
	enum dimentions = size;
	
	static if(isFloatingPoint!(StType))
	{
		StType m[size] = initArray!(StType,size)(0.);
	} else
	{
		StType m[size];
	}

	alias Vector!(StType, size) thistype;

	this(StType[] vals...)
	{
		assert(vals.length == size, "Passed wrong arguments count to "~thistype.stringof~" constructor! Needed: "~to!string(size)~", but geted: "~to!string(vals.length));
		foreach(i,ref val; m)
			val = vals[i];
	}

	static if(size > 0)
	{
		@property StType x() nothrow @trusted
		{
			return m[0];
		}

		@property void x(StType val) nothrow @trusted
		{
			m[0] = val;
		}
	}

	static if(size > 1)
	{
		@property StType y() nothrow @trusted
		{
			return m[1];
		}

		@property void y(StType val) nothrow @trusted
		{
			m[1] = val;
		}
	}

	static if(size > 2)
	{
		@property StType z() nothrow @trusted
		{
			return m[2];
		}

		@property void z(StType val) nothrow @trusted
		{
			m[2] = val;
		}
	}

	static if(size > 3)
	{
		@property StType w()
		{
			return m[3];
		}

		@property void w(StType val)
		{
			m[3] = val;
		}
	}


	/// Доступ к элементу на чтение
	StType opIndex(size_t i)
	in
	{
		assert( i < size, "Vector i index overflow!" );
	}
	body
	{
		return m[i];
	}

	/// Доступ к элементу на запись
	void opIndexAssign(StType val, size_t i)
	in
	{
		assert( i < size, "Vector i index overflow!" );
	}
	body
	{
		m[i] = val;
	}

	/// Трансформация в 4->3мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,3)) && size == 4)
	{
		Vector!(StType,3) v;
		v.x = x;
		v.y = y;
		v.z = z;
		return v;
	}

	/// Трансформация в 4->2мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,2)) && size == 4)
	{
		Vector!(StType,2) v;
		v.x = x;
		v.y = y;
		return v;
	}	

	/// Трансформация в 3->4мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,4)) && size == 3)
	{
		Vector!(StType,4) v;
		v.x = x;
		v.y = y;
		v.z = z;
		static if(isFloatingPoint!(StType))
		{
			v.w = 0.;
		}
		return v;
	}

	/// Трансформация в 3->2мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,2)) && size == 3)
	{
		Vector!(StType,2) v;
		v.x = x;
		v.y = y;
		return v;
	}	

	/// Трансформация в 2->4мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,4)) && size == 2)
	{
		Vector!(StType,4) v;
		v.x = x;
		v.y = y;
		static if(isFloatingPoint!(StType))
		{
			v.z = 0.;
			v.w = 0.;
		}
		return v;
	}	

	/// Трансформация в 2->3мерный вектор
	T opCast(T)() if(is(T==Vector!(StType,3)) && size == 2)
	{
		Vector!(StType,3) v;
		v.x = x;
		v.y = y;
		static if(isFloatingPoint!(StType))
		{
			v.z = 0.;
		}
		return v;
	}

	/// Скалярное умножение
	StType dot(thistype v)
	{
		StType temp;
		static if(isFloatingPoint!(StType))
		{
			temp = 0.;
		}		

		foreach(i,val; v.m)
			temp += m[i]*val;

		return temp;
	}

	/// Cложение
	thistype opBinary(string op)(thistype v) if (op == "+")
	{
		thistype ret;
		foreach(i,val;v.m)
			ret.m[i] = m[i]+val;

		return ret;
	}

	/// Вычитание
	thistype opBinary(string op)(thistype v) if (op == "-")
	{
		thistype ret;
		foreach(i,val;v.m)
			ret.m[i] = m[i]-val;

		return ret;
	}

	/// Умножение на число
	thistype opBinary(string op)(StType val) if (op == "*")
	{
		thistype ret;
		foreach(i,coord; m)
			ret.m[i] = coord*val;

		return ret;
	}

	/// Сравнение двух векторов
	bool opEquals(thistype v)
	{
		bool ret = true;
		foreach(i,coord; v.m)
			ret = ret && approxEqual(m[i], coord);

		return ret;
	}

	/// Угол между векторами в радианах
	double angle(thistype v)
	{
		return cast(double)(dot(v)/length);
	}

	/// Длина вектора
	@property double length()
	{
		StType temp;
		static if(isFloatingPoint!(StType))
		{
			temp = 0.;
		}	

		foreach(val; m)
			temp += val*val;

		return sqrt(cast(double)(temp));
	}

	/// Длина в квадрате
	/**
	*	Во многих случаях ускоряет вычисления
	*/
	@property double length2()
	{
		StType temp;
		static if(isFloatingPoint!(StType))
		{
			temp = 0.;
		}	

		foreach(val; m)
			temp += val*val;
			
		return cast(double)(temp);
	}

	/// Привести длину вектора к 1
	void normalize()
	{
		auto l = length;
		foreach(ref val; m)
			val /= l;
	}

	/// Привести длину вектора к 1
	thistype normalized()
	{
		thistype ret;
		auto l = length;
		foreach(i,val; m)
			ret[i] = cast(StType)(val/l);
		return ret;
	}

	static if(size == 3 || size == 4)
	{
		/// Векторное умножение
		thistype cross(thistype v)
		{
			thistype ret;
			ret.x = y*v.z - v.y*z;
			ret.y = v.x*z - x*v.z;
			ret.z = x*v.y - v.x*y;
			static if(size == 4 && isFloatingPoint!(StType))
			{
				ret.w = 0;
			}
			return ret;
		}
	}

	/// Векторное умножение
	static if(size == 2)
	{
		Vector!(StType, 3) cross(thistype v)
		{
			Vector!(StType, 3) ret;
			ret.z = x*v.y - v.x*y;
			return ret;		
		}
	}
}

unittest
{
	import std.stdio;
	import std.math;
	import std.conv;

	write("Testing vectors... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	vec3 a;
	a.x = 1;
	a.y = 2;
	a.z = 3;

	vec3 b;
	b.x = 3;
	b.y = 2;
	b.z = 1;

	auto c = a.cross(b);
	assert( c.x == -4 && c.y == 8 && c.z == -4, "Vector cross product failed! "~ to!string(c));

	a.normalize();
	assert(approxEqual(a.length, 1.), "Normalization test failed!" );
}