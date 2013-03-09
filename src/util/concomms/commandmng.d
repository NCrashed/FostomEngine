//          Copyright Gushcha Anton, Shamyan Roman 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	@file commandmng.d Менеджер учета консольных комманд вводимых через UI
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