//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Составная часть модели, минимальная часть со своим материалом.
/**
*	@file mesh.d Составная часть модели, использующая один материал.
*/
module client.model.mesh;

import util.log;
import util.resources.resmng;
import client.model.material;
import client.texture;
import derelict.opengl3.gl3;

/// Кусок модели с одинаковыми свойствами
/**
*
*/
class Mesh
{

	this()
	{
		mVertex = new float[0];
		mUvs = new float[0];
		mNormals = new float[0];
		mIndex = new uint[0];

		if(mDefaultTexture is null)
		{
			auto resmng = ResourceMng.getSingleton();
			mDefaultTexture = cast(Texture)(resmng.getResource("default.tga", "General"));
		}
	}

	/// Инициализация меша и задание основных буферов
	void init(
		float[] verts,
		float[] uvs,
		float[] normals,
		uint[] inds
		)
	{
		if( verts is null )
		{
			writeLog("Passed to mesh wrong vertex array!", LOG_ERROR_LEVEL.WARNING);
			return;
		}
		if( uvs is null )
		{
			writeLog("Passed to mesh wrong uvs array!", LOG_ERROR_LEVEL.WARNING);
			return;
		}
		if( normals is null )
		{
			writeLog("Passed to mesh wrong normals array!", LOG_ERROR_LEVEL.WARNING);
			return;
		}
		if( inds is null )
		{
			writeLog("Passed to mesh wrong inds array!", LOG_ERROR_LEVEL.WARNING);
			return;
		}

		mVertex = verts;
		mUvs = uvs;
		mNormals = normals;
		mIndex = inds;
	}

	/// Получение вершин модели
	@property const(float[]) vertecies()
	{
		return mVertex;
	} 

	/// Получение текстурных координат
	@property const(float[]) uvs()
	{
		return mUvs;
	}

	/// Получение нормалей
	@property const(float[]) normals()
	{
		return mNormals;
	}

	/// Получение индексов
	@property const(uint[]) indecies()
	{
		return mIndex;
	}

	/// Привязывание материала к мешу
	void bindMaterial(Material mat)
	{
		mMaterial = mat;
		auto resmng = ResourceMng.getSingleton();

		try
		{
			mTexture = cast(Texture)(resmng.getResource(mat.texture, "General"));
		} 
		catch(Exception e)
		{
			writeLog("Failed to load texture "~mat.texture~" from material! Reason: "~e.msg, LOG_ERROR_LEVEL.WARNING);
		}
	}

	/// Применение настроек отрисовки перед отрисовкой модели
	void applyOptions()
	{
		if(mMaterial is null) return;
		
		mMaterial.applyRenderOptions();
	}

	/// Получение текстуры для отрисовки
	/**
	*	Если возникли проблемы с текстурой, будет передана текстура по умолчанию.
	*/
	@property GLuint texture()
	{
		if(mTexture !is null)
			return mTexture.opengl;
		else
			return mDefaultTexture.opengl;
	}

	Mesh dup() @property
	{
		auto ret = new Mesh;

		ret.mVertex = mVertex.dup;
		ret.mUvs = mUvs.dup;
		ret.mNormals = mNormals.dup;
		ret.mIndex = mIndex.dup;

		ret.mMaterial = mMaterial;
		ret.mTexture = mTexture;

		return ret;
	}
	
private:
	float[] mVertex;
	float[] mUvs;
	float[] mNormals;
	uint[] mIndex;

	Material mMaterial;
	Texture mTexture;

	static Texture mDefaultTexture;
}