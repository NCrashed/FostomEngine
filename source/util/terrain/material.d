// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   Описание материала ландшафта. 
*
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