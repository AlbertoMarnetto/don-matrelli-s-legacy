cmake_minimum_required(VERSION 3.16)
project(gpc-vehicle-edit)

set(CMAKE_CXX_STANDARD 20 REQUIRED)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets Charts)

add_executable(gpc-vehicle-edit
    main.cpp
    mainwindow.cpp
    vehicledata.cpp
)

target_link_libraries(gpc-vehicle-edit Qt6::Widgets Qt6::Charts)
