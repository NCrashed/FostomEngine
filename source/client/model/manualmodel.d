// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Кастомная(процедурная) модель
*
*	Наследники этого класса реализуют процедурную генерацию моделей.
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