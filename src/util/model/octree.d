//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	License: Boost 1.0
*	Authors: Gushcha Anton (NCrashed)
*
*	Implementation of generic N^3-tree with N = 2 used for compact model representation.
*	It uses out of GC memory to ensure memory position wouldn't chage due direct GPU memory
*	access.
*
*	Octree contains voxel volume brick (simply brick) at each level. Volume brick can be replaced
*	with constant value to reduce memory usage. Node child nodes grouped in node-tile and can be
*	accessed with one pointer and constant shift.
*
*	Structure of arrays (SOA) method is used for storing node pointer and brick pointer seperatly in
*	different pools.
*/
module util.model.octree;

import util.allocators.pagepool;
import util.color;
import util.vector;
import std.array;
import std.container;
import std.conv;

debug
{
	import std.stdio;
	import std.process;
	
	void dbg(T...)(T args)
	{
		writeln(args);  
	}
	
	void debugList(T)(SList!T list, void delegate(T element) debugPrint)
	{
		foreach(el; list)
		{
			debugPrint(el);
		}
	}
	
	void listSize(T)(SList!T list)
	{
		size_t l = 0;
		foreach(el; list) l++;
		dbg("List size: ", l);
	}
	
	void pause()
	{
		system("pause");
	}
}

alias Octree!(4,1,48) StdOctree;

class Octree(size_t brickSize, size_t borderSize = 1, size_t brickPoolSide = 48)
{
	enum BrickSize = brickSize;
	enum BorderSize = borderSize;
	enum BrickPoolSide = brickPoolSide;
	protected enum brickMemSize = (brickSize+2*borderSize)*(brickSize+2*borderSize)*(brickSize+2*borderSize)*int.sizeof;
	enum BrickFullSide = brickSize+2*borderSize;
	enum BrickVolume = BrickFullSide*BrickFullSide*BrickFullSide;
	
	this(uint[][][] data, uint[][][] normal)
	{
		size_t sizex, sizey, sizez;
		if(!checkCubeSize(data, sizex, sizey, sizez))
		{
			throw new Exception("Data massive passed to Octree should be cube form!");
		}
		
		if(sizex == 0 || sizey == 0 || sizez == 0)
		{
			throw new Exception("Passed to Octree zero sized data!");
		}
		
		size_t nsizex, nsizey, nsizez;
		if(!checkCubeSize(normal, nsizex, nsizey, nsizez))
		{
			throw new Exception("Normal massive passed to Octree should be cube form!");
		}
		
		if(nsizex != sizex || nsizey != sizey || nsizez != sizez)
		{
			throw new Exception("Normal massive must have same dimentions as data!");
		}
		
		auto tileApp = Appender!(NodeTile[], NodeTile)();
		auto brickApp = Appender!(uint[], uint)();
		auto normApp = Appender!(uint[], uint)();
		
		recurseDescend(data, normal, tileApp, brickApp, normApp);

		childPool = new PagePool!(NodeTile.sizeof)(tileApp.data.length, tileApp.data.ptr);

		size_t brickCount = brickApp.data.length/BrickVolume;
		auto preparedBrickData = prepareBricks(brickApp.data, brickCount, mBrickPoolSize);
		auto preparedBrickNormalData = prepareBricks(normApp.data, brickCount, mBrickPoolSize);
		brickPool = new CBuffer(preparedBrickData.length*uint.sizeof, preparedBrickData.ptr);
		normalPool = new CBuffer(preparedBrickNormalData.length*uint.sizeof, preparedBrickNormalData.ptr);

		/*
		mBrickPoolSize = clampBrickPoolSize(brickApp.data.length/BrickVolume);
		size_t brickPoolLength = mapBrickToLinear(mBrickPoolSize.x, mBrickPoolSize.y, mBrickPoolSize.z);
		brickPool = new PagePool!(brickMemSize)(brickPoolLength, brickApp.data.ptr);
		normalPool = new PagePool!(brickMemSize)(brickPoolLength, normApp.data.ptr);*/
	}
	
	/**
	*	Returns particular brick's memory location. 
	*/
	void* getBrickTile(size_t x, size_t y, size_t z)
	{
		return cast(void*)(cast(size_t)brickPool.memory + mapBrickToLinear(x,y,z));
	}
	
	/**
	*	Returns particular normal tile's memory location.
	*/
	void* getNormalTile(size_t x, size_t y, size_t z)
	{
		return cast(void*)(cast(size_t)normalPool.memory + mapBrickToLinear(x,y,z));
	}

