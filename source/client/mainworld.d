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
*	Главный ClientWorld, который держит в себе ландшафт, ИИ, основной ГУИ и т.п и т.д.
*/
module client.mainworld;

import client.camera;
import client.rendersys;
import client.clworld;
import client.app;

import util.resources.resmng;
import util.resources.archivemng;
import util.log;
import util.vector;

import std.math;

enum CAMERA_STEP = 0.1;
enum CAMERA_TURN = PI/500.;
enum CAMERA_ROLL_TURN = PI/250.;

/**
*	Основной мир, где игрок играет в игру.
*/
class MainWorld : ClientWorld
{

	/// Имя мира
	override string name() @property
	{
		return "MainWorld";
	}

	/**
	*	Инициализация мира, передается для сохранения камера по умолчанию $(B camera).
	*	Вызывается после окончания инициализации сцены приложения. 
	*/
	override void init(Camera camera)
	{
		mCamera = camera;

		mCamera.position.x = 2;
		mCamera.position.y = 0;
		mCamera.position.z = -2;

		mCamera.target = vec3(2, 0.1, -3);

		auto resmng = ResourceMng.getSingleton();
		auto scenemng = RenderSystem.getSingleton().sceneManager;
	}

	/**
	*	Действия по выгрузке мира.
	*/
	override void unload()
	{

	}

	/**
	*	После каждой отрисовки кадра вызывается эта функция. Параметр $(B dt) определяет
	*	время между предыдущем вызовом этой функции и текущим. Текущее окно передается
	*	в $(B window).
	*/
	override void update(GLFWwindow* window, double dt)
	{
		// Вперед-назад
		if(glfwGetKey( window, GLFW_KEY_W ))
		{
			mCamera.moveRel(mCamera.dir*CAMERA_STEP);
		} else if(glfwGetKey( window, GLFW_KEY_S ))
		{
			mCamera.moveRel(mCamera.dir*(-CAMERA_STEP));
		}

		// Влево-вправо
		if(glfwGetKey( window, GLFW_KEY_A ))
		{
			mCamera.moveRel(mCamera.left*CAMERA_STEP);
		} else if(glfwGetKey( window, GLFW_KEY_D ))
		{
			mCamera.moveRel(mCamera.left*(-CAMERA_STEP));
		}

		// Roll камеры
		if(glfwGetKey( window, GLFW_KEY_Q ))
		{
			mCamera.roll(CAMERA_ROLL_TURN);
		} else if(glfwGetKey( window, GLFW_KEY_E ))
		{
			mCamera.roll(-CAMERA_ROLL_TURN);
		}

		if(glfwGetKey( window, GLFW_KEY_ESCAPE ))
		{
			writeLog("Exiting...", LOG_ERROR_LEVEL.NOTICE);
			App.getSingleton().shouldExit();
		}
	}

	/**
	*	При перемещении мышки вызывается эта функция. 
	*	@par dx Относительное перемещение по оси X.
	*	@par dy Относительное перемещение по оси Y.
	*	@par absx Абсолютное положение мышки по оси X.
	*	@par absy Абсолютное положение мышки по оси Y.
	*/
	override void mousePosEvent(double dx, double dy, double absx, double absy)
	{
		enum RESTRICTED_ANGLE = 0.01;

		if(mCamMode)
		{
			if(dx!=0)
			{
				mCamera.rotate(mCamera.up,-CAMERA_TURN*dx);
			} 

			if(dy!=0
				&& !(dy < 0 && mCamera.dir.angle(YUNIT) < -1.0 + RESTRICTED_ANGLE) 
				&& !(dy > 0 && mCamera.dir.angle(YUNIT) >  1.0 - RESTRICTED_ANGLE))
			{
				mCamera.rotate(mCamera.left,-CAMERA_TURN*dy);
			}
		}
	}

	/**
	*	При нажатии на клавишу $(B key) вызывается эта функция.
	*/
	override void keyPressed(int key)
	{
		auto rendersys = RenderSystem.getSingleton();
		if (key == GLFW_KEY_SPACE)
		{
			mCamMode = !mCamMode;
			if(!mCamMode)
			{
				glfwSetInputMode(rendersys.window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
			} else
			{
				glfwSetInputMode(rendersys.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
			}
		} else if (key == GLFW_KEY_PAUSE)
		{
			rendersys.saveScreen2File();
		}
	}

	/**
	*	При отпускании клавиши $(B key) вызывается эта функция.
	*/
	override void keyReleased(int key)
	{

	}

	private
	{
		Camera mCamera;
		bool mCamMode = true;
	}
}