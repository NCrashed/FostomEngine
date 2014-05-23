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
*   Описание примеси для создания синглетона (одиночный объект).
*
*	Реализация поточно-безопасного синглетона, некоторые 
*	уже считают его антипаттерном, но без него сложно делать глобальные менеджеры.
*/
module util.singleton;

/// Примесь для создания синглетона
/**
*	@example 
*	class MyAwesomeClass
*	{
*		mixin Singleton!MyAwesomeClass;
*		...
*	}
*	@note Данная реализация многопоточна и
*	работает по принципу двойной блокировки
*/
mixin template Singleton(T)
{
	/// Локальная переменная для потоков
	private static bool initialized; 
	/// Расшаренный указатель
	private static __gshared T mSingleton = null;

	/// Создавать нас напрямую нельзя
	private this(){}

	/// Получение указателя на экземпляр синглетона
	/**
	*	Если объект не существовал до этого, создаем его.
	*/
	static T getSingleton()
	{
		if(initialized)
			return mSingleton;

		synchronized(T.classinfo)
		{
			scope(success) initialized = true;
			if (mSingleton !is null)
				return mSingleton;

			mSingleton = new T();
			return mSingleton;
		}
	}
}