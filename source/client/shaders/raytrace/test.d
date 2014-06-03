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
*   Testing drawing.
*/
module client.shaders.raytrace.test;

public 
{
    import client.shaders.clprog;
    import util.matrix;
    import derelict.opengl3.gl3;
}

import util.model.octree;
import util.color;
import std.stdio;

import client.shaders.dsl;
import client.shaders.raytrace.matrix;
import client.shaders.raytrace.common;
import client.shaders.doutput;

debug
{
    import std.stdio;
    import std.process;
    
    void dbg(T...)(T args)
    {
        writeln(args);
    }
    
    void debugList(T)(SList!T list, void delegate(T element) debugPrint)
    {
        foreach(el; list)
        {
            debugPrint(el);
        }
    }
    
    void listSize(T)(SList!T list)
    {
        size_t l = 0;
        foreach(el; list) l++;
        dbg("List size: ", l);
    }
    
    void pause()
    {
        system("pause");
    }
}


class TestRendererProg : CLKernelProgram
{
    /// Имя входного kernel'а
    override string mainKernelName() @property
    {
        return testKernel.kernelName;
    }

    /// Исходные коды kernel'a
    override string programSource() @property
    {
        return testKernel.sources;
    }

    /**
    *   Инициализация дополнительных буферов.
    */
    override void customInitialize(CLContext clContex)
    {
        mContext = clContex;
        gpuMatProjViewInv = GPUMatrix4x4(clContex);
        gpuDebugOutput = DOutput(clContex);
    }

    /**
    *   Установка P матрицы.
    */
    void projMatrix(Matrix!4 mtrx) @property 
    {
        matProj = mtrx;
        try
        {
            matProjViewInv = (matProj * matView).inverse();
        } catch(MatrixNoInverse exp)
        {
            //std.stdio.writeln("NO INVERSE! PAIN!");
        }
    }

    /**
    *   Установка V матрицы.
    */
    void viewMatrix(Matrix!4 mtrx) @property 
    {
        matView = mtrx;
        try
        {
            matProjViewInv = (matProj * matView).inverse();
        } catch(MatrixNoInverse exp)
        {
            writeln("Something wreid!");
        }
    }
    
    /**
    *   Выводит на экран отладочную информацию. 
    */
    void printDebugInfo()
    {
        writeln(tempBuffer);
    }

    /**
    *   Инициализурует программу. Компиляция и настройка буфферов должна быть здесь.
    */
    override void initialize(CLContext clContex, CLCommandQueue clQ, CLImage2DGL inTex, CLImage2DGL outTex, CLSampler sampler, GPUScreenSize screenSize)
    {
        CQ = clQ;
        
        // Собираем программу для GPU
        mProgram = CLProgram(clContex, programSource);
        mProgram.build("", clContex.devices);

        // Извлекаем ядро
        mMainKernel = mProgram.createKernel(mainKernelName);
        mMainKernel.setArgs(inTex, outTex, sampler, screenSize.buffer, gpuMatProjViewInv.buffer, gpuDebugOutput.buffer);
    }

    override void acquireGLObjects()
    {
        //CQ.enqueueAcquireGLObjects(clTexMem);
    }
    
    override void releaseGLObjects()
    {
        //CQ.enqueueReleaseGLObjects(clTexMem);
    }
    
    /**
    *   Между вызовами кернелов можно обновить буферы для дополнительных аргументов.
    */
    override void updateCustomBuffers()
    {
        gpuMatProjViewInv.write(CQ, matProjViewInv);
        tempBuffer = gpuDebugOutput.read(CQ);
    }

    private
    {
        Matrix!4 matView = Matrix!(4).identity;
        Matrix!4 matProj = Matrix!(4).identity;
        Matrix!4 matProjViewInv = Matrix!(4).identity;
        
        alias DOutput = GPUDebugOutput!(4, float);
        DOutput.BufferType tempBuffer;
        DOutput gpuDebugOutput;
        
        GPUMatrix4x4 gpuMatProjViewInv;
    }
}

/// Исходники кернела
private alias testKernel = Kernel!(DebugOutputKernels, MatrixKernels, CommonKernels, "testKernel", q{

    /**
    *   Отрисовывает один кирпич. 
    */
    __kernel void testKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp
        , ScreenSize screenSize, Matrix4x4 matProjViewInv, DebugOutput debugOutput)
    {
        const int idx = get_global_id(0);
        const int idy = get_global_id(1);
        
        if (idx < screenSize[0] && idy < screenSize[1])
        {
            float3 rayDir, rayOrigin;
            if(!getPixelRay(matProjViewInv, screenSize[0], screenSize[1], idx, idy, &rayDir, &rayOrigin))
            {
                return;
            }
            
            float3 minBox = (float3)(0, 0, 5);
            float3 maxBox = (float3)(5, 5, 10);
            float t0, t1;
            
            float4 bgcolor = (float4)(0.0f, 0.0f, 0.0f, 1.0f);
            float4 color = bgcolor;
            
            if(boxIntersect(rayDir, rayOrigin, minBox, maxBox, &t0, &t1) && t1 > 0)
            {
                if(t0 < 0)
                {
                    t0 = 0;
                }

                color.x = 1.0f;
                color.y = 1.0f;
                color.z = 0.0f;
                color.w = 1.0f;
            }
            
            // Lets play wit blur!
//            #define blurConst 0.2f
//            float4 prevColor = read_imagef(texture, smp, (int2)(idx, idy));
//            color.x = blurConst*color.x + (1.0f-blurConst)*prevColor.x;
//            color.y = blurConst*color.y + (1.0f-blurConst)*prevColor.y;
//            color.z = blurConst*color.z + (1.0f-blurConst)*prevColor.z;
            
            debugOutput[0] = 0.0f;
            debugOutput[1] = 0.0f;
            debugOutput[2] = 0.0f;
            debugOutput[3] = 0.0f;
            write_imagef(output, (int2)(idx, idy), color);
        }
    }
});
