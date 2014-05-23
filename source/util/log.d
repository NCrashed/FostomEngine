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
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Модуль для безопасного ведения логов.
*
*	Модуль безопасного ведения логов. Позволяет вести несколько логов одновременно, записывать
*	сообщения разных уровней важности. Если запись в лог фейлит, приложение целиком остается цело.
*/
module util.log;

import std.stdio;
import std.array;
import std.datetime;

/// Уровень сообщения в логе
enum LOG_ERROR_LEVEL
{
	NOTICE 	= 0,
	WARNING = 1,
	DEBUG 	= 2,
	FATAL 	= 3
}

/// Стандартный лог для сопуствующих модулей
public enum GENERAL_LOG = "General.log";

/// Вывод в консоль всех сообщений
enum PRINT_ALL = true;
/// Директория для создание лога по умолчанию
enum DEFAULT_DIR = "./";

/// Хранилище логов
private File*[string] logsMap;

/// Стили отображения
private string[LOG_ERROR_LEVEL] logsStyles;

/// Инициализация модуля
static this()
{
	logsStyles = [
		LOG_ERROR_LEVEL.NOTICE	:	"Notice: ",
		LOG_ERROR_LEVEL.WARNING :	"Warning: ",
		LOG_ERROR_LEVEL.DEBUG	:	"Debug: ",
		LOG_ERROR_LEVEL.FATAL	:	"FATAL ERROR: "
	];
}

///  Закрытие логов при выходе
static ~this()
{
	foreach(log; logsMap)
		if (log !is null)
			log.close();
}

/// Создать лог
/**
*	@par logName Имя лога
*	@par dirName Папка, где будет создан лог
*/
void createLog(string logName, string dirName = DEFAULT_DIR)
{
	if (logName.empty) return;
	if (logName in logsMap) 
	{
		writeln(logsStyles[LOG_ERROR_LEVEL.WARNING], "Tried to recreate ", logName, ". Aborted.");
		return;
	}
	try
	{
		auto f = new File(dirName~"/"~logName, "w");
		logsMap[logName] = f;
	}
	catch(Exception e)
	{
		writeln(logsStyles[LOG_ERROR_LEVEL.WARNING], "Failed to create ", logName, ". Aborted.");
	}
}

/// Закрыть лог
/**
*	@par logName Имя лога
*/
void closeLog(string logName)
{
	if(logName.empty) return;
	if(logName in logsMap)
		logsMap[logName].close();
}

/// Записать в лог сообщение
/**
*	Записывает сообщение $(B msg) в лог с именем $(B logName). Лог должен быть заранее созданс с помощью createLog.
*	Параметр $(B errLevel) описывает уровень важности сообщения. DEBUG и WARNING/FATAL сообщения всегда выводятся на экран.
*	NOTICE сообщения обычно только записываются в файл. FATAL сообщения предвещают скорое падение системы. Если глобальный
*	флаг $(B PRINT_ALL) установлен в $(B true), в консоль будут выводится все сообщения. Флаг $(B forcedMute) указывает, нужно
*	ли принудительно заглушить вывод сообщения в консоль.
*/
void writeLog(string msg, LOG_ERROR_LEVEL errLevel = LOG_ERROR_LEVEL.DEBUG, string logName = GENERAL_LOG, bool forcedMute = false) nothrow
{
	try
	{
		if( ( errLevel == LOG_ERROR_LEVEL.FATAL || errLevel == LOG_ERROR_LEVEL.WARNING || PRINT_ALL ) && !forcedMute )
			writeln(logsStyles[errLevel], msg);
		
		if (!logName.empty && logName in logsMap)
		{
			auto logFile = logsMap[logName];
			if (logFile is null)
			{
				//if(!forcedMute)
				//	writeln(logsStyles[LOG_ERROR_LEVEL.WARNING], "Log ", logName, " doesnt exist. Creating new log.");
				logsMap.remove(logName);
				createLog(logName);
				logFile = logsMap[logName];	
			}
			try
			{
				auto currTime = Clock.currTime();
				auto timeString = currTime.toISOExtString();
				logFile.writeln("["~timeString~"]:"~logsStyles[errLevel], msg);
			} 
			catch(Exception e)
			{
				writeln(logsStyles[LOG_ERROR_LEVEL.WARNING], "Log ", logName, " writing failed.");
			}
		}
		else
		{
			//if(!forcedMute)
			//	writeln(logsStyles[LOG_ERROR_LEVEL.WARNING], "Log ", logName, " doesnt exist. Creating new log.");
			createLog(logName);
		}
	} catch(Exception e)
	{
	}
}

unittest
{
	import std.process;
	import std.regex;
	import std.path;
	
	write("Testing log system... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	createLog("TestLog");
	writeLog("Notice msg!", LOG_ERROR_LEVEL.NOTICE, "TestLog", true);
	writeLog("Warning msg!", LOG_ERROR_LEVEL.WARNING, "TestLog", true);
	writeLog("Debug msg!", LOG_ERROR_LEVEL.DEBUG, "TestLog", true);
	writeLog("Fatal msg!", LOG_ERROR_LEVEL.FATAL, "TestLog", true);
	closeLog("TestLog");

	auto f = new File(DEFAULT_DIR~"TestLog", "r");
	// Перед проверкой удаляем из строки дату
	assert(replace(f.readln()[0..$-1], regex(r"[\[][\p{InBasicLatin}]*[\]][:]"), "") == logsStyles[LOG_ERROR_LEVEL.NOTICE]~"Notice msg!", "Log notice testing fail!");
	assert(replace(f.readln()[0..$-1], regex(r"[\[][\p{InBasicLatin}]*[\]][:]"), "") == logsStyles[LOG_ERROR_LEVEL.WARNING]~"Warning msg!", "Log warning testing fail!");
	assert(replace(f.readln()[0..$-1], regex(r"[\[][\p{InBasicLatin}]*[\]][:]"), "") == logsStyles[LOG_ERROR_LEVEL.DEBUG]~"Debug msg!", "Log debug testing fail!");
	assert(replace(f.readln()[0..$-1], regex(r"[\[][\p{InBasicLatin}]*[\]][:]"), "") == logsStyles[LOG_ERROR_LEVEL.FATAL]~"Fatal msg!", "Log fatal testing fail!");
	f.close();

	version(linux)
		system("rm "~buildNormalizedPath(DEFAULT_DIR~"TestLog"));
	version(Windows)
		system("del "~buildNormalizedPath(DEFAULT_DIR~"TestLog"));
}

