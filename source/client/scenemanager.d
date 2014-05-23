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