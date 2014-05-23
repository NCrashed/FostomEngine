//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Модуль, отвечающий за работу с OpenCL
/**
*	Обеспечивает сокрытие работы с OpenCL, загрузку, компиляцию, вызов кернелов,
*	копирование текстур для рендеринга между собой.
*/
module client.shaders.opencl;

import derelict.opengl3.gl3;
import opencl.all;
import util.resources.resmng;
import util.resources.archivemng;
import client.texture;

//import client.shaders.gameLife;
import client.shaders.coneRayTracing;

import util.log;

version(Windows)
    import derelict.opengl3.wgl;
else version(Posix)
    import derelict.opengl3.glx;
else
    static assert(0, "OS not supported");

enum RENDER_LOG = "RenderLog.log";

import std.stdio;
import std.math;

public
{
    /**
    *   Инициализация OpenCL: получение контекста, компиляция кернелов и создание буферов.
    */
    void initOpenCL(GLuint renderTexId1, GLuint renderTexId2, Matrix!4 viewMatrix, Matrix!4 projMatrix)
    {
    	createContex();
    	initRaycastingKernels(renderTexId1, renderTexId2);

        CQ = CLCommandQueue(clContex, clContex.devices[0]);
        //mMainProgram = new GameLifeProg();
        mRenderProg = new ConeRayTracingRendererProg();
        mMainProgram = mRenderProg;
        //auto resmng = ResourceMng.getSingleton();
        //auto tex = cast(Texture)(resmng.getResource("heightmap.png", "General"));
        
        mMainProgram.customInitialize(clContex);
        mRenderProg.projMatrix = projMatrix;
        mRenderProg.viewMatrix = viewMatrix;
        mRenderProg.setupVoxelBrick(CQ);
        mMainProgram.initialize(clContex, CQ, clRenderTexture1, clRenderTexture2, clSampler,
            clScreenSize);
        
    }

    void callKernels(int screenX, int screenY, Matrix!4 viewMatrix, Matrix!4 projMatrix)
    {
    	static float angle = 0;
    	enum dist = 3;
    	enum angVel = PI/180;
    	
        glFinish();
        
        void writingScreenSize()
        {
	        clScreenSizeData[0] = screenX;
	        clScreenSizeData[1] = screenY;
	        CQ.enqueueWriteBuffer(clScreenSize, CL_TRUE, 0, clScreenSizeData.sizeof*uint.sizeof, clScreenSizeData.ptr);        	
        }

        CQ.enqueueAcquireGLObjects(clMem);
        writingScreenSize();
        mRenderProg.projMatrix = projMatrix;
        mRenderProg.viewMatrix = viewMatrix;
        mRenderProg.lightPosition = vec3(cos(angle)*dist, 2, sin(angle)*dist);
        mRenderProg.printDebugInfo();
        
        mMainProgram.acquireGLObjects();
        mMainProgram.updateCustomBuffers();
		mMainProgram.callKernel(screenX, screenY);
		mMainProgram.releaseGLObjects();
		CQ.enqueueReleaseGLObjects(clMem);

        CQ.finish();
        
        angle += angVel;
        if(angle > 2*PI)
        {
        	angle = 0;
        }
    }

    /**
    *   Создает FBO'ы для возможности быстрого копирования содержания выходной $(B renderTexId2) текстуры во входную
    *   $(B renderTexId1). Обе текстуры должны иметь одинаковые размеры $(B sizex), $(B sizey).
    */
    void initFBO(GLuint renderTexId1, GLuint renderTexId2, int sizex, int sizey)
    {
        void initInternal(GLuint texid, out GLuint fbo)
        {
            writeln("Generating buffer");
            glGenFramebuffers(1, &fbo);
            GLuint depthTex;

            writeln("Generating depth texture");
            glGenTextures(1, &depthTex);

            glBindFramebuffer(GL_FRAMEBUFFER, fbo);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                GL_TEXTURE_2D, texid, 0);

            glBindTexture(GL_TEXTURE_2D, depthTex);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, sizex, sizey, 0,
                GL_DEPTH_COMPONENT, GL_FLOAT, null);

            glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameterf( GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);

            writeln("Binding texture");
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, 
                GL_TEXTURE_2D, depthTex, 0);
            glBindFramebuffer(GL_FRAMEBUFFER, 0);

            writeln("Checking correctness");
            if(!CheckFramebufferStatus())
            {
                writeLog("Failed to init FBO!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
                throw new Exception("Failed to init FBO!");
            }
        }

        initInternal(renderTexId1, colorFBO1);
        initInternal(renderTexId2, colorFBO2);

        fboSizeX = sizex;
        fboSizeY = sizey;
    }

    /**
    *   Быстрое копирование выходного буфера во входной. 
    */
    void copyFBOs()
    {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, colorFBO2);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, colorFBO1);
        glBlitFramebuffer(0, 0, fboSizeX, fboSizeY, 0, 0, fboSizeX, fboSizeY, 
            GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT, GL_NEAREST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    }
}

