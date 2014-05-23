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
*	Описание интерфейса для кодирования/декодирования данных.
*	Используется для подключения различных форматов ресурсов к движку, кодирования
*	данных и пр. Каждая реализация кодека регистрирует себя в менджере, через который
*	пользователи могут получить доступ к кодекам.
*/
module util.codec;

public import std.stream;

/// Описание интерфейса для кодирования/декодирования данных.
/**
*	Используется для подключения различных форматов ресурсов к движку, кодирования
*	данных и пр. Каждая реализация кодека регистрирует себя в менджере, через который
*	пользователи могут получить доступ к кодекам.
*/
interface Codec
{
public:
	/// Получение уникального идентификатора кодека
	@property string type();

	/// Стандарт потока данных, который обеспечивает кодек
	/**
	*	Т.к. кодек возвращает поток данных, то нужно знать формат этого потока.
	*	Возвращаемая строка является именем стандарта, например "model", "image" и т.д.
	*	Стандарты описываются обычно в файлах с ресурсами, которые и пользуют кодеки.
	*/
	@property string standart();

	/// Декодирование данных 
	Stream decode(Stream data);

	/// Кодирование исходных данных
	Stream code(Stream data);
private:

}