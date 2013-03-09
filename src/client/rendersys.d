//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Модуль, занимающийся отрисовкой на клиенте
/**
*	@file rendersys.d В модуле описаны все необходимое для отрисовки графики.
*	@todo Разделить модуль на несколько подсистем.
*/
module client.rendersys;

public
{
	import derelict.opengl3.gl3;
	import derelict.glfw3.glfw3;
	import derelict.freeimage.freeimage;
}
import client.shaders.opencl;

import util.log;
import util.common;
import util.resources.resmng;
import util.matrix;
import util.singleton;
import clmodel = client.model.model;

import util.resources.resmng;
import client.graphconf;
import client.camera;
import client.model.model;

import client.texture;
import client.scenemanager;
//import client.stdscenemanager;

import std.conv;
import std.string;
import std.array;
import std.stdio;
import std.exception;
import std.datetime;
import std.algorithm;
import std.path;

enum RENDER_LOG = "RenderLog.log";
enum SHADERS_GROUP = "General";
enum STD_SCENE_MANAGER = "client.stdscenemanager.StdSceneManager";


/// Занимается отрисовкой сцены на экран
/**
*   @todo Нужно заставить SceneManager сортировать объекты по удалению от камеры
*/
class RenderSystem
{
    mixin Singleton!RenderSystem;

    this()
    {
        version(Windows)
        {
            DerelictGL3.load();
            DerelictGLFW3.load();
            DerelictFI.load();
        }
        version(linux)
        {
            DerelictGL3.load();
            DerelictGLFW3.load("./libglfw.so");
            DerelictFI.load();      
        }

        createLog(RENDER_LOG);

        writeLog("Initing GLFW3...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        if ( !glfwInit() )
        {
            writeLog("Failed to init GLF3!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("Failed to init GLFW3!");
        }

        // Вообще я был удивлен, что кастом можно добавить флаг nothrow к функции Оо
        writeLog("Initing FreeImage...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        FreeImage_SetOutputMessage(cast(FreeImage_OutputMessageFunction)&RenderSystem.FreeImageErrorHandler);
    }

    /// Инициализация системы отрисовки
    void initRenderSys(string windowTitle)
    {
        initWindow(windowTitle);
        initExtOpengl();
        initGl();
        loadStdShaders();

        // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
        mProjection = projection(deg2rad(45.0f), cast(float)mGraphicConfigs.screenY / cast(float)mGraphicConfigs.screenX, 0.1f, 100.0f); 

        initOpenCL(renderTexId1, renderTexId2, Matrix!(4).identity, mProjection);
        initFBO(renderTexId1, renderTexId2, mGraphicConfigs.screenX, mGraphicConfigs.screenY);

        if(!ARB_framebuffer_object)
        {
            writeLog("ARB_framebuffer_object extention wasn't found! Fatal error!",LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("ARB_framebuffer_object extention wasn't found! Fatal error!");
        }
    }
    
    /// Отрисовка сцены
    /**
    *   @par camera Камера, для которой будет отрисована сцена
    */
    void drawScenePoly(Camera camera)
    {
        enforce(mScenemng !is null, "SceneManager not selected! Please load manager with RenderSystem.setSceneManager(string name)!");

        auto tuples = mScenemng.getToRender(camera);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        foreach(t; tuples)
        {
            auto mesh = t.mesh;
            auto node = t.node;
            // Итого у нас есть model, node, camera
            mModel = node.modelMatrix;
            mView = camera.getMatrix();

            loadModel(mesh);
			mesh.applyOptions();
			
            mMVP =  mProjection*(mView*mModel);

            vec3 lightPos = vec3(1,2,1);
            // Use our shader
            glUseProgram(programID);
            glUniformMatrix4fv(MatrixID, 1, GL_FALSE, mMVP.toOpenGL());
            glUniformMatrix4fv(ModelMtrxID, 1, GL_FALSE, mModel.toOpenGL());
            glUniformMatrix4fv(CameraMtrxID, 1, GL_FALSE, mView.toOpenGL());
            glUniformMatrix4fv(MVMtrxID, 1, GL_FALSE, (mModel*mView).toOpenGL());
            glUniform3f(LightPosID, lightPos.x, lightPos.y, lightPos.z);

            // Bind our texture in Texture Unit 0
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, mesh.texture);
			
            // Set our "myTextureSampler" sampler to user Texture Unit 0
            glUniform1i(TextureID, 0);

            // 1rst attribute buffer : vertices
            glEnableVertexAttribArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, mVertexBuffer);
            glVertexAttribPointer(
                0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
                3,                  // size
                GL_FLOAT,           // type
                GL_FALSE,           // normalized?
                0,                  // stride
                null            // array buffer offset
            );

            glEnableVertexAttribArray(1);
            glBindBuffer(GL_ARRAY_BUFFER, mUvBuffer);
            glVertexAttribPointer(
                1,                                // attribute. No particular reason for 1, but must match the layout in the shader.
                2,                                // size
                GL_FLOAT,                         // type
                GL_FALSE,                         // normalized?
                0,                                // stride
                null                          // array buffer offset
            );

            // 3rd attribute buffer : normals
            glEnableVertexAttribArray(2);
            glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
            glVertexAttribPointer(
                2,                                // attribute
                3,                                // size
                GL_FLOAT,                         // type
                GL_FALSE,                         // normalized?
                0,                                // stride
                null                          // array buffer offset
            );

            // Index buffer
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mElementBuffer);
                             
            // Draw the triangles !
            glDrawElements(
                GL_TRIANGLES,          // mode
                cast(uint)mesh.indecies.length,  // count
                GL_UNSIGNED_INT,       // type
                null                   // element array buffer offset
            );

            glDisableVertexAttribArray(0);
            glDisableVertexAttribArray(1);
            glDisableVertexAttribArray(2);

            unloadModel();
        }
    }

    void drawScene(Camera camera)
    {
        enforce(mScenemng !is null, "SceneManager not selected! Please load manager with RenderSystem.setSceneManager(string name)!");

        //auto tuples = mScenemng.getToRender(camera);
        

        /*foreach(t; tuples)
        {
            auto mesh = t.mesh;
            auto node = t.node;
            // Итого у нас есть model, node, camera
            mModel = node.modelMatrix;
            mView = camera.getMatrix();

            loadModel(mesh);
            mesh.applyOptions();
            
            mMVP =  mProjection*(mView*mModel);

            unloadModel();
        }*/
        callKernels(mGraphicConfigs.screenX, mGraphicConfigs.screenY, camera.getMatrix(), mProjection); 
        drawQuad();

        copyFBOs();
    }
    
    void drawQuad()
    {
        auto mesh = mQuadMesh;
        mesh.applyOptions();

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Use our shader
        glUseProgram(quadProgram);

        // Bind our texture in Texture Unit 0
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, renderTexId2);
        
        // Set our "myTextureSampler" sampler to user Texture Unit 0
        glUniform1i(quadTextureID, 0);

        // 1rst attribute buffer : vertices
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, mQuadVertexBuffer);
        glVertexAttribPointer(
            0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
            3,                  // size
            GL_FLOAT,           // type
            GL_FALSE,           // normalized?
            0,                  // stride
            null            // array buffer offset
        );

