FostomEngine
============

Voxel based game engine written in D2 programming language. Voxel engines became actual when graphics card were able
to excecute generic code (CUDA and OpenCL). At this moment there are some experimental developments: Atomontage Engine,
Gigavoxels, Procedural Worlds. But all of them are closed or unrelased.

This engine based on Gigavoxel technology described in 
[this paper](http://maverick.inria.fr/Publications/2011/Cra11/). The article can be seen as disign document and road map
for the project.

Compilation
===========

Project uses some open-source libraries as dependencies. They can be found at Dependencies folder. Project compilation
has dependency compilation ability. It requires MinGW, CMake for windows and GCC, CMAKE for linux. You can compile
dependency yourself as described bellow.

For automatic compilation go to script directory and call:
```
$ rdmd compile.d all [debug|release]
```

Manual dependency compilation
=============================

**[Derelict3](https://github.com/aldacron/Derelict3)**

Dynamic bindings to OpenGL, GLFW3, FreeImage and others. Location: Dependencies/Derelict3.

**Compilation**
Go to build folder:
```
$ dmd build.d && ./build.exe
```

**[GLFW3](https://github.com/elmindreda/glfw)**

Crossplatform library for creating window and manipulating drawing context. Written in C and compiles with Cmake,GCC/MinGW.
Also you can manually compile it with VisualC. Location: Dependencies/GLFW3.

**Compilation**
GNU/Linux:
```
cmake
make
```
Finally copy src/libglfw.so into project bin derectory (if it doesn't exist, create).

Windows: 
MinGW:
```
cmake -G "MinGW Makefiles" .\
make
```
Finally copy src/glfw.dll into project bin derectory (if it doesn't exist, create).

VisualStudio:
Generate studio project with CMake gui, compile it with VisualStudio and copy 
glfw.dll into project Bin derectory (if it doesn't exist, create).

**[FreeImage](http://freeimage.sourceforge.net/)**

FreeImage is an Open Source library project for developers who would like to support popular 
graphics image formats like PNG, BMP, JPEG, TIFF and others as needed by today's multimedia applications.
Written in C/C++ and used to provide texture loading. Location: Dependencies/FreeImage.

**Compilation**

GNU/Linux:
```
make -f Makefile.fip
```
Finally copy libfreeimageplus-3.15.4.so into project Bin directory and rename to libfreeimage.so. Fostom uses
modified freeimage version, therefore offical version can fail.

Windows:

With MinGW:
```
make -fMakefile.mingw
```
Finally copy FreeImage.dll into project bin directory.

With Visual Studio:

FreeImage provide project for VisualStudio, compile it and
copy FreeImage.dll into project Bin directory. Compilation in debug 
mode adds 'd' suffix to dll name, remove it.

**[cl4d](https://github.com/Trass3r/cl4d)**

Static bindings to OpenCL. Fostom renders picture with OpenCL kernels. Location: Dependencies/cl4d.

**Compilation**
```
$ cd Dependencies/cl4d
$ rdmd compile.d all release
```
There is some big problem. I don't know how cl4d author have got OpenCL.lib and i can't get OpenCL.a for Linux.
I am going to rewrite cl4d to use dynamic bindings as Derelict does.

Milestones
===========
* Creating base polygon engine. (DONE)
* Creating wrapper for OpenCL renderer. (DONE)
* Rendering a single voxel. (DONE)
* Rendering simple octree. (In progress)
* Rendering complex octree.
* Creating GPU cache system.
* Rendering multiple octrees.
