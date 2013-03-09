//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Менеджер, занимающийся сортировкой моделей для отрисовки.
/**
*	@file scenemanager.d Менеджер, управляющий сценой, отображающей текующий кусок мира, управляет его отрисовкой и т.п.
*/
module client.scenemanager;

public import client.scenenode;
public import client.model.model;
public import client.camera;

struct MeshNodeTuple
{
	Mesh mesh;
	SceneNode node;
}

/// Абстрактный менджер сцены
/**
*	Менеджер сцены занимается сортировкой мешей и выдает системе отрисовки список мешей для
*	отрисовки. Также хранит рутовый нод, к которому прикрепляются все остальные ноды.
*/
abstract class SceneManager 
{
	this()
	{
		mRootNode = new SceneNode;
	}

	/// Получение рутового нода
	@property SceneNode rootNode()
	{
		return mRootNode;
	}

	/// Получение списка мешей для отрисовки
	MeshNodeTuple[] getToRender(Camera cam);

	void clearScene();
protected:
	SceneNode mRootNode;
}