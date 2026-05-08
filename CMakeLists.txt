## Title:
## Description:
## Created on:
## Modified on:


cmake_minimum_required(VERSION 3.10)
project(CM3070_final_project)
set(CMAKE_CXX_STANDARD 20)
find_package(OpenCV REQUIRED)
add_executable(CM3070_final_project src/main.cpp
        src/detector.cpp
        src/detector.cpp
        include/detector.h
        include/detector.h
        src/tracker.cpp
        include/tracker.h
        src/counter.cpp
        include/counter.h
        src/io.cpp
        include/io.h
        tests/test_tracker.cpp
        tests/test_counter.cpp
        tests/test_detector.cpp)
target_link_libraries(CM3070_final_project ${OpenCV_LIBS})