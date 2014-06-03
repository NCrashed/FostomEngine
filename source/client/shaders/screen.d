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
*   OpenCL kernels to work with screen size, also defines wrapper for CLBuffer around uint[2] array.
*/
module client.shaders.screen;

import opencl.all;
import client.shaders.dsl;

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