#!/usr/bin/rdmd
/// Скрипт автоматической компиляции проекта под Linux и Windows
/** 
 * Очень важно установить пути к зависимостям (смотри дальше), 
 */
module compile;

import dmake;

import std.stdio;
import std.process;

// Здесь прописать пути к зависимостям клиента
string[string] clientDepends;

// Зависимости сервера
string[string] serverDepends;

// Список либ от Derelict3
string[] derelictLibs;

version(X86)
	enum MODEL = "32";
version(X86_64)
	enum MODEL = "64";

static this()
{
	clientDepends =
	[
		"Derelict3": "../Dependencies/Derelict3",
		"GLFW3": "../Dependencies/GLFW3",
		"FreeImage": "../Dependencies/FreeImage",
		"cl4d": "../Dependencies/cl4d",
	];

	derelictLibs =
	[
		"DerelictGL3",
		"DerelictGLU",
		"DerelictGLFW3",
		"DerelictUtil",
		"DerelictFI",
	];

	/*
	serverDepends =
	[
		"Orange": "../Dependencies/orange"
	];
	*/
}

void compileFreeImage(string libPath)
{
	writeln("Building FreeImage...");

	version(linux)
	{
		system("cd "~libPath~` && make -f Makefile.fip`);
		system("cp "~libPath~"/libfreeimageplus-3.15.4.so "~getCurrentTarget().outDir~`/libfreeimage.so`);
	}
	version(Windows)
	{
		checkProgram("make", "Cannot find MinGW to build FreeImage! You can build manualy with Visual Studio and copy FreeImage.dll to output folder or get MinGW from http://www.mingw.org/wiki/Getting_Started");
		system("cd "~libPath~` && make -fMakefile.mingw`);
		system("copy "~libPath~"\\FreeImage.dll "~getCurrentTarget().outDir~"\\FreeImage.dll");
	}
}

void compileGLFW3(string libPath)
{
	writeln("Building GLFW3...");
	version(linux)
	{
		checkProgram("cmake", "Cannot find CMake to build GLFW3! You can get it from http://www.cmake.org/cmake/resources/software.html");
		system("cd "~libPath~` && cmake ./`);
		system("cd "~libPath~` && make`);
		system("cp "~libPath~`/src/libglfw.so `~getCurrentTarget().outDir~`/libglfw.so`);
	}
	version(Windows)
	{
		checkProgram("cmake", "Cannot find CMake to build GLFW3! You can get it from http://www.cmake.org/cmake/resources/software.html");
		checkProgram("make", "Cannot find MinGW to build GLFW3! You can build manualy with GLFW3 and copy glfw.dll to output folder or get MinGW from http://www.mingw.org/wiki/Getting_Started");
		system("cd "~libPath~` & cmake -G "MinGW Makefiles" .\`);
		system("cd "~libPath~` & make`);
		system("copy "~libPath~`\src\glfw.dll `~getCurrentTarget().outDir~`\glfw.dll`);
	}
}

void compileCl4d(string libPath)
{
	writeln("Building cl4d...");
	system("cd "~libPath~` && rdmd compile.d all release`);
}

//======================================================================
//							Основная часть
//======================================================================
int main(string[] args)
{
	// Клиент
	addCompTarget("client", "../bin", "FostomClient", BUILD.APP);
	setDependPaths(clientDepends);

	addLibraryFiles("Derelict3", "lib", derelictLibs, ["import"], 
		(string libPath)
		{
			writeln("Building Derelict3 lib...");
			version(Windows)
				system("cd "~libPath~`/build && dmd build.d && build.exe`);
			version(linux)
				system("cd "~libPath~`/build && dmd build.d && ./build`);	
		});

	addLibraryFiles("cl4d", ".", ["OpenCL","cl4d"], ["."], &compileCl4d);

	checkSharedLibraries("GLFW3", ["glfw"], &compileGLFW3);
	checkSharedLibraries("FreeImage", ["freeimage"], &compileFreeImage);

	addSource("../src/client");
	addSource("../src/util");

	addCustomFlags("-D -Dd../docs ../docs/candydoc/candy.ddoc ../docs/candydoc/modules.ddoc -version=CL_VERSION_1_1");

	// Сервер
	addCompTarget("server", "../bin", "FostomServer", BUILD.APP);
	setDependPaths(serverDepends);

	addSource("../src/server");
	addSource("../src/util");
	
	addCustomFlags("-D -Dd../docs ../docs/candydoc/candy.ddoc ../docs/candydoc/modules.ddoc");

	checkProgram("dmd", "Cannot find dmd to compile project! You can get it from http://dlang.org/download.html");
	// Компиляция!
	return proceedCmd(args);
}