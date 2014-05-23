//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Серверное приложение
/**
*	@file server/app.d Основной класс занимается управлением остальных подсистем. 
*	Здесь находится бесконечный цикл проверки сообщений, вызовы событий и пр.
*/
module server.app;

import util.singleton;
import util.log;
import util.concomms.commandmng;
import std.stdio:readln;



class App 
{
	mixin Singleton!App;

	this()
	{	

	}

	void startLooping()
	{
		/*
		* Бесконечный цикл проверки сообщений, вводимых
		* непосредственно с окна сервера
		*
		*/
		bool flag = true;
		while (flag) 
		{
			string line = readln();
			if (line == "exit\n") flag = false;
			else Manager.exec(line);
		}		
	}
}