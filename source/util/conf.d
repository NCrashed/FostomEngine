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
*	Modules provides functions to work with config files. All configs should be in $(B CONFIGS_PATHS) and should have $(B CONFIG_EXT) extentions.
*	
*	Authors: Gushcha Anton (NCrashed)
*
*	License: Boost Software License, Version 1.0. (http://www.boost.org/LICENSE_1_0.txt)
*/
module util.conf;

import util.serialization.serializer;

import util.log;
import std.stdio;
import std.process;
import std.array;

/// Standart path for config files
enum CONFIGS_PATHS = "../configs/";
/// Standart extention of config file
enum CONFIG_EXT = ".cfg";

static this()
{
	import std.file, std.path;

	string p = buildNormalizedPath(CONFIGS_PATHS);
	if(!exists(p))
		mkdir(p);
}

/**
*	Checks if config exists with name $(B confName). $(B confName) should
*	be without any extention, function will add it itself.
*/
bool isConfExists(string confName)
{
	try
	{
		auto f = new std.stream.File(CONFIGS_PATHS~confName~CONFIG_EXT, FileMode.In);
	}
	catch(Exception e)
	{
		writeLog("Config file "~confName~CONFIG_EXT~" doesn't exist.", 
			 LOG_ERROR_LEVEL.NOTICE);
		return false;
	}
	return true;
}

/**
*	Writes a config struct (or class) $(B confStruct) down to hard disk with name $(B confName).
*	$(B confName) should be specified without extentions. Returns true if success, false and log message
*	if error.
*/
bool writeConf(ConfStruct)(string confName, ConfStruct confStruct) nothrow
{
	try
	{
		auto stream = serialize!GendocArchive(confStruct);
		auto f = new std.stream.File(CONFIGS_PATHS~confName~CONFIG_EXT, FileMode.Out);
		scope(exit) f.close();
		f.copyFrom(stream);
	}
	catch(Exception e)
	{
		writeLog("Failed to write config "~confName~"!", 
			 LOG_ERROR_LEVEL.WARNING);
		return false;
	}
	return true;
}

/**
*	Reads config from file $(B confName) and writes content in $(B ConfStruct) which will be returned.
*	$(B confName) should be specified without extentions. If error occures, returns default $(ConfStruct)
*	and logs error.
*/
ConfStruct readConf(ConfStruct)(string confName)
{
	// Преобразуем строки в структуру
	ConfStruct ret;
	try
	{
		ret = deserialize!(GendocArchive, ConfStruct)(CONFIGS_PATHS~confName~CONFIG_EXT);
	} 
	catch(Exception e)
	{
		writeLog("Failed to read config "~confName~"! Reason: "~e.msg, 
			 LOG_ERROR_LEVEL.WARNING);		
		return ConfStruct();	
	}

	return ret;
}

/**
*	Reads config from file $(B confName) and writes content in $(B ConfStruct) which will be returned.
*	$(B confName) should be specified without extentions. If error occures, throws exception.
*/
ConfStruct readConfCritical(ConfStruct)(string confName)
{
	// Преобразуем строки в структуру
	ConfStruct ret;
	try
	{
		ret = deserialize!(GendocArchive, ConfStruct)(CONFIGS_PATHS~confName~CONFIG_EXT);
	} 
	catch(Exception e)
	{
		writeLog("Failed to read config "~confName~"! Reason: "~e.msg,
			 LOG_ERROR_LEVEL.WARNING);
		throw e;		
	}

	return ret;
}