//========================================================================
// Gamma correction test program
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
// This program is used to test the gamma correction functionality for
// both fullscreen and windowed mode windows
//
//========================================================================

#include <GL/glfw3.h>

#include <stdio.h>
#include <stdlib.h>

#include "getopt.h"

#define STEP_SIZE 0.1f

static GLfloat gamma = 1.0f;

static void usage(void)
{
    printf("Usage: gamma [-h] [-f]\n");
}

static void set_gamma(float value)
{
    gamma = value;
    printf("Gamma: %f\n", gamma);
    glfwSetGamma(gamma);
}

static void key_callback(GLFWwindow window, int key, int action)
{
    if (action != GLFW_PRESS)
        return;

    switch (key)
    {
        case GLFW_KEY_ESCAPE:
        {
            glfwCloseWindow(window);
            break;
        }

        case GLFW_KEY_KP_ADD:
        case GLFW_KEY_Q:
        {
            set_gamma(gamma + STEP_SIZE);
            break;
        }

        case GLFW_KEY_KP_SUBTRACT:
        case GLFW_KEY_W:
        {
            if (gamma - STEP_SIZE > 0.f)
                set_gamma(gamma - STEP_SIZE);

            break;
        }
    }
}

static void size_callback(GLFWwindow window, int width, int height)
{
    glViewport(0, 0, width, height);
}

int main(int argc, char** argv)
{
    int width, height, ch;
    int mode = GLFW_WINDOWED;
    GLFWwindow window;

    while ((ch = getopt(argc, argv, "fh")) != -1)
    {
        switch (ch)
        {
            case 'h':
                usage();
                exit(EXIT_SUCCESS);

            case 'f':
                mode = GLFW_FULLSCREEN;
                break;

            default:
                usage();
                exit(EXIT_FAILURE);
        }
    }

    if (!glfwInit())
    {
        fprintf(stderr, "Failed to initialize GLFW: %s\n", glfwErrorString(glfwGetError()));
        exit(EXIT_FAILURE);
    }

    if (mode == GLFW_FULLSCREEN)
    {
        GLFWvidmode mode;
        glfwGetDesktopMode(&mode);
        width = mode.width;
        height = mode.height;
    }
    else
    {
        width = 0;
        height = 0;
    }

    window = glfwOpenWindow(width, height, mode, "Gamma Test", NULL);
    if (!window)
    {
        glfwTerminate();

        fprintf(stderr, "Failed to open GLFW window: %s\n", glfwErrorString(glfwGetError()));
        exit(EXIT_FAILURE);
    }

    set_gamma(1.f);

    glfwSwapInterval(1);
    glfwSetKeyCallback(key_callback);
    glfwSetWindowSizeCallback(size_callback);

    glMatrixMode(GL_PROJECTION);
    glOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    glMatrixMode(GL_MODELVIEW);

    glClearColor(0.5f, 0.5f, 0.5f, 0);

    while (glfwIsWindow(window))
    {
        glClear(GL_COLOR_BUFFER_BIT);

        glColor3f(0.8f, 0.2f, 0.4f);
        glRectf(-0.5f, -0.5f, 0.5f, 0.5f);

        glfwSwapBuffers();
        glfwPollEvents();
    }

    glfwTerminate();
    exit(EXIT_SUCCESS);
}