private
{
    CLContext 	clContex;
    CLCommandQueue CQ;

    CLImage2DGL clRenderTexture1, clRenderTexture2;
    CLKernelProgram mMainProgram;
    ConeRayTracingRendererProg mRenderProg;
    CLMemories 	clMem;

    CLSampler 	clSampler;
    uint[2]  	clScreenSizeData;
    CLBuffer   	clScreenSize;

    GLuint	colorFBO1, colorFBO2;
    GLuint  fboSizeX, fboSizeY;

    enum GL_DEPTH_TEXTURE_MODE = 0x884B;
    enum GL_LUMINANCE = 0x1909;

    /**
    *	Инициализирует OpenCL контекст.
    */
    void createContex()
    {
        version(Windows)
        {
            auto rawContextHandle = wglGetCurrentContext();
            auto curDC = wglGetCurrentDC();
        }
        else version(linux)
        {
            auto rawContextHandle = glXGetCurrentContext();
            auto curDisplay = glXGetCurrentDisplay();
        } else
            static assert(0, "OS not supported!");

        // Создаем контекст
        cl_context_properties[] props = null;

        version(Windows)
            props = [CL_GL_CONTEXT_KHR, cast(cl_context_properties) rawContextHandle,
                     CL_WGL_HDC_KHR, cast(cl_context_properties) curDC];
        else version(Posix)
            props = [CL_GL_CONTEXT_KHR, cast(cl_context_properties) rawContextHandle,
                     CL_GLX_DISPLAY_KHR, cast(cl_context_properties) curDisplay];
        else
            static assert(0, "OS not supported");

        clContex = CLContext(CLHost.getPlatforms()[0], CL_DEVICE_TYPE_GPU, props);    	
    }

    /**
    *	Создает ядра для tex1->tex2.
    */
    void initRaycastingKernels(GLuint renderTexId1, GLuint renderTexId2)
    {
	    clSampler = CLSampler(clContex, cast(cl_bool) false, CL_ADDRESS_CLAMP_TO_EDGE, CL_FILTER_NEAREST);
	    clScreenSize = CLBuffer(clContex, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, clScreenSizeData.sizeof*uint.sizeof, clScreenSizeData.ptr);

        // Создаем буфер из текстуры
        clRenderTexture1 = CLImage2DGL(clContex, CL_MEM_READ_ONLY, GL_TEXTURE_2D, 0, renderTexId1);
        clRenderTexture2 = CLImage2DGL(clContex, CL_MEM_WRITE_ONLY, GL_TEXTURE_2D, 0, renderTexId2);
        clMem = CLMemories([clRenderTexture1, clRenderTexture2]);
	}

	bool CheckFramebufferStatus( bool silent = false)
	{
	    GLenum status;
	    status = cast(GLenum) glCheckFramebufferStatus(GL_FRAMEBUFFER);
	    switch(status) {
	        case GL_FRAMEBUFFER_COMPLETE:
	            break;
	        case GL_FRAMEBUFFER_UNSUPPORTED:
	            if (!silent) writeln("Unsupported framebuffer format");
	            return false;
	        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
	            if (!silent) writeln("Framebuffer incomplete, missing attachment");
	            return false;
	        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
	            if (!silent) writeln("Framebuffer incomplete, duplicate attachment");
	            return false;
	        case GL_INVALID_FRAMEBUFFER_OPERATION:
	            if (!silent) writeln("Framebuffer incomplete, invalid operation");
	            return false;
	        case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
	            if (!silent) writeln("Framebuffer incomplete, missing draw buffer");
	            return false;
	        case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
	            if (!silent) writeln("Framebuffer incomplete, missing read buffer");
	            return false;
	        default:
	            assert(0);
	            return false;
	    }
	    return true;
	}
}