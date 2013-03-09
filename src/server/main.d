//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Серверный стартовый модуль
/**
*	@file ServerMain.d С этого модуля начинаются различия между компиляцией клиента и сервера.
*	В модуле описана main функция и создание приложения.
*	@todo Как только заработает ресурсная и render системы, отсюда надо убрать код примера.
*/
module server.main;

import server.app;


int main(string[] args)
{
	auto app = App.getSingleton();

	app.startLooping();

	return 0;
}