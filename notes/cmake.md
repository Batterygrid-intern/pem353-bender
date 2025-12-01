# crosscompile with cmake

# cmake variables
Variables are used to store information that can be used throughout the build process.

In cmake they are defined with set()
## variable scope
each variable has a scope, which defines where it can be used.(dynamic scope)

## set() function
the set function is used to set variables in cmake

## unset() function 
the unset function is used to unset variables in cmake

## block() command
creates new scope for variables
## cache option for variables
to set variables in cmake cache that will be stored over multiple runs

# Directories

## CMakeLists.txt
entry point for cmake is the CMakeLists.txt in the root directory of the project