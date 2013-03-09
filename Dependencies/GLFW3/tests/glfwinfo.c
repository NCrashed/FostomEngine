//========================================================================
// Version information dumper
// Copyright (c) Camilla Berglund <elmindreda@elmindreda.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================
//
// This test is a pale imitation of glxinfo(1), except not really
//
// It dumps GLFW and OpenGL version information
//
//========================================================================

#include <GL/glfw3.h>
#include <GL/glext.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "getopt.h"

#ifdef _MSC_VER
#define strcasecmp(x, y) _stricmp(x, y)
#endif

#define PROFILE_NAME_CORE   "core"
#define PROFILE_NAME_COMPAT "compat"
#define PROFILE_NAME_ES2    "es2"

#define STRATEGY_NAME_NONE "none"
#define STRATEGY_NAME_LOSE "lose"

static void usage(void)
{
    printf("Usage: glfwinfo [-h] [-m MAJOR] [-n MINOR] [-d] [-l] [-f] [-p PROFILE] [-r STRATEGY]\n");
    printf("available profiles: " PROFILE_NAME_CORE " " PROFILE_NAME_COMPAT " " PROFILE_NAME_ES2 "\n");
    printf("available strategies: " STRATEGY_NAME_NONE " " STRATEGY_NAME_LOSE "\n");
}

static void error_callback(int error, const char* description)
{
    fprintf(stderr, "Error: %s in %s\n", glfwErrorString(error), description);
}

static const char* get_glfw_profile_name(int profile)
{
    if (profile == GLFW_OPENGL_COMPAT_PROFILE)
        return PROFILE_NAME_COMPAT;
    else if (profile == GLFW_OPENGL_CORE_PROFILE)
        return PROFILE_NAME_CORE;
    else if (profile == GLFW_OPENGL_ES2_PROFILE)
        return PROFILE_NAME_ES2;

    return "unknown";
}

static const char* get_profile_name(GLint mask)
{
    if (mask & GL_CONTEXT_COMPATIBILITY_PROFILE_BIT)
        return PROFILE_NAME_COMPAT;
    if (mask & GL_CONTEXT_CORE_PROFILE_BIT)
        return PROFILE_NAME_CORE;

    return "unknown";
}

static void list_extensions(int major, int minor)
{
    int i;
    GLint count;
    const GLubyte* extensions;

    printf("OpenGL context supported extensions:\n");

    if (major > 2)
    {
        PFNGLGETSTRINGIPROC glGetStringi = (PFNGLGETSTRINGIPROC) glfwGetProcAddress("glGetStringi");
        if (!glGetStringi)
            exit(EXIT_FAILURE);

        glGetIntegerv(GL_NUM_EXTENSIONS, &count);

        for (i = 0;  i < count;  i++)
            puts((const char*) glGetStringi(GL_EXTENSIONS, i));
    }
    else
    {
        extensions = glGetString(GL_EXTENSIONS);
        while (*extensions != '\0')
        {
            if (*extensions == ' ')
                putchar('\n');
            else
                putchar(*extensions);

            extensions++;
        }
    }

    putchar('\n');
}

