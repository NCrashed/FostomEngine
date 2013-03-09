#!/usr/bin/rdmd
/// Скрипт автоматической компиляции проекта под Linux и Windows
/** 
 * Очень важно установить пути к зависимостям (смотри дальше), 
 */
module compile;

import dmake;

import std.stdio;
import std.process;

version(X86)
	enum MODEL = "32";
version(X86_64)
	enum MODEL = "64";

static this()
{

}

//======================================================================
//							Основная часть
//======================================================================
int main(string[] args)
{
	// Клиент
	addCompTarget("cl4d", ".", "cl4d", BUILD.LIB);

	addSource("./opencl");
	addCustomFlags(" -version=CL_VERSION_1_1");

	checkProgram("dmd", "Cannot find dmd to compile project! You can get it from http://dlang.org/download.html");
	// Компиляция!
	return proceedCmd(args);
}