// written in the D programming language
/*
*   This file is part of FostomEngine.
*   
*   FostomEngine is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*   
*   FostomEngine is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*   
*   You should have received a copy of the GNU General Public License
*   along with FostomEngine.  If not, see <http://www.gnu.org/licenses/>.
*/
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
