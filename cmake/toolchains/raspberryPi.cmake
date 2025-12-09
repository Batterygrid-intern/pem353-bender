# raspberryPi.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Path to sysroot
set(CMAKE_SYSROOT $ENV{HOME}/cross-compile/rpi4-sysroot)

# Cross-compiler (installed on PC)
set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)

# Use PC's mak
# DO NOT set CMAKE_MAKE_PROGRAM to anything inside the sysroot
