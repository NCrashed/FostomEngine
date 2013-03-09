//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Кастомная(процедурная) модель
/**
*	@file manualmodel.d Наследники этого класса реализуют процедурную генерацию моделей.
*	Класс реализует необходимые общие методы для упрощения генерации.
*/
module client.model.manualmodel;

import client.model.model;
import std.stream;

class ManualModel : Model
{
	/// Инициализация ресурса
	void init(string name)
	{

	}

	/// Отрисовка модели
	/**
	*	@par dt Время, прошедшее с предыдущего кадра
	*/
	override void draw(double dt)
	{

	}

	/// Загрузка ресурса и подготовка к использованию
	override void load(Stream file, string filename)
	{

	}

	/// Выгрузка ресурса с возможностью загрузки
	override void unload()
	{
		
	}
	
private:

}