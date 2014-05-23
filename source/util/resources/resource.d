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
*   Основной интерфейс для ресурсов
*
*	Общий интерфейс для реализации фоновой загрузки, быстрого поиска,
*	конвертации, загрузки и сохранения. Каждый ресурс должен реализовать этот интерфейс
*	и зарегистрировать фабрику в менеджере ресурсов.
*/
module util.resources.resource;

public import std.stream;

interface Resource
{
	/// Получение имени ресурса
	@property string name();

	/// Инициализация ресурса
	/**
	*	@par name Имя ресурса, по которому будет искаться файл.
	*	@par ext Расширение файла, нужно для детекта формата данных.
	*/
	void init(string name, string ext);

	/// Загрузка ресурса и подготовка к использованию
	void load(Stream file, string filename);

	/// Выгрузка ресурса с возможностью загрузки
	void unload();

	/// Копирование ресурса
	/**
	*	Довольно часто возникает ситуация, когда ресурс надо создать на основе другого того же типа
	*	без загрузки из архива. Каждая реализация ресурса сама определяет логику копирования.
	*/
	Resource dup() @property;
}


/// Фабрика ресурсов
/**
*	Предназначена для распознования файлов и созадния
*	нужного вида ресурса. Каждый тип ресурса реализует
*	этот интерфейс и регистрирует фабрику в менеджере 
*	ресурсов.
*/
interface ResourceFactory
{
	/// Идентификатор фабрики
	string getType();

	/// Получить список расширений, которые поддерживает эта фабрика
	/**
	*	@note Если менеджер обнаружит конфликты, непременно начнет ругаться
	*/
	string[] getExtentions();

	/// Создание экземпляра ресурса
	/**
	*	@par file Открытый файл с ресурсом.
	*	@par name Имя файла
	*	@par ext Расширение файла, нужно для алгоритмов загрузки
	*/
	Resource createInstance(Stream file, string name, string fullname, string ext);
}