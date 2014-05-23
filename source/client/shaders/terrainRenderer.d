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
*	Модуль для отрисовки ландашфта по карте высот, тестовый.
*/
module client.shaders.terrainRenderer;

public 
{
	import client.shaders.clprog;
	import util.matrix;
	import derelict.opengl3.gl3;
}

import std.stdio;
/**
*	Тестовый рендерер для box'а. Основа для более сложных рендереров.
*/
class TerrainRendererProg : CLKernelProgram
{
	/// Имя входного kernel'а
	override string mainKernelName() @property
	{
		return "terrainKernel";
	}

	/// Исходные коды kernel'a
	override string programSource() @property
	{
		return terrainRendererProgSource;
	}

	/**
	*	Инициализация дополнительных буферов.
	*/
	override void customInitialize(CLContext clContex)
	{
		mContext = clContex;
		clMatProjViewInvBuff = CLBuffer(clContex, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 16*float.sizeof,
			matProjViewInv.toOpenGL);
		clDebugOutput = CLBuffer(clContex, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR, mDebugOutput.length*float.sizeof,
			mDebugOutput.ptr);
		
	}

	/**
	*	Установка P матрицы.
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
	*	Установка V матрицы.
	*/
	void viewMatrix(Matrix!4 mtrx) @property 
	{
		matView = mtrx;
		try
		{
			matProjViewInv = (matProj * matView).inverse();
		} catch(MatrixNoInverse exp)
		{
			
		}
	}
	
	/**
	*	Выводит на экран отладочную информацию. 
	*/
	void printDebugInfo()
	{
		//writeln(mDebugOutput);
	}
	
	/**
	*	Установка положения коробки
	*/
	void setHeightMap(GLuint textureID)
	{
		clHeightMap = CLImage2DGL(mContext, CL_MEM_READ_ONLY, GL_TEXTURE_2D, 0, textureID);
		clTexMem = CLMemories([clHeightMap]);
	}

	/**
	*	Инициализурует программу. Компиляция и настройка буфферов должна быть здесь.
	*/
	override void initialize(CLContext clContex, CLCommandQueue clQ, CLImage2DGL inTex, CLImage2DGL outTex, CLSampler sampler, CLBuffer screenSize)
	{
		CQ = clQ;
		
	    // Собираем программу для GPU
	    mProgram = CLProgram(clContex, programSource);
	    mProgram.build("", clContex.devices);

	    // Извлекаем ядро
	    mMainKernel = mProgram.createKernel(mainKernelName);
	    mMainKernel.setArgs(inTex, outTex, sampler, screenSize, clMatProjViewInvBuff, clHeightMap, clDebugOutput);
	}

	override void acquireGLObjects()
	{
		CQ.enqueueAcquireGLObjects(clTexMem);
	}
	
	override void releaseGLObjects()
	{
		CQ.enqueueReleaseGLObjects(clTexMem);
	}
	
	/**
	*	Между вызовами кернелов можно обновить буферы для дополнительных аргументов.
	*/
	override void updateCustomBuffers()
	{

		CQ.enqueueWriteBuffer(clMatProjViewInvBuff, CL_TRUE, 0, 16*float.sizeof,
			matProjViewInv.toOpenGL);
		//CQ.enqueueReadBuffer(clDebugOutput, CL_FALSE, 0, mDebugOutput.length*float.sizeof,
		//	mDebugOutput.ptr);
		
		/*
		float[6] boxBuff;
		boxBuff[0] = boxBegin.x;
		boxBuff[1] = boxBegin.y;
		boxBuff[2] = boxBegin.z;
		boxBuff[3] = boxEnd.x;
		boxBuff[4] = boxEnd.y;
		boxBuff[5] = boxEnd.z;

		CQ.enqueueWriteBuffer(clBoxBuff, CL_TRUE, 0, 6*float.sizeof,
			boxBuff.ptr);*/
	}

	private
	{
		Matrix!4 matView = Matrix!(4).identity;
		Matrix!4 matProj = Matrix!(4).identity;
		Matrix!4 matProjViewInv = Matrix!(4).identity;
		CLMemories clTexMem; 
		CLBuffer clMatProjViewInvBuff;
		CLBuffer clDebugOutput;
		CLImage2DGL clHeightMap;
		
		float[4] mDebugOutput;
	}
}

