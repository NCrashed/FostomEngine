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
*   Copyright: © 2013-2014 Anton Gushcha, Shamyan Roman
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Shamyan Roman,
*            Anton Gushcha <ncrashed@gmail.com>         
*
*   Команда Get предназначена для вывода имформации о системе.
*   Например: $ get list выдает список зарегистрированных комманд
*   в мэнеджере комманд
*/

module util.concomms.get;

import util.concomms.commandmng;

static this() {
	Manager.register(new Get);
}

class Get:ConComInterface
{

	override @property public  string COMMA_CALL()  {return  "get"; }
	override @property public  string COMMA_ALIAS() {return "get";}
	override @property protected string FUNC_HELP() {return "use get <param>"; }

	override public void showDescription()
	{
		writeln("Command get use for getting value of intresting constant.\nFor example, use : get <constant>");
	}
	
	override public void execute(string[] argv)
	{
		super.execute(argv);

		if (argv.length > 1)
		switch (argv[1]) // add <params> here
		{
			case "list" :
				writeln(Manager.list);
				break;
			
			default :
				writefln("Wrong parameter:%s",argv[1]);
				break;
		}
	}


}
