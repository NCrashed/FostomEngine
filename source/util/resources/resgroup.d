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
*   Группа ресурсов.
*
*	@file resgroup.d Все ресурсы объединяются в группы, для удобного поиска и доступа. 
*	Каждая группа содержит несколько архивов с разными источниками. В основном группы 
*	ресурсов загружаются из файла настроек.
*/
module util.resources.resgroup;

public import util.resources.resource;
import util.resources.archivemng;
import util.log;
import std.array;

/// Структура для загрузки из файла
struct LoadedResGroup
{
	string name;
	struct ResGroupEntry
	{
		string path;
		string type;
	} ResGroupEntry[] entries;
}

/// Группа ресурсов
/**
*	Объединяет несколько источников ресурсов (архивы)
*	в общую группу для удобного поиска.
*/
class ResourceGroup
{
	/// Конструктор
	/**
	*	@par name Имя группы ресурсов
	*/
	this(string name)
	{
		mName = name;
		mArchives = new Archive[0];
	}

	/// Получение имени группы
	@property string name()
	{
		return mName;
	}

	/// Получение главного пути
	@property string basePath()
	{
		if(mArchives.length == 0)
			throw new Exception("Archive "~name~" has no entries to return basePath!");

		return mArchives[0].name;
	}

	/// Добавление архива в группу
	/**
	*	@par arch уже открытый архив.
	*/
	void addEntry(Archive arch)
	{
		if(!arch.isOpened())
		{
			writeLog("Tried to add closed archive to resource group "~mName, LOG_ERROR_LEVEL.WARNING);
			return;
		}
		mArchives ~= arch;
	}

	/// Добавление архива в группу
	/**
	*	@par path Путь до ахрива
	*	@par type Тип архива, например FileSystem
	*/
	void addEntry(string path, string type, FileMode mode = FileMode.In)
	{
		if (!ArchiveMng.getSingleton().isRegistered(type))
		{
			writeLog("Archive type "~type~" not registered, canceled adding "~path~" to "~mName, LOG_ERROR_LEVEL.WARNING);
			return;
		}
		auto arch = ArchiveMng.getSingleton().createArchive(type);
		arch.open(path, mode);
		mArchives ~= arch;
	}

	/// Загрузка группы ресурсов из файла
	/**
	*	@par st Структура, загруженная из файла
	*	Большей частью этот метод нужен для ресурсного менеджера,
	*	но никто не запрещает заполнять структуру самим.
	*/
	void loadFromStruct(LoadedResGroup st)
	{
		mName = st.name;
		foreach(entry; st.entries)
		{
			addEntry(entry.path, entry.type);
		}
	}

	/// Получение ресурса по имени
	/**
	*	Поиск производится по всем подключенным архивам.
	*	@par name Полное имя ресурса от корня препологаемого архива
	*	@par recursive Рекусривный поиск по всем архивам и всему архиву
	*	@todo Добавить поддержку рекурсивного поиска и отркытия
	*/
	Stream openFile(string name, out string fullname, bool recursive = false)
	{
		fullname = "";
		// Проверка в кеше
		if( name == lastName && lastRecursive == recursive)
		{
			fullname = lastArch.name~"/"~name;
			return lastArch.openFile(name, FileMode.In);
		}

		foreach(arch; mArchives)
			if(arch.hasFile(name, recursive))
			{
				fullname = arch.name~"/"~name;
				return arch.openFile(name, FileMode.In);
			}
		throw new Exception("File "~name~" doesn't belong to gorup "~mName);		
	}

	/// Проверка, присутствует ли файл в группе
	/**
	*	Запрос кешируется для использования в openFile
	*	@par name Полное имя ресурса от корня препологаемого архива
	*	@par recursive Рекусривный поиск по всем архивам и всему архиву
	*/
	bool hasFile(string name, bool recursive = false)
	{
		if (name.empty) return false;
		foreach(arch; mArchives)
			if(arch.hasFile(name, recursive))
			{
				lastName = name;
				lastRecursive = recursive;
				lastArch = arch;
				return true;
			}
		return false;
	}
private:

	string mName;
	/// Список подключенных архивов
	Archive[] mArchives;

	/// Переменные для кеширования
	string lastName;
	bool lastRecursive;
	Archive lastArch;
}