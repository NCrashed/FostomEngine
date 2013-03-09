//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Описание материала ландшафта. 
/**
*	@file material.d Описание элементарных кусочков ландшафта. Цвет, текстуры, физические свойства и другая информация.
*/
module util.terrain.material;

/// Описание материала ландшафта
abstract class TerrainMaterial
{
	/// Получение названия текстуры
	@property string texture();

private:

}