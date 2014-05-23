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