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
*    Модуль с описанием настроек графики клиента.
*
*	Структура загружается из файла и сохраняется посресдством системы
*	конфиг файлов util.conf. Здесь содержатся все графические настройки пользователя.
*/
module client.graphconf;

public import util.conf;

import derelict.glfw3.glfw3;

enum GRAPH_CONF = "graphics";

/// Структура для хранения конфигов графики
struct GraphConf
{
	/// Разрешение экрана X компонента
	int screenX = 800;
	/// Разрешение экрана Y компонента
	int screenY = 600;
	/// Оконный или полноэкранный режим
	bool windowed = true;
	/// Глубина цвета
	int depthBits = 32;
	/// Вертикальная синхронизация
	bool vertSync = true;
}