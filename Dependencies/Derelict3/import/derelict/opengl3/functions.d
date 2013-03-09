/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.opengl3.functions;

private
{
    import derelict.opengl3.types;
}

extern(System)
{
    // OpenGL 1.0
    alias nothrow void function(GLenum) da_glCullFace;
    alias nothrow void function(GLenum) da_glFrontFace;
    alias nothrow void function(GLenum, GLenum) da_glHint;
    alias nothrow void function(GLfloat) da_glLineWidth;
    alias nothrow void function(GLfloat) da_glPointSize;
    alias nothrow void function(GLenum, GLenum) da_glPolygonMode;
    alias nothrow void function(GLint, GLint, GLsizei, GLsizei) da_glScissor;
    alias nothrow void function(GLenum, GLenum, GLfloat) da_glTexParameterf;
    alias nothrow void function(GLenum, GLenum, const(GLfloat)*) da_glTexParameterfv;
    alias nothrow void function(GLenum, GLenum, GLint) da_glTexParameteri;
    alias nothrow void function(GLenum, GLenum, const(GLint)*) da_glTexParameteriv;
    alias nothrow void function(GLenum, GLint, GLint, GLsizei, GLint, GLenum, GLenum, const(GLvoid)*) da_glTexImage1D;
    alias nothrow void function(GLenum, GLint, GLint, GLsizei, GLsizei, GLint, GLenum, GLenum, const(GLvoid)*) da_glTexImage2D;
    alias nothrow void function(GLenum) da_glDrawBuffer;
    alias nothrow void function(GLbitfield) da_glClear;
    alias nothrow void function(GLclampf, GLclampf, GLclampf, GLclampf) da_glClearColor;
    alias nothrow void function(GLint) da_glClearStencil;
    alias nothrow void function(GLclampd) da_glClearDepth;
    alias nothrow void function(GLuint) da_glStencilMask;
    alias nothrow void function(GLboolean, GLboolean, GLboolean, GLboolean) da_glColorMask;
    alias nothrow void function(GLenum) da_glDisable;
    alias nothrow void function(GLenum) da_glEnable;
    alias nothrow void function() da_glFinish;
    alias nothrow void function() da_glFlush;
    alias nothrow void function(GLenum, GLenum) da_glBlendFunc;
    alias nothrow void function(GLenum) da_glLogicOp;
    alias nothrow void function(GLenum, GLint, GLuint) da_glStencilFunc;
    alias nothrow void function(GLenum, GLenum, GLenum) da_glStencilOp;
    alias nothrow void function(GLenum) da_glDepthFunc;
    alias nothrow void function(GLenum, GLfloat) da_glPixelStoref;
    alias nothrow void function(GLenum, GLint) da_glPixelStorei;
    alias nothrow void function(GLenum) da_glReadBuffer;
    alias nothrow void function(GLint, GLint, GLsizei, GLsizei, GLenum, GLenum, GLvoid*) da_glReadPixels;
    alias nothrow void function(GLenum, GLboolean*) da_glGetBooleanv;
    alias nothrow void function(GLenum, GLdouble*) da_glGetDoublev;
    alias nothrow GLenum function() da_glGetError;
    alias nothrow void function(GLenum, GLfloat*) da_glGetFloatv;
    alias nothrow void function(GLenum, GLint*) da_glGetIntegerv;
    alias nothrow const(char*) function(GLenum) da_glGetString;
    alias nothrow void function(GLenum, GLint, GLenum, GLenum, GLvoid*) da_glGetTexImage;
    alias nothrow void function(GLenum, GLenum, GLfloat*) da_glGetTexParameterfv;
    alias nothrow void function(GLenum, GLenum, GLint*) da_glGetTexParameteriv;
    alias nothrow void function(GLenum, GLint, GLenum, GLfloat*) da_glGetTexLevelParameterfv;
    alias nothrow void function(GLenum, GLint, GLenum, GLint*) da_glGetTexLevelParameteriv;
    alias nothrow GLboolean function(GLenum) da_glIsEnabled;
    alias nothrow void function(GLclampd, GLclampd) da_glDepthRange;
    alias nothrow void function(GLint, GLint, GLsizei, GLsizei) da_glViewport;
}

