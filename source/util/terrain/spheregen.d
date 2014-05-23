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
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*/
module util.terrain.spheregen;

/// Генератор эллипсоидов
/**
*	Ландшафтный генератор, который умеет создавать сферы и эллипсоиды.
*/
class SphereGenerator
{
	/**
	*	Создание эллипсоида на основе размеров по каждой оси (x,y,z).
	*	С помощью $(B getValFunc) можно заполнять фигуру различными значениями.
	*/
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
					if((i-x/2)*(i-x/2)/(cast(double)x*x/4)+(j-y/2)*(j-y/2)/(cast(double)y*y/4)+(k-z/2)*(k-z/2)/(cast(double)z*z/4) <= 1)
					{
						buff[i][j][k] = getValFunc(i,j,k);
					}
				}

		return buff;
	}
}