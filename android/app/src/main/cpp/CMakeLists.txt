cmake_minimum_required(VERSION 3.22.1)
project(pause_guard_bridge)

add_library(pause_guard_bridge SHARED pause_guard_bridge.cpp)

find_library(log-lib log)
target_link_libraries(pause_guard_bridge ${log-lib})