        glEnableVertexAttribArray(1);
        glBindBuffer(GL_ARRAY_BUFFER, mQuadUvBuffer);
        glVertexAttribPointer(
            1,                                // attribute. No particular reason for 1, but must match the layout in the shader.
            2,                                // size
            GL_FLOAT,                         // type
            GL_FALSE,                         // normalized?
            0,                                // stride
            null                          // array buffer offset
        );

        // Index buffer
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mQuadElementBuffer);
                         
        // Draw the triangles !
        glDrawElements(
            GL_TRIANGLES,          // mode
            cast(uint)mesh.indecies.length,  // count
            GL_UNSIGNED_INT,       // type
            null                   // element array buffer offset
        );

        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
    }

    /// Сохраняет текущее отрендеренное изображение в файл
    void saveScreen2File(string name = "")
    {
        if(name.length == 0)
            name = Clock.currTime().toISOString();

        glBindBuffer(GL_TEXTURE_2D, renderTexId2);
        glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
        GLint width, height;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);

        auto bitmap = FreeImage_Allocate(width, height, 32, 0xFF000000u, 0x00FF0000u, 0x0000FF00u);
        auto texture = new ubyte[4*width*height];
        char* pixels = cast(char*)FreeImage_GetBits(bitmap);

        glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture.ptr);

        writeln("save");
        for(int pix=0; pix<mGraphicConfigs.screenX*mGraphicConfigs.screenY; pix++)
        {
            pixels[pix*uint.sizeof+2] = (cast(char*)&texture[pix*uint.sizeof])[0];
            pixels[pix*uint.sizeof+1] = (cast(char*)&texture[pix*uint.sizeof])[1];
            pixels[pix*uint.sizeof+0] = (cast(char*)&texture[pix*uint.sizeof])[2];
            pixels[pix*uint.sizeof+3] = (cast(char*)&texture[pix*uint.sizeof])[3];
        }

        string basepath;
        try basepath = ResourceMng.getSingleton().getByName("Images").basePath;
        catch(Exception e)
        {
            writeLog("Failed to save texture to "~name~", because: "~e.msg);
            return;
        }

        FreeImage_Save(FIF_PNG, bitmap, toStringz(basepath~dirSeparator~name~".png"), 0);
        FreeImage_Unload(bitmap);
    }

    /// Получение текущих графических настроек
    @property const GraphConf graphicConfigs()
    {
        return mGraphicConfigs;
    }

    @property void graphicConfigs(GraphConf val)
    {
        mGraphicConfigs = val;

        mProjection = projection(deg2rad(45.0f), cast(float)mGraphicConfigs.screenY / cast(float)mGraphicConfigs.screenX, 0.1f, 100.0f); 
        glfwSetWindowSize(mWindow, val.screenX, val.screenY);
        glViewport(0,0,val.screenX, val.screenY);
    }

    /// Получение окна приложения
    @property GLFWwindow window()
    {
        return mWindow;
    }

    /// Получение времени с предыдущего кадра
    @property double timing()
    {
        return dt;
    }

    /// Установка нужного SceneManager
    void setSceneManager(string name)
    {
        mScenemng = cast(SceneManager)Object.factory(name);
        enforce(mScenemng !is null, "Failed to load "~name~" scene manager!");
    }

    ~this()
    {
        glDeleteProgram(programID);
        glDeleteProgram(quadProgram);
        glDeleteVertexArrays(1, &mVertexArrayID);      

        glDeleteBuffers(1, &mVertexBuffer);
        glDeleteBuffers(1, &mUvBuffer);
        glDeleteBuffers(1, &mNormalBuffer); 

        glDeleteBuffers(1, &mQuadVertexBuffer);
        glDeleteBuffers(1, &mQuadUvBuffer);
        glDeleteBuffers(1, &mQuadNormalBuffer); 
    }

    /// Замер скорости отрисовки
    /**
    *   @return Время от предыдущего запуска функции.
    */
    double renderTiming()
    {
        t = glfwGetTime();
        dt = t - t_old;
        t_old = t;
        return dt;
    }

    /// Условие продолжения выполнения приложения
    /**
    *   @return false - выходим из приложения
    */
    bool shouldContinue()
    {
        return (glfwIsWindow(mWindow) == 1);
    }

    /// Получение текущего сцен менджера
    @property SceneManager sceneManager()
    {
        return mScenemng;
    }

