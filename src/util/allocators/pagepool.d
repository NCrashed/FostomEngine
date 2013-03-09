//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	License: Boost 1.0
*	Authors: Gushcha Anton (NCrashed)
*
*	Custom memory allocator to handle fixed-size memory chunks called pages.
*/
module util.allocators.pagepool;

import std.c.stdlib;
import std.c.string;

/**
*	Class wrapper around memory pool of $(B pageSize) memory blocks. Provides
*	interface for reallocating and relative pointer access.
*/
class PagePool(size_t pageSize)
{
	this(size_t pageCount)
	{
		memoryPool = malloc(pageCount * pageSize);
	}
	
	this(size_t pageCount, void* memory)
	{
		this(pageCount);
		
		memcpy(memoryPool, memory, pageCount*pageSize);
	}
	
	~this()
	{
		free(memoryPool);
	}
	
	void* memory() @property
	{
		return memoryPool;
	}
	
	private
	{
		private void* memoryPool = null;
	}
}
