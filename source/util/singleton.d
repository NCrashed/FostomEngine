//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Описание примеси для создания синглетона (одиночный объект)
/**
*	@file singleton.d Реализация поточно-безопасного синглетона, некоторые 
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