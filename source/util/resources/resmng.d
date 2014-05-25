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
*   Менеджер ресусров
*
*	Менеджер управляет ресурсными группами, отвечает на запросы доступа к ресурсам.
*/
module util.resources.resmng;

public
{
	import util.resources.resgroup;
	import std.stream;
}

import std.regex;
import std.algorithm;

import util.singleton;
import util.log;
import util.conf;

enum DEFAULT_RESGROUP_CONFIG = "resources";

/// Загружаемая из файла структура
struct ResManagerConfig
{
	LoadedResGroup[] resGroups;
}

/// Менеджер ресурсов
/**
*	Менеджер ресурсов занимается управлением группами ресурсов,
*	позволяет быстро и легко получить нужный ресурс по имени.
*/
class ResourceMng
{
	mixin Singleton!ResourceMng;

	/// Конструктор
	private this()
	{
		mGroups = new ResourceGroup[0];
		mResFactories = new ResourceFactory[0];
	}

	/// Получение массива групп ресурсов
	/**
	*	Получение массива групп ресурсов, зарегистрированных в системе.
	*	Изменение массива запрещено, для этого используются другие методы класса,
	*	но можно изменять отдельные группы.
	*/
	@property const(ResourceGroup[]) groups()
	{
		return mGroups;
	}

	/// Поиск группы по имени
	/**
	*	Возвращает группу с именем group. Если группа не найдена вернет null.
	*/
	ResourceGroup getByName(string resGroup)
	{
		foreach(gr; mGroups)
			if(gr.name == resGroup)
				return gr;
		return null;
	}

	/// Загрузка всех ресурсных групп из файла
	/**
	*	@par filename Имя файла, он будет искаться в папке с конфигами
	*/
	void loadGroupsFromFile(string filename = DEFAULT_RESGROUP_CONFIG)
	{
		ResManagerConfig st;
		try
		{
			st = readConfCritical!ResManagerConfig(filename);
		} catch(Exception e)
		{
			writeLog("Error by parsing resource config, trying to create valid-one...");
			generateDefaultConfig(filename);
			// Последняя попытка исправить ситуацию
			try
			{
				st = readConfCritical!ResManagerConfig(filename);
			} catch(Exception e2)
			{
				writeLog("Failed to create default resource config. Sorry.", LOG_ERROR_LEVEL.FATAL);
				throw new Exception("Failed to create default resource config. Sorry.");
			}
		}
		
		// Теперь приступаем к загрузке
		foreach(lGroup; st.resGroups)
		{
			auto group = new ResourceGroup("");
			group.loadFromStruct(lGroup);
			mGroups ~= group;
		}
	}

	/// Поиск и открытие файла
	/**
	*	@par resGroup Имя группы ресурсов
	*	@par filename Имя файла
	*/
	Stream loadFile(string filename, string resGroup, out string fullname)
	{
		fullname = "";
		ResourceGroup gr = getByName(resGroup);
		if (gr is null)
		{
			writeLog("Resource group "~resGroup~" isn't exists!", LOG_ERROR_LEVEL.FATAL);
			throw new Exception("Resource group "~resGroup~" isn't exists!");
		}
		return gr.openFile(filename, fullname);
	}

	/// Поиск и получение ресурса
	/**
	*	@par filename Имя файла с ресурсом
	*	@par resGroup Группа, в которой будет проводиться поиск
	*/
	Resource getResource(string filename, string resGroup)
	{ 
		string fullname;
		auto res = getLoadedRes(filename, fullname, resGroup);
		if (res !is null) return res;

		string ext = fetchExt(filename);
		auto fact = getByExt(ext);
		if (fact is null)
		{
			import std.stdio;
			writeLog("Don't know fabric to open resource type "~fetchExt(filename), LOG_ERROR_LEVEL.FATAL);
			throw new Exception("Don't know fabric to open resource type "~fetchExt(filename));
		}
		Stream file = loadFile(filename, resGroup, fullname);

		auto ret = fact.createInstance(file, filename, fullname, ext);
		mResources[filename~resGroup] = ret;
		mFullNames[ret] = fullname;
		return ret;
	}
	