private:

    /// После загрузки настройки графики хранятся здесь
    GraphConf mGraphicConfigs;

    /// Окно приложения
    GLFWwindow mWindow;
    /// Переменные для замера скорости отрисовки
    double t = 0., t_old = 0., dt = 0.;

    /// Матрицы, которые передаются в шейдер
    Matrix!4 mView;
    Matrix!4 mProjection;
    Matrix!4 mModel;
    Matrix!4 mMVP;

    /// Временные переменные для шейдеров
    /// Этим должен заниматься менджер шейдеров
    GLuint programID; //temp
    GLuint MatrixID;
    GLuint ModelMtrxID;
    GLuint CameraMtrxID;
    GLuint TextureID;
    GLuint MVMtrxID;
    GLuint LightPosID;

    /// Буферы
    GLuint mVertexArrayID;
    GLuint mVertexBuffer;
    GLuint mUvBuffer;
    GLuint mNormalBuffer;
    GLuint mElementBuffer;

    clmodel.Mesh mQuadMesh;
    GLuint mQuadVertexBuffer;
    GLuint mQuadUvBuffer;
    GLuint mQuadNormalBuffer;
    GLuint mQuadElementBuffer;

    // Рендеринг в текстуру
    GLuint renderTexId1, renderTexId2;

    // Для вывода текстуры на экран
    GLuint quadProgram;
    GLuint quadTextureID;


    SceneManager mScenemng;
