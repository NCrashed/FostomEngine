// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Реализация архива для файловой системы.
*
*	Реализация архива для файловой системы. Является
*	основным типом архива. Умеет создавать необходимые папки.
*/
module util.resources.filesys;

public import util.resources.archive;
import util.resources.archivemng;

import std.file;
import std.array;
import util.log;

/// Хранилище ресурсов, реализованное файловой системой
/**
*	Обертка вокруг стандартных средств для работы с файлами.
*/
class FileSys: Archive
{
	/// Открытие архива
	/**
	*	@par name Полный путь до архива вместе с именем
	*	@par mode Режим открытия архива, некоторые режимы могут
	*	не поддерживаться, тогда вызывается исключение.
	*/
	void open(string name, FileMode mode)
	{
		if (!exists(name))
		{
			writeLog("Failed to open directory "~name~". Trying to create...", LOG_ERROR_LEVEL.WARNING);
			try
			{
				mkdir(name);
			}
			catch(Exception e)
			{
				writeLog("Failed to create directory "~name~".", LOG_ERROR_LEVEL.FATAL);
				throw new Exception("Failed to create directory "~name~".");
			}
		}
		if (!attrIsDir(getAttributes(name)))
		{
			writeLog("Tried to open none dir with FileSys archive! At: "~name, LOG_ERROR_LEVEL.FATAL);
			throw new ReadException("Tried to open none dir with FileSys archive! At: "~name);
		}
		dirname = name;
	}

	/// Закрытие архива
	/**
	*	Вызывается также и при удалении объекта. Здесь может 
	*	производится запись данных на диск.
	*/
	void close()
	{
		dirname = "";
	}

	/// Проверка, открыт ли архив.
	bool isOpened()
	{
		return !dirname.empty;
	}

	/// Путь до архива
	@property string name()
	{
		return dirname;
	}

	/// Проверка на наличие файла
	/**
	*	@par name Имя файла относительно корня архива
	*	@par recursive Рекурсивный поиск по всему архиву
	*/
	bool hasFile(string name, bool recursive=false)
	{
		if (dirname.empty)
		{
			writeLog("Tried to read file at closed archive", LOG_ERROR_LEVEL.WARNING);
			return false;
		}
		return exists(dirname~"/"~name);
	}

	/// Получение списка файлов
	/**
	*	@par pattern Шаблон, содержащий спец. символы *,& для выбора только нужных файлов
	*	@par recursive Флаг рекурсивного поиска по всем подпапкам архива
	*	@return Список найденных файлов, их полные имена от корня архива
	*/
	string[] getFileList(string pattern="*", bool recursive=false)
	{
		if (dirname.empty)
		{
			writeLog("Tried to read files list at closed archive", LOG_ERROR_LEVEL.WARNING);
			return new string[0];
		}
		
		// Выбираем режим просмотра вглубь
		SpanMode mode;
		if (recursive) mode = SpanMode.depth;
		else mode = SpanMode.shallow;
		
		// Получаем список файлов и записываем имена
		auto files = dirEntries(dirname, pattern, mode);
		auto ret = new string[0];
		foreach(f; files)
			ret ~= f.name;
		return ret;
	}

	/// Открытие файла для чтения, записи
	/**
	*	@par name Имя файла от корня архива
	*	@par mode Режим открытия файла
	*/
	Stream openFile(string name, FileMode mode)
	{
		if (dirname.empty)
		{
			writeLog("Tried to read files list at closed archive!", LOG_ERROR_LEVEL.WARNING);
			throw new ReadException("Tried to read files list at closed archive!");
		}
		
		auto f = new File(dirname~"/"~name, mode);
		return f;
	}

private:
	string dirname;
}

/// Фабрика, которая создает экземпляры Архива
/**
*	Через регистрацию уникального типа фабрики менеджер архивов узнает о новом типе
*	архивов и как их создавать.
*/
class FileSysFabric: ArchiveFabric
{
	/// Получение уникального идентификатора типа архива
	/**
	*	Идентификатор используется для загрузки типов хранилищ из файла.
	*/
	string getType()
	{
		return "FileSystem";
	}

	/// Создание экземпляра нужного класса архива
	Archive createInstance()
	{
		return new FileSys();
	}
}

/// Регистрация фабрики
static this()
{
	ArchiveMng.getSingleton().addArchiveType(new FileSysFabric());
}