__gshared
{
    da_glCullFace glCullFace;
    da_glFrontFace glFrontFace;
    da_glHint glHint;
    da_glLineWidth glLineWidth;
    da_glPointSize glPointSize;
    da_glPolygonMode glPolygonMode;
    da_glScissor glScissor;
    da_glTexParameterf glTexParameterf;
    da_glTexParameterfv glTexParameterfv;
    da_glTexParameteri glTexParameteri;
    da_glTexParameteriv glTexParameteriv;
    da_glTexImage1D glTexImage1D;
    da_glTexImage2D glTexImage2D;
    da_glDrawBuffer glDrawBuffer;
    da_glClear glClear;
    da_glClearColor glClearColor;
    da_glClearStencil glClearStencil;
    da_glClearDepth glClearDepth;
    da_glStencilMask glStencilMask;
    da_glColorMask glColorMask;
    da_glDisable glDisable;
    da_glEnable glEnable;
    da_glFinish glFinish;
    da_glFlush glFlush;
    da_glBlendFunc glBlendFunc;
    da_glLogicOp glLogicOp;
    da_glStencilFunc glStencilFunc;
    da_glStencilOp glStencilOp;
    da_glDepthFunc glDepthFunc;
    da_glPixelStoref glPixelStoref;
    da_glPixelStorei glPixelStorei;
    da_glReadBuffer glReadBuffer;
    da_glReadPixels glReadPixels;
    da_glGetBooleanv glGetBooleanv;
    da_glGetDoublev glGetDoublev;
    da_glGetError glGetError;
    da_glGetFloatv glGetFloatv;
    da_glGetIntegerv glGetIntegerv;
    da_glGetString glGetString;
    da_glGetTexImage glGetTexImage;
    da_glGetTexParameterfv glGetTexParameterfv;
    da_glGetTexParameteriv glGetTexParameteriv;
    da_glGetTexLevelParameterfv glGetTexLevelParameterfv;
    da_glGetTexLevelParameteriv glGetTexLevelParameteriv;
    da_glIsEnabled glIsEnabled;
    da_glDepthRange glDepthRange;
    da_glViewport glViewport;
}

// OpenGL 1.1
extern(System)
{
    alias nothrow void function(GLenum, GLint, GLsizei) da_glDrawArrays;
    alias nothrow void function(GLenum, GLsizei, GLenum, const(GLvoid)*) da_glDrawElements;
    alias nothrow void function(GLenum, GLvoid*) da_glGetPointerv;
    alias nothrow void function(GLfloat, GLfloat) da_glPolygonOffset;
    alias nothrow void function(GLenum, GLint, GLenum, GLint, GLint, GLsizei, GLint) da_glCopyTexImage1D;
    alias nothrow void function(GLenum, GLint, GLenum, GLint, GLint, GLsizei, GLsizei, GLint) da_glCopyTexImage2D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLint, GLsizei) da_glCopyTexSubImage1D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLint, GLint, GLsizei, GLsizei) da_glCopyTexSubImage2D;
    alias nothrow void function(GLenum, GLint, GLint, GLsizei, GLenum, GLenum, const(GLvoid)*) da_glTexSubImage1D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLenum, const(GLvoid)*) da_glTexSubImage2D;
    alias nothrow void function(GLenum, GLuint) da_glBindTexture;
    alias nothrow void function(GLsizei, const(GLuint)*) da_glDeleteTextures;
    alias nothrow void function(GLsizei, GLuint*) da_glGenTextures;
    alias nothrow GLboolean function(GLuint) da_glIsTexture;
}

__gshared
{
    da_glDrawArrays glDrawArrays;
    da_glDrawElements glDrawElements;
    da_glGetPointerv glGetPointerv;
    da_glPolygonOffset glPolygonOffset;
    da_glCopyTexImage1D glCopyTexImage1D;
    da_glCopyTexImage2D glCopyTexImage2D;
    da_glCopyTexSubImage1D glCopyTexSubImage1D;
    da_glCopyTexSubImage2D glCopyTexSubImage2D;
    da_glTexSubImage1D glTexSubImage1D;
    da_glTexSubImage2D glTexSubImage2D;
    da_glBindTexture glBindTexture;
    da_glDeleteTextures glDeleteTextures;
    da_glGenTextures glGenTextures;
    da_glIsTexture glIsTexture;
}

// OpenGL 1.2
extern(System)
{
    alias nothrow void function(GLclampf, GLclampf, GLclampf, GLclampf) da_glBlendColor;
    alias nothrow void function(GLenum) da_glBlendEquation;
    alias nothrow void function(GLenum, GLuint, GLuint, GLsizei, GLenum, const(GLvoid)*) da_glDrawRangeElements;
    alias nothrow void function(GLenum, GLint, GLint, GLsizei, GLsizei, GLsizei, GLint, GLenum, GLenum, const(GLvoid)*) da_glTexImage3D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLenum, const(GLvoid)*) da_glTexSubImage3D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLint, GLint, GLint, GLsizei, GLsizei) da_glCopyTexSubImage3D;
}

__gshared
{
    da_glBlendColor glBlendColor;
    da_glBlendEquation glBlendEquation;
    da_glDrawRangeElements glDrawRangeElements;
    da_glTexImage3D glTexImage3D;
    da_glTexSubImage3D glTexSubImage3D;
    da_glCopyTexSubImage3D glCopyTexSubImage3D;
}

// OpenGL 1.3
extern(System)
{
    alias nothrow void function(GLenum) da_glActiveTexture;
    alias nothrow void function(GLclampf, GLboolean) da_glSampleCoverage;
    alias nothrow void function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei, GLint, GLsizei, const(GLvoid)*) da_glCompressedTexImage3D;
    alias nothrow void function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, const(GLvoid)*) da_glCompressedTexImage2D;
    alias nothrow void function(GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, const(GLvoid)*) da_glCompressedTexImage1D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, const(GLvoid)*) da_glCompressedTexSubImage3D;
    alias nothrow void function(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, const(GLvoid)*) da_glCompressedTexSubImage2D;
    alias nothrow void function(GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, const(GLvoid)*) da_glCompressedTexSubImage1D;
    alias nothrow void function(GLenum, GLint, GLvoid*) da_glGetCompressedTexImage;
}

