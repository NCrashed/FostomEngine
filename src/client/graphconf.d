//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Модуль с описанием настроек графики клиента 
/**
*	@file graphconf.d Структура загружается из файла и сохраняется посресдством системы
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

	/// Конвертация инфы о оконном/полноэкранном режиме
	int getWindowMode()
	{
		if (windowed) return GLFW_WINDOWED;
		return GLFW_FULLSCREEN;
	}
}