cmake_minimum_required(VERSION 3.22.1)
project(atlas_llama)

add_library(atlas_llama_bridge SHARED llama_bridge.cpp)

find_library(log-lib log)
find_library(android-lib android)

add_library(llama SHARED IMPORTED)
set_target_properties(llama PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama.so")

target_link_libraries(atlas_llama_bridge
    llama
    ${log-lib}
    ${android-lib})
