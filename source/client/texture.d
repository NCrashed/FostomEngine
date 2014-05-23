// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Текстура для наложения на модель.
*
*	Текстуры загружаются из графических файлов, поддерживается широкий спектр форматов. Для конвертирования текстур используется
*	FreeImage.
*/
module client.texture;

import util.resources.resmng;
import util.resources.resource;
import util.log;

import derelict.freeimage.freeimage;
import derelict.opengl3.gl;

import std.string;
import std.stdio;
import std.conv;
import std.path;

class Texture: Resource
{
	/// Получение имени ресурса
	@property string name()
	{
		return mName;
	}


	@property int width()
	{
		return mWidth;
	}

	@property int height()
	{
		return mHeight;
	}

	@property GLuint opengl()
	{
		return mTexture;
	}

	/// Инициализация ресурса
	/**
	*	@par name Имя ресурса, по которому будет искаться файл.
	*	@par group Ресурсная группа
	*/
	void init(string name, string ext)
	{
		mName = name;
		string sExt = ext;
		mFormat = FreeImage_GetFIFFromFilename(toStringz("file."~ext));
	}

	/// Загрузка ресурса и подготовка к использованию
	void load(Stream file, string filename)
	{
		if (mBitmap !is null)
			unload();

		FreeImageIO io;
		io.read_proc = &readProc;
		io.write_proc =&writeProc;
		io.seek_proc = &seekProc;
		io.tell_proc = &tellProc;

		version(Windows)
			mBitmap = FreeImage_Load(mFormat, filename.toStringz(), 0);
		else
			mBitmap = FreeImage_LoadFromHandle(mFormat, &io, cast(fi_handle)file, 0);

		file.close();

		FIBITMAP* temp = mBitmap;
		mBitmap = FreeImage_ConvertTo32Bits(mBitmap);
		FreeImage_Unload(temp);


		mWidth = FreeImage_GetWidth(mBitmap);
		mHeight = FreeImage_GetHeight(mBitmap);

	
		writeLog("Loading texture "~mName~" width = "~to!string(mWidth)~" height = "~to!string(mHeight));

		// Создаем рабочую текстуру
		generateOpenGL();
		
		if (glGetError())
		{
			writeLog("Error while loading texture "~mName, LOG_ERROR_LEVEL.WARNING);
			return;
		}
		writeLog("Finished loading texture "~mName~" width = "~to!string(mWidth)~" height = "~to!string(mHeight));
	}

	/// Загрузка текстуры в opengl формат
	void generateOpenGL()
	{
		GLubyte[] texture = new GLubyte[4*mWidth*mHeight];
		char* pixels = cast(char*)FreeImage_GetBits(mBitmap);
		//FreeImage loads in BGR format
	
		for(int pix=0; pix<mWidth*mHeight; pix++)
		{
			texture[pix*4+0]=pixels[pix*4+2];
			texture[pix*4+1]=pixels[pix*4+1];
			texture[pix*4+2]=pixels[pix*4+0];
			texture[pix*4+3]=pixels[pix*4+3];
		}
		
		// Create one OpenGL texture
		glGenTextures(1, &mTexture);
		 
		// "Bind" the newly created texture : all future texture functions will modify this texture
		glBindTexture(GL_TEXTURE_2D, mTexture);
		 
		// Give the image to OpenGL
		glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture.ptr);
		 
