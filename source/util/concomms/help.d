//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
* @file help.d
* Команда Help выдает спраку о других командах, включая саму себя
*/

module util.concomms.help;

import util.concomms.commandmng;

static this() {
	Manager.register(new Help);
}

class Help:ConComInterface
{

	override @property public  string COMMA_CALL()  {return  "help"; }
	override @property public  string COMMA_ALIAS() {return "?";}
	override @property protected string FUNC_HELP() {return "use help <command>"; }



	private void findDescription(string name)
	{
		for (int i = 0; i < Manager.list.length; i++)
			if ((name == Manager.list[i].COMMA_CALL)||(name == Manager.list[i].COMMA_ALIAS))
			{	
				Manager.list[i].showDescription();
				break;
			}
	}
	
	override public void showDescription()
	{
		writeln("Command help use for calling help of intresting command.\nFor example, use : help <command>");
	}


	override public void execute(string[] argv)
	{
		super.execute(argv);

		if (argv.length > 1)
			findDescription(argv[1]);
	}


}