// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Серверное приложение
*
*	Основной класс занимается управлением остальных подсистем. 
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