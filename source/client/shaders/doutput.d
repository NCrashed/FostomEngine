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
*   Defines kernels for debug output array
*/
module client.shaders.doutput;

import opencl.all;
import client.shaders.dsl;

/**
*   GPU side buffer for debug output from OpenCL kernels
*/
struct GPUDebugOutput(size_t size = 4, ElementType = float)
{
    /// Shortcut alias for storing read result for inner code
    public alias BufferType = ElementType[size];
    
    /// Initing buffer
    this(CLContext clContex)
    {
        _buffer = CLBuffer(clContex, CL_MEM_WRITE_ONLY, size*ElementType.sizeof);
    }
    
    /// Reading output from GPU
    ElementType[size] read(CLCommandQueue CQ)
    {
        ElementType[size] buff;
        CQ.enqueueReadBuffer(_buffer, CL_FALSE, 0, size*ElementType.sizeof, buff.ptr);
        return buff;
    }
    
    /// Getting inner buffer
    /**
    *   Used while passing the buffer to kernel arguments list
    */
    CLBuffer buffer()
    {
        return _buffer;
    }
    
    private CLBuffer _buffer;
}

/**
*   Kernel definitions for debug output buffer. 
*/
alias DebugOutputKernels = Kernel!("DebugOutput", q{
    /// Debug output is write only array
    #define DebugOutput __global write_only float*
    /// We statically know debug output length
    #define DebugOutputLength 4
});