__gshared
{
    da_glActiveTexture glActiveTexture;
    da_glSampleCoverage glSampleCoverage;
    da_glCompressedTexImage3D glCompressedTexImage3D;
    da_glCompressedTexImage2D glCompressedTexImage2D;
    da_glCompressedTexImage1D glCompressedTexImage1D;
    da_glCompressedTexSubImage3D glCompressedTexSubImage3D;
    da_glCompressedTexSubImage2D glCompressedTexSubImage2D;
    da_glCompressedTexSubImage1D glCompressedTexSubImage1D;
    da_glGetCompressedTexImage glGetCompressedTexImage;
}

// OpenGL 1.4
extern(System)
{
    alias nothrow void function(GLenum, GLenum, GLenum, GLenum) da_glBlendFuncSeparate;
    alias nothrow void function(GLenum, const(GLint)*, const(GLsizei)*, GLsizei) da_glMultiDrawArrays;
    alias nothrow void function(GLenum, const(GLsizei)*, GLenum, const(GLvoid)*, GLsizei) da_glMultiDrawElements;
    alias nothrow void function(GLenum, GLfloat) da_glPointParameterf;
    alias nothrow void function(GLenum, const(GLfloat)*) da_glPointParameterfv;
    alias nothrow void function(GLenum, GLint) da_glPointParameteri;
    alias nothrow void function(GLenum, const(GLint)*) da_glPointParameteriv;
}

__gshared
{
    da_glBlendFuncSeparate glBlendFuncSeparate;
    da_glMultiDrawArrays glMultiDrawArrays;
    da_glMultiDrawElements glMultiDrawElements;
    da_glPointParameterf glPointParameterf;
    da_glPointParameterfv glPointParameterfv;
    da_glPointParameteri glPointParameteri;
    da_glPointParameteriv glPointParameteriv;
}

// OpenGL 1.5
extern(System)
{
    alias nothrow void function(GLsizei, GLuint*) da_glGenQueries;
    alias nothrow void function(GLsizei, const(GLuint)*) da_glDeleteQueries;
    alias nothrow GLboolean function(GLuint) da_glIsQuery;
    alias nothrow void function(GLenum, GLuint) da_glBeginQuery;
    alias nothrow void function(GLenum) da_glEndQuery;
    alias nothrow void function(GLenum, GLenum, GLint*) da_glGetQueryiv;
    alias nothrow void function(GLuint, GLenum, GLint*) da_glGetQueryObjectiv;
    alias nothrow void function(GLuint, GLenum, GLuint*) da_glGetQueryObjectuiv;
    alias nothrow void function(GLenum, GLuint) da_glBindBuffer;
    alias nothrow void function(GLsizei, const(GLuint)*) da_glDeleteBuffers;
    alias nothrow void function(GLsizei, GLuint*) da_glGenBuffers;
    alias nothrow GLboolean function(GLuint) da_glIsBuffer;
    alias nothrow void function(GLenum, GLsizeiptr, const(GLvoid)*, GLenum) da_glBufferData;
    alias nothrow void function(GLenum, GLintptr, GLsizeiptr, const(GLvoid)*) da_glBufferSubData;
    alias nothrow void function(GLenum, GLintptr, GLsizeiptr, GLvoid*) da_glGetBufferSubData;
    alias nothrow GLvoid* function(GLenum, GLenum) da_glMapBuffer;
    alias nothrow GLboolean function(GLenum) da_glUnmapBuffer;
    alias nothrow void function(GLenum, GLenum, GLint*) da_glGetBufferParameteriv;
    alias nothrow void function(GLenum, GLenum, GLvoid*) da_glGetBufferPointerv;
}

__gshared
{
    da_glGenQueries glGenQueries;
    da_glDeleteQueries glDeleteQueries;
    da_glIsQuery glIsQuery;
    da_glBeginQuery glBeginQuery;
    da_glEndQuery glEndQuery;
    da_glGetQueryiv glGetQueryiv;
    da_glGetQueryObjectiv glGetQueryObjectiv;
    da_glGetQueryObjectuiv glGetQueryObjectuiv;
    da_glBindBuffer glBindBuffer;
    da_glDeleteBuffers glDeleteBuffers;
    da_glGenBuffers glGenBuffers;
    da_glIsBuffer glIsBuffer;
    da_glBufferData glBufferData;
    da_glBufferSubData glBufferSubData;
    da_glGetBufferSubData glGetBufferSubData;
    da_glMapBuffer glMapBuffer;
    da_glUnmapBuffer glUnmapBuffer;
    da_glGetBufferParameteriv glGetBufferParameteriv;
    da_glGetBufferPointerv glGetBufferPointerv;
}

