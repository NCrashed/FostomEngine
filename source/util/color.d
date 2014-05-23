//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
module util.color;

import util.vector;
import std.math;
import std.stdio;

debug
{
	string tobits(T)(T value)
	{
		string ret = "";
		for(int i = 8*T.sizeof-1; i >= 0; i--)
		{
			if(((value >> i) & 0x01) == 1)
			{
				ret ~= "1";
			} else
			{
				ret ~= "0";
			}
		}
		return ret;
	}
}

struct ColorRGBA
{
	ubyte r, g, b, a;
	
	static int fastCompact(ubyte r, ubyte g, ubyte b, ubyte a)
	{
		return r + ((g & 0x000000FF) << 8) + ((b & 0x000000FF) << 16) + ((a & 0x000000FF) << 24);
	}
	
	this(uint compactValue)
	{
		r = cast(ubyte) compactValue & 0x000000FF;
		g = cast(ubyte) (compactValue & 0x0000FF00) >> 8;
		b = cast(ubyte) (compactValue & 0x00FF0000) >> 16;
		a = cast(ubyte) (compactValue & 0xFF000000) >> 24;
	}
	
	this(uint[] values)
	{
		uint rv, gv, bv, av;
		
		foreach(v; values)
		{
			rv += v & 0x000000FF;
			gv += (v & 0x0000FF00) >> 8;
			bv += (v & 0x00FF0000) >> 16;
			av += (v & 0xFF000000) >> 24;
		}
		r = cast(ubyte) (rv / values.length);
		g = cast(ubyte) (gv / values.length);
		b = cast(ubyte) (bv / values.length);
		a = cast(ubyte) (av / values.length);
	}

	this(uint[][][] values, size_t x1, size_t x2, size_t y1, size_t y2, size_t z1, size_t z2)
	{
		uint rv, gv, bv;
		float mv = 0;

		for(size_t x = x1; x < x2; x++)
			for(size_t y = y1; y < y2; y++)
				for(size_t z = z1; z < z2; z++)
				{
					int v = values[x][y][z];
					ubyte av = (v & 0xFF000000) >> 24;
					float at = av/255.0f;
					a = cast(ubyte)fmax(a, av);
					
					rv += (v & 0x000000FF)*at;
					gv += ((v & 0x0000FF00) >> 8)*at;
					bv += ((v & 0x00FF0000) >> 16)*at;
					mv += at;
				}

		if(mv != 0.0f)
		{
			r = cast(ubyte) (rv / mv);
			g = cast(ubyte) (gv / mv);
			b = cast(ubyte) (bv / mv);
		}
	}
	
	int compact() @property
	{
		return r + (g << 8) + (b << 16) + (a << 24);
	}
	
}

struct NormalVectorDistr
{
	vec3 vector;
	float dispertion;
	
	static uint fastCompact(float x, float y, float z, float disp)
	{
		float l = 1 / ((disp + 1)*sqrt(x*x + y*y + z*z));
		int sign = z < 0 ? 1 : 0;
		uint zs = (cast(uint)(l * abs(z) * 0x7F) + sign*0x80) << 16;
		sign = y < 0 ? 1 : 0;
		uint ys = (cast(uint)(l * abs(y) * 0x7F) + sign*0x80) << 8;
		sign = x < 0 ? 1 : 0;
		uint xs = cast(uint)(l * abs(x) * 0x7F) + sign*0x80;
		
		return zs + ys  + xs;
	}
	
	this(vec3 vector, float dispertion)
	{
		this.vector = vector.normalized;
		this.dispertion = dispertion;
	}
	
	this(uint compactValue)
	{
		int sign = ((compactValue >> 16) & 0x80) == 0 ? 1 : -1;
		vector.z = sign*(((compactValue >> 16) & 0x7F)/cast(float)0x7F);
		sign = ((compactValue >> 8) & 0x80) == 0 ? 1 : -1;
		vector.y = sign*(((compactValue >> 8) & 0x7F)/cast(float)0x7F);
		sign = (compactValue & 0x80) == 0 ? 1 : -1;
		vector.x = sign*((compactValue & 0x7F)/cast(float)0x7F);
		
		float l = vector.length;
		dispertion = (1 - l)/l;
		vector.normalize();
		assert(dispertion >= 0, "Dispertion cannot be negative! Check compactValue to be valid!");
	}
	
	this(uint[][][] values, size_t x1, size_t x2, size_t y1, size_t y2, size_t z1, size_t z2)
	{
		int count = 0;
		dispertion = 0.0f;
		for(size_t x = x1; x < x2; x++)
			for(size_t y = y1; y < y2; y++)
				for(size_t z = z1; z < z2; z++)
				{
					NormalVectorDistr distr = NormalVectorDistr(values[x][y][z]);
					if(distr.vector.length > 0)
					{
						vector = vector + distr.vector;
						dispertion = dispertion + distr.dispertion;
						count++;
					}
				}
		vector.normalize();		
		dispertion = dispertion / count;
	}
	
	uint compact() @property
	{
		if(isNaN(vector.x) || isNaN(vector.y) || isNaN(vector.z) || isNaN(dispertion) || approxEqual(vector.length, 0.0f)) return 0;
		assert(approxEqual(vector.length, 1.0f), "Vector length should be normalized!");
		float l = 1 / (dispertion + 1);
		int sign = vector.z < 0 ? 1 : 0;
		uint zs = (cast(uint)(l * abs(vector.z) * 0x7F) + sign*0x80) << 16;
		sign = vector.y < 0 ? 1 : 0;
		uint ys = (cast(uint)(l * abs(vector.y) * 0x7F) + sign*0x80) << 8;
		sign = vector.x < 0 ? 1 : 0;
		uint xs = cast(uint)(l * abs(vector.x) * 0x7F) + sign*0x80;
		return cast(uint)(zs + ys + xs);
	}
}