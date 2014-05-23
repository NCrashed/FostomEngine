//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Стандартный менджер сцены
/**
*	@file stdscenemanager.d Стандартный менджер сцены, который просто составляет список всех мешей и передает на отрисовку.
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