// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Менеджер, занимающийся сортировкой моделей для отрисовки.
*
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