/// Исходники кернела
private enum terrainRendererProgSource = q{

	/**
	*	Определение пересечения коробки и луча
	*/
	/*bool rayBoxIntersection(float4 rayPos, float4 dir, float3 boxMin, float3 boxMax,
		float* tmino, float* tmaxo)
	{
		float t1, t2, temp, tCube;
		float tnear = -1000.0f; 
		float tfar =  1000.0f;

		// X_plane
		if(dir.x == 0)
		{
			if(rayPos.x < boxMin.x || rayPos.x > boxMax.x)	
				return false;
		} else
		{
			t1 = (boxMin.x-rayPos.x)/dir.x;
			t2 = (boxMax.x-rayPos.x)/dir.x;
			if(t1 > t2)
			{
				temp = t1;
				t1 = t2;
				t2 = temp;
			}
			if(t1 > tnear)
				tnear = t1;
			if(t2 < tfar)
				tfar = t2;
			if(tnear > tfar || tfar < 0)
				return false;
		}

		// Y_plane
		if(dir.y == 0)
		{
			if(rayPos.y < boxMin.y || rayPos.y > boxMax.y)	
				return false;
		} else
		{
			t1 = (boxMin.y-rayPos.y)/dir.y;
			t2 = (boxMax.y-rayPos.y)/dir.y;
			if(t1 > t2)
			{
				temp = t1;
				t1 = t2;
				t2 = temp;
			}
			if(t1 > tnear)
				tnear = t1;
			if(t2 < tfar)
				tfar = t2;
			if(tnear > tfar || tfar < 0)
				return false;
		}

		// Z_plane
		if(dir.z == 0)
		{
			if(rayPos.z < boxMin.z || rayPos.z > boxMax.z)	
				return false;
		} else
		{
			t1 = (boxMin.z-rayPos.z)/dir.z;
			t2 = (boxMax.z-rayPos.z)/dir.z;
			if(t1 > t2)
			{
				temp = t1;
				t1 = t2;
				t2 = temp;
			}
			if(t1 > tnear)
				tnear = t1;
			if(t2 < tfar)
				tfar = t2;
			if(tnear > tfar || tfar < 0)
				return false;
		}
		*tmino = tnear;
		*tmaxo = tfar;
		return true;
	}*/

