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
*   Кодек для декодирования моделей в obj формате
*	
*   Кодек для декодирования моделей в obj формате
*/
module client.model.objcodec;

import util.codecmng;
import util.serialization.serializer;

import client.model.model;
import util.codec;
import util.common;
import util.log;
import util.vector;

import std.string;
import std.array;
import std.conv;
import std.typetuple;
import std.stdio;

struct DecodedInfo
{
	vec3 vecs[];
	vec2 uvs[];
	vec3 normals[];
	vec3ui faces[][];
}

/** Кодек для декодирования моделей в obj формате
*	@note Формат выходного потока данных 'model': 
*	uint mesh_count;
*	{
*		uint vertex_count;
*		float[vertex_count] vecs;
*		uint uvs_count;
*		float[uvs_count] uvs;
*		uint normals_count;
*		float[normals_count] normals;
*		uint indexes_count;
*		unit[indexes_count] indexes;
*	} mesh_count
*/
class ObjCodec : Codec
{
public:
	/// Получение уникального идентификатора кодека
	@property string type()
	{
		return "obj";
	}

	/// Стандарт потока данных, который обеспечивает кодек
	/**
	*	Т.к. кодек возвращает поток данных, то нужно знать формат этого потока.
	*	Возвращаемая строка является именем стандарта, например "model", "image" и т.д.
	*	Стандарты описываются обычно в файлах с ресурсами, которые и пользуют кодеки.
	*/
	@property string standart()
	{
		return "model";
	}

	/// Декодирование данных 
	Stream decode(Stream data)
	{

		DecodedInfo res;
		res.vecs = new vec3[0];
		res.uvs = new vec2[0];
		res.normals = new vec3[0];
		res.faces = new vec3ui[][0];

		while(!data.eof)
		{
			auto buff = data.readLine();

			if(buff.empty) continue;

			string s = buff.idup;

			// Удаление комментов
			s = strip(removeAfter(s, "#"));
			if(s.empty) continue;

			auto words = split(s, " ");

			//writeln(words);
			auto resKey = commutateByKey(words[0], keys, words[1..$],
			(string[] args) // f
			{
				if(args.length != 3) throw new Exception("ObjCodec: Failed to load model, f key has invalid values count");
				vec3ui temp[3];

				foreach(i,arg; args)
				{
					auto indx = split(arg,"/");
					temp[i].x = to!uint(indx[0])-1;
					temp[i].y = to!uint(indx[1])-1;
					temp[i].z = to!uint(indx[2])-1;
				}

				res.faces ~= temp.dup;

				return 0;
			},
			(string[] args) // s
			{
				return 0;
			},
			(string[] args) // usemtl
			{
				return 0;
			},
			(string[] args) // vn
			{
				if(args.length != 3) throw new Exception("ObjCodec: Failed to load model, vn key has invalid values count");

				float x = to!float(args[0]);
				float y = to!float(args[1]);
				float z = to!float(args[2]);

				res.normals ~= vec3(x,y,z);
				
				return 0;
			},
			(string[] args) // vt
			{
				
				if(args.length != 2) throw new Exception("ObjCodec: Failed to load model, vt key has invalid values count");
				float x = to!float(args[0]);
				float y = to!float(args[1]);

				res.uvs ~= vec2(x,y);
				
				return 0;
			},
			(string[] args) // v
			{	
				if(args.length != 3) throw new Exception("ObjCodec: Failed to load model, v key has invalid values count");
				float x = to!float(args[0]);
				float y = to!float(args[1]);
				float z = to!float(args[2]);

				res.vecs ~= vec3(x,y,z);
				
				return 0;
			},
			(string[] args) // mtllib
			{
				return 0;
			});
			if (resKey < 0) writeLog("ObjCodec: Detected unknown key "~words[0]);
		}
 	
		lastDecode = res;
		return convertDecoded2Stream(res);
	}

	/// Кодирование исходных данных
	Stream code(Stream data)
	{
		throw new Exception("Obj coding not implemented!");
	}

	/// Получения инфы о последней расшифровке
	@property DecodedInfo info()
	{
		return lastDecode;
	}

private:
	static string[] keys = ["f","s","usemtl","vn","vt","v","mtllib"];


	Stream convertDecoded2Stream(ref DecodedInfo info)
	{
		ModelStandart modelStnd;
		modelStnd.meshes = new ModelStandart.MeshInfo[1];
		
		with(modelStnd.meshes[0])
		{
			vecs 	= new float[0];
			uvs 	= new float[0];
			normals = new float[0];
			indexes = new uint[0];
			
			foreach(ref inds; info.faces)
			{

				foreach(ref ind; inds)
				{
					/// Проверяет, есть ли уже в массиве вершина с данным набором параметров
					bool listedInVBO(ref vec3 vec, ref vec2 uv, ref vec3 norm, out uint index)
					{
						for(uint i=0; i<cast(uint)(vecs.length/3); i++)
							if( vecs[3*i] == vec.x && vecs[3*i+1] == vec.y, vecs[3*i+2] == vec.z && 
								uvs[2*i] == uv.x && uvs[2*i+1] == uv.y && 
								normals[3*i] == norm.x && normals[3*i+1] == norm.y && normals[3*i+2] == norm.z)
							{
								index = i;
								return true;
							}
						index = 0;
						return false;

					}

					uint index = 0;
					if( !listedInVBO( info.vecs[ind[0]], info.uvs[ind[1]], info.normals[ind[2]], index))
					{
						// Добавляем в VBO
						vec3 temp = info.vecs[ind[0]];
						vecs ~= temp.x;
						vecs ~= temp.y;
						vecs ~= temp.z;

						vec2 temp2 = info.uvs[ind[1]];
						uvs ~= temp2.x;
						uvs ~= temp2.y;

						temp =  info.normals[ind[2]];
						normals ~= temp.x;
						normals ~= temp.y;
						normals ~= temp.z;

						indexes ~= cast(uint)(vecs.length-3)/3;
					}
					else
					{
						// Уже есть в буфере, добавляем только индекс
						indexes ~= index;
					}
				}
			}
		}

		return serialize!BinaryArchive(modelStnd);
	}

	DecodedInfo lastDecode;
}

static this()
{
	CodecMng.getSingleton().registerCodec(new ObjCodec);
}