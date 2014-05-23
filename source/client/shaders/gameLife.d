//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	Модуль, описывающий kernel для клеточного автомата "Жизнь".
*/
module client.shaders.gameLife;

public import client.shaders.clprog;

/**
*	Тестовый кернел для отрисовки игры Жизнь.
*/
class GameLifeProg : CLKernelProgram
{
	/// Имя входного kernel'а
	override string mainKernelName() @property
	{
		return "gameLifeKernel";
	}

	/// Исходные коды kernel'a
	override string programSource() @property
	{
		return gameLifeKernelSource;
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
private enum gameLifeKernelSource = q{
    /**
    *   Отрисовывает клеточный автомат на текстуру. 
    */
    __kernel void gameLifeKernel(read_only image2d_t texture, write_only image2d_t output, sampler_t smp, __global const uint* screenSize)
    {
        const int idx = get_global_id(0);
        const int idy = get_global_id(1);

        if (idx < screenSize[0] && idy < screenSize[1])
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
};	