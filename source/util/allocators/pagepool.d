// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Custom memory allocator to handle fixed-size memory chunks called pages.
*/
module util.allocators.pagepool;

import std.c.stdlib;
import std.c.string;

alias PagePool!1 CBuffer;

/**
*	Class wrapper around memory pool of $(B pageSize) memory blocks. Provides
*	interface for reallocating and relative pointer access.
*/
class PagePool(size_t pageSize)
{
	this(size_t pageCount)
	{
		memoryPool = malloc(pageCount * pageSize);
		mPageCount = pageCount;
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

	size_t pageCount() @property
	{
		return mPageCount;
	}

	size_t memorySize() @property
	{
		return mPageCount*pageSize;
	}

	private
	{
		private void* memoryPool = null;
		size_t mPageCount;
	}
}
