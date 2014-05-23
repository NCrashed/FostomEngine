// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Серверный стартовый модуль
*
*	С этого модуля начинаются различия между компиляцией клиента и сервера.
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