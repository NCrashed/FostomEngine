// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Описание элемента сцены.
*
*	Каждому объекту в игровом мире соответствует свой нод. Ноды образуют дерево, корень которого - специальный
*	нод, используемый системой отрисовки. Система нодов позволяет создавать относительное движение, т.к. координаты отсчитываются
*	от рутового нода.
*/
module client.scenenode;

import client.model.model;

import util.vector;
import util.quaternion;
import util.matrix;

import std.array;

/// Определяет позицию и вращение объекта игры
class SceneNode
{
	this()
	{
		mModels = new Model[0];
		mChilds = new SceneNode[0];
		mPos = vec3(0,0,0);
		mScale = vec3(1,1,1);
		mRot = UNIT_QUATERNION;
	}

	/// Создание нода от предка
	this(SceneNode parent)
	{
		this();

		mParent = parent;
	}

	/// Создание нода от предка и позиции
	this(SceneNode parent, vec3 position)
	{
		this(parent);

		mPos = position;
	}

	/// Создание на основе позиции и поворота
	this(SceneNode parent, vec3 position, Quaternion rotation)
	{
		this(parent, position);

		mRot = rotation;
	}

	/// Получение относительной позиции
	@property vec3 position()
	{
		return mPos;
	}

	/// Получение абсолютных координат
	@property vec3 absposition()
	{
		if(mParent is null)
			return mPos;
		return mParent.absposition() + mPos;
	}

	/// Получение относительного поворота
	@property Quaternion rotation()
	{
		return mRot;
	}

	/// Получение абсолютного поворота
	@property Quaternion absrotation()
	{
		if(mParent is null)
			return mRot;
		return mParent.absrotation()*mRot;
	}

	/**
	*	Получение масштабирования узла.
	*/
	@property vec3 scale()
	{
		return mScale;
	}
	
	/// Получение матрицы модели
	@property Matrix!4 modelMatrix()
	{
		if (!mModified) return mCashed;

		// Rotation
		auto absrot = absrotation;
		auto ret = absrot.toMatrix();
		
		// Translation
		vec3 abspos = absposition;
		ret = ret*translateMtrx(abspos.x, abspos.y, abspos.z);

		// Scaling
		ret = ret*scaleMtrx(mScale.x, mScale.y, mScale.z);
		
		mCashed = ret;
		mModified = false;
		return ret;
	}

	/// Установка позиции
	@property void position(vec3 val)
	{
		mModified = true;
		mPos = val;
	}

	/// Установка вращения
	@property void rotation(Quaternion val)
	{
		mModified = true;
		mRot = val;
	}

	/**
	*	Задание масштабирования узла
	*/
	@property void scale(vec3 val)
	{
		mScale = val;
	}
	
	/// Повернуть нод, поворот относительный
	void rotate(vec3 axis, float angle)
	{
		auto corrAxis = position+axis;
		auto rot = Quaternion.create(corrAxis, angle);
		mModified = true;
		mRot = rot*mRot;
	}

	/// Относительное перемещение нода
	void move(vec3 val)
	{
		mModified = true;
		mPos = mPos + val;
	}

	/// Добавление дочерного нода
	/**
	*	@par name Имя нода для удобства доступа, можно не указывать.
	*	@par pos Относительная позиция нода
	*	@note Если такой нод уже существует, то он будет перезаписан.
	*/
	SceneNode addChild(string name = "", vec3 pos = vec3(0,0,0))
	{
		auto ret = new SceneNode(this, pos);
		mChilds ~= ret;
		if(!name.empty)
		{
			mNamedChilds[name] = ret;
		}
		return ret;
	}

	/// Добавление дочерного нода
	/**
	*	@par name Имя нода для удобства доступа, можно не указывать.
	*	@par pos Относительная позиция нода
	*	@par rot 
	*	@note Если такой нод уже существует, то он будет перезаписан.
	*/
	SceneNode addChild(string name = "", vec3 pos = vec3(0,0,0), Quaternion rot = UNIT_QUATERNION)
	{
		auto ret = new SceneNode(this, pos, rot);
		mChilds ~= ret;
		if(!name.empty)
		{
			mNamedChilds[name] = ret;
		}
		return ret;
	}

