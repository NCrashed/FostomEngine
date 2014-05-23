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
*   Абстракное хранилище ресурсов
*
*	Интерфейс для реализации унифицированной работы с разными
*	архивами, в том числе и с файловой системой.
*/
module util.resources.archive;

public
{
	import std.stream;
}

/// Абстрактное хранилище ресурсов
/**
*	Это может быть файловая система или zip архив, или другой формат архива. 	
*/
interface Archive
{
	/// Открытие архива
	/**
	*	@par name Полный путь до архива вместе с именем
	*	@par mode Режим открытия архива, некоторые режимы могут
	*	не поддерживаться, тогда вызывается исключение.
	*/
	void open(string name, FileMode mode);

	/// Закрытие архива
	/**
	*	Вызывается также и при удалении объекта. Здесь может 
	*	производится запись данных на диск.
	*/
	void close();

	/// Проверка, открыт ли архив.
	bool isOpened();

	/// Путь до архива
	@property string name();

	/// Проверка на наличие файла
	/**
	*	@par name Имя файла относительно корня архива
	*	@par recursive Рекурсивный поиск по всему архиву
	*/
	bool hasFile(string name, bool recursive=false);

	/// Получение списка файлов
	/**
	*	@par pattern Шаблон, содержащий спец. символы *,& для выбора только нужных файлов
	*	@par recursive Флаг рекурсивного поиска по всем подпапкам архива
	*	@return Список найденных файлов, их полные имена от корня архива
	*/
	string[] getFileList(string pattern="*", bool recursive=false);

	/// Открытие файла для чтения, записи
	/**
	*	@par name Имя файла от корня архива
	*	@par mode Режим открытия файла
	*/
	Stream openFile(string name, FileMode mode);
}

/// Фабрика, которая создает экземпляры Архива
/**
*	Через регистрацию уникального типа фабрики менеджер архивов узнает о новом типе
*	архивов и как их создавать.
*/
interface ArchiveFabric
{
	/// Получение уникального идентификатора типа архива
	/**
	*	Идентификатор используется для загрузки типов хранилищ из файла.
	*/
	string getType();

	/// Создание экземпляра нужного класса архива
	Archive createInstance();
}