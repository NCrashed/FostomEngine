// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Модуль описывает состояние работы клинета с помощью ClientWorld.
*/
module client.clworld;

public
{
	import client.camera;
	import client.rendersys;
}

/**
*	Для начала я приведу примеры ClientWorld: главное меню, игровой мир, лобби сервера.
*	Итого ClientWorld можно представить как определенное состояние клиента, когда
*	загружены определенные ресурсы, заданы нужные обработчики событий ввода/вывода и
*	устанавливаются собственные настройки графики.
*
*	ClientWorld позволяет разделить приложение на несколько независимых модулей, которые
*	не пересекаются и не засоряют отключенным кодом обработчики событий приложения.
*/
abstract class ClientWorld
{
	/// Имя мира
	string name() @property;

	/**
	*	Инициализация мира, передается для сохранения камера по умолчанию $(B camera).
	*	Вызывается после окончания инициализации сцены приложения. 
	*/
	void init(Camera camera);

	/**
	*	Действия по выгрузке мира.
	*/
	void unload();
	
	/**
	*	После каждой отрисовки кадра вызывается эта функция. Параметр $(B dt) определяет
	*	время между предыдущем вызовом этой функции и текущим. Текущее окно передается
	*	в $(B window).
	*/
	void update(GLFWwindow* window, double dt);

	/**
	*	При перемещении мышки вызывается эта функция. 
	*	@par dx Относительное перемещение по оси X.
	*	@par dy Относительное перемещение по оси Y.
	*	@par absx Абсолютное положение мышки по оси X.
	*	@par absy Абсолютное положение мышки по оси Y.
	*/
	void mousePosEvent(int dx, int dy, int absx, int absy);

	/**
	*	При нажатии на клавишу $(B key) вызывается эта функция.
	*/
	void keyPressed(int key);

	/**
	*	При отпускании клавиши $(B key) вызывается эта функция.
	*/
	void keyReleased(int key);
}