// OpenGL 2.0
extern(System)
{
    alias nothrow void function(GLenum, GLenum) da_glBlendEquationSeparate;
    alias nothrow void function(GLsizei, const(GLenum)*) da_glDrawBuffers;
    alias nothrow void function(GLenum, GLenum, GLenum, GLenum) da_glStencilOpSeparate;
    alias nothrow void function(GLenum, GLenum, GLint, GLuint) da_glStencilFuncSeparate;
    alias nothrow void function(GLenum, GLuint) da_glStencilMaskSeparate;
    alias nothrow void function(GLuint, GLuint) da_glAttachShader;
    alias nothrow void function(GLuint, GLuint, const(GLchar)*) da_glBindAttribLocation;
    alias nothrow void function(GLuint) da_glCompileShader;
    alias nothrow GLuint function() da_glCreateProgram;
    alias nothrow GLuint function(GLenum) da_glCreateShader;
    alias nothrow void function(GLuint) da_glDeleteProgram;
    alias nothrow void function(GLuint) da_glDeleteShader;
    alias nothrow void function(GLuint, GLuint) da_glDetachShader;
    alias nothrow void function(GLuint) da_glDisableVertexAttribArray;
    alias nothrow void function(GLuint) da_glEnableVertexAttribArray;
    alias nothrow void function(GLuint, GLuint, GLsizei, GLsizei*, GLint*, GLenum*, GLchar*) da_glGetActiveAttrib;
    alias nothrow void function(GLuint, GLuint, GLsizei, GLsizei*, GLint*, GLenum*, GLchar*) da_glGetActiveUniform;
    alias nothrow void function(GLuint, GLsizei, GLsizei*, GLuint*) da_glGetAttachedShaders;
    alias nothrow GLint function(GLuint, const(GLchar)*) da_glGetAttribLocation;
    alias nothrow void function(GLuint, GLenum, GLint*) da_glGetProgramiv;
    alias nothrow void function(GLuint, GLsizei, GLsizei*, GLchar*) da_glGetProgramInfoLog;
    alias nothrow void function(GLuint, GLenum, GLint*) da_glGetShaderiv;
    alias nothrow void function(GLuint, GLsizei, GLsizei*, GLchar*) da_glGetShaderInfoLog;
    alias nothrow void function(GLuint, GLsizei, GLsizei*, GLchar*) da_glGetShaderSource;
    alias nothrow GLint function(GLuint, const(GLchar)*) da_glGetUniformLocation;
    alias nothrow void function(GLuint, GLint, GLfloat*) da_glGetUniformfv;
    alias nothrow void function(GLuint, GLint, GLint*) da_glGetUniformiv;
    alias nothrow void function(GLuint, GLenum, GLdouble*) da_glGetVertexAttribdv;
    alias nothrow void function(GLuint, GLenum, GLfloat*) da_glGetVertexAttribfv;
    alias nothrow void function(GLuint, GLenum, GLint*) da_glGetVertexAttribiv;
    alias nothrow void function(GLuint, GLenum, GLvoid*) da_glGetVertexAttribPointerv;
    alias nothrow GLboolean function(GLuint) da_glIsProgram;
    alias nothrow GLboolean function(GLuint) da_glIsShader;
    alias nothrow void function(GLuint) da_glLinkProgram;
    alias nothrow void function(GLuint, GLsizei, const(GLchar*)*, const(GLint)*) da_glShaderSource;
    alias nothrow void function(GLuint) da_glUseProgram;
    alias nothrow void function(GLint, GLfloat) da_glUniform1f;
    alias nothrow void function(GLint, GLfloat, GLfloat) da_glUniform2f;
    alias nothrow void function(GLint, GLfloat, GLfloat, GLfloat) da_glUniform3f;
    alias nothrow void function(GLint, GLfloat, GLfloat, GLfloat, GLfloat) da_glUniform4f;
    alias nothrow void function(GLint, GLint) da_glUniform1i;
    alias nothrow void function(GLint, GLint, GLint) da_glUniform2i;
    alias nothrow void function(GLint, GLint, GLint, GLint) da_glUniform3i;
    alias nothrow void function(GLint, GLint, GLint, GLint, GLint) da_glUniform4i;
    alias nothrow void function(GLint, GLsizei, const(GLfloat)*) da_glUniform1fv;
    alias nothrow void function(GLint, GLsizei, const(GLfloat)*) da_glUniform2fv;
    alias nothrow void function(GLint, GLsizei, const(GLfloat)*) da_glUniform3fv;
    alias nothrow void function(GLint, GLsizei, const(GLfloat)*) da_glUniform4fv;
    alias nothrow void function(GLint, GLsizei, const(GLint)*) da_glUniform1iv;
    alias nothrow void function(GLint, GLsizei, const(GLint)*) da_glUniform2iv;
    alias nothrow void function(GLint, GLsizei, const(GLint)*) da_glUniform3iv;
    alias nothrow void function(GLint, GLsizei, const(GLint)*) da_glUniform4iv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix2fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix3fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix4fv;
    alias nothrow void function(GLuint) da_glValidateProgram;
    alias nothrow void function(GLuint, GLdouble) da_glVertexAttrib1d;
    alias nothrow void function(GLuint, const(GLdouble)*) da_glVertexAttrib1dv;
    alias nothrow void function(GLuint, GLfloat) da_glVertexAttrib1f;
    alias nothrow void function(GLuint, const(GLfloat)*) da_glVertexAttrib1fv;
    alias nothrow void function(GLuint, GLshort) da_glVertexAttrib1s;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttrib1sv;
    alias nothrow void function(GLuint, GLdouble, GLdouble) da_glVertexAttrib2d;
    alias nothrow void function(GLuint, const(GLdouble)*) da_glVertexAttrib2dv;
    alias nothrow void function(GLuint, GLfloat, GLfloat) da_glVertexAttrib2f;
    alias nothrow void function(GLuint, const(GLfloat)*) da_glVertexAttrib2fv;
    alias nothrow void function(GLuint, GLshort, GLshort) da_glVertexAttrib2s;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttrib2sv;
    alias nothrow void function(GLuint, GLdouble, GLdouble, GLdouble) da_glVertexAttrib3d;
    alias nothrow void function(GLuint, const(GLdouble)*) da_glVertexAttrib3dv;
    alias nothrow void function(GLuint, GLfloat, GLfloat, GLfloat) da_glVertexAttrib3f;
    alias nothrow void function(GLuint, const(GLfloat)*) da_glVertexAttrib3fv;
    alias nothrow void function(GLuint, GLshort, GLshort, GLshort) da_glVertexAttrib3s;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttrib3sv;
    alias nothrow void function(GLuint, const(GLbyte)*) da_glVertexAttrib4Nbv;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttrib4Niv;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttrib4Nsv;
    alias nothrow void function(GLuint, GLubyte, GLubyte, GLubyte, GLubyte) da_glVertexAttrib4Nub;
    alias nothrow void function(GLuint, const(GLubyte)*) da_glVertexAttrib4Nubv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttrib4Nuiv;
    alias nothrow void function(GLuint, const(GLushort)*) da_glVertexAttrib4Nusv;
    alias nothrow void function(GLuint, const(GLbyte)*) da_glVertexAttrib4bv;
    alias nothrow void function(GLuint, GLdouble, GLdouble, GLdouble, GLdouble) da_glVertexAttrib4d;
    alias nothrow void function(GLuint, const(GLdouble)*) da_glVertexAttrib4dv;
    alias nothrow void function(GLuint, GLfloat, GLfloat, GLfloat, GLfloat) da_glVertexAttrib4f;
    alias nothrow void function(GLuint, const(GLfloat)*) da_glVertexAttrib4fv;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttrib4iv;
    alias nothrow void function(GLuint, GLshort, GLshort, GLshort, GLshort) da_glVertexAttrib4s;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttrib4sv;
    alias nothrow void function(GLuint, const(GLubyte)*) da_glVertexAttrib4ubv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttrib4uiv;
    alias nothrow void function(GLuint, const(GLushort)*) da_glVertexAttrib4usv;
    alias nothrow void function(GLuint, GLint, GLenum, GLboolean, GLsizei, const(GLvoid)*) da_glVertexAttribPointer;
}

