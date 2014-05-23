//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Клиентский стартовый модуль
/**
*	@file main.d С этого модуля начинаются различия между компиляцией клиента и сервера.
*	В модуле описана main функция и создание приложения.
*/
module client.main;

import client.app;

int main(string[] args)
{
	auto app = App.getSingleton();

	app.startLooping();

	return 0;
}