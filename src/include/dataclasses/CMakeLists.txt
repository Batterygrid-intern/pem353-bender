#interface (header only library) for pemData
add_library(pemData INTERFACE)
target_include_directories(pemData
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)
#settings for RTU
add_library(mbRtuSettings INTERFACE)
target_include_directories(mbRtuSettings
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)
#settings for modbus TCP
add_library(mbTcpSettings INTERFACE)
target_include_directories(mbTcpSettings
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)
#settings for mqtt
add_library(mqttPubSettings INTERFACE)
target_include_directories(mqttPubSettings
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)