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
        return "renderKernel";
    }

    /// Исходные коды kernel'a
    override string programSource() @property
    {
        return coneRayTracingProgSource;
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
        mMainKernel.setArgs(inTex, outTex, sampler, screenSize, clMatProjViewInvBuff, clNodeData, clBrickData, clNormData, clLightPosBuffer, clLightColorBuffer, clLightCountBuffer, clDebugOutput);
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

/// Исходники кернела
private enum coneRayTracingProgSource = q{

    /**
    *   Получает следующий воксель, в который ударился луч.
    */
    float4 traverseBrick(read_only image3d_t brick, sampler_t smp, float3* oldtMax, int3* oldPos, int3 step, float3 delta, int3 justOut)
    {
        float tMaxX = (*oldtMax).x, tMaxY = (*oldtMax).y, tMaxZ = (*oldtMax).z;
        int X = (*oldPos).x, Y = (*oldPos).y, Z = (*oldPos).z;
        float4 color;
        do
        {
            if(tMaxX < tMaxY)
            {
                if(tMaxX < tMaxZ)
                {
                    X = X + step.x;
                    if(X == justOut.x)
                        return (float4)(-1.0f, -1.0f, -1.0f, -1.0f);
                    tMaxX = tMaxX + delta.x;    
                } else
                {
                    Z = Z + step.z;
                    if(Z == justOut.z)
                        return (float4)(-1.0f, -1.0f, -1.0f, -1.0f);
                    tMaxZ = tMaxZ + delta.z;    
                }
            } else
            {
                if(tMaxY < tMaxZ)
                {
                    Y = Y + step.y;
                    if(Y == justOut.y)
                        return (float4)(-1.0f, -1.0f, -1.0f, -1.0f);
                    tMaxY = tMaxY + delta.y;    
                } else
                {
                    Z = Z + step.z;
                    if(Z == justOut.z)
                        return (float4)(-1.0f, -1.0f, -1.0f, -1.0f);
                    tMaxZ = tMaxZ + delta.z;    
                }
            }
            uint4 colorui = read_imageui(brick, smp, (int4)(X,Y,Z,0));
            color.x = (float)colorui.x / 255.0f;
            color.y = (float)colorui.y / 255.0f;
            color.z = (float)colorui.z / 255.0f;
            color.w = (float)colorui.w / 255.0f;
        } while(color.w == 0);
        
        (*oldtMax).x = tMaxX;
        (*oldtMax).y = tMaxY;
        (*oldtMax).z = tMaxZ;
        (*oldPos).x = X;
        (*oldPos).y = Y;
        (*oldPos).z = Z;
        return color;
    }
    /**
    *   Определение пересечения коробки и луча
    */
    bool boxIntersect(float3 rayDir, float3 rayOrigin, float3 minBox, float3 maxBox, float* t0, float* t1)
    {
        float tmin, tmax, tymin, tymax, tzmin, tzmax, div;
        div = 1 / rayDir.x;
        if (div >= 0)
        {
            tmin = (minBox.x - rayOrigin.x) * div;
            tmax = (maxBox.x - rayOrigin.x) * div;
        } else
        {
            tmin = (maxBox.x - rayOrigin.x) * div;
            tmax = (minBox.x - rayOrigin.x) * div;
        }
        
        div = 1 / rayDir.y;
        if (div >= 0)
        {
            tymin = (minBox.y - rayOrigin.y) * div;
            tymax = (maxBox.y - rayOrigin.y) * div;
        } else
        {
            tymin = (maxBox.y - rayOrigin.y) * div;
            tymax = (minBox.y - rayOrigin.y) * div;
        }
        
        if ( (tmin > tymax) || (tymin > tmax) )
        {
            return false;
        }
        if (tymin > tmin)
            tmin = tymin;
        if (tymax < tmax)
            tmax = tymax;
            
        div = 1 / rayDir.z; 
        if (div >= 0)
        {
            tzmin = (minBox.z - rayOrigin.z) * div;
            tzmax = (maxBox.z - rayOrigin.z) * div;
        } else
        {
            tzmin = (maxBox.z - rayOrigin.z) * div;
            tzmax = (minBox.z - rayOrigin.z) * div;
        }
        
        if ( (tmin > tzmax) || (tzmin > tmax) )
        {
            return false;
        }   
        if (tzmin > tmin)
            tmin = tzmin;
        if (tzmax < tmax)
            tmax = tzmax;
        
        *t0 = tmin;
        *t1 = tmax;
        return true;    
    }
    
    /**
    *   Умножение вектора на матрицу
    */
    float4 multiply(__global float* m, float4 b)
    {
        float4 ret;
        ret.x = m[0]*b.x+m[4]*b.y+m[8]*b.z+m[12]*b.w;
        ret.y = m[1]*b.x+m[5]*b.y+m[9]*b.z+m[13]*b.w;
        ret.z = m[2]*b.x+m[6]*b.y+m[10]*b.z+m[14]*b.w;
        ret.w = m[3]*b.x+m[7]*b.y+m[11]*b.z+m[15]*b.w;
        return ret;
    }

    /**
    *   Вычисление положение и направления луча для пикселя (idx, idy).
    */
    int getPixelRay(__global float* matProjViewInv, float screenWidth, float screenHeight, int idx, int idy, float3* rayDir, float3* rayOrigin)
    {
            float4 screenPos; 
            
            screenPos.x =         ( ( ( 2.0f * idx ) / screenWidth ) - 1 );
            screenPos.y =  1.0f - ( ( ( 2.0f * idy ) / screenHeight ) - 1 );
            screenPos.z =  0.0f;
            screenPos.w =  1.0f;
            
            float4 vec1 = multiply(matProjViewInv, screenPos);
            if(vec1.w == 0)
            {
                return -1;
            }
            vec1.w = 1.0f/vec1.w;
            vec1.x = vec1.x*vec1.w;
            vec1.y = vec1.y*vec1.w;
            vec1.z = vec1.z*vec1.w;
            
            screenPos.z = 1.0f;
            float4 vec2 = multiply(matProjViewInv, screenPos);
            if(vec2.w == 0)
            {
                return -1;
            }
            vec2.w = 1.0f/vec2.w;
            vec2.x = vec2.x*vec2.w;
            vec2.y = vec2.y*vec2.w;
            vec2.z = vec2.z*vec2.w;
            
            (*rayOrigin) = vec1.xyz;
            
            vec2.x = vec2.x - vec1.x;
            vec2.y = vec2.y - vec1.y;
            vec2.z = vec2.z - vec1.z;
            (*rayDir) = normalize(vec2.xyz);
            
            return 0;
    }
    
    /**
    *   Вычисляет значение нормали из значения, полученного из 3D текстуры.
    */
    float3 extractNormal(uint4 vec)
    {
        float3 norm;
        int sign = (vec.x & 0x80) == 0 ? 1 : -1;
        norm.x = sign*((vec.x & 0x7F)/(float)0x7F);
        sign = (vec.y & 0x80) == 0 ? 1 : -1;
        norm.y = sign*((vec.y & 0x7F)/(float)0x7F);
        sign = (vec.z & 0x80) == 0 ? 1 : -1;
        norm.z = sign*((vec.z & 0x7F)/(float)0x7F);
        return norm;
    }
    
    float4 renderBrick(read_only image3d_t brickColor, read_only image3d_t brickNormal, uint3 brickOffset, sampler_t smp, __global float* lightsPos, __global float* lightsColor, __global int* lightsCount,
        float3 rayOrigin, float3 rayDir, float t0, float3 minBox, float3 maxBox, __global write_only float* debugOutput)
    {
        //=======================
        //  Initialization part
        //=======================
        float3 tMax;
        int3 pos;
        int3 step;
        int3 justOut;
        float3 delta;
        
        float4 accum = (float4)(0.0f, 0.0f, 0.0f, 1.0f);
        #define BORDER_SIZE 1
        #define BRICK_SIZE 6
        
        // finding justOut
        justOut.x = brickOffset.x + BRICK_SIZE - BORDER_SIZE;
        justOut.y = brickOffset.y + BRICK_SIZE - BORDER_SIZE;
        justOut.z = brickOffset.z + BRICK_SIZE - BORDER_SIZE;
        
        debugOutput[0] = brickOffset.x;
        debugOutput[1] = brickOffset.y;
        debugOutput[2] = brickOffset.z;
        debugOutput[3] = 0.0f;
            
        if(rayDir.x < 0)
            justOut.x = brickOffset.x + BORDER_SIZE-1;
        if(rayDir.y < 0)
            justOut.y = brickOffset.y + BORDER_SIZE-1;
        if(rayDir.z < 0)
            justOut.z = brickOffset.z + BORDER_SIZE-1;
            
        // finding pos
        float3 voxelSize = maxBox - minBox;
        voxelSize.x = voxelSize.x / (BRICK_SIZE - BORDER_SIZE);
        voxelSize.y = voxelSize.y / (BRICK_SIZE - BORDER_SIZE);
        voxelSize.z = voxelSize.z / (BRICK_SIZE - BORDER_SIZE); 
        float3 rayPos = (rayOrigin + t0*rayDir)-minBox; 
        pos.x = brickOffset.x + (int)(rayPos.x / voxelSize.x);
        pos.y = brickOffset.y + (int)(rayPos.y / voxelSize.y);
        pos.z = brickOffset.z + (int)(rayPos.z / voxelSize.z);
        
        
        // finding step
        step = (int3)(1,1,1);
        if(rayDir.x < 0)
            step.x = -1;
        if(rayDir.y < 0)
            step.y = -1;
        if(rayDir.z < 0)
            step.z = -1;
            
        // finding tMax
        if(rayDir.x < 0)
            tMax.x = (pos.x*voxelSize.x - rayPos.x) / rayDir.x;
        else    
            tMax.x = ((pos.x+1)*voxelSize.x - rayPos.x) / rayDir.x;
            
        if(rayDir.y < 0)
            tMax.y = (pos.y*voxelSize.y - rayPos.y) / rayDir.y;
        else    
            tMax.y = ((pos.y+1)*voxelSize.y - rayPos.y) / rayDir.y;

        if(rayDir.z < 0)
            tMax.z = (pos.z*voxelSize.z - rayPos.z) / rayDir.z;
        else    
            tMax.z = ((pos.z+1)*voxelSize.z - rayPos.z) / rayDir.z;
            
        // finding delta
        delta.x = step.x * voxelSize.x / rayDir.x;
        delta.y = step.y * voxelSize.y / rayDir.y;
        delta.z = step.z * voxelSize.z / rayDir.z;
            
        //=======================
        //  Render part
        //=======================
        
        // presetting first voxel
        uint4 colorui = read_imageui(brickColor, smp, (int4)(pos.x, pos.y, pos.z, 0));
        float4 color;
        color.x = (float)colorui.x / 255.0f;
        color.y = (float)colorui.y / 255.0f;
        color.z = (float)colorui.z / 255.0f;
        color.w = (float)colorui.w / 255.0f;
        
        uint4 normalDistr = read_imageui(brickNormal, smp, (int4)(pos.x, pos.y, pos.z, 0));
        float3 normal = extractNormal(normalDistr);
        
        float dispertion = length(normal);
        dispertion = (1 - dispertion)/dispertion;
        normal = normalize(normal);
        
        do
        {   
            float3 voxelPos;
            voxelPos.x = voxelSize.x * ((float)pos.x + 0.5);
            voxelPos.y = voxelSize.y * ((float)pos.y + 0.5);
            voxelPos.z = voxelSize.z * ((float)pos.z + 0.5);
            
            if(color.w > 0)
            {
                for(int i = 0; i<*lightsCount; i++)
                {
                    // Phong shading model
//                  float3 lightDir = normalize((float3)(lightsPos[3*i], lightsPos[3*i+1], lightsPos[3*i+2]) - voxelPos);
//                  float4 lightColor = (float4)(lightsColor[4*i], lightsColor[4*i+1], lightsColor[4*i+2], lightsColor[4*i+3]);
//                  
//                  float diffuseDot = max(0.0f, dot(lightDir, normal));
//                  float3 specVec = 2*diffuseDot*normal - lightDir;
//                  float specDot = pow(max(0.0f,dot(specVec, normal)), dispertion);
//                  accum.x = accum.x + color.x*color.w*diffuseDot + lightColor.x*specDot;
//                  accum.y = accum.y + color.y*color.w*diffuseDot + lightColor.y*specDot;
//                  accum.z = accum.z + color.z*color.w*diffuseDot + lightColor.z*specDot;
//                  accum.w = accum.w*(1 - color.w);
                    
                    accum.x = accum.x + color.x*color.w;
                    accum.y = accum.y + color.y*color.w;
                    accum.z = accum.z + color.z*color.w;
                    accum.w = accum.w*(1 - color.w);
                }
            }
            
            // traversing to new voxel
            color = traverseBrick(brickColor, smp, &tMax, &pos, step, delta, justOut);
            
            // extracting normal and dispertion
            normalDistr = read_imageui(brickNormal, smp, (int4)(pos.x, pos.y, pos.z, 0));   
            normal = extractNormal(normalDistr);
            dispertion = length(normal);
            dispertion = (1 - dispertion)/dispertion;
            normal = normalize(normal);
        } 
        while(color.w > 0.0f && accum.w > 0.01f);
        
        // returning from transparancy to opacity
        accum.w = 1 - accum.w;
        
        return accum;
    }

    bool isNodeLeaf(uint val)
    {
        return ((val >> 31) & 0x01) == 1;
    }

    bool isNodeConstant(uint val)
    {
        return ((val >> 30) & 0x01) == 1;
    }

    uint3 getBrickAddress(uint val)
    {
        return (uint3)((val >> 20) & 0x3FF, (val >> 10) & 0x3FF, val & 0x3FF);
    }

    float4 getBrickConstantColor(uint val)
    {
        return (float4)(val & 0x000000FF, (val & 0x0000FF00) >> 8, (val & 0x00FF0000) >> 16, (val & 0xFF000000) >> 24);
    }

    uint getNextTileAddress(uint val)
    {
        return val & 0x3FFFFFFF;
    }

//  float4 renderOctree(__global uint* nodePool, read_only image3d_t brickPool, read_only image3d_t brickNormalPool, sampler_t smp, 
//                     __global float* lightsPos, __global float* lightsColor, __global int* lightsCount,
//                     float3 rayOrigin, float3 rayDir, float t0, float3 minBox, float3 maxBox,
//                      __global write_only float* debugOutput)
//  {
//      uint address = *nodePool;
//      uint color = *(nodePool+1);
//
//      if(isNodeLeaf(address))
//      {
//          return renderBrick(brickPool, brickNormalPool, getBrickAddress(color), smp, 
//              lightsPos, lightsColor, lightsCount, rayOrigin, rayDir, t0, minBox, maxBox);
//      }
//
//      if(isNodeConstant(address))
//      {
//          return getBrickConstantColor(color);
//      }
//
//      address = getNextTileAddress(address);
//      float3 currMinBox = minBox;
//      float3 currMaxBox = maxBox;
//
//      float3 rayPos = (rayOrigin + t0*rayDir)-currMinBox; 
//      rayPos.x = rayPos.x / (currMaxBox.x - currMinBox.x);
//      rayPos.y = rayPos.y / (currMaxBox.y - currMinBox.y);
//      rayPos.z = rayPos.z / (currMaxBox.z - currMinBox.z);
//
//      float4 accum = (float4)(0.0f, 0.0f, 0.0f, 1.0f);
//      bool stop = false;
//      while(!stop)
//      {
//          uint3 off = (uint3)((uint)(2*rayPos.x), (uint)(2*rayPos.y), (uint)(2*rayPos.z));
//          if(off.x == 2) off.x = 1;
//          if(off.y == 2) off.y = 1;
//          if(off.z == 2) off.z = 1;
//
//          __global uint* currentTile = nodePool+address*16;
//          __global uint* currentNode = currentTile + (off.x + 2*off.y + 4*off.z)*2;
//
//          if(off.x == 0)
//          {
//              currMaxBox.x -= (currMaxBox.x-currMinBox.x)/2;
//          } else
//          {
//              currMinBox.x += (currMaxBox.x-currMinBox.x)/2;
//          }
//          if(off.y == 0)
//          {
//              currMaxBox.y -= (currMaxBox.y-currMinBox.y)/2;
//          } else
//          {
//              currMinBox.y += (currMaxBox.y-currMinBox.y)/2;
//          }
//          if(off.z == 0)
//          {
//              currMaxBox.z -= (currMaxBox.z-currMinBox.z)/2;
//          } else
//          {
//              currMinBox.z += (currMaxBox.z-currMinBox.z)/2;
//          }
//
//          debugOutput[0] = currMinBox.x;
//            debugOutput[1] = currMaxBox.x;
//            debugOutput[2] = 0.0f;
//            debugOutput[3] = 0.0f;
//            
//          address = *currentNode;
//          color = *(currentNode+1);

            /*debugOutput[0] = getBrickAddress(color).x;
            debugOutput[1] = getBrickAddress(color).y;
            debugOutput[2] = getBrickAddress(color).z;
            debugOutput[3] = isNodeLeaf(address);*/

//          float t1;
//          if(isNodeLeaf(address))
//          {
//              if(boxIntersect(rayDir, rayOrigin, currMinBox, currMaxBox, &t0, &t1) && t1 > 0)
//              {
//                  if(t0 < 0)
//                  {
//                      t0 = 0;
//                  }
//                  float4 tempColor = renderBrick(brickPool, brickNormalPool, getBrickAddress(color), smp, 
//                      lightsPos, lightsColor, lightsCount, rayOrigin, rayDir, t0, currMinBox, currMaxBox);
//
//                  accum.x = accum.x + tempColor.x*tempColor.w;
//                  accum.y = accum.y + tempColor.y*tempColor.w;
//                  accum.z = accum.z + tempColor.z*tempColor.w;
//                  accum.w = accum.w*(1 - tempColor.w);
//                  if(accum.w < 0.01f)
//                  {
//                      accum.w = 1 - accum.w;
//                      return accum;
//                  }
//
//                  float3 nextPos = (rayOrigin + t1*rayDir)-currMinBox; 
//                  uint3 noff = (uint3)((uint)(2*nextPos.x), (uint)(2*nextPos.y), (uint)(2*nextPos.z));
//                  if(noff.x == 2) noff.x = 1;
//                  if(noff.y == 2) noff.y = 1;
//                  if(noff.z == 2) noff.z = 1;
//
//                  if(noff.x == off.x && noff.y == off.y && noff.z == off.z)
//                  {
//                      accum.w = 1 - accum.w;
//                      return accum;
//                  }
//
//                  t0 = t1;
//                  currMinBox = minBox;
//                  currMaxBox = maxBox;
//                  rayPos = nextPos;
//                  address = *nodePool;
//              }
//              stop = true; // STOPED THERE
//          }
//
//          rayPos = 2*rayPos - (float3)((uint)(2*rayPos.x), (uint)(2*rayPos.y), (uint)(2*rayPos.z));
//      }
//
//      accum.w = 1 - accum.w;
//      return accum;
//  }

    /**
    *   Отрисовывает один кирпич. 
    */
    __kernel void renderKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp, __global const uint* screenSize,
        __global float* matProjViewInv, __global uint* nodePool, read_only image3d_t brickPool, read_only image3d_t normalBrickPool, 
        __global float* lightsPos, __global float* lightsColor, __global int* lightsCount, 
        __global write_only float* debugOutput)
    {
        const int idx = get_global_id(0);
        const int idy = get_global_id(1);
        
        if (idx < screenSize[0] && idy < screenSize[1])
        {
            float3 rayDir, rayOrigin;
            if(getPixelRay(matProjViewInv, screenSize[0], screenSize[1], idx, idy, &rayDir, &rayOrigin) < 0)
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

                uint scolor = *(nodePool+1);
                color = renderBrick(brickPool, normalBrickPool, getBrickAddress(scolor), smp, 
                        lightsPos, lightsColor, lightsCount, rayOrigin, rayDir, t0, minBox, maxBox, debugOutput);
                //color = renderBrick(brick, normalBrick, smp, lightsPos, lightsColor, lightsCount, rayOrigin, rayDir, t0, minBox, maxBox);
//              color = renderOctree(nodePool, brickPool, normalBrickPool, smp, lightsPos, lightsColor, 
//                  lightsCount, rayOrigin, rayDir, t0, minBox, maxBox, debugOutput);

                if(color.w < 0.99f)
                {
                    color.x = color.x + bgcolor.x;
                    color.y = color.y + bgcolor.y;
                    color.z = color.z + bgcolor.z;
                    color.w = 1.0f;
                }
            }
            
            write_imagef(output, (int2)(idx, idy), color);
        }
    }
};
