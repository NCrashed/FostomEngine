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
*	Менеджер учета консольных комманд вводимых через UI
*/

module util.concomms.commandmng;

public import std.stdio: writef, writefln, writeln, readln;

class ConComInterface
{

	@property public  string COMMA_CALL()  {return "commCall"; }
	@property public  string COMMA_ALIAS() {return "commAlias";}
	@property protected string FUNC_HELP() {return "this is default commHelp"; }


	public void execute(string[] argv) 
	{
		if (argv.length == 1) this.showHelp();
	}

	public void showHelp() //вызов справки
	{
		writeln(FUNC_HELP);
	}


	public void showDescription() //вызов описания команды
	{
		/*File *f;
		try 
		{
			f = new File(DESCR_PATH~"/description.txt","r");

		} catch (Exception e)
		{
			mkdir(DESCR_PATH);
			f = new File(DESCR_PATH~"/description.txt","w");
			f.writeln("Put Command Description Here");
		} finally 
		{
			f = new File(DESCR_PATH~"/description.txt","r");
			foreach(str; f.byLine()) //Вывод сообщения на экран
			{
				writeln(str);
			}
			f.close();
		}*/
		
		writeln("Command help use for calling help of intresting command.\nFor example, use : help <command>");
	} 

}

static class Manager 
{


	public static ConComInterface[] list;

	this()
	{
		list = new ConComInterface[0];
	}

	public static  void register (ConComInterface CCI)
	{
		list ~= CCI;
	}


	private static string[] translate(string line) 
	{
		string[] argv;
		int j = 0;


		for(int i = 0; i < line.length ; i++)
			if ((line[i] == ' ')||(i == line.length - 1))
			{
				argv ~= line[j..i];
				j = i + 1;
			}

		return argv;

	}

	public static void exec(string line)
	{
		string[] trns = translate(line);
		
		if (trns.length < 1) 
		{ /*TODO exception here */ 
			throw new Exception("Nothing to do");
		}
		
		
		
		for (int i = 0; i < list.length; i++ )
		{
			
			if ((trns[0] == list[i].COMMA_CALL)||(trns[0] == list[i].COMMA_ALIAS))
			{
				
				list[i].execute(trns);
				break;
			}
		}

	}
}