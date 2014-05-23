//          Copyright Gushcha Anton, Shamyan Roman 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
* @file get.d
* Команда Get предназначена для вывода имформации о системе.
* Например: $ get list выдает список зарегистрированных комманд
* в мэнеджере комманд
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
