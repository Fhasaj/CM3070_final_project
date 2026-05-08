## Title: Vehicle Detection, Tracking and Counting
## Description: A real-time C++ pipeline for detecting, tracking, and counting vehicles in traffic camera footage.
## Built as a final-year project for CM3065 Intelligent Signal Processing at the University of London (BSc Computer Science).

cmake_minimum_required(VERSION 3.10)
project(vehicle_tracker)
set(CMAKE_CXX_STANDARD 20)
find_package(OpenCV REQUIRED)
add_executable(vehicle_tracker src/main.cpp
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
target_link_libraries(vehicle_tracker ${OpenCV_LIBS})