	/// Регистрация фабрики в менджере
	/**
	*	@par fact Экземпляр фабрики
	*	@return true при успехе, false если фабрика конфликует с остальными
	*/
	bool registryFactory(ResourceFactory fact)
	{
		foreach(ext; fact.getExtentions())
		{
			auto afact = getByExt(ext);
			if (afact !is null) 
			{
				writeLog("Resource fabric "~fact.getType()~" is confilicting with "~afact.getType~" with extention "~ext, LOG_ERROR_LEVEL.WARNING);
				return false;
			}
		}
		mResFactories~= fact;

		return true;
	}

	/// Удаление фабрики из менеджера
	void unregistryFactory(string type)
	{
		foreach(i,fac; mResFactories)
		{
			if (fac.getType() == type)
			{
				mResFactories = mResFactories[0..i]~mResFactories[i+1..$];
			}
		}
	}

private:
	ResourceGroup[] mGroups;
	Resource[string] mResources;
	string[Resource] mFullNames;
	ResourceFactory[] mResFactories;

	/// Генерация конфига по умолчанию
	/**
	*	Ручной лобовой метод, не пинайте сильно
	*/
	void generateDefaultConfig(string filename)
	{
		ResManagerConfig st;
		st.resGroups = new LoadedResGroup[3];
		st.resGroups[0].name = "General";
		st.resGroups[0].entries = new LoadedResGroup.ResGroupEntry[5];
		st.resGroups[0].entries[0].path = "../media";
		st.resGroups[0].entries[0].type = "FileSystem";
		st.resGroups[0].entries[1].path = "../media/mextures";
		st.resGroups[0].entries[1].type = "FileSystem";
		st.resGroups[0].entries[2].path = "../media/mhaders";
		st.resGroups[0].entries[2].type = "FileSystem";
		st.resGroups[0].entries[3].path = "../media/models";
		st.resGroups[0].entries[3].type = "FileSystem";
		st.resGroups[0].entries[4].path = "../media/textures/materials";
		st.resGroups[0].entries[4].type = "FileSystem";

		st.resGroups[1].name = "Terrain";
		st.resGroups[1].entries = new LoadedResGroup.ResGroupEntry[1];
		st.resGroups[1].entries[0].path = "../media/merrain";
		st.resGroups[1].entries[0].type = "FileSystem";
		
		st.resGroups[2].name = "Images";
		st.resGroups[2].entries = new LoadedResGroup.ResGroupEntry[1];
		st.resGroups[2].entries[0].path = "../media/images";
		st.resGroups[2].entries[0].type = "FileSystem";

		writeConf(filename, st);
	}

	/// Получение уже загруженного ресурса
	Resource getLoadedRes(string filename, out string fullname, string resgroup)
	{
		fullname = "";
		string nkey = filename~resgroup;
		foreach(key,res; mResources)
			if(key == nkey)
			{
				fullname = mFullNames[res];
				return res;
			}
		return null;
	}

	/// Получение фабрики по расширению
	/**
	*	@return null, если фабрика не найдена
	*/
	ResourceFactory getByExt(string ext)
	{
		foreach(fac; mResFactories)
		{
			auto exts = fac.getExtentions();
			foreach(s;exts)
				if (s == ext)
					return fac;
		}
		return null;
	}	

	/// Поиск фабрики по имени
	ResourceFactory getFabrByName(string name)
	{
		foreach(fac; mResFactories)
		{
			if (fac.getType() == name)
				return fac;
		}
		return null;
	}
	/// Вытащить расширение из имени файла
	/**
	*	@return Если файл без расширения, вернет пустую строку.
	*/
	string fetchExt(string filename)
	{
		auto ctr = regex(`[qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM]*[.]+`);

		auto buff = filename.dup;
		reverse(buff);
  		auto m2 = match(buff, ctr);
  		if(m2)
  		{
  			buff =  m2.captures[0][0..$-1];
			reverse(buff);
			return buff.idup;
  		} else return "";
	}

	unittest
	{
		auto mng = ResourceMng.getSingleton();
		assert(mng.fetchExt("file.png") == "png", "Simple test failed: "~mng.fetchExt("file.png"));
		assert(mng.fetchExt("file.ext1.ext2") == "ext2", "Complex test failed: "~mng.fetchExt("file.ext1.ext2"));
		assert(mng.fetchExt("file") == "", "Invalid test failed: "~mng.fetchExt("file"));
	}
}