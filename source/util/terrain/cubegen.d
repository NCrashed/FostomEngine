// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*/
module util.terrain.cubegen;

class CubeGenerator
{
	static T[][][] generate(T)(size_t x, size_t y, size_t z, T delegate(size_t, size_t, size_t) getValFunc)
	{
		T[][][] buff = new T[][][z];

		foreach(ref arr1; buff)
		{
			arr1 = new uint[][y];
			foreach(ref arr2; arr1)
				arr2 = new uint[x];
		}

		for(size_t i=0; i<x; i++)
			for(size_t j=0; j<y; j++)
				for(size_t k=0; k<z; k++)
				{
					buff[i][j][k] = getValFunc(i,j,k);
				}

		return buff;
	}	
}