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
        clMatProjViewInvBuff = CLBuffer(clContex, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 16*float.sizeof,
            matProjViewInv.toOpenGL);
        clLightPosBuffer = CLBuffer(clContex, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 3*float.sizeof, lightPos.m.ptr);
        clLightColorBuffer = CLBuffer(clContex, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 3*float.sizeof, lightColor.m.ptr);
        clLightCountBuffer = CLBuffer(clContex, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, int.sizeof, &lightCount);
        clDebugOutput = CLBuffer(clContex, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR, mDebugOutput.length*float.sizeof,
            mDebugOutput.ptr);
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
        writeln(mDebugOutput);
    }
    
    /**
    *   Установка тестового кирпича.
    */
    void setupVoxelBrick(CLCommandQueue clQ)
    {
        uint[][][] data = genTestData1();
        uint[][][] norm = genTestNormalData1();
        StdOctree octree1 = new StdOctree(data, norm);
    
        cl_image_format colorFormat;
        colorFormat.image_channel_data_type = CL_UNSIGNED_INT8;
        colorFormat.image_channel_order = CL_RGBA;
        
        cl_image_format normalFormat;
        normalFormat.image_channel_data_type = CL_UNSIGNED_INT8;
        normalFormat.image_channel_order = CL_RGBA;

        vec3st size = octree1.brickPoolSize;
        clBrickData = CLImage3D(mContext, CL_MEM_READ_ONLY, colorFormat, size.x, size.y, size.z, 0, 0, null);
        clNormData = CLImage3D(mContext, CL_MEM_READ_ONLY, normalFormat, size.x, size.y, size.z, 0, 0, null);
        clNodeData = CLBuffer(mContext, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, octree1.nodePoolSize, octree1.getNodeTile(0));

        writeln(octree1.brickPoolMemSize, " != ", size.x*size.y*size.z*uint.sizeof);
        assert(octree1.brickCount*216 == size.x*size.y*size.z);
        assert(octree1.brickPoolMemSize == size.x*size.y*size.z*uint.sizeof);
        clQ.enqueueWriteImage(clBrickData, CL_TRUE, [0, 0, 0], size.m, octree1.getBrickTile(0,0,0));
        clQ.enqueueWriteImage(clNormData, CL_TRUE, [0, 0, 0], size.m, octree1.getNormalTile(0,0,0));
        clQ.enqueueWriteBuffer(clNodeData, CL_TRUE, 0, octree1.nodePoolSize, octree1.getNodeTile(0));
        clQ.enqueueWriteBuffer(clLightCountBuffer, CL_TRUE, 0, int.sizeof, &lightCount);
    }

    /**
    *   Инициализурует программу. Компиляция и настройка буфферов должна быть здесь.
    */
    override void initialize(CLContext clContex, CLCommandQueue clQ, CLImage2DGL inTex, CLImage2DGL outTex, CLSampler sampler, CLBuffer screenSize)
    {
        CQ = clQ;
        
        // Собираем программу для GPU
        mProgram = CLProgram(clContex, programSource);
        mProgram.build("", clContex.devices);

        // Извлекаем ядро
        mMainKernel = mProgram.createKernel(mainKernelName);
        mMainKernel.setArgs(inTex, outTex, sampler, screenSize, clMatProjViewInvBuff, clDebugOutput);
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
        CQ.enqueueWriteBuffer(clMatProjViewInvBuff, CL_TRUE, 0, 16*float.sizeof,
            matProjViewInv.toOpenGL);
        CQ.enqueueWriteBuffer(clLightPosBuffer, CL_TRUE, 0, 3*float.sizeof, lightPos.m.ptr);
        CQ.enqueueWriteBuffer(clLightColorBuffer, CL_TRUE, 0, 3*float.sizeof, lightColor.m.ptr);
        CQ.enqueueReadBuffer(clDebugOutput, CL_FALSE, 0, mDebugOutput.length*float.sizeof,
            mDebugOutput.ptr);
    }

    private
    {
        Matrix!4 matView = Matrix!(4).identity;
        Matrix!4 matProj = Matrix!(4).identity;
        Matrix!4 matProjViewInv = Matrix!(4).identity;
        CLMemories clTexMem; 
        CLBuffer clMatProjViewInvBuff;
        CLBuffer clDebugOutput;
        CLBuffer clLightPosBuffer;
        CLBuffer clLightColorBuffer;
        CLBuffer clLightCountBuffer;
        CLBuffer clNodeData;
        CLImage3D clBrickData;
        CLImage3D clNormData;
        
        float[4] mDebugOutput;
        vec3 lightPos;
        vec3 lightColor = vec3(1.0f, 1.0f, 1.0f);
        int lightCount = 1;
        
        uint[][][] genSizedArray(size_t sizex, size_t sizey, size_t sizez)
        {
            uint[][][] data = new uint[][][sizex];
            foreach(ref yzslice; data)
            {
                yzslice = new uint[][sizey];
                foreach(ref zslice; yzslice)
                {
                    zslice = new uint[sizez];
                }
            }
            return data;
        }
        
        uint[][][] genTestData1()
        {
            enum size = 8;
            uint[][][] data = genSizedArray(size, size, size);
            
            data[1][1][1] = ColorRGBA.fastCompact(0, 150, 0, 255);
            data[0][0][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[1][0][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[2][0][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[0][0][1] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[0][0][2] = ColorRGBA.fastCompact(150, 0, 0, 255);
            
            data[0][3][0] = ColorRGBA.fastCompact(0, 30, 150, 255);
            data[1][3][0] = ColorRGBA.fastCompact(0, 30, 150, 255);
            data[0][2][0] = ColorRGBA.fastCompact(0, 30, 150, 255);

            data[4][0][0] = ColorRGBA.fastCompact(0, 30, 150, 255);
            data[4][1][0] = ColorRGBA.fastCompact(0, 30, 150, 255);
            data[4][2][0] = ColorRGBA.fastCompact(0, 30, 150, 255);
            data[7][7][7] = ColorRGBA.fastCompact(150, 0, 0, 255);

            /*data[0][3][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[1][2][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            data[1][3][0] = ColorRGBA.fastCompact(150, 0, 0, 255);
            
            data[0][2][1] = ColorRGBA.fastCompact(0, 0, 150, 255);
            data[0][3][1] = ColorRGBA.fastCompact(0, 0, 150, 255);
            data[1][2][1] = ColorRGBA.fastCompact(0, 0, 150, 255);
            data[1][3][1] = ColorRGBA.fastCompact(0, 0, 150, 255);
            
            data[3][3][0] = ColorRGBA.fastCompact(150, 0, 0, 255);*/
            return data;
        }
        
        uint[][][] genTestNormalData1()
        {
            enum size = 8;
            uint[][][] data = genSizedArray(size, size, size);
            
            foreach(ref mass1; data)
                foreach(ref mass2; mass1)
                    foreach(ref val; mass2)
                    {
                        val = NormalVectorDistr.fastCompact(0, 0, -1, 9.1);
                    }
                
            /*data[1][1][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            data[0][0][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            data[1][0][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            data[2][0][0] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            data[0][0][1] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            data[0][0][2] = NormalVectorDistr.fastCompact(0, 1, 0, 2.1);
            
            writeln(data);*/
            /*data[0][0][0] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            
            data[0][2][0] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[0][3][0] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[1][2][0] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[1][3][0] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            
            data[0][2][1] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[0][3][1] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[1][2][1] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            data[1][3][1] = NormalVectorDistr.fastCompact(0, 1, 0, 0.1);
            
            data[3][3][0] = NormalVectorDistr.fastCompact(1, 0, 0, 0.1);*/
            return data;
        }
        
        uint[] genLinearData(alias func)()
        {
            uint[][][] data = func();
            uint[] ret = new uint[data.length*data[0].length*data[0][0].length];
            int i = 0;
            foreach(ref m1; data)
                foreach(ref m2; m1)
                    foreach(val; m2)
                    {
                        ret[i++] = val;
                    }
            return ret;     
        }
        
        string tobits(uint value)
        {
            string ret = "";
            for(int i = 8*uint.sizeof-1; i >= 0; i--)
            {
                if(((value >> i) & 0x01) == 1)
                {
                    ret ~= "1";
                } else
                {
                    ret ~= "0";
                }
            }
            return ret;
        }
    }
}

import client.shaders.dsl;
import client.shaders.raytrace.matrix;
import client.shaders.raytrace.common;

/// Исходники кернела
private alias testKernel = Kernel!(MatrixKernels, CommonKernels, "testKernel", q{

    /**
    *   Отрисовывает один кирпич. 
    */
    __kernel void testKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp, __global const uint* screenSize,
        Matrix4x4 matProjViewInv, 
        __global write_only float* debugOutput)
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
            
            float4 bgcolor = (float4)(1.0f, 1.0f, 1.0f, 1.0f);
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
            
            write_imagef(output, (int2)(idx, idy), color);
        }
    }
});
