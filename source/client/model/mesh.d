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
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	@Составная часть модели, использующая один материал.
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