// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Преобразование kd дерева в модель
*
*/
module client.model.kdmodelcodec;

import util.terrain.kdtree;
import util.codecmng;
import util.codec;
import util.log;
import util.vector;

import util.standarts.model;
import util.generators.cubegen;
import util.serialization.serializer;

/** Кодек для преобразования kd-дерева в модель
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
class KdtreeModelCodec : Codec
{
public:

	/// Получение уникального идентификатора кодека
	@property string type()
	{
		return "kdtree";
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
	/**
	*	@par data В поток записывается указатель на kd-дерево.
	*/
	Stream decode(Stream data)
	{
		import std.stdio;

		/// Создание коробки из координат
		void constructBox(ref TempModel.MeshInfo info, ref StdKdTree.LeafInfo leaf)
		{
			TempModel box;
			with(leaf)
				box = CubeGenerator.generate(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z);

			info.attach(box.meshes[0]);
		}

		StdKdTree tree = null;
		data.readExact(cast(void*)&tree, StdKdTree.sizeof);
		bool loadWire;
		data.readExact(cast(void*)&loadWire, loadWire.sizeof);
		
		TempModel ret;
		ret.meshes = new TempModel.MeshInfo[1];
		// 1 меш для конечных листьев, 1 для узлов
		ret.meshes[0].init();
		

		foreach(leaf; tree.leafs)
			if(leaf.colorIndex != 0)
			{
				writeln("Constructing box for ", leaf);
				constructBox(ret.meshes[0], leaf);
				writeln("Verts count: ", ret.meshes[0].vecs.length);
			}

		/*if(loadWire)
		{
			ret.meshes ~= TempModel.MeshInfo();
			ret.meshes[1].init();
			foreach(node; tree.nodes)
			{
				constructBox(ret.meshes[1], node);
			}
		}*/
		return convertDecoded2Stream(ret);
	}

	/// Кодирование исходных данных
	Stream code(Stream data)
	{
		throw new Exception("Kdtree coding not implemented!");
	}

private:

	Stream convertDecoded2Stream(ref TempModel info)
	{
		ModelStandart modelInfo = info.finalize();

		auto stream = serialize!BinaryArchive(modelInfo);
		stream.position = 0;
		
		return stream;
	}

}

static this()
{
	CodecMng.getSingleton().registerCodec(new KdtreeModelCodec);
}