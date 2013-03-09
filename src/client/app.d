/// Клиентское основное приложение
/**
*	@file client/app.d Приложение доступно отовсюду, используя getSingleton. Здесь реализован бесконечный
*	цикл отрисовки и проверки событий, также здесь будет вызываться обработка физики.
*/
module client.app;

import util.singleton;
import util.log;
import util.matrix;
import util.common;

import client.rendersys;
import client.scenemanager;

import util.resources.resmng;
import util.resources.archivemng;

import client.texture;
import clmodel = client.model.model;
import client.model.material;

import client.camera;
import client.clworld;
import client.mainworld;

import std.stdio;
import std.concurrency;
import std.math;
import core.time;

class App 
{
	mixin Singleton!App;

	private this()
	{
		mainThread = thisTid;

		ResourceMng.getSingleton().loadGroupsFromFile();
		rendersys = RenderSystem.getSingleton();
		rendersys.initRenderSys("Fostom Engine");
		rendersys.setSceneManager(STD_SCENE_MANAGER);

		initScene();
		
		loadWorld(new MainWorld);
	}
	
	/// Бесконечный цикл, в котором крутится приложение
	void startLooping()
	{
		while( running )
		{
			// Timing
			rendersys.renderTiming();

			// FPS counter
			debug
			{
				double currentTime = glfwGetTime();
				nbFrames++;
				if ( currentTime - lastTime >= 1.0 )
				{ // If last prinf() was more than 1 sec ago
				  // printf and reset timer
		 			writeln( 1000.0/cast(double)(nbFrames), " ms/frame");
					nbFrames = 0;
					lastTime += 1.0;
				}
		    }

		    rendersys.drawScene(mCamera);
		    //rendersys.drawScenePoly(mCamera);

			// Swap buffers
			glfwSwapBuffers(rendersys.windowPtr);
			glfwPollEvents();

			update(rendersys.timing);

			// Check if we are still running
			running = running && rendersys.shouldContinue();

			// Reading messages from other threads
			auto gotMessage = receiveTimeout(
				dur!"nsecs"(1),
				&proceedEvent );
   		}
	}

	/// Завершение работы приложения
	/**
	*	@todo Сделать многопоточность
	*/
	void shouldExit()
	{
		running = false;
	}

	~this()
	{

	}

	/**
	*	Загружает мир, если был активен другой
	*	мир, предварительно выгружает его.
	*/
	void loadWorld(ClientWorld world)
	{
		if(mCurrWorld !is null)
			mCurrWorld.unload();

		mCurrWorld = world;

		mCamera.position.x = 0;
		mCamera.position.y = 0;
		mCamera.position.z = 0;
		mCamera.target = vec3(0, 0, -1);

		rendersys.sceneManager.clearScene();

		mCurrWorld.init(mCamera);
	}

	/**
	*	Устанавливает текущую камеру.
	*/
	void setActiveCam(Camera cam)
	{
		mCamera = cam;
	}
private:
	/// Показывает, что приложение работает. Как только меняется на false идет завершение работы.
	__gshared bool running = true;

	/// Текущий активный мир
	ClientWorld mCurrWorld;

	/// Текущая камера игрока
	Camera mCamera;

	RenderSystem rendersys;

	/// Старые позиции мышки
	static int oldposx;
	static int oldposy;

	// FPS counter
	debug
	{
	 	double lastTime;
	 	int nbFrames;
	}

	/// Главный поток программы
	static extern(C) __gshared Tid mainThread;

	void proceedEvent(string msg, int p1, int p2)
	{
		if (msg == "resize")
		{
			auto newConf = rendersys.graphicConfigs;
			newConf.screenX = p1;
			newConf.screenY = p2;
			rendersys.graphicConfigs = newConf;
		} else if (msg == "mpos")
		{
			mousePosEvent(p1, p2);
		} else if (msg == "press")
		{
			keyPressed(p1);
		} else if (msg == "release")
		{
			keyReleased(p1);
		}
	}

	/// Загрузка начальной сцены
	void initScene()
	{
		import std.stream;
		/// Заливка фона
		
		glfwSetWindowSizeCallback(rendersys.windowPtr, &reshape );  
		glfwSetCursorPosCallback(rendersys.windowPtr, &mouseUpdate );
		glfwSetKeyCallback(rendersys.windowPtr, &charUpdate);

		glfwSetInputMode(rendersys.windowPtr, GLFW_CURSOR_MODE, GLFW_CURSOR_CAPTURED);

		// Создание камеры
		mCamera = new Camera;  

		mCamera.position.x = 0;
		mCamera.position.y = 0;
		mCamera.position.z = 0;
		
		mCamera.target = vec3(0, 0, -1);

		// Инициализация мышки
		oldposx = rendersys.graphicConfigs.screenX/2;
		oldposy = rendersys.graphicConfigs.screenY/2;
		
		// FPS counter
		debug
		{
	 		lastTime = glfwGetTime();
	 		nbFrames = 0;
	 	}
	}

	/// Обновление всех систем
	void update(double dt)
	{
		mCurrWorld.update(rendersys.windowPtr, dt);

		// Апдейт камеры
		mCamera.update(dt);
	}

	/// Обновление позиции мышки
	void mousePosEvent(int xpos, int ypos)
	{
		int dx = xpos-oldposx;
		int dy = ypos-oldposy;

		mCurrWorld.mousePosEvent(dx, dy, xpos, ypos);

		oldposx = xpos;
		oldposy = ypos;

	}

	/// Обработка нажатия клавиши
	void keyPressed(int key)
	{
		mCurrWorld.keyPressed(key);
	}

	/// Обработка отпускания клавиши
	void keyReleased(int key)
	{
		mCurrWorld.keyReleased(key);
	}

	/// Обновление положения мышки
	/**
	*	Вызывается сама через GLFW3
	*/
	extern(C) static void mouseUpdate(GLFWwindow* window, int xpos, int ypos)
	{
		mainThread.send("mpos",xpos,ypos);
	}

	/// Обновление окна при resize
	/**
	*	Вызывается сама через GLFW3
	*/
	extern(C) static void reshape(GLFWwindow* window, int w, int h )
	{
		mainThread.send("resize",w,h);
	}

	/// Событие нажатия клавиш
	/**
	*	Вызывается сама через GLFW3
	*/
	extern(C) static void charUpdate(GLFWwindow* window,  int key, int action)
	{
		if(action == GLFW_PRESS)
		{
			mainThread.send("press",key,0);
		} else if(action == GLFW_RELEASE)
		{
			mainThread.send("release",key,0);
		}
	}
}