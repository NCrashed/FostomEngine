//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	Описание контейнера для хранения большого объема памяти маленькими кусками.
*/
module util.linkedarray;

void d(T...)(T args)
{
	import std.stdio;
	import std.conv;
	
	debug writeln(text(args));
}

/**
*	Виртуальный массив, состоящий из маленьких фиксированной длинны chunkSize.
*/
class LinkedArray(T, size_t chunkSize)
{
	this()
	{
		
	}
	
	this(T[] array)
	{
		
	}
	
	T opIndex(ulong index)
	{
		if(index >= length)
			throw new Exception("Out of range index LinkedList!"~T.stringof);
			
		return mMem[index / chunkSize][index % chunkSize];	
	}
	
	T[] opSlice(ulong x, ulong y)
	{
		d("slicing [",x,"..",y,"]");
		
		if( y <= x )
			return [];
			
		auto l = length;
		if( x > l || y > l)
			throw new Exception("Out of range slicing LinkedList!"~T.stringof);
			
		auto x1 = x/chunkSize;
		auto x2 = cast(size_t)(x-x1*chunkSize);
		auto y1 = y/chunkSize;
		auto y2 = cast(size_t)(y-y1*chunkSize);
		
		d("transformed: [",x1,":",x2,"..",y1,":",y2,"]");
		if(x1 == y1) // В одном чанке
		{
			d("In one chunk");
			return mMem[x1][x2..y2];
		} else // В разных чанках
		{
			d("In different chunks");
			return mMem[x1][x2..$]~mMem[y1][0..y2];
		}
	}
	
	void opOpAssign(string op)(T[] array)
		if( op == "~" )
	{
		if(array is null || array.length == 0) return;
		
		auto l = length;
		
		auto lastX = l/chunkSize;
		auto lastY = l%chunkSize;
		
		if(array.length <= chunkSize)
		{
			if(lastY + array.length <= chunkSize)
			{
				mMem[lastX] ~= array;
			} else
			{
				mMem[lastX] ~= array[0..cast(size_t)(chunkSize-lastY)];
				mMem[lastX+1] = array[cast(size_t)(chunkSize-lastY+1)..$];
			}
		} else
		{
			mMem[lastX] ~= array[0..cast(size_t)(chunkSize-lastY)];
			array = array[cast(size_t)(chunkSize-lastY+1)..$];
			
			lastX+=1;
			lastY = 0;
			
			while(array.length > 0)
			{
				if(array.length > chunkSize)
				{
					mMem[lastX] = array[0..chunkSize];
					array = array[cast(size_t)(chunkSize+1)..$];
				}
				else
				{
					mMem[lastX] = array;
					array = [];
				}
			}
		}
	}
	
	/**
	*	Итерирование по чанкам массива, нужен для потомков.
	*/
	protected T[][] memoryChunks() @property
	{
		auto ret = new T[][cast(size_t)mMem.keys.length];
		for(size_t i =0; i<ret.length; i++)
		{
			ret[i] = mMem[i];
		}		
		return ret;
	}
	
	ulong length() @property
	{
		ulong ret = 0;
		foreach(m; mMem)
			ret += m.length;
		return ret;	
	}
	
	ulong opDollar()
	{
		return length;
	}
	
	private
	{
		T[][ulong] mMem;
	}
}