int main(int argc, char** argv)
{
    int ch, profile = 0, strategy = 0, major = 1, minor = 0, revision;
    GLboolean debug = GL_FALSE, forward = GL_FALSE, list = GL_FALSE;
    GLint flags, mask;
    GLFWwindow window;

    while ((ch = getopt(argc, argv, "dfhlm:n:p:r:")) != -1)
    {
        switch (ch)
        {
            case 'd':
                debug = GL_TRUE;
                break;
            case 'f':
                forward = GL_TRUE;
                break;
            case 'h':
                usage();
                exit(EXIT_SUCCESS);
            case 'l':
                list = GL_TRUE;
                break;
            case 'm':
                major = atoi(optarg);
                break;
            case 'n':
                minor = atoi(optarg);
                break;
            case 'p':
                if (strcasecmp(optarg, PROFILE_NAME_CORE) == 0)
                    profile = GLFW_OPENGL_CORE_PROFILE;
                else if (strcasecmp(optarg, PROFILE_NAME_COMPAT) == 0)
                    profile = GLFW_OPENGL_COMPAT_PROFILE;
                else if (strcasecmp(optarg, PROFILE_NAME_ES2) == 0)
                    profile = GLFW_OPENGL_ES2_PROFILE;
                else
                {
                    usage();
                    exit(EXIT_FAILURE);
                }
                break;
            case 'r':
                if (strcasecmp(optarg, STRATEGY_NAME_NONE) == 0)
                    strategy = GLFW_OPENGL_NO_RESET_NOTIFICATION;
                else if (strcasecmp(optarg, STRATEGY_NAME_LOSE) == 0)
                    strategy = GLFW_OPENGL_LOSE_CONTEXT_ON_RESET;
                else
                {
                    usage();
                    exit(EXIT_FAILURE);
                }
                break;
            default:
                usage();
                exit(EXIT_FAILURE);
        }
    }

    argc -= optind;
    argv += optind;

    glfwSetErrorCallback(error_callback);

    if (!glfwInit())
    {
        fprintf(stderr, "Failed to initialize GLFW: %s\n", glfwErrorString(glfwGetError()));
        exit(EXIT_FAILURE);
    }

    if (major != 1 || minor != 0)
    {
        glfwOpenWindowHint(GLFW_OPENGL_VERSION_MAJOR, major);
        glfwOpenWindowHint(GLFW_OPENGL_VERSION_MINOR, minor);
    }

    if (debug)
        glfwOpenWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

    if (forward)
        glfwOpenWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    if (profile != 0)
        glfwOpenWindowHint(GLFW_OPENGL_PROFILE, profile);

    if (strategy)
        glfwOpenWindowHint(GLFW_OPENGL_ROBUSTNESS, strategy);

    // We assume here that we stand a better chance of success by leaving all
    // possible details of pixel format selection to GLFW

    window = glfwOpenWindow(0, 0, GLFW_WINDOWED, "Version", NULL);
    if (!window)
        exit(EXIT_FAILURE);

    // Report GLFW version

    glfwGetVersion(&major, &minor, &revision);

    printf("GLFW header version: %u.%u.%u\n",
           GLFW_VERSION_MAJOR,
           GLFW_VERSION_MINOR,
           GLFW_VERSION_REVISION);

    printf("GLFW library version: %u.%u.%u\n", major, minor, revision);

    if (major != GLFW_VERSION_MAJOR ||
        minor != GLFW_VERSION_MINOR ||
        revision != GLFW_VERSION_REVISION)
    {
        printf("*** WARNING: GLFW version mismatch! ***\n");
    }

    printf("GLFW library version string: \"%s\"\n", glfwGetVersionString());

    // Report OpenGL version

    printf("OpenGL context version string: \"%s\"\n", glGetString(GL_VERSION));

    major = glfwGetWindowParam(window, GLFW_OPENGL_VERSION_MAJOR);
    minor = glfwGetWindowParam(window, GLFW_OPENGL_VERSION_MINOR);
    revision = glfwGetWindowParam(window, GLFW_OPENGL_REVISION);

    printf("OpenGL context version parsed by GLFW: %u.%u.%u\n", major, minor, revision);

    // Report OpenGL context properties

    if (major >= 3)
    {
        glGetIntegerv(GL_CONTEXT_FLAGS, &flags);
        printf("OpenGL context flags:");

        if (flags & GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT)
            puts(" forward-compatible");
        else
            puts(" none");

        printf("OpenGL forward-compatible flag parsed by GLFW: %s\n",
               glfwGetWindowParam(window, GLFW_OPENGL_FORWARD_COMPAT) ? "true" : "false");
    }

    if (major > 3 || (major == 3 && minor >= 2))
    {
        glGetIntegerv(GL_CONTEXT_PROFILE_MASK, &mask);
        printf("OpenGL profile mask: %s (0x%08x)\n", get_profile_name(mask), mask);

        printf("OpenGL profile parsed by GLFW: %s\n",
               get_glfw_profile_name(glfwGetWindowParam(window, GLFW_OPENGL_PROFILE)));
    }

    printf("OpenGL context renderer string: \"%s\"\n", glGetString(GL_RENDERER));
    printf("OpenGL context vendor string: \"%s\"\n", glGetString(GL_VENDOR));

    if (major > 1)
    {
        printf("OpenGL context shading language version: \"%s\"\n",
               glGetString(GL_SHADING_LANGUAGE_VERSION));
    }

    // Report OpenGL extensions
    if (list)
        list_extensions(major, minor);

    glfwTerminate();
    exit(EXIT_SUCCESS);
}

