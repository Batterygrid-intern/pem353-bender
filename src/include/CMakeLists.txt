#interface (header only library) for pemData
add_library(pemData INTERFACE)
target_include_directories(pemData
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)