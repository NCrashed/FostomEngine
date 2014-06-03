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
*   Описывает функции для преобразований координат, полезные для ray tracing. 
*/
module client.shaders.raytrace.common;

import client.shaders.dsl;
import client.shaders.raytrace.matrix;

alias CommonKernels = Kernel!(MatrixKernels, "Common", q{
    /**
    *   Calculates world ray origin and direction for screen pixel (idx, idy).
    *   Params:
    *   matProjViewInv  inverse of projection-view matrix
    *   screenWidth     screen width in pixels
    *   screenHeight    screen height in pixels
    *   idx             x coordinate of pixel from left upper corner
    *   idy             y coordinate of pixel from left upper corner
    *   rayDir          [out] direction of resulted ray in world space
    *   rayOrigin       [out] position of resulted ray in world space
    *   
    *   Returns: -1 if cannot calculate ray, 0 if successful 
    */
    int getPixelRay(Matrix4x4 matProjViewInv, uint screenWidth, uint screenHeight, int idx, int idy, float3* rayDir, float3* rayOrigin)
    {
            float4 screenPos; 
            
            screenPos.x =         ( ( ( 2.0f * idx ) / (float) screenWidth ) - 1 );
            screenPos.y =  1.0f - ( ( ( 2.0f * idy ) / (float) screenHeight ) - 1 );
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
});