		// When MAGnifying the image (no bigger mipmap available), use LINEAR filtering
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); // GL_LINEAR
		// When MINifying the image, use a LINEAR blend of two mipmaps, each filtered LINEARLY too
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		// Generate mipmaps, by the way.
		glGenerateMipmap(GL_TEXTURE_2D);
	}
	
	/// Выгрузка ресурса с возможностью загрузки
	void unload()
	{
		writeLog("Unloading"~mName);
		if (mBitmap !is null)
			FreeImage_Unload(mBitmap);
		mBitmap = null;

		if (mTexture != 0)
			glDeleteTextures( 1, &mTexture );
		mTexture = 0;
	}

	/// Сохраняет данные из opengl буфера для дальнейших операций
	/**
	*	Если используется динамическая генерация текстур, то данный метод поможет
	*	сохранить текстуру в файл с форматом format, именем name и в группе ресурсов
	*	resgroup (берется базовый путь к группе, т.е. первый путь в группе).
	*/
	void saveOpenGL2File(string format, string name, string resgroup = "Image")
	{
		if(mTexture == 0)
		{
			writeLog("Cannot save texture, it hasn't loaded to opengl format!");
		}


		auto texture = new GLubyte[4*width*height];
		char* pixels = cast(char*)FreeImage_GetBits(mBitmap);

		glBindTexture(GL_TEXTURE_2D, mTexture);
		glGetTexImage( GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_INT, texture.ptr ); 

		auto err = glGetError();
		if (err)
		{
			writeLog("Error ("~to!string(err)~") while saving texture "~name, LOG_ERROR_LEVEL.WARNING);
			if(err == GL_INVALID_ENUM )
				writeLog("target, format, or type is not an accepted value.", LOG_ERROR_LEVEL.WARNING);
			else if(err == GL_INVALID_VALUE  )
				writeLog("level is greater than log 2 ⁡ max , where max is the returned value of GL_MAX_TEXTURE_SIZE.", LOG_ERROR_LEVEL.WARNING);
			else if(err == GL_INVALID_OPERATION   )
				writeLog("GL_INVALID_OPERATION ", LOG_ERROR_LEVEL.WARNING);

			return;
		}


		for(int pix=0; pix<width*height; pix++)
		{
			pixels[pix*4+2] = texture[pix*4+0];
			pixels[pix*4+1] = texture[pix*4+1];
			pixels[pix*4+0] = texture[pix*4+2];
			pixels[pix*4+3] = texture[pix*4+3];
		}

		string basepath;
		try basepath = ResourceMng.getSingleton().getByName(resgroup).basePath;
		catch(Exception e)
		{
			writeLog("Failed to save texture to "~name~", because: "~e.msg);
			return;
		}

		auto fifFormat = FreeImage_GetFIFFromFilename(toStringz("file."~format));
		FreeImage_Save(fifFormat, mBitmap, toStringz(basepath~dirSeparator~name~"."~format), 0);
	}

	/// Сохраняет данные из opengl текстуры для дальнейших операций
	/**
	*	Если используется динамическая генерация текстур, и текстура создавалась без помощи
	*	данного класса, то данный метод поможет сохранить текстуру tex в файл
	*	с форматом format, именем name и в группе ресурсов
	*	resgroup (берется базовый путь к группе, т.е. первый путь в группе).
	*/
	static void saveOpenGL2File(GLuint tex, string format, string name, string resgroup = "Images", FIBITMAP* bitmap=null, int width = 0, int height = 0, FREE_IMAGE_TYPE type = FIT_RGBA16)
	{
		
	}

	~this()
	{
		unload();
	}

	Texture dup() @property
	{
		auto ret = new Texture;
		ret.mName = mName;
		ret.mFormat = mFormat;

		ret.mBitmap = FreeImage_Clone(mBitmap);

		ret.mWidth = FreeImage_GetWidth(ret.mBitmap);
		ret.mHeight = FreeImage_GetHeight(ret.mBitmap);		

		ret.generateOpenGL();
		return ret;
	}
	
private:
	string mName;
	FREE_IMAGE_FORMAT mFormat;
	FIBITMAP* mBitmap = null;
	GLuint mTexture;

	int mWidth, mHeight;
}

private extern(Windows) uint readProc(void *buffer, uint size, uint count, fi_handle handle) nothrow
{
	try
	{
		Stream file = cast(Stream)handle;
			
		auto tmp = new ubyte[size*count];
		file.read(tmp);

		auto buff = cast(ubyte*)buffer;
		foreach(i,val;tmp)
			buff[i] = val;
	} 
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}

private extern(Windows) uint writeProc(void *buffer, uint size, uint count, fi_handle handle) nothrow
{
	try
	{
		Stream file = cast(Stream)handle;
		file.writeExact(buffer, count);
	} 
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}

private extern(Windows) int seekProc(fi_handle handle, int offset, int origin) nothrow
{
	try
	{
		Stream file = cast(Stream)handle;
		file.seek(offset, cast(SeekPos)origin);
	} 
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}

private extern(Windows) int tellProc(fi_handle handle) nothrow
{ 
	try
	{
		Stream file = cast(Stream)handle;
		return cast(int)file.position();
	} 
	catch(Exception e)
	{
		return 1;
	}
	return 0;
}

/// Фабрика ресурсов
/**
*	Предназначена для распознования файлов и созадния
*	нужного вида ресурса. Каждый тип ресурса реализует
*	этот интерфейс и регистрирует фабрику в менеджере 
*	ресурсов.
*/
class TextureFactory : ResourceFactory
{
	/// Идентификатор фабрики
	string getType() 
	{
		return "TextureFactory";
	}

	/// Получить список расширений, которые поддерживает эта фабрика
	/**
	*	@note Если менеджер обнаружит конфликты, непременно начнет ругаться
	*/
	string[] getExtentions()
	{
		return ["png", "gif", "ico", "jpg", "pcd", "psd", "raw", "targa", "tiff",
		 "bmp", "cut", "dds", "exr", "g3", "hdr", "iff", "lbm", "j2k", "j2c", 
		 "jng", "jp2", "jif", "jpeg", "jpe", "koa", "mng", "pbm", "pcd", "pcx", "pfm",
		 "pgm", "pic", "pict", "pct", "ppm", "ras", "sgi", "tga", "tif", "wbmp", "xbm", "xpm"];
	}

	/// Создание экземпляра ресурса
	/**
	*	@par file Открытый файл с ресурсом.
	*/
	Resource createInstance(Stream file, string name, string filename, string ext)
	{
		auto res = new Texture();
		res.init(name, ext);
		res.load(file, filename);
		return res;
	}
}

static this()
{
	ResourceMng.getSingleton().registryFactory(new TextureFactory);
}