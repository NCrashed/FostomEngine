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
*   Defines guard to check availability of cl_khr_fp64 or cl_amd_fp64 extension.
*/
module client.shaders.extension._double;

import client.shaders.dsl;

/**
*   Guad to check availability of cl_khr_fp64 or cl_amd_fp64 extension.
*   Include this kernel and you can safely use double type in your kernel.
*/
alias DoubleExtensionKernel = Kernel!("DoubleExtension", q{
    #ifdef cl_khr_fp64
        #pragma OPENCL EXTENSION cl_khr_fp64 : enable
    #elif defined(cl_amd_fp64)
        #pragma OPENCL EXTENSION cl_amd_fp64 : enable
    #else
        #error "Double precision floating point not supported by OpenCL implementation."
    #endif
});