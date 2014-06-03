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
*	Модуль стандартизирует форму kernel'ов для OpenCL. Каждая программа
*	должна принимать 4 обязательных аргумента: входная текстура, выходная
*	текстура, семплер для текстур, массив с размерами для текстур. 
*	Остальные параметры, передаваемые kernel'у характеризуются в этом модуле.
*/
module client.shaders.clprog;

public import opencl.all;
import client.shaders.screen;
import util.log;

/**
*	Общий интерфейс для OpenCL программ.
*/
abstract class CLKernelProgram
{
	public
	{
		/// Имя входного kernel'а
		string mainKernelName() @property
		out(value)
		{
			assert(value.length > 0, "mainKernelName length is zero! Maybe your've forgotten to overload this property?");
		}		
		body
		{
			return "";
		}

		/// Исходные коды kernel'a
		string programSource() @property
		out(value)
		{
			assert(value.length > 0, "programSource length is zero! Maybe your've forgotten to overload this property?");
		}		
		body
		{
			return "";
		}

		/**
		*	Инициализурует программу. Компиляция и настройка буфферов должна быть здесь.
		*/
		void initialize(CLContext clContext, CLCommandQueue clQ, CLImage2DGL inTex, CLImage2DGL outTex, CLSampler sampler, GPUScreenSize screenSize)
		{
			CQ = clQ;
			mContext = clContext;
			
		    // Собираем программу для GPU
		    mProgram = CLProgram(clContext, programSource);
		    mProgram.build("", clContext.devices);

		    // Извлекаем ядро
		    mMainKernel = mProgram.createKernel(mainKernelName);
		    mMainKernel.setArgs(inTex, outTex, sampler, screenSize.buffer);
		}

		/**
		*	Инициализация дополнительных буферов.
		*/
		void customInitialize(CLContext clContex);

		/**
		*	Между вызовами кернелов можно обновить буферы для дополнительных аргументов.
		*/
		void updateCustomBuffers();

		void callKernel(int sizex, int sizey)
		{
			const NDRange range = NDRange(sizex, sizey);
			CQ.enqueueNDRangeKernel(mMainKernel, range);
		} 
		
		/**
		*	Если в кернеле используются дополнительные текстуры OpenGL,
		*	то в этот метод следует поместить вызов блокировки этих текстур.
		*/
		void acquireGLObjects()
		{
			
		}
		
		/**
		*	Если в кернеле используются дополнительные текстуры OpenGL,
		*	то в этот метод следует поместить вызов освобождения этих текстур.
		*/
		void releaseGLObjects()
		{
			
		}
	}

	protected
	{
		CLContext		mContext;
		CLCommandQueue 	CQ;
		CLProgram 		mProgram;
		CLKernel 		mMainKernel;
	}
}

