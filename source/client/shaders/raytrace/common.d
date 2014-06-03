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
    *   Returns: false if cannot calculate ray, true if successful 
    */
    bool getPixelRay(Matrix4x4 matProjViewInv, uint screenWidth, uint screenHeight, int idx, int idy, float3* rayDir, float3* rayOrigin)
    {
            float4 screenPos; 
            
            screenPos.x =         ( ( ( 2.0f * idx ) / (float) screenWidth ) - 1 );
            screenPos.y =  1.0f - ( ( ( 2.0f * idy ) / (float) screenHeight ) - 1 );
            screenPos.z =  0.0f;
            screenPos.w =  1.0f;
            
            float4 vec1 = m44MultiplyByVec(matProjViewInv, screenPos);
            if(vec1.w == 0)
            {
                return false;
            }
            vec1.w = 1.0f/vec1.w;
            vec1.x = vec1.x*vec1.w;
            vec1.y = vec1.y*vec1.w;
            vec1.z = vec1.z*vec1.w;
            
            screenPos.z = 1.0f;
            float4 vec2 = m44MultiplyByVec(matProjViewInv, screenPos);
            if(vec2.w == 0)
            {
                return false;
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
            
            return true;
    }
    
    /**
    *   Calculates intersection between ray and axis aligned bounding box
    *   Params:
    *   rayDir      ray direction vector
    *   rayOrigin   ray origin vector
    *   minBox      box corner closest to the global origin
    *   maxBox      box corner most farthest from the global origin
    *   t0          [out] ray based coordinate of entering intersection
    *   t1          [out] ray based coordinate of leaving intersection
    *
    *   Returns: true if there is intersection, false else.
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
});