__gshared
{
    da_glBlendEquationSeparate glBlendEquationSeparate;
    da_glDrawBuffers glDrawBuffers;
    da_glStencilOpSeparate glStencilOpSeparate;
    da_glStencilFuncSeparate glStencilFuncSeparate;
    da_glStencilMaskSeparate glStencilMaskSeparate;
    da_glAttachShader glAttachShader;
    da_glBindAttribLocation glBindAttribLocation;
    da_glCompileShader glCompileShader;
    da_glCreateProgram glCreateProgram;
    da_glCreateShader glCreateShader;
    da_glDeleteProgram glDeleteProgram;
    da_glDeleteShader glDeleteShader;
    da_glDetachShader glDetachShader;
    da_glDisableVertexAttribArray glDisableVertexAttribArray;
    da_glEnableVertexAttribArray glEnableVertexAttribArray;
    da_glGetActiveAttrib glGetActiveAttrib;
    da_glGetActiveUniform glGetActiveUniform;
    da_glGetAttachedShaders glGetAttachedShaders;
    da_glGetAttribLocation glGetAttribLocation;
    da_glGetProgramiv glGetProgramiv;
    da_glGetProgramInfoLog glGetProgramInfoLog;
    da_glGetShaderiv glGetShaderiv;
    da_glGetShaderInfoLog glGetShaderInfoLog;
    da_glGetShaderSource glGetShaderSource;
    da_glGetUniformLocation glGetUniformLocation;
    da_glGetUniformfv glGetUniformfv;
    da_glGetUniformiv glGetUniformiv;
    da_glGetVertexAttribdv glGetVertexAttribdv;
    da_glGetVertexAttribfv glGetVertexAttribfv;
    da_glGetVertexAttribiv glGetVertexAttribiv;
    da_glGetVertexAttribPointerv glGetVertexAttribPointerv;
    da_glIsProgram glIsProgram;
    da_glIsShader glIsShader;
    da_glLinkProgram glLinkProgram;
    da_glShaderSource glShaderSource;
    da_glUseProgram glUseProgram;
    da_glUniform1f glUniform1f;
    da_glUniform2f glUniform2f;
    da_glUniform3f glUniform3f;
    da_glUniform4f glUniform4f;
    da_glUniform1i glUniform1i;
    da_glUniform2i glUniform2i;
    da_glUniform3i glUniform3i;
    da_glUniform4i glUniform4i;
    da_glUniform1fv glUniform1fv;
    da_glUniform2fv glUniform2fv;
    da_glUniform3fv glUniform3fv;
    da_glUniform4fv glUniform4fv;
    da_glUniform1iv glUniform1iv;
    da_glUniform2iv glUniform2iv;
    da_glUniform3iv glUniform3iv;
    da_glUniform4iv glUniform4iv;
    da_glUniformMatrix2fv glUniformMatrix2fv;
    da_glUniformMatrix3fv glUniformMatrix3fv;
    da_glUniformMatrix4fv glUniformMatrix4fv;
    da_glValidateProgram glValidateProgram;
    da_glVertexAttrib1d glVertexAttrib1d;
    da_glVertexAttrib1dv glVertexAttrib1dv;
    da_glVertexAttrib1f glVertexAttrib1f;
    da_glVertexAttrib1fv glVertexAttrib1fv;
    da_glVertexAttrib1s glVertexAttrib1s;
    da_glVertexAttrib1sv glVertexAttrib1sv;
    da_glVertexAttrib2d glVertexAttrib2d;
    da_glVertexAttrib2dv glVertexAttrib2dv;
    da_glVertexAttrib2f glVertexAttrib2f;
    da_glVertexAttrib2fv glVertexAttrib2fv;
    da_glVertexAttrib2s glVertexAttrib2s;
    da_glVertexAttrib2sv glVertexAttrib2sv;
    da_glVertexAttrib3d glVertexAttrib3d;
    da_glVertexAttrib3dv glVertexAttrib3dv;
    da_glVertexAttrib3f glVertexAttrib3f;
    da_glVertexAttrib3fv glVertexAttrib3fv;
    da_glVertexAttrib3s glVertexAttrib3s;
    da_glVertexAttrib3sv glVertexAttrib3sv;
    da_glVertexAttrib4Nbv glVertexAttrib4Nbv;
    da_glVertexAttrib4Niv glVertexAttrib4Niv;
    da_glVertexAttrib4Nsv glVertexAttrib4Nsv;
    da_glVertexAttrib4Nub glVertexAttrib4Nub;
    da_glVertexAttrib4Nubv glVertexAttrib4Nubv;
    da_glVertexAttrib4Nuiv glVertexAttrib4Nuiv;
    da_glVertexAttrib4Nusv glVertexAttrib4Nusv;
    da_glVertexAttrib4bv glVertexAttrib4bv;
    da_glVertexAttrib4d glVertexAttrib4d;
    da_glVertexAttrib4dv glVertexAttrib4dv;
    da_glVertexAttrib4f glVertexAttrib4f;
    da_glVertexAttrib4fv glVertexAttrib4fv;
    da_glVertexAttrib4iv glVertexAttrib4iv;
    da_glVertexAttrib4s glVertexAttrib4s;
    da_glVertexAttrib4sv glVertexAttrib4sv;
    da_glVertexAttrib4ubv glVertexAttrib4ubv;
    da_glVertexAttrib4uiv glVertexAttrib4uiv;
    da_glVertexAttrib4usv glVertexAttrib4usv;
    da_glVertexAttribPointer glVertexAttribPointer;
}

