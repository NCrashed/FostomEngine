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
*	Модуль, описывающий kernel для клеточного автомата "Жизнь".
*/
module client.shaders.gameLife;

public import client.shaders.clprog;
import client.shaders.dsl;
import client.shaders.screen;

/**
*	Тестовый кернел для отрисовки игры Жизнь.
*/
class GameLifeProg : CLKernelProgram
{
	/// Имя входного kernel'а
	override string mainKernelName() @property
	{
		return gameLifeKernel.kernelName;
	}

	/// Исходные коды kernel'a
	override string programSource() @property
	{
		return gameLifeKernel.sources;
	}

    /**
    *   Инициализация дополнительных буферов.
    */
    override void customInitialize(CLContext clContex)
    {

    }

    /**
    *   Между вызовами кернелов можно обновить буферы для дополнительных аргументов.
    */
    override void updateCustomBuffers()
    {
        
    }
}

/**
*	Исходники кернела.
*/
private alias gameLifeKernel = Kernel!(SceenSizeKernels, "gameLifeKernel", q{
    /**
    *   Отрисовывает клеточный автомат на текстуру. 
    */
    __kernel void gameLifeKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp, ScreenSize screenSize)
    {
        const int idx = get_global_id(0);
        const int idy = get_global_id(1);

        if (idx < screenWidth(screenSize) && idy < screenHeight(screenSize))
        {
            float4 color;
            color = read_imagef(texture, smp, (int2)(idx, idy));

            const float abs = 0.6;
            int alive = 0;
            float4 ncolor = read_imagef(texture, smp, (int2)(idx-1, idy-1));
            if(ncolor.x >= abs) alive++;
            ncolor = read_imagef(texture, smp, (int2)(idx, idy-1));
            if(ncolor.x >= abs) alive++;  
            ncolor = read_imagef(texture, smp, (int2)(idx+1, idy-1));
            if(ncolor.x >= abs) alive++;  
            ncolor = read_imagef(texture, smp, (int2)(idx-1, idy));
            if(ncolor.x >= abs) alive++;  
            ncolor = read_imagef(texture, smp, (int2)(idx-1, idy+1));
            if(ncolor.x >= abs) alive++;  
            ncolor = read_imagef(texture, smp, (int2)(idx, idy+1));
            if(ncolor.x >= abs) alive++;
            ncolor = read_imagef(texture, smp, (int2)(idx+1, idy+1));
            if(ncolor.x >= abs) alive++;  
            ncolor = read_imagef(texture, smp, (int2)(idx+1, idy));
            if(ncolor.x >= abs) alive++;  

            if(color.x < abs )
            {
                if(alive == 3)
                {
                    color.x = abs;                       
                }
            } else if(alive < 2 || alive > 3)
            {
                color.x = 0; 
            }

            // Получаем соседние пиксели
            write_imagef(output, (int2)(idx, idy), color);
        }
    }
});	