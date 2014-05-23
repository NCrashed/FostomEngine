// written in the D programming language
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

import derelict.glfw3.types;

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