// OpenGL 2.1
extern(System)
{
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix2x3fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix3x2fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix2x4fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix4x2fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix3x4fv;
    alias nothrow void function(GLint, GLsizei, GLboolean, const(GLfloat)*) da_glUniformMatrix4x3fv;
}

__gshared
{
    da_glUniformMatrix2x3fv glUniformMatrix2x3fv;
    da_glUniformMatrix3x2fv glUniformMatrix3x2fv;
    da_glUniformMatrix2x4fv glUniformMatrix2x4fv;
    da_glUniformMatrix4x2fv glUniformMatrix4x2fv;
    da_glUniformMatrix3x4fv glUniformMatrix3x4fv;
    da_glUniformMatrix4x3fv glUniformMatrix4x3fv;
}

// OpenGL 3.0
extern(System)
{
    alias nothrow void function(GLuint, GLboolean, GLboolean, GLboolean, GLboolean) da_glColorMaski;
    alias nothrow void function(GLenum, GLuint, GLboolean*) da_glGetBooleani_v;
    alias nothrow void function(GLenum, GLuint, GLint*) da_glGetIntegeri_v;
    alias nothrow void function(GLenum, GLuint) da_glEnablei;
    alias nothrow void function(GLenum, GLuint) da_glDisablei;
    alias nothrow GLboolean function(GLenum, GLuint) da_glIsEnabledi;
    alias nothrow void function(GLenum) da_glBeginTransformFeedback;
    alias nothrow void function() da_glEndTransformFeedback;
    alias nothrow void function(GLenum, GLuint, GLuint, GLintptr, GLsizeiptr) da_glBindBufferRange;
    alias nothrow void function(GLenum, GLuint, GLuint) da_glBindBufferBase;
    alias nothrow void function(GLuint, GLsizei, const(GLchar*)*, GLenum) da_glTransformFeedbackVaryings;
    alias nothrow void function(GLuint, GLuint, GLsizei, GLsizei*, GLsizei*, GLenum*, GLchar*) da_glGetTransformFeedbackVarying;
    alias nothrow void function(GLenum, GLenum) da_glClampColor;
    alias nothrow void function(GLuint, GLenum) da_glBeginConditionalRender;
    alias nothrow void function() da_glEndConditionalRender;
    alias nothrow void function(GLuint, GLint, GLenum, GLsizei, const(GLvoid)*) da_glVertexAttribIPointer;
    alias nothrow void function(GLuint, GLenum, GLint*) da_glGetVertexAttribIiv;
    alias nothrow void function(GLuint, GLenum, GLuint*) da_glGetVertexAttribIuiv;
    alias nothrow void function(GLuint, GLint) da_glVertexAttribI1i;
    alias nothrow void function(GLuint, GLint, GLint) da_glVertexAttribI2i;
    alias nothrow void function(GLuint, GLint, GLint, GLint) da_glVertexAttribI3i;
    alias nothrow void function(GLuint, GLint, GLint, GLint, GLint) da_glVertexAttribI4i;
    alias nothrow void function(GLuint, GLuint) da_glVertexAttribI1ui;
    alias nothrow void function(GLuint, GLuint, GLuint) da_glVertexAttribI2ui;
    alias nothrow void function(GLuint, GLuint, GLuint, GLuint) da_glVertexAttribI3ui;
    alias nothrow void function(GLuint, GLuint, GLuint, GLuint, GLuint) da_glVertexAttribI4ui;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttribI1iv;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttribI2iv;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttribI3iv;
    alias nothrow void function(GLuint, const(GLint)*) da_glVertexAttribI4iv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttribI1uiv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttribI2uiv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttribI3uiv;
    alias nothrow void function(GLuint, const(GLuint)*) da_glVertexAttribI4uiv;
    alias nothrow void function(GLuint, const(GLbyte)*) da_glVertexAttribI4bv;
    alias nothrow void function(GLuint, const(GLshort)*) da_glVertexAttribI4sv;
    alias nothrow void function(GLuint, const(GLubyte)*) da_glVertexAttribI4ubv;
    alias nothrow void function(GLuint, const(GLushort)*) da_glVertexAttribI4usv;
    alias nothrow void function(GLuint, GLint, GLuint*) da_glGetUniformuiv;
    alias nothrow void function(GLuint, GLuint, const(GLchar)*) da_glBindFragDataLocation;
    alias nothrow GLint function(GLuint, const(GLchar)*) da_glGetFragDataLocation;
    alias nothrow void function(GLint, GLuint) da_glUniform1ui;
    alias nothrow void function(GLint, GLuint, GLuint) da_glUniform2ui;
    alias nothrow void function(GLint, GLuint, GLuint, GLuint) da_glUniform3ui;
    alias nothrow void function(GLint, GLuint, GLuint, GLuint, GLuint) da_glUniform4ui;
    alias nothrow void function(GLint, GLsizei, const(GLuint)*) da_glUniform1uiv;
    alias nothrow void function(GLint, GLsizei, const(GLuint)*) da_glUniform2uiv;
    alias nothrow void function(GLint, GLsizei, const(GLuint)*) da_glUniform3uiv;
    alias nothrow void function(GLint, GLsizei, const(GLuint)*) da_glUniform4uiv;
    alias nothrow void function(GLenum, GLenum, const(GLint)*) da_glTexParameterIiv;
    alias nothrow void function(GLenum, GLenum, const(GLuint)*) da_glTexParameterIuiv;
    alias nothrow void function(GLenum, GLenum, GLint*) da_glGetTexParameterIiv;
    alias nothrow void function(GLenum, GLenum, GLuint*) da_glGetTexParameterIuiv;
    alias nothrow void function(GLenum, GLint, const(GLint)*) da_glClearBufferiv;
    alias nothrow void function(GLenum, GLint, const(GLuint)*) da_glClearBufferuiv;
    alias nothrow void function(GLenum, GLint, const(GLfloat)*) da_glClearBufferfv;
    alias nothrow void function(GLenum, GLint, GLfloat, GLint) da_glClearBufferfi;
    alias nothrow const(char)* function(GLenum, GLuint) da_glGetStringi;
}

