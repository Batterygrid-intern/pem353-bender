# cross compiling for raspberry pi
A CrossCompiler is a compiler that compiles code for a different/targeted architecture other than the host system.  
# what is a toolchain?
can for example be a compiler,linker,debugger that works simultaneously to build a [software product](https://en.wikipedia.org/wiki/Toolchain)
# what is sysroot
sysroot is a directory that contains the system headers and libraries that are needed to build a software product.
need to setup this before you can cross compile. will contain the headers and libraries for the targeted system which you will compile against

# install the compiler  used for the targeted system?


# Toolchain for my project
download toolchain for AArch64 point to it in cmake toolchain file now stored in ~/xcompilation/rpi4
next step add it to path. 

1. Download in home directory
2. unzip in home directory
3.  arm-gnu toolchian to path add to path
4. set in my cmake toolchains
5. compile my libraries with the toolchain from my home directory
6. package all dynamic and binaries in a zip file
7. copy to raspberry pi
8. when i run the program it will find the toolchain in the home directory. by me running cmake with -DCMAKE.... using raspberrypi.cmake toolchain.
