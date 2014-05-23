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