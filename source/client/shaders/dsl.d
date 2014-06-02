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
*   Helper templates to organize OpenCL code and separates it into modules.
*/
module client.shaders.dsl;

/**
*   Helps to organize D-like module structure for OpenCL kernels:
*   dependencies are included only once.
*
*   Kernel are defined as:
*   - list of dependent kernels
*   - name literal (unique for one kernel)
*   - kernel source code
* 
*   Example:
*   ----------
*   alias Kernel1 = Kernel!("Kernel1", q{it is kernel 1});
*   alias Kernel2 = Kernel!(Kernel1, "Kernel2", q{it is kernel 2});
*   alias Kernel3 = Kernel!(Kernel1, "Kernel3", q{it is kernel 3});
*   alias Kernel4 = Kernel!(Kernel2, Kernel3, "Kernel4", q{it is kernel 4});
*   // printing all sources including dependencies
*   pragma(msg, Kernel4.sources);
*   ----------
*/
template Kernel(TS...)
{
    static assert(TS.length >= 2);
    enum kernelName   = TS[$-2];
    enum kernelSource = TS[$-1];
    alias dependentKernels = TS[0 .. $-2];
    
    /// Builds lis of unique dependencies
    private template makeDepends()
    {
        private template inner1(TSS...)
        {
            static if(TSS.length <= 1)
            {
                alias inner1 = Tuple!();
            }
            else
            {
                enum savedLength = TSS[0];
                alias saved = TSS[1 .. savedLength+1];
                alias TS = TSS[savedLength+1 .. $];
                
//                pragma(msg, "Making deps");
//                pragma(msg, "Saved length: ");
//                pragma(msg, savedLength);
//                pragma(msg, "Saved tuple: ");
//                pragma(msg, MapNames!(saved));
//                pragma(msg, "Tuple to process: ");
//                pragma(msg, MapNames!(TS));
//                pragma(msg, "");
                
                static if(TS.length == 0)
                {
                    alias inner1 = saved;
                }
                else
                {
                    alias currDep = TS[0]; 
//                    pragma(msg, "Going down for " ~ currDep.kernelName);
                    alias newDeps = Tuple!(currDep.makeDepends!(), currDep);
//                    pragma(msg, "Deps for " ~ currDep.kernelName);
//                    pragma(msg, MapNames!(newDeps));
                    static if(newDeps.length == 0)
                    {
                        alias inner1 = addNext!(savedLength, saved, currDep);
                    }
                    else
                    {
                        alias temp = addNext!(savedLength, saved, newDeps);
                        alias inner1 = inner1!(temp.length, temp, TS[1..$]);
                    }
                }
            }
        }
        
        private template isAdded(TS...)
        {
            alias T = TS[0];
            
            private template Inner(TS...)
            {
                static if(TS.length == 0)
                {
                    enum Inner = false;
                }
                else
                {
//                    pragma(msg, T.kernelName);
//                    pragma(msg, TS[0].kernelName);
                    static if(TS[0].kernelName == T.kernelName)
                    {
                        enum Inner = true;
                    }
                    else
                    {
                        enum Inner = Inner!(TS[1 .. $]);
                    }
                }
            }
           
            enum isAdded = Inner!(TS[1 .. $]);
        }
        
        private template addNext(TS...)
        {
            enum dependsLength = TS[0];
            alias depends = TS[1 .. dependsLength+1];
            alias toadd = TS[1+dependsLength .. $];
            
//            pragma(msg, "addNext is called");
//            pragma(msg, "dependsLength");
//            pragma(msg, dependsLength);
//            pragma(msg, "depends");
//            pragma(msg, MapNames!(depends));
//            pragma(msg, "toadd");
//            pragma(msg, MapNames!(toadd));
//            pragma(msg, "");
            
            private template Inner(TS...)
            {
                static if(TS.length == 0)
                {
                    alias Inner = Tuple!();
                }
                else
                {
//                    pragma(msg, isAdded!(TS[0], depends));
                    static if(isAdded!(TS[0], depends))
                    {
                        alias Inner = Inner!(TS[1..$]);
                    }
                    else
                    {
                        alias Inner = Tuple!(TS[0], Inner!(TS[1..$]));
                    } 
                }
            }
            
            alias addNext = Tuple!(depends, Inner!toadd);
//            pragma(msg, "Resulted saved: ");
//            pragma(msg, MapNames!(addNext));
        }
        
        alias makeDepends = inner1!(0, dependentKernels);
    }
    
    private template MakeDepsSource(TS...)
    {
        static if(TS.length == 0)
        {
            enum MakeDepsSource = "";
        }
        else
        {
            enum MakeDepsSource = TS[0].kernelSource ~ "\n" 
                ~ MakeDepsSource!(TS[1..$]);
        }
    }
    
    enum sources = MakeDepsSource!(makeDepends!()) ~ kernelSource;
}

private:

template Tuple(E...)
{
    alias Tuple = E;
}

private template MapNames(TS...)
{
    static if(TS.length == 0)
    {
        alias MapNames = Tuple!();
    }
    else
    {
        alias MapNames = Tuple!(TS[0].kernelName, MapNames!(TS[1..$]));
    }
}