	/**
	 *	Returns particular octree node memory location.
	 */
	void* getNodeTile(size_t n)
	{
		return cast(void*)childPool.memory + nodeTileSize*n;
	}

	/**
	 *	Returns actual size in pixels of brick pool.
	 */ 
	vec3st brickPoolSize() @property
	{
		return mBrickPoolSize;
	}

	size_t brickPoolMemSize() @property
	{
		return brickPool.memorySize();
	}

	size_t brickCount() @property
	{
		return brickPool.pageCount/(BrickVolume*uint.sizeof);
	}

	/**
	 * 	Returns node pool size in bytes.
	 */
	size_t nodePoolSize() @property
	{
		return nodeTileSize*childPool.pageCount;
	}

	/**
	 *	Returns tile node size in bytes.
	 */
	static size_t nodeTileSize() @property
	{
		static assert(NodeTile.sizeof == 16*uint.sizeof);
		return NodeTile.sizeof;
	}

	private
	{
		struct DataRegion
		{
			size_t x1, y1, z1;
			size_t x2, y2, z2;
			
			size_t sizex() @property
			{
				return x2-x1;
			}
			
			size_t sizey() @property
			{
				return y2-y1;
			}
			
			size_t sizez() @property
			{
				return z2-z1;
			}
			
			this(uint[][][] data)
			{
				x2 = data[0][0].length;
				y2 = data[0].length;
				z2 = data.length;
			}
			
			this(size_t x1, size_t x2, size_t y1, size_t y2, size_t z1, size_t z2)
			{
				this.x1 = x1;
				this.x2 = x2;
				this.y1 = y1;
				this.y2 = y2;
				this.z1 = z1;
				this.z2 = z2;
			}
			
			string nicestr() @property
			{
				return text("DataRegion(x = ", x1, " .. ", x2, "; y = ", y1, " .. ", y2, "; z = ", z1, " .. ", z2, ")");
			}
		}
		
		/**
		*	Allows to get access to brick tile at (x,y,z).
		*/
		static size_t mapBrickToLinear(size_t x, size_t y, size_t z)
		{
			if(x >= brickPoolSide || y >= brickPoolSide || z >= brickPoolSide)
			{
				return 0;
			}
			return x + brickPoolSide*BrickVolume*y + brickPoolSide*brickPoolSide*BrickVolume*z;
		}

		/**
		 *	Calculates brick coordinates from index.
		 */ 
		static vec3st mapBrickFromLinear(size_t n)
		{
			vec3st ret;
			ret.x = n % (brickPoolSide*BrickVolume);
			n /= brickPoolSide*BrickVolume;
			ret.y = n % (brickPoolSide);
			ret.z = n / brickPoolSide;
			return ret;
		}
		unittest
		{
			static assert(1 % (brickPoolSide*BrickVolume) == 1);
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(0,0,0)) == vec3st(0,0,0));
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(1,0,0)) == vec3st(1,0,0));
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(0,1,0)) == vec3st(0,1,0));
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(0,0,1)) == vec3st(0,0,1));
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(1,1,1)) == vec3st(1,1,1));
			assert(StdOctree.mapBrickFromLinear(mapBrickToLinear(23,42,15)) == vec3st(23,42,15));
		}

		/**
		 * Clamps brick texture sizes to pass them to OpenCL buffer
		 */
		vec3st clampBrickPoolSize(size_t n)
		{
			auto vec = mapBrickFromLinear(n);
			vec.x = brickPoolSide*BrickVolume;
			if(vec.y > 0)
				vec.y = brickPoolSide*BrickVolume;
			else
				vec.y = 1;
			vec.z = vec.z + 1;
			return vec;
		}

		/**
		*	Increases $(B pos) value with evenly filling the brick pool along vector (1,1,1).
		*/
		void incBrickPos(ref vec3st pos)
		{
			pos.x = pos.x + 1;
			if(pos.x >= brickPoolSide)
			{
				pos.x = 0;
				pos.y = pos.y + 1;
				if(pos.y >= brickPoolSide)
				{
					pos.y = 0;
					pos.z = pos.z + 1;
					if(pos.z >= brickPoolSide)
					{
						throw new Exception("Brick pool overflow! Increase brickPoolSide!");
					}
				}
			}
		}

		/**
		 *	Raw generated bricks has wrong order in memory, this functions maps 1D array of 3D bricks
		 *	to 3D array. $(B maxSize) fills with size of texture in pixels.
		 */ 
		uint[] prepareBricks(uint[] rawBricks, size_t brickCount, out vec3st maxSize)
		{
			size_t maxX = brickPoolSide;
			size_t maxY = brickPoolSide;
			size_t maxZ = brickCount / (brickPoolSide*brickPoolSide) + 1;

			maxSize.x = maxX*BrickFullSide;
			maxSize.y = maxY*BrickFullSide;
			maxSize.z = maxZ*BrickFullSide;
			auto ret = new uint[maxX*maxY*maxZ*BrickVolume];

			void copyBrickToTexture(ref uint[] tex, ref uint[] brick, size_t sx, size_t sy, size_t sz)
			{
				size_t mapTexCoord(size_t x, size_t y, size_t z)
				{
					return x + y*maxSize.x + z*maxSize.x*maxSize.y;
				}

				size_t mapBrickCoord(size_t x, size_t y, size_t z)
				{
					return x + y*BrickFullSide + z*BrickFullSide*BrickFullSide;
				}

				for(size_t z = 0; z < BrickFullSide; z++)
				{
					for(size_t y = 0; y < BrickFullSide; y++)
					{
						for(size_t x = 0; x < BrickFullSide; x++)
						{
							tex[mapTexCoord(sx+x, sy+y, sz+z)] = brick[mapBrickCoord(x,y,z)];
						}
					}
				}
			}

			size_t rawBrickIndex = 0;
			mainloop: for(size_t z = 0; z < maxZ; z++)
			{
				for(size_t y = 0; y<maxY; y++)
				{
					for(size_t x = 0; x<maxX; x++)
					{
						copyBrickToTexture(ret, rawBricks[rawBrickIndex*BrickVolume .. (rawBrickIndex+1)*BrickVolume], x*BrickFullSide, y*BrickFullSide, z*BrickFullSide);
						rawBrickIndex+=1;
						if(rawBrickIndex >= brickCount) break mainloop;
					}
				}
			}

			return ret;
		}

		/**
		*	Generates mip-brick for $(B data) and adds to $(B brickApp) generated brick. Does not fill
		*	address of next octree node address.
		*/
		NodeTile.NodeTexel traverseTile(uint[][][] data, uint[][][] normData, DataRegion region, ref Appender!(uint[], uint) brickApp, ref Appender!(uint[], uint) normApp, ref vec3st lastBrickPos)
		{
			NodeTile.NodeTexel texel;
			uint value;
			
			if(isDataHomogenius(data, region, value))
			{
				texel.color = value;
				bool isLeaf = false;
				if(region.sizex <= brickSize || region.sizey <= brickSize || region.sizez <= brickSize)
				{
					isLeaf = true;
				}
				texel.setAddress(0, isLeaf, true);
				return texel;
			}
						
			// generating brick
			int stepX = region.sizex / brickSize;
			int stepY = region.sizey / brickSize;
			int stepZ = region.sizez / brickSize;
			
			if(stepX == 0) stepX = 1;
			if(stepY == 0) stepY = 1;
			if(stepZ == 0) stepZ = 1;
								
			/*dbg("xsize = ", region.sizex);
			dbg("ysize = ", region.sizey);
			dbg("zsize = ", region.sizez);
			dbg("xstep = ", stepX);
			dbg("ystep = ", stepY);
			dbg("zstep = ", stepZ);*/
			
			uint[] brick = new uint[BrickVolume];
			uint[] norm  = new uint[BrickVolume];
			for(size_t x = borderSize; x <= brickSize; x++)
			{
				for(size_t y = borderSize; y <= brickSize; y++)
				{
					for(size_t z = borderSize; z <= brickSize; z++)
					{
						//dbg("x = ", (x-borderSize)*stepX, " .. ", (x-borderSize + 1)*stepX);
						//dbg("y = ", (y-borderSize)*stepY, " .. ", (y-borderSize + 1)*stepY);
						//dbg("z = ", (z-borderSize)*stepZ, " .. ", (z-borderSize + 1)*stepZ);
						
						ColorRGBA acol = ColorRGBA(data, (x-borderSize)*stepX, (x-borderSize + 1)*stepX, (y-borderSize)*stepY, (y-borderSize + 1)*stepY, (z-borderSize)*stepZ, (z-borderSize + 1)*stepZ);
						brick[x + (brickSize+2*borderSize)*y + (brickSize+2*borderSize)*(brickSize+2*borderSize)*z] = acol.compact;
						
						NormalVectorDistr dist = NormalVectorDistr(normData, (x-borderSize)*stepX, (x-borderSize + 1)*stepX, (y-borderSize)*stepY, (y-borderSize + 1)*stepY, (z-borderSize)*stepZ, (z-borderSize + 1)*stepZ);
						norm[x + (brickSize+2*borderSize)*y + (brickSize+2*borderSize)*(brickSize+2*borderSize)*z] = dist.compact;
					}
				} 
			}
			brickApp.put(brick);
			normApp.put(norm);
			incBrickPos(lastBrickPos);
			
			bool isLeaf = false;
			if(region.sizex <= brickSize || region.sizey <= brickSize || region.sizez <= brickSize)
			{
				isLeaf = true;
			}
			
			texel.setAddress(0, isLeaf, false);
			texel.setBrickAddress(lastBrickPos.x, lastBrickPos.y, lastBrickPos.z);
			return texel;
			// borders
			// fill borders after all bricks!
			/*if(cast(int)reg.z-borderSize*stepZ < 0)
			{
				for(size_t z = 0; z<borderSize; z++)
				{
					brick[mapToLinear(borderSize, borderSize, z) .. mapToLinear(brickSize+borderSize, brickSize+borderSize, z)] =
						brick[mapToLinear(borderSize, borderSize, brickSize-z) .. mapToLinear(brickSize+borderSize, brickSize+borderSize, brickSize-z)];
				}
			} else
			{
				for(size_t x = borderSize; x < brickSize; x++)
				{
					for(size_t y = borderSize; y < brickSize; y++
				}
			}*/
			
			
		}
		
		/**
		*	Goes down octree, generating mip bricks and tiles until hit brickSize data size.
		*/
		void recurseDescend(uint[][][] data, uint[][][] normal, ref Appender!(NodeTile[], NodeTile) tileApp, ref Appender!(uint[], uint) brickApp, ref Appender!(uint[], uint) normApp)
		{
			NodeTile rootTile;
			vec3st lastBrickPos;
			rootTile.t0 = traverseTile(data, normal, DataRegion(data), brickApp, normApp, lastBrickPos);
			
			struct StackElement
			{
				DataRegion region;
				NodeTile tile;
				NodeTile parent; 
				byte parentTexel;
			}

			SList!StackElement stack;
			stack.insert(StackElement(DataRegion(data), NodeTile(), rootTile, 0));
			int lastTilePos = 0;
			
			while(!stack.empty)
			{
				StackElement element = stack.front();
				stack.removeFront();
				size_t sizex = element.region.sizex;
				size_t sizey = element.region.sizey;
				size_t sizez = element.region.sizez;
				
				if(element.parent.getTexelPointer(element.parentTexel).leaf)
				{
					tileApp.put(element.parent);
					lastTilePos++;
					continue;
				}
				
				DataRegion t0reg = DataRegion(0, 			sizex/2, 	0, 			sizey/2, 	0, 	sizez/2);
				DataRegion t1reg = DataRegion(sizex/2, 		sizex, 		0, 			sizey/2, 	0, 	sizez/2);
				DataRegion t2reg = DataRegion(0, 			sizex/2, 	sizey/2, 	sizey, 		0, 	sizez/2);
				DataRegion t3reg = DataRegion(sizex/2, 		sizex, 		sizey/2, 	sizey, 		0, 	sizez/2);
				DataRegion t4reg = DataRegion(0, 			sizex/2, 	0, 			sizey/2, 	sizez/2, sizez);
				DataRegion t5reg = DataRegion(sizex/2, 		sizex, 		0, 			sizey/2, 	sizez/2, sizez);
				DataRegion t6reg = DataRegion(0, 			sizex/2, 	sizey/2, 	sizey, 		sizez/2, sizez);
				DataRegion t7reg = DataRegion(sizex/2, 		sizex, 		sizey/2, 	sizey, 		sizez/2, sizez);
				
				element.tile.t0 = traverseTile(data, normal, t0reg, brickApp, normApp, lastBrickPos);
				element.tile.t1 = traverseTile(data, normal, t1reg, brickApp, normApp, lastBrickPos);
				element.tile.t2 = traverseTile(data, normal, t2reg, brickApp, normApp, lastBrickPos);
				element.tile.t3 = traverseTile(data, normal, t3reg, brickApp, normApp, lastBrickPos);
				
				element.tile.t4 = traverseTile(data, normal, t4reg, brickApp, normApp, lastBrickPos);
				element.tile.t5 = traverseTile(data, normal, t5reg, brickApp, normApp, lastBrickPos);
				element.tile.t6 = traverseTile(data, normal, t6reg, brickApp, normApp, lastBrickPos);
				element.tile.t7 = traverseTile(data, normal, t7reg, brickApp, normApp, lastBrickPos);
				
				
				if(!element.tile.t0.leaf)
					stack.insert(StackElement(t0reg, NodeTile(), element.tile, 0));
				if(!element.tile.t1.leaf)	
					stack.insert(StackElement(t1reg, NodeTile(), element.tile, 1));
				if(!element.tile.t2.leaf)
					stack.insert(StackElement(t2reg, NodeTile(), element.tile, 2));
				if(!element.tile.t3.leaf)
					stack.insert(StackElement(t3reg, NodeTile(), element.tile, 3));
				
				if(!element.tile.t4.leaf)
					stack.insert(StackElement(t4reg, NodeTile(), element.tile, 4));
				if(!element.tile.t5.leaf)
					stack.insert(StackElement(t5reg, NodeTile(), element.tile, 5));
				if(!element.tile.t6.leaf)
					stack.insert(StackElement(t6reg, NodeTile(), element.tile, 6));
				if(!element.tile.t7.leaf)
					stack.insert(StackElement(t7reg, NodeTile(), element.tile, 7));
					
				element.parent.getTexelPointer(element.parentTexel).setAddress(lastTilePos+1);	
				tileApp.put(element.parent);
				lastTilePos++;
				
				//listSize(stack);
				//debugList(stack, (StackElement el) { dbg(el.region.nicestr); });
				//pause();
			}
		}
		
		/**
		*	Checks if data massive has cube form. If it does return $(B true), $(B false) otherwise.
		*	If check successes, returns constant cube size in $(B sizex), $(B sizey), $(B sizez). 
		*/
		bool checkCubeSize(uint[][][] data, out size_t sizex, out size_t sizey, out size_t sizez)
		{
			sizex = sizey = sizez = 0;
			if(data is null)
			{
				return false;
			}
			
			sizex = data.length;
			if(sizex != 0)
			{
				sizey = data[0].length;
			}
			for(size_t x = 0; x < sizex; x++)
			{
				if(data[x].length != sizey)
				{
					return false;
				}
				sizey = data[x].length;
			}
			
			if(sizey != 0)
			{
				sizez = data[0][0].length;
			}
			for(size_t x = 0; x < sizex; x++)
			{
				for(size_t y = 0; y < sizey; y++)
				{
					if(data[x][y].length != sizez)
					{
						return false;
					}
					sizez = data[x][y].length;
				}
			}
			
			return true; 
		}
		
		/**
		*	Checks if $(B data) massive fully consists of constant value and returns this $(B value).
		*	Warning: Functions consider non zero sized array.
		*/
		bool isDataHomogenius(uint[][][] data, DataRegion region, out uint value)
		{
			value = data[0][0][0];
			for(size_t x = region.x1; x < region.x2; x++)
			{
				for(size_t y = region.y1; y < region.y2; y++)
				{
					for(size_t z = region.z1; z < region.z2; z++)
					{
						if(data[x][y][z] != value)
						{
							value = 0;
							return false;
						}
					}
				}
			}
			return true;
		}
	}
	
	protected
	{
		int rootNode = 0;
		PagePool!(NodeTile.sizeof) 		childPool;
		CBuffer 						brickPool;
		CBuffer 						normalPool;
		vec3st	mBrickPoolSize;

		/**
		*	Memory block/page for storing node child info.
		*
		*	Layer z = 0:	
		*	
		*	0----> X
		*	|    ______ ______
		*	|   |      |      |
		*	V   |  0   |  1   |
		*	Y   |______|______|
		*	    |      |      |
		*	    |  2   |  3   |
		*	    |______|______|
		*
		*	Layer z = 1:
		*
		*	0----> X
		*	|    ______ ______
		*	|   |      |      |
		*	V   |  4   |  5   |
		*	Y   |______|______|
		*	    |      |      |
		*	    |  6   |  7   |
		*	    |______|______|
		*
		*	Node field structure:
		*    1 1                 30
		*	-----------------------------------------
		*	| | |                                   |
		*	| | |             Address               |
		*   | | |                                   |
		*	-----------------------------------------
		*	                 32
		*
		*	First bit: leaf flag (1 - this node is a leaf).
		*	Second bit: data type (1 - constant value, 0 - brick value)
		*
		*	Color/Brick field structure:
		*        8         8         8          8
		*	-----------------------------------------
		*	|         |         |         |          |
		*	|    R    |    G    |    B    |     A    |
		*   |         |         |         |          |
		*	-----------------------------------------
		*	                 32
		*	or
		*     2      10            10          10
		*	------------------------------------------
		*	|   |           |             |           |
		*	|   |     X     |      Y      |     Z     |
		*   |   |           |             |           |
		*	------------------------------------------
		*	                 32
		*/
		align(4) struct NodeTile
		{
			align(4) struct NodeTexel
			{
				uint address;
				uint color;
				
				void setBrickAddress(size_t x, size_t y, size_t z)
				{
					color = 0;
					
					color += (z & 0x3FF);
					color += (y & 0x3FF) << 10;
					color += (x & 0x3FF) << 20;
				}
				
				void setAddress(uint value, bool isLeaf, bool isConstant)
				{
					address = 0;
					if(isLeaf)
					{
						address += 1 << 31; 
					}
					if(isConstant)
					{
						address += 1 << 30;
					}
					
					address += value & 0x3FFFFFFF;
				}
				
				void setAddress(uint value)
				{
					address = address & 0xC0000000;
					address += value & 0x3FFFFFFF;
				}
				
				bool leaf() @property
				{
					return ((address >> 31) & 0x01) == 1;
				}
				
				bool constant() @property
				{
					return ((address >> 30) & 0x01) == 1;
				}
			}
			NodeTexel t0, t1, t2, t3, t4, t5, t6, t7;
			
			NodeTexel* getTexelPointer(byte i)
			{
				switch(i)
				{
					case 0:
						return &t0;
					case 1:
						return &t1;
					case 2:
						return &t2;
					case 3:
						return &t3;
					case 4:
						return &t4;
					case 5:
						return &t5;
					case 6:
						return &t6;
					case 7:
						return &t7;
					default:
						return null;
				}
			}
		}
	}
}

