cmake_minimum_required(VERSION 3.16)
#Project name
project(pem353 LANGUAGES C CXX)

#Project target binary will be stored in ./bin
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
#Set version of c and c++ compiler
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_MINIMUM_REQUIRED_VERSION ON)
#add subdirectory to nlohmann json library
add_subdirectory(lib/nlohmann)
#add subdirectories which will include all my classes and main loops used
add_subdirectory(src)