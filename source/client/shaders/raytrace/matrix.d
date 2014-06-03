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
*   Описывает функции для работы с in-memory матрицами, полезные для ray tracing. 
*/
module client.shaders.raytrace.matrix;

import client.shaders.dsl;
import opencl.all;
import util.matrix;

alias GPUMatrix4x4 = GPUMatrix!4;

/// Representation of GPU-side matrix
struct GPUMatrix(size_t size)
{
    /// Count of elements in matrix
    enum elementsCount = size*size;
    
    /// Construct undefined matrix
    /**
    *   Params:
    *   clContex    OpenCL context
    *   readOnly    Adds CL_MEM_READ_ONLY to inner buffer
    */
    this()(CLContext clContex, bool readOnly = true)
    {
        auto flags = CL_MEM_COPY_HOST_PTR;
        if(readOnly) flags |= CL_MEM_READ_ONLY;
        
        _buffer = CLBuffer(clContex, flags, elementsCount*float.sizeof);
    }
    
    /// Construct matrix filled from CPU matrix
    /**
    *   Params:
    *   clContex    OpenCL context
    *   source      Matrix to copy data from
    *   readOnly    Adds CL_MEM_READ_ONLY to inner buffer
    */
    this()(CLContext clContex, auto const ref Matrix!size source, bool readOnly = true)
    {
        auto flags = CL_MEM_COPY_HOST_PTR;
        if(readOnly) flags |= CL_MEM_READ_ONLY;
        
        _buffer = CLBuffer(clContex, flags, elementsCount*float.sizeof, source.toOpenGL);
    }
    
    /// Loading data to GPU matrix
    void write()(CLCommandQueue CQ, auto const ref Matrix!size source)
    {
        CQ.enqueueWriteBuffer(buffer, CL_TRUE, 0, elementsCount*float.sizeof, source.toOpenGL);
    }
    
    /// Reading data from GPU matrix
    Matrix!size read(CLCommandQueue CQ)
    {
        float[elementsCount] buff;
        CQ.enqueueReadBuffer(buffer, CL_FALSE, 0, elementsCount*float.sizeof, buff.ptr);
        return Matrix!size(buff);
    }
    
    /// Getting inner buffer
    /**
    *   Used to pass it as argument to OpenCL kernel
    */
    CLBuffer buffer()
    {
        return _buffer;
    }
    
    private CLBuffer _buffer;
}

alias MatrixKernels = Kernel!("Matrix", q{
    /// Alias для инкапсуляции
    #define Matrix4x4 __global float*
    
    /**
    *   Multiply 4x4 matrix by float4 vector
    */
    float4 m44MultiplyByVec(Matrix4x4 m, float4 b)
    {
        float4 ret;
        ret.x = m[0]*b.x+m[4]*b.y+m[8]*b.z+m[12]*b.w;
        ret.y = m[1]*b.x+m[5]*b.y+m[9]*b.z+m[13]*b.w;
        ret.z = m[2]*b.x+m[6]*b.y+m[10]*b.z+m[14]*b.w;
        ret.w = m[3]*b.x+m[7]*b.y+m[11]*b.z+m[15]*b.w;
        return ret;
    }
});