	/// Поиск именованного потомка
	/**
	*	@par name Имя потомка
	*	@return null если не найден
	*/
	SceneNode getChild(string name)
	{
		if(name !in mNamedChilds)
			return null;
		return mNamedChilds[name];
	}

	/// Удаление именованного нода
	/**
	*	@par name Имя нода
	*	@note Если не найдено, игнорируется
	*/
	void removeChild(string name)
	{
		if(name in mNamedChilds)
		{
			foreach(i,node; mChilds)
				if( node == mNamedChilds[name] )
					mChilds = mChilds[0..i]~mChilds[i+1..$];
			mNamedChilds.remove(name);
		}
	}

	/// Удаление нода по индексу
	void removeChild(size_t index)
	{
		if(index>=mChilds.length) return;

		auto key = getNameOfChild(mChilds[index]);
		if(!key.empty)
			mNamedChilds.remove(key);

		mChilds = mChilds[0..index]~mChilds[index+1..$];
	}

	/// Удаление нода
	void removeChild(SceneNode node)
	{
		foreach(i,n; mChilds)
			if(n==node)
			{
				auto key = getNameOfChild(node);
				if(!key.empty)
					mNamedChilds.remove(key);

				mChilds = mChilds[0..i]~mChilds[i+1..$];
				return;
			}

	}

	/// Получение списка детей
	@property SceneNode[] childs()
	{
		return mChilds;
	}

	/// Получение списка прикрепленных моделей
	@property Model[] models()
	{
		return mModels;
	}

	/// Присоединение модели к ноду
	/**
	*	@par name Имя модели, для удобства поиска
	*	@par model Модель, которая будет прикреплена
	*	@note Если модель с таким именем уже зарегистрирована,
	*	то имя будет перезаписано.
	*/
	void attachModel(Model model, string name = "" )
	{
		if(model is null) return;

		mModels ~= model;
		if( !name.empty )
			mNamedModels[name] = model;
	}

	/// Получение модели по имени
	/**
	*	@par name Имя модели
	*	@return null, если не найдено
	*/
	Model getModel(string name)
	{
		if(name !in mNamedModels)
			return null;
		return mNamedModels[name];
	}

	/// Удаление модели по имени
	/**
	*	@par name Имя модели
	*	@note Если не найдено, то запрос игнорируется.
	*/
	void removeModel(string name)
	{
		if(name in mNamedModels)
		{
			foreach(i,model; mModels)
				if( model == mNamedModels[name] )
					mModels = mModels[0..i]~mModels[i+1..$];
			mNamedModels.remove(name);
		}
	}
	/// @todo Написать удаление по индексам для моделей и нодов

	/// Удаление модели по индексу
	void removeModel(size_t i)
	{
		if(i>=mModels.length) return;

		auto key = getNameOfModel(mModels[i]);
		if(!key.empty)
			mNamedModels.remove(key);

		mModels = mModels[0..i]~mModels[i+1..$];
	}

	/// Удаление модели
	void removeModel(Model mdl)
	{
		foreach(i,m; mModels)
			if(m == mdl)
			{
				auto key = getNameOfModel(mdl);
				if(!key.empty)
					mNamedModels.remove(key);

				mModels = mModels[0..i]~mModels[i+1..$];
				return;
			}
	}

private:
	/// Позиция относительно рутового сцен-нода
	vec3 mPos;
	vec3 mScale;
	Quaternion mRot;

	Model[] mModels;
	Model[string] mNamedModels;

	SceneNode 	mParent;
	SceneNode[] mChilds;
	SceneNode[string] mNamedChilds;

	// Сохраненная матрица
	Matrix!4 mCashed = Matrix!4.identity;
	bool mModified = true;

	string getNameOfModel(Model mdl)
	{
		foreach(s,m; mNamedModels)
			if( m == mdl)
				return s;
		return "";
	}

	string getNameOfChild(SceneNode node)
	{
		foreach(s,n; mNamedChilds)
			if( n == node)
				return s;
		return "";		
	}
}