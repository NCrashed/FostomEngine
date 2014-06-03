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

import opencl.all;

/**
*   GPU side representation of screen sizes array.
*/
struct GPUScreenSize
{
    /// Creating inner buffer filled with zeros
    this(CLContext clContex)
    {
        this.width  = 0;
        this.height = 0;
        
        _buffer = CLBuffer(clContex, CL_MEM_READ_ONLY, 2*uint.sizeof);
    }
    
    /// Creating inner buffer and fills with data
    this(CLContext clContex, uint width, uint height)
    {
        this.width  = width;
        this.height = height;
        
        _buffer = CLBuffer(clContex, CL_MEM_COPY_HOST_PTR | CL_MEM_READ_ONLY, 2*uint.sizeof, sizes.ptr);
    }
    
    /// Creating inner buffer and fills with data
    this(CLContext clContex, uint[2] sizes)
    {
        this.sizes = sizes;
        
        _buffer = CLBuffer(clContex, CL_MEM_COPY_HOST_PTR | CL_MEM_READ_ONLY, 2*uint.sizeof, sizes.ptr);
    }
    
    /// Reading width
    uint width()
    {
        return sizes[0];
    }
    
    /// Writing width
    /**
    *   This doesn't actually updates the buffer, see $(B write) method
    */
    void width(uint val)
    {
        sizes[0] = val;
    }
    
    /// Reading height
    uint height()
    {
        return sizes[1];
    }
    
    /// Writing width
    /**
    *   This doesn't actually updates the buffer, see $(B write) method
    */
    void height(uint val)
    {
        sizes[1] = val;
    }
    
    /// Loading stored data to GPU buffer
    void write(CLCommandQueue CQ)
    {
        CQ.enqueueWriteBuffer(buffer, CL_TRUE, 0, 2*uint.sizeof, sizes.ptr);
    }
    
    /// Loading stored data to GPU buffer
    void write(CLCommandQueue CQ, uint width, uint height)
    {
        this.width = width;
        this.height = height;
        CQ.enqueueWriteBuffer(buffer, CL_TRUE, 0, 2*uint.sizeof, sizes.ptr);
    }
    
    /// Getting inner buffer
    /**
    *   Used to pass it as argument to OpenCL kernel
    */
    CLBuffer buffer()
    {
        return _buffer;
    }
    
    private uint[2] sizes;
    private CLBuffer _buffer;
}

/**
*   Simplifies work with screen size array passed to root kernel
*/
alias SceenSizeKernels = Kernel!("ScreenSize", q{
    /// Screen size is a uint[2] array
    #define ScreenSize __global uint*
    /// Macro for screen width
    #define screenWidth(x) ((x)[0])
    /// Macro for screen height
    #define screenHeight(x) ((x)[1])
});

/**
*   Kernels to work with screen to world transformation and vice versa
*/
alias CoordTransformKernels = Kernel!(MatrixKernels, "CoordTransform", q{
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
});

/**
*   Kernels to work with axis aligned boxes
*/
alias AABBoxKernels = Kernel!("AABBox", q{
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

/**
*   Aggregates often used kernels.
*/
alias CommonKernels = Kernel!(
      SceenSizeKernels
    , CoordTransformKernels
    , AABBoxKernels
    , "Common", "");