__gshared
{
    da_glColorMaski glColorMaski;
    da_glGetBooleani_v glGetBooleani_v;
    da_glGetIntegeri_v glGetIntegeri_v;
    da_glEnablei glEnablei;
    da_glDisablei glDisablei;
    da_glIsEnabledi glIsEnabledi;
    da_glBeginTransformFeedback glBeginTransformFeedback;
    da_glEndTransformFeedback glEndTransformFeedback;
    da_glBindBufferRange glBindBufferRange;
    da_glBindBufferBase glBindBufferBase;
    da_glTransformFeedbackVaryings glTransformFeedbackVaryings;
    da_glGetTransformFeedbackVarying glGetTransformFeedbackVarying;
    da_glClampColor glClampColor;
    da_glBeginConditionalRender glBeginConditionalRender;
    da_glEndConditionalRender glEndConditionalRender;
    da_glVertexAttribIPointer glVertexAttribIPointer;
    da_glGetVertexAttribIiv glGetVertexAttribIiv;
    da_glGetVertexAttribIuiv glGetVertexAttribIuiv;
    da_glVertexAttribI1i glVertexAttribI1i;
    da_glVertexAttribI2i glVertexAttribI2i;
    da_glVertexAttribI3i glVertexAttribI3i;
    da_glVertexAttribI4i glVertexAttribI4i;
    da_glVertexAttribI1ui glVertexAttribI1ui;
    da_glVertexAttribI2ui glVertexAttribI2ui;
    da_glVertexAttribI3ui glVertexAttribI3ui;
    da_glVertexAttribI4ui glVertexAttribI4ui;
    da_glVertexAttribI1iv glVertexAttribI1iv;
    da_glVertexAttribI2iv glVertexAttribI2iv;
    da_glVertexAttribI3iv glVertexAttribI3iv;
    da_glVertexAttribI4iv glVertexAttribI4iv;
    da_glVertexAttribI1uiv glVertexAttribI1uiv;
    da_glVertexAttribI2uiv glVertexAttribI2uiv;
    da_glVertexAttribI3uiv glVertexAttribI3uiv;
    da_glVertexAttribI4uiv glVertexAttribI4uiv;
    da_glVertexAttribI4bv glVertexAttribI4bv;
    da_glVertexAttribI4sv glVertexAttribI4sv;
    da_glVertexAttribI4ubv glVertexAttribI4ubv;
    da_glVertexAttribI4usv glVertexAttribI4usv;
    da_glGetUniformuiv glGetUniformuiv;
    da_glBindFragDataLocation glBindFragDataLocation;
    da_glGetFragDataLocation glGetFragDataLocation;
    da_glUniform1ui glUniform1ui;
    da_glUniform2ui glUniform2ui;
    da_glUniform3ui glUniform3ui;
    da_glUniform4ui glUniform4ui;
    da_glUniform1uiv glUniform1uiv;
    da_glUniform2uiv glUniform2uiv;
    da_glUniform3uiv glUniform3uiv;
    da_glUniform4uiv glUniform4uiv;
    da_glTexParameterIiv glTexParameterIiv;
    da_glTexParameterIuiv glTexParameterIuiv;
    da_glGetTexParameterIiv glGetTexParameterIiv;
    da_glGetTexParameterIuiv glGetTexParameterIuiv;
    da_glClearBufferiv glClearBufferiv;
    da_glClearBufferuiv glClearBufferuiv;
    da_glClearBufferfv glClearBufferfv;
    da_glClearBufferfi glClearBufferfi;
    da_glGetStringi glGetStringi;
}

