## Title:
## Description:
## Created on:
## Modified on:
cmake_minimum_required(VERSION 3.10)
project(CM3070_final_project)
set(CMAKE_CXX_STANDARD 20)
find_package(OpenCV REQUIRED)
add_executable(CM3070_final_project main.cpp)
target_link_libraries(CM3070_final_project ${OpenCV_LIBS})