	/**
	*	Умножение вектора на матрицу
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
    *   Отрисовывает один бокс. box[3*float - PosBeg, 3*float - PosEnd]
    */
    __kernel void terrainKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp, __global const uint* screenSize,
    	__global float* matProjViewInv, read_only image2d_t heightmap, __global write_only float* debugOutput)
    {
        const int idx = get_global_id(0);
        const int idy = get_global_id(1);

        if (idx < screenSize[0] && idy < screenSize[1])
        {
        	float4 screenPos; 
        	
        	screenPos.x =  	      ( ( ( 2.0f * idx ) / screenSize[0] ) - 1 );
        	screenPos.y =  1.0f - ( ( ( 2.0f * idy ) / screenSize[1] ) - 1 );
        	screenPos.z =  0.0f;
        	screenPos.w =  1.0f;
        	
        	float3 rayDir, rayOrigin;
        	
        	float4 vec1 = multiply(matProjViewInv, screenPos);
        	if(vec1.w == 0)
        	{
        		debugOutput[0] = 42.0;
        		debugOutput[1] = 0.0f;
        		debugOutput[2] = 0.0f;
        		debugOutput[3] = 0.0f;
        		return;
        	}
        	vec1.w = 1.0f/vec1.w;
        	vec1.x = vec1.x*vec1.w;
        	vec1.y = vec1.y*vec1.w;
        	vec1.z = vec1.z*vec1.w;
        	
        	screenPos.z = 1.0f;
        	float4 vec2 = multiply(matProjViewInv, screenPos);
        	if(vec2.w == 0)
        	{
        		debugOutput[0] = 0.0f;
        		debugOutput[1] = 42.0;
        		debugOutput[2] = 0.0f;
        		debugOutput[3] = 0.0f;
        		return;
        	}
        	vec2.w = 1.0f/vec2.w;
        	vec2.x = vec2.x*vec2.w;
        	vec2.y = vec2.y*vec2.w;
        	vec2.z = vec2.z*vec2.w;
        	
        	rayOrigin.x = vec1.x;
        	rayOrigin.y = vec1.y;
        	rayOrigin.z = vec1.z;
        	
        	rayDir.x = vec2.x - vec1.x;
        	rayDir.y = vec2.y - vec1.y;
        	rayDir.z = vec2.z - vec1.z;
        	rayDir = normalize(rayDir);
        	
 	        debugOutput[0] = rayOrigin.x;
        	debugOutput[1] = rayOrigin.y;
        	debugOutput[2] = rayOrigin.z;
        	debugOutput[3] = 0.0f;
        	
			float MIN_DIST = 0.1f;
			float MAX_DIST = 50.0f;
			float DELTA = 0.1f;
			float TERRAIN_SCALE = 5.0f;
			float VOXEL_SIZE = 0.05f;
			
			float4 color;
			color.x = 0.0f;
			color.y = 0.0f;
			color.z = 0.0f;
			color.w = 1.0f;
			float3 currPos = rayOrigin;
			for(float i = MIN_DIST; i < MAX_DIST; i+= DELTA)
			{
				int2 heightMapPos = (int2)(
						currPos.x/VOXEL_SIZE + get_image_width(heightmap)/2, 
						currPos.z/VOXEL_SIZE + get_image_height(heightmap)/2);

				float4 heightColor = read_imagef(heightmap, smp, heightMapPos);
				float mapPointY = TERRAIN_SCALE * heightColor.x;

				if(heightMapPos.x > get_image_width(heightmap) || heightMapPos.x < 0)
				{
					break;
				}
				if(heightMapPos.y > get_image_height(heightmap) || heightMapPos.y < 0)
				{
					break;
				}
				
				float dist = currPos.y - mapPointY;
				if(currPos.y - mapPointY < 0.0f)
				{
					/*float rollback = 0.0f;
					if(rayDir.y != 0)
					{
						rollback = dist/rayDir.y;
						currPos = currPos - rollback*DELTA;
						heightMapPos = (int2)(
								currPos.x/VOXEL_SIZE + get_image_width(heightmap)/2, 
								currPos.z/VOXEL_SIZE + get_image_height(heightmap)/2);
		
						heightColor = read_imagef(heightmap, smp, heightMapPos);
					}*/

					color.x = heightColor.x;
					color.y = heightColor.y;
					color.z = heightColor.z;
					break;
				}
				
				currPos = currPos + DELTA*rayDir;
			}
			
        	
        	write_imagef(output, (int2)(idx, idy), color);
        	
        	/*float4 vec1;
        	vec1.x = (idx/(float)screenSize[0])*2.0 - 1.0;
        	vec1.y = 1.0 - (idy/(float)screenSize[1])*2.0;
        	vec1.w = 1.0;

        	vec1.z = 0.0;
        	float4 rayBegin = multiply(invPV, vec1);
        	rayBegin = rayBegin*(1/rayBegin.w);
        	vec1.z = -1.0;
        	float4 rayEnd   = multiply(invPV, vec1);
        	rayEnd = rayEnd*(1/rayEnd.w);
        	float4 rayDir = normalize(rayEnd-rayBegin);

            float4 color;
            color.x = 0;
            color.y = 0;
            color.z = 0;
            color.w = 1;
            //color = read_imagef(texture, smp, (int2)(idx, idy));

            float tmin = 0.0f, tmax = 0.0f;
            float3 boxMin;
            boxMin.x = box[0];
            boxMin.y = box[1];
            boxMin.z = box[2];
            float3 boxMax;
            boxMax.x = box[3];
            boxMax.y = box[4];
            boxMax.z = box[5];

            if(rayBoxIntersection(rayBegin, rayDir, boxMin, boxMax, &tmin, &tmax))
            {
            	color.x = 0;
            	color.y = 0.6;
            	color.z = 0;
            	color.w = 1;            	
            }
            write_imagef(output, (int2)(idx, idy), color);*/
        }
    }
};