// OpenGL 3.1
extern(System)
{
    alias nothrow void function(GLenum, GLint, GLsizei, GLsizei) da_glDrawArraysInstanced;
    alias nothrow void function(GLenum, GLsizei, GLenum, const(GLvoid)*, GLsizei) da_glDrawElementsInstanced;
    alias nothrow void function(GLenum, GLenum, GLuint) da_glTexBuffer;
    alias nothrow void function(GLuint) da_glPrimitiveRestartIndex;
}

__gshared
{
    da_glDrawArraysInstanced glDrawArraysInstanced;
    da_glDrawElementsInstanced glDrawElementsInstanced;
    da_glTexBuffer glTexBuffer;
    da_glPrimitiveRestartIndex glPrimitiveRestartIndex;
}

// OpenGL 3.2
extern(System)
{
    alias nothrow void function(GLenum, GLuint, GLint64*) da_glGetInteger64i_v;
    alias nothrow void function(GLenum, GLenum, GLint64*) da_glGetBufferParameteri64v;
    alias nothrow void function(GLenum, GLenum, GLuint, GLint) da_glFramebufferTexture;
}

__gshared
{
    da_glGetInteger64i_v glGetInteger64i_v;
    da_glGetBufferParameteri64v glGetBufferParameteri64v;
    da_glFramebufferTexture glFramebufferTexture;
}

// OpenGL 3.3
extern(System) alias nothrow void function(GLuint, GLuint) da_glVertexAttribDivisor;
__gshared da_glVertexAttribDivisor glVertexAttribDivisor;

// OpenGL 4.0
extern(System)
{
    alias nothrow void function(GLclampf) da_glMinSampleShading;
    alias nothrow void function(GLuint, GLenum) da_glBlendEquationi;
    alias nothrow void function(GLuint, GLenum, GLenum) da_glBlendEquationSeparatei;
    alias nothrow void function(GLuint, GLenum, GLenum) da_glBlendFunci;
    alias nothrow void function(GLuint, GLenum, GLenum, GLenum, GLenum) da_glBlendFuncSeparatei;
}

__gshared
{
    da_glMinSampleShading glMinSampleShading;
    da_glBlendEquationi glBlendEquationi;
    da_glBlendEquationSeparatei glBlendEquationSeparatei;
    da_glBlendFunci glBlendFunci;
    da_glBlendFuncSeparatei glBlendFuncSeparatei;
}