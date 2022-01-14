cmake_minimum_required(VERSION 3.21)
project(graphical)

set(CMAKE_CXX_STANDARD 23)

add_executable(graphical main.cpp)

set(CMAKE_CXX_FLAGS "-I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/harfbuzz -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/sysprof-4 -pthread -lsfml-graphics -lsfml-window -lsfml-system -L/usr/lib/x86_64-linux-gnu -lOpenCL")