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