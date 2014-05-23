// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Стандартный менджер сцены
*
*	Стандартный менджер сцены, который просто составляет список всех мешей и передает на отрисовку.
*/
module client.stdscenemanager;

import client.scenemanager;
import std.array;
import std.stdio;

/// Стандартный менеджер сцены
/**
*	Стандартный менджер сцены, который просто составляет список всех мешей и передает на отрисовку.
*	@todo Написать менджер сцены на октодеревьях
*	@todo Добавить в стандартный менеджер отсечение невидимых объектов.
*/
class StdSceneManager : SceneManager
{

	/// Получение списка мешей для отрисовки
	override MeshNodeTuple[] getToRender(Camera cam)
	{
		// Обход дерева в ширину
        auto nodes = new SceneNode[0];
        auto ret = new MeshNodeTuple[0];
        nodes~= rootNode;

        while(!nodes.empty)
        {
            auto node = nodes[0];
            nodes = nodes[1..$];

            nodes ~= node.childs;

            foreach(model; node.models)
                foreach(mesh; model.meshes)
                	ret ~= MeshNodeTuple(mesh, node);
        }
        return ret;
	}
	
	override void clearScene()
	{
		mRootNode = new SceneNode;
	}
}