//======================================================================================
// Unit testing
//======================================================================================
version(unittest)
{
	uint[][][] genSizedArray(size_t sizex, size_t sizey, size_t sizez)
	{
		uint[][][] data = new uint[][][sizex];
		foreach(ref yzslice; data)
		{
			yzslice = new uint[][sizey];
			foreach(ref zslice; yzslice)
			{
				zslice = new uint[sizez];
			}
		}
		return data;
	}
	
	uint[][][] genTestColorData1()
	{
		enum size = 4;
		uint[][][] data = genSizedArray(size, size, size);
		
		data[0][0][0] = ColorRGBA.fastCompact(255, 0, 0, 255);
		
		data[0][2][0] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[0][3][0] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[1][2][0] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[1][3][0] = ColorRGBA.fastCompact(0, 255, 0, 255);
		
		data[0][2][1] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[0][3][1] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[1][2][1] = ColorRGBA.fastCompact(0, 255, 0, 255);
		data[1][3][1] = ColorRGBA.fastCompact(0, 255, 0, 255);
		
		data[3][3][0] = ColorRGBA.fastCompact(0, 0, 255, 255); 
		return data;
	}
	
	uint[][][] genTestNormalData1()
	{
		enum size = 4;
		uint[][][] data = genSizedArray(size, size, size);
		
		data[0][0][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		
		data[0][2][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[0][3][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[1][2][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[1][3][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		
		data[0][2][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[0][3][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[1][2][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		data[1][3][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
		
		data[3][3][0] = NormalVectorDistr.fastCompact(1, 0, 0, 2.1);
		
		return data;
	}
	
	string tobits(uint value)
	{
		string ret = "";
		for(int i = 8*uint.sizeof-1; i >= 0; i--)
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
unittest
{
	import std.stdio;
	import std.math;
	import std.conv;
	
	write("Testing octree module...");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	StdOctree.NodeTile.NodeTexel texel;
	texel.setAddress(0, true, false);
	assert(texel.leaf, "Texel leaf property has broken! "~tobits(texel.address));
	
	uint test1 = NormalVectorDistr.fastCompact(0, -1, 0, 0.5);
	float disp = NormalVectorDistr(test1).dispertion;
	assert(approxEqual(disp, 0.5, 0.1), "Dispertion NDF bug! "~to!string(disp));
	 
	uint[][][] data = genTestColorData1();
	uint[][][] norm = genTestNormalData1();
	StdOctree octree1 = new StdOctree(data, norm);
}