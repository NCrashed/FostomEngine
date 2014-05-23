// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Основной интерфейс моделей.
*
*	Класс задает интерфейс для конкретизаций моделей и определеяет
*	необходимые общие методы. Все модели, загружаемые или генерируемые являются 
*	потомками этого класса.
*/
module client.model.model;

import util.resources.resmng;
import util.codecmng;
import util.vector;
import util.log;

import util.codec;
import util.terrain.kdtree;
import util.serialization.serializer;

public import client.model.mesh;
public import client.model.material;

import std.stream;
import std.conv;

public import util.standarts.model;

/// Класс модели
/**
*	Содержит всю необходимую информацию о модели: буферы вершин, текстурных
*	координат, нормалей.
*	Использует стандарт для кодека: 'model'
*	@note Формат потока данных 'model': 
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
class Model : Resource
{
	/// Получение имени ресурса
	@property string name()
	{
		return mName;
	}

	/// Инициализация ресурса
	void init(string name, string ext)
	{
		mName = name;

		try
		{
			mCodec = CodecMng.getSingleton().getCodec(ext);
		} catch(Exception e)
		{
			writeLog("Cannot get codec for model format "~ext~". Remove format from list of models or implement codec!");
			mCodec = null;
		}

		if(mCodec.standart != "model")
		{
			writeLog("Codec for model format "~ext~" doesn't support standart 'model'! Restricted.");
			mCodec = null;
		}
	}

	/// Отрисовка модели
	/**
	*	@par dt Время, прошедшее с предыдущего кадра
	*/
	void draw(double dt)
	{

	}

	/// Загрузка ресурса и подготовка к использованию
	void load(Stream file, string filename)
	{
		// Инициализация завершилась неуспешно
		if (mCodec is null) return;

		scope(failure)
		{
			writeLog("Failed to load model "~mName~"!", LOG_ERROR_LEVEL.FATAL);
		}

		auto stream = mCodec.decode(file);

		loadFromStream(stream);
	}

	/// Загрузка из kd-дерева
	/**
	*	В большинстве случаев модель загружается из файла, но есть возможность
	*	загрузить вручную.
	*/
	void load(StdKdTree tree, bool loadWire = false)
	{
		// Загружаем кодек
		try
		{
			mCodec = CodecMng.getSingleton().getCodec("kdtree");
			if(mCodec.standart != "model")
			{
				throw new Exception("Kdtree codec doesn't support 'model' stream format standart!");
			}
		} 
		catch(Exception e)
		{
			writeLog("Failed to load model from tree. Reason: "~e.msg, LOG_ERROR_LEVEL.FATAL);
			return;
		}

		// Запись указателя в поток
		auto tempStream = new MemoryStream();
		//tempStream.reserve((StdKdTree*).sizeof);

		tempStream.writeExact(cast(void*)&tree, size_t.sizeof);
		tempStream.writeExact(cast(void*)&loadWire, loadWire.sizeof);
		tempStream.position = 0;

		// Декодирование и загрузка
		auto stream = mCodec.decode(tempStream);
		loadFromStream(stream);
	}

	/// Получение субмешей
	@property Mesh[] meshes()
	{
		return mMeshes;
	}

	/// Выгрузка ресурса с возможностью загрузки
	void unload()
	{
		mMeshes = new Mesh[0];
	}

	/// Создание копии модели
	Model dup() @property
	{
		auto ret = new Model;
		ret.mName = mName;
		ret.mCodec = mCodec;

		ret.mMeshes = new Mesh[mMeshes.length];
		foreach(i, ref mesh; ret.mMeshes)
			mesh = mMeshes[i].dup;

		return ret;
	}
	
private:
	string mName;
	Codec mCodec;

	Mesh[] mMeshes;
private:

	/// Загружает модель уже из раскодированного потока
	/**
	*	@par stream поток стандарта 'model'.
	*/
	void loadFromStream(Stream stream)
	{

		ModelStandart modelStr;
		try
		{
			modelStr = deserialize!(BinaryArchive, ModelStandart)(stream);
		}
		catch(Exception e)
		{
			writeLog(text("Failed to load model ", mName, ". Reason: ", e.msg), LOG_ERROR_LEVEL.WARNING);
			return;
		}

		if(!modelStr.checkFormat())
		{
			writeLog(text("Failed to load model ", mName, ". Wrong stream format."), LOG_ERROR_LEVEL.WARNING);
			return;
		}

		foreach(meshi; modelStr.meshes)
			with(meshi)
			{
				auto mesh = new Mesh;
				mesh.init(
					vecs,
					uvs,
					normals,
					indexes);
				
				mMeshes ~= mesh;
			}
	}
}

/// Фабрика ресурсов
/**
*	Предназначена для распознования файлов и созадния
*	нужного вида ресурса. Каждый тип ресурса реализует
*	этот интерфейс и регистрирует фабрику в менеджере 
*	ресурсов.
*/
class ModelFactory : ResourceFactory
{
	/// Идентификатор фабрики
	string getType() 
	{
		return "ModelFactory";
	}

	/// Получить список расширений, которые поддерживает эта фабрика
	/**
	*	@note Если менеджер обнаружит конфликты, непременно начнет ругаться
	*/
	string[] getExtentions()
	{
		return ["obj","kdtree"];
	}

	/// Создание экземпляра ресурса
	/**
	*	@par file Открытый файл с ресурсом.
	*/
	Resource createInstance(Stream file, string name, string filename, string ext)
	{
		auto res = new Model();
		res.init(name, ext);
		res.load(file, filename);
		return res;
	}
}

static this()
{
	ResourceMng.getSingleton().registryFactory(new ModelFactory);
}