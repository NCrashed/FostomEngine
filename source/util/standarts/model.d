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
*
*	Структура стандарта данных для моделей, используется для передачи данных от генераторов в ресурсы.
*/
module util.standarts.model;

import util.vector;

/**
*	Готовые данные для модели, из которых можно собрать полноценный ресурс. Содержит в себе несколько
*	мешей (подгеометрий). Каждый меш содежит в себе массив вершин, нормалей и текстурных координат.
*	Размеры этих массивов должны совпадать, каждой вершине по одной нормали и uv-вектору. Треугольники
*	записаны в массиве indexes индексами вершин по часовой стрелке.
*/
struct ModelStandart
{
	struct MeshInfo
	{
		float[] vecs;
		float[] uvs;
		float[] normals;
		uint[] indexes;

		bool checkFormat()
		{
			return vecs.length == normals.length && vecs.length%3 == 0 && uvs.length%2 == 0 && normals.length%3 == 0;
		}

		void init()
		{
			vecs = new float[0];
			uvs = new float[0];
			normals = new float[0];
			indexes = new uint[0];
		}
	}

	MeshInfo[] meshes;

	bool checkFormat()
	{
		foreach(mesh; meshes)
			if(!mesh.checkFormat())
				return false;
		return true;
	}
}

/**
*	Промежуточное представление модели, удобное для модификации, но еще не готовое
*	к отображению.
*/
struct TempModel
{
	struct MeshInfo
	{
		vec3[] vecs;
		vec2[] uvs;
		vec3[] normals;
		vec3ui[] indexes;

		bool checkFormat()
		{
			return vecs.length == normals.length;
		}

		void init()
		{
			vecs = new vec3[0];
			uvs = new vec2[0];
			normals = new vec3[0];
			indexes = new vec3ui[0];
		}

		/**
		*	Добавляет все вершинны из $(B info) и связанную с ними информацию в меш.
		*/
		void attach(ref TempModel.MeshInfo info)
		{
			// пересчитываем индексы
			auto temp = info.indexes.dup;
			foreach(ref val; temp)
			{
				val.x = cast(uint)(val.x + vecs.length);
				val.y = cast(uint)(val.y + vecs.length);
				val.z = cast(uint)(val.z + vecs.length);
			}
			
			vecs ~= info.vecs;
			uvs ~= info.uvs;
			normals ~= info.normals;
			indexes ~= temp;
		}
	}

	MeshInfo[] meshes;

	bool checkFormat()
	{
		foreach(mesh; meshes)
			if(!mesh.checkFormat())
				return false;
		return true;
	}

	/**
	*	Преобразование временного представления к финальному.
	*/
	ModelStandart finalize()
	{
		ModelStandart ret;
		ret.meshes = new ModelStandart.MeshInfo[meshes.length];
		foreach(i,mesh; meshes)
		{
			ret.meshes[i].init();
			with(ret.meshes[i])
			{
				foreach(v; mesh.vecs)
					vecs ~= v.m;
				foreach(v; mesh.normals)
					normals ~= v.m;
				foreach(v; mesh.uvs)
					uvs ~= v.m;
				foreach(v; mesh.indexes)
					indexes ~= v.m;
			}
		}
		return ret;
	}
}