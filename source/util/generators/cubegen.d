// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Генератор различных кубов и его производных.
*/
module util.generators.cubegen;

import util.standarts.model;
import util.vector;

/**
*	Умеет генерировать меши кубов и параллепипедов с различными параметрами
*	и текстурными развертками.
*/
class CubeGenerator
{
	/**
	*	Генерация параллепипеда, каждая грань будет независимой и занимать всю текстуру.
	*	Куб задается с помощью двух диагональных точек с координатами $(B (x1,y1,z1)) и $(B (x2,y2,z2)).
	*	$(B startIndex) задает смещение в индексах, на случай, если полученный куб будет присоединен к другой модели.
	*/
	static TempModel generate(float x1, float y1, float z1, float x2, float y2, float z2, uint startIndex = 0)
	{
		TempModel ret;
		ret.meshes = new TempModel.MeshInfo[1];

		with(ret.meshes[0])
		{
			vecs = new vec3[24];
			uvs = new vec2[24];
			normals = new vec3[24];
			indexes = new vec3ui[12];

			// Генерация граней
			//1
			vecs[0] 	= vec3(x1,y1,z1);
			normals[0] 	= vec3(0,-1,0);
			uvs[0] 		= vec2(0,1);

			vecs[1]		= vec3(x1,y1,z2);
			normals[1]	= vec3(0,-1,0);
			uvs[1]		= vec2(0,0);

			vecs[2]		= vec3(x2,y1,z2);
			normals[2]	= vec3(0,-1,0);
			uvs[2]		= vec2(1,0);

			vecs[3]		= vec3(x2,y1,z1);
			normals[3]	= vec3(0,-1,0);
			uvs[3]		= vec2(1,1);

			//2
			vecs[4] 	= vec3(x2,y1,z1);
			normals[4] 	= vec3(1,0,0);
			uvs[4] 		= vec2(0,1);

			vecs[5] 	= vec3(x2,y1,z2);
			normals[5] 	= vec3(1,0,0);
			uvs[5] 		= vec2(0,0);

			vecs[6] 	= vec3(x2,y2,z2);
			normals[6] 	= vec3(1,0,0);
			uvs[6] 		= vec2(1,0);

			vecs[7] 	= vec3(x2,y2,z1);
			normals[7] 	= vec3(1,0,0);
			uvs[7] 		= vec2(1,1);

			//3
			vecs[8] 	= vec3(x2,y2,z1);
			normals[8] 	= vec3(0,1,0);
			uvs[8] 		= vec2(0,1);

			vecs[9] 	= vec3(x2,y2,z2);
			normals[9] 	= vec3(0,1,0);
			uvs[9] 		= vec2(0,0);

			vecs[10] 	= vec3(x1,y2,z2);
			normals[10] = vec3(0,1,0);
			uvs[10] 	= vec2(1,0);

			vecs[11] 	= vec3(x1,y2,z1);
			normals[11] = vec3(0,1,0);
			uvs[11] 	= vec2(1,1);

			//4
			vecs[12] 	= vec3(x1,y2,z1);
			normals[12] = vec3(-1,0,0);
			uvs[12] 	= vec2(0,1);

			vecs[13] 	= vec3(x1,y2,z2);
			normals[13] = vec3(-1,0,0);
			uvs[13] 	= vec2(0,0);

			vecs[14] 	= vec3(x1,y1,z2);
			normals[14] = vec3(-1,0,0);
			uvs[14] 	= vec2(1,0);

			vecs[15] 	= vec3(x1,y1,z1);
			normals[15] = vec3(-1,0,0);
			uvs[15] 	= vec2(1,1);

			//5
			vecs[16] 	= vec3(x1,y1,z2);
			normals[16] = vec3(0,0,1);
			uvs[16] 	= vec2(0,1);

			vecs[17] 	= vec3(x1,y2,z2);
			normals[17] = vec3(0,0,1);
			uvs[17] 	= vec2(0,0);

			vecs[18] 	= vec3(x2,y2,z2);
			normals[18] = vec3(0,0,1);
			uvs[18] 	= vec2(1,0);

			vecs[19] 	= vec3(x2,y1,z2);
			normals[19] = vec3(0,0,1);
			uvs[19] 	= vec2(1,1);

			//6
			vecs[20] 	= vec3(x1,y2,z1);
			normals[20] = vec3(0,0,-1);
			uvs[20] 	= vec2(0,1);

			vecs[21] 	= vec3(x1,y1,z1);
			normals[21] = vec3(0,0,-1);
			uvs[21] 	= vec2(0,0);

			vecs[22] 	= vec3(x2,y1,z1);
			normals[22] = vec3(0,0,-1);
			uvs[22] 	= vec2(1,0);

			vecs[23] 	= vec3(x2,y2,z1);
			normals[23] = vec3(0,0,-1);
			uvs[23] 	= vec2(1,1);				
			
			// Треугольники
			indexes[0] = vec3ui(3,1,0);
			indexes[1] = vec3ui(2,1,3);

			indexes[2] = vec3ui(7,5,4);
			indexes[3] = vec3ui(6,5,7);

			indexes[4] = vec3ui(11,9,8);
			indexes[5] = vec3ui(10,9,11);

			indexes[6] = vec3ui(15,13,12);
			indexes[7] = vec3ui(14,13,15);

			indexes[8] = vec3ui(19,17,16);
			indexes[9] = vec3ui(18,17,19);

			indexes[10] = vec3ui(23,21,20);
			indexes[11] = vec3ui(22,21,23);

			// Смещаем индексы
			foreach(ref ind; indexes)
			{
				ind.x = ind.x+startIndex;
				ind.y = ind.y+startIndex;
				ind.z = ind.z+startIndex;
			}
		}
		return ret;
	}
}