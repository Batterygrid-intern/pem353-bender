#CMAKE_SYSTEM_NAME is default set to the same value as the CMAKE_HOST_SYSTEM_NAME.
#For CrossCompilation we need to explicitly tell which os we are targeting in this case Linux(Linux value * all linux distros
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

#Set the compilers for the targeted environments stored on my computer at..
set(CMAKE_C_COMPILER )
set(CMAKE_CXX_COMPILER )