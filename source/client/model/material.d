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
*   Описание материала меша
*
*	Описывает материал меша, все необходимые его свойства. Текстуры, используемые шейдеры и пр.
*/
module client.model.material;

import util.resources.resource;
import util.resources.resmng;

import util.serialization.serializer;
import util.log;

import derelict.opengl3.gl3;

/// Структура для хранения материала на диске
/**
*	Эта структура загружается и сохраняется на диск с помощью сериализатора. Разбором загруженных данных
*	занимается класс $(B Material).
*/
struct MaterialInfo
{
	struct PolygonMode
	{
		string face;
		string mode;
	}
	PolygonMode[] polyMods;

	string texture;

	/// Копирование
	MaterialInfo dup()
	{
		MaterialInfo ret;
		ret.texture = texture;

		ret.polyMods = new PolygonMode[polyMods.length];
		foreach(i, ref mode; ret.polyMods)
		{
			mode.face = polyMods[i].face;
			mode.mode = polyMods[i].mode;
		}

		return ret;
	}
}

/// Имя, под которым сохраняется материал в файле
enum SAVED_MATERIAL_KEY = "Material";

/// Материал меша
/**
*	Материал определяет настройки видеорежима и шейдеры для конкретного набора вершин в модели. 
*	Материалы грузятся из специальных файлов .material, для этого используется стандарт потока
*	material:
*
*/
class Material : Resource 
{
public:
	/// Получение имени ресурса
	@property string name()
	{
		return mName;
	}

	/// Инициализация ресурса
	/**
	*	@par name Имя ресурса, по которому будет искаться файл.
	*	@par ext Расширение файла, нужно для детекта формата данных.
	*/
	void init(string name, string ext)
	{
		mName = name;
	}

	/// Загрузка ресурса и подготовка к использованию
	void load(Stream file, string filename)
	{
		try
		{
			mInfo = deserialize!(GendocArchive, MaterialInfo)(file, SAVED_MATERIAL_KEY);
		}
		catch(Exception e)
		{
			writeLog("Failed to load material from "~filename~". Reason: "~e.msg, LOG_ERROR_LEVEL.WARNING);
			return;
		}
	}

	/// Выгрузка ресурса с возможностью загрузки
	void unload()
	{
		
	}

	/// Применение настроек рендеринга
	void applyRenderOptions()
	{
		foreach(mode; mInfo.polyMods)
		{
			GLenum faceFlag, modeFlag;
			switch(mode.face)
			{
				case "GL_FRONT":
				{
					faceFlag = GL_FRONT;
					break;
				}
				case "GL_BACK":
				{
					faceFlag = GL_BACK;
					break;
				}
				case "GL_FRONT_AND_BACK":
				{
					faceFlag = GL_FRONT_AND_BACK;
					break;
				}
				default:
				{
					faceFlag = GL_FRONT_AND_BACK;
				}
			}
			switch(mode.mode)
			{
				case "GL_POINT":
				{
					modeFlag = GL_POINT;
					break;
				}
				case "GL_LINE":
				{
					modeFlag = GL_LINE;
					break;
				}
				case "GL_FILL":
				{
					modeFlag = GL_FILL;
					break;
				}
				default:
				{
					modeFlag = GL_FILL;
				}
			}

			glPolygonMode(faceFlag, modeFlag);
		}
	}

	/// Текстура для натягивания на модель
	string texture() @property
	{
		return mInfo.texture;
	}

	/// Копирование материала
	Material dup() @property
	{
		auto ret = new Material;
		ret.mName = mName;
		ret.mInfo = mInfo.dup();
		return ret;
	}
	
private:
	string mName;
	MaterialInfo mInfo;
}

class MaterialFactory : ResourceFactory
{
	/// Идентификатор фабрики
	string getType()
	{
		return "MaterialFactory";
	}

	/// Получить список расширений, которые поддерживает эта фабрика
	/**
	*	@note Если менеджер обнаружит конфликты, непременно начнет ругаться
	*/
	string[] getExtentions()
	{
		return ["material"];
	}

	/// Создание экземпляра ресурса
	/**
	*	@par file Открытый файл с ресурсом.
	*	@par name Имя файла
	*	@par ext Расширение файла, нужно для алгоритмов загрузки
	*/
	Resource createInstance(Stream file, string name, string fullname, string ext)
	{
		auto res = new Material();
		res.init(name, ext);
		res.load(file, fullname);
		return res;		
	}
}

static this()
{
	ResourceMng.getSingleton().registryFactory(new MaterialFactory);
}