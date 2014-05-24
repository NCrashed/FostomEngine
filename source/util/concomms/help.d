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
*   Команда Help выдает спраку о других командах, включая саму себя
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