private:

    /// Обработчик ошибок FreeImage
    /**
    *   @par fif Формат или плагин, который ответственен за ошибку
    *   @par message Сообщение об ошибке
    */
    extern(C) static void FreeImageErrorHandler(FREE_IMAGE_FORMAT fif, const char *msg) 
    {
        if(fif != FIF_UNKNOWN)
        {
            writeLog(fromStringz(FreeImage_GetFormatFromFIF(fif))~" Format: "~fromStringz(msg), LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
        } else
        {
            writeLog("Unknown Format: "~fromStringz(msg), LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
        }
    }


    /// Инициализация opengl
    /**
    *   @todo Большую часть перенести в материалы
    */
    void initGl()
    {
        writeLog("Initing opengl...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        glGenVertexArrays(1, &mVertexArrayID);
        glBindVertexArray(mVertexArrayID);

        // Enable depth test
        glEnable(GL_DEPTH_TEST);
        // Accept fragment if it closer to the camera than the former one
        glDepthFunc(GL_LESS);
        glEnable(GL_CULL_FACE);

        // Enable blending
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

        glGenBuffers(1, &mVertexBuffer);
        glGenBuffers(1, &mUvBuffer);
        glGenBuffers(1, &mNormalBuffer);
        glGenBuffers(1, &mElementBuffer);

        glGenBuffers(1, &mQuadVertexBuffer);
        glGenBuffers(1, &mQuadUvBuffer);
        glGenBuffers(1, &mQuadNormalBuffer);
        glGenBuffers(1, &mQuadElementBuffer);

        // Рендеринг в текстуру
        void initTexture(ref GLuint texid)
        {
            glGenTextures(1, &texid);
            glBindTexture(GL_TEXTURE_2D, texid);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16, mGraphicConfigs.screenX, mGraphicConfigs.screenY, 0,GL_RGBA, GL_UNSIGNED_SHORT, null);
 
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        initTexture(renderTexId2);
        //initTexture(renderTexId1);

        void initTestTexture(ref GLuint texid)
        {
            import std.random;
            auto filler = new ubyte[4*mGraphicConfigs.screenX*mGraphicConfigs.screenY];
            for(size_t i = 0; i<mGraphicConfigs.screenX*mGraphicConfigs.screenY; i++)
            {
                if (uniform!"[]"(0.0, 1.0) <= 0.3)
                    filler[i*4] = ubyte.max;
                else
                    filler[i*4] = ubyte.min;

                filler[i*4+3] = ubyte.max;
            }

            //glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture.ptr);
            glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
            glGenTextures(1, &texid);
            glBindTexture(GL_TEXTURE_2D, texid);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16, mGraphicConfigs.screenX, mGraphicConfigs.screenY, 0,GL_RGBA, GL_UNSIGNED_BYTE, filler.ptr);
 
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        initTestTexture(renderTexId1);
        //saveScreen2File("debug");
        //assert(false);
        //renderTexId1 = renderTexId2;

        mQuadMesh = loadQuadModel();
    }

    clmodel.Mesh loadQuadModel()
    {
        auto resmng = ResourceMng.getSingleton();
        auto mesh = (cast(clmodel.Model)(resmng.getResource("quad.obj", "General"))).meshes[0];

        glBindBuffer(GL_ARRAY_BUFFER, mQuadVertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.vertecies.length*float.sizeof, mesh.vertecies.ptr, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, mQuadUvBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.uvs.length*float.sizeof, mesh.uvs.ptr, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, mQuadNormalBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.normals.length*float.sizeof, mesh.normals.ptr, GL_STATIC_DRAW);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mQuadElementBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indecies.length*uint.sizeof, mesh.indecies.ptr, GL_STATIC_DRAW);
        return mesh;
    }

    /// Загрузка стандартных шейдеров
    /**
    *   @todo Работу с шейдерами перенести в менеджер с шейдерами.
    */
    void loadStdShaders()
    {
        writeLog("Initing shaders...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        // Create and compile our GLSL program from the shaders
        programID = LoadShaders( "../Media/Shaders/VertexShader.glsl", "../Media/Shaders/FragmentShader.glsl" );

        MatrixID = glGetUniformLocation(programID, "MVP");
        ModelMtrxID = glGetUniformLocation(programID, "M");
        CameraMtrxID = glGetUniformLocation(programID, "V");
        MVMtrxID = glGetUniformLocation(programID, "MV");
        LightPosID = glGetUniformLocation(programID, "LightPosition_worldspace");

        // Get a handle for our "myTextureSampler" uniform
        TextureID  = glGetUniformLocation(programID, "myTextureSampler");

        quadProgram = LoadShaders("../Media/Shaders/QuadVertexShader.glsl", "../Media/Shaders/QuadFragmentShader.glsl");
        quadTextureID  = glGetUniformLocation(programID, "myTextureSampler");
    }

    /// Загружаем продвинутый OpenGL
    void initExtOpengl()
    {
        GLVersion glver = DerelictGL3.reload();
        writeLog("OpenGL version: "~to!string(DerelictGL3.loadedVersion), LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);

        if(DerelictGL3.loadedVersion < GLVersion.GL30)
        {
            writeLog("OpenGL version too low!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("OpenGL version too low!");
        }
        if(!ARB_sync)
        {
            writeLog("No ARB_sync extension detected!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("No ARB_sync extension detected!");
        }
    }

    /// Создание окна приложения
    /**
    *   @par tittle Заголовок окна
    */
    void initWindow(string tittle)
    {
        writeLog("Initing app window...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);

        // Получаем графические настройки
        GraphConf grConf;
        if (!isConfExists(GRAPH_CONF))
            writeConf(GRAPH_CONF, grConf);
        else
            grConf = readConf!GraphConf(GRAPH_CONF);

        // Загружаем окно
        glfwOpenWindowHint(GLFW_DEPTH_BITS, grConf.depthBits);
        glfwOpenWindowHint(GLFW_FSAA_SAMPLES, 4);

        mWindow = glfwOpenWindow( grConf.screenX, grConf.screenY, grConf.getWindowMode(), toStringz(tittle), null );
        if ( mWindow is null)
        {
            writeLog("Failed to create window!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("Failed to create window!");
        }
        
        glfwSetInputMode( mWindow, GLFW_STICKY_KEYS, GL_TRUE );
        glfwSetTime( 0.0 );

        // Включение вертикальной синхронизации
        if (grConf.vertSync) setVsync(true);

        mGraphicConfigs = grConf;
    }

    /// Вулючение и выключение вертикальной синхронизации
    void setVsync(bool flag)
    {
        glfwSwapInterval(flag ? 1 : 0);
    }

    void loadModel(Mesh mesh)
    {
        //static bool test = true;
        //if(!test) return;
        //test = false;

        // Generate 1 buffer, put the resulting identifier in vertexbuffer
        // The following commands will talk about our 'vertexbuffer' buffer
        glBindBuffer(GL_ARRAY_BUFFER, mVertexBuffer);
        // Give our vertices to OpenGL.
        glBufferData(GL_ARRAY_BUFFER, mesh.vertecies.length*float.sizeof, mesh.vertecies.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ARRAY_BUFFER, mUvBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.uvs.length*float.sizeof, mesh.uvs.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.normals.length*float.sizeof, mesh.normals.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mElementBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indecies.length*uint.sizeof, mesh.indecies.ptr, GL_STATIC_DRAW);
    }

    void unloadModel()
    {

    }

}



/// Загрузка основных шейдеров
private GLuint LoadShaders(string vertex_file_path, string fragment_file_path)
{
    // Create the shaders
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
 	auto rmng = ResourceMng.getSingleton();

    // Read the Vertex Shader code from the file
    string VertexShaderCode;
    string fullname;
    auto VertexShaderFile = rmng.loadFile(vertex_file_path, SHADERS_GROUP, fullname);
    while(!VertexShaderFile.eof())
    {
    	string line = VertexShaderFile.readLine().idup;
    	VertexShaderCode ~= "\n" ~ line;
    }


    string FragmentShaderCode;
    auto FragmentShaderFile = rmng.loadFile(fragment_file_path, SHADERS_GROUP, fullname);
    while(!FragmentShaderFile.eof())
    {
    	string line = FragmentShaderFile.readLine().idup;
    	FragmentShaderCode ~= "\n" ~ line;
    }
    FragmentShaderFile.close();

    GLint Result = GL_FALSE;
    int InfoLogLength;
 
    // Compile Vertex Shader
    writeLog("Compiling shader : "~vertex_file_path, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    auto VertexSourcePointer = toStringz(VertexShaderCode);
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , null);
    glCompileShader(VertexShaderID);
 
    // Check Vertex Shader
    glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    auto VertexShaderErrorMessage = new char[InfoLogLength];
    glGetShaderInfoLog(VertexShaderID, InfoLogLength, null, &VertexShaderErrorMessage[0]);
    writeLog(VertexShaderErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
 
    // Compile Fragment Shader
    writeLog("Compiling shader : "~fragment_file_path, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    auto FragmentSourcePointer = toStringz(FragmentShaderCode);
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , null);
    glCompileShader(FragmentShaderID);
 
    // Check Fragment Shader
    glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    auto FragmentShaderErrorMessage = new char[InfoLogLength];
    glGetShaderInfoLog(FragmentShaderID, InfoLogLength, null, &FragmentShaderErrorMessage[0]);
    writeLog(FragmentShaderErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
 
    // Link the program
    writeLog("Linking program", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    GLuint ProgramID = glCreateProgram();
    glAttachShader(ProgramID, VertexShaderID);
    glAttachShader(ProgramID, FragmentShaderID);
    glLinkProgram(ProgramID);
 
    // Check the program
    glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
    glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    auto ProgramErrorMessage = new char[InfoLogLength];
    glGetProgramInfoLog(ProgramID, InfoLogLength, null, &ProgramErrorMessage[0]);
    writeLog(ProgramErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
 
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
 
    return ProgramID;
}