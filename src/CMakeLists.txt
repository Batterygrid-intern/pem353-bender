#build static library and include header for modbusRtu
add_library(modbusRTU STATIC modbusRTU.cpp)
target_include_directories(modbusRTU
       PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(modbusRTU
        PUBLIC
            configManager
            PkgConfig::MODBUS
)
#build static library and include header for modbusTcp
add_library(modbusTCP STATIC modbusTCP.cpp)
target_include_directories(modbusTCP
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(modbusTCP
        PUBLIC
            PkgConfig::MODBUS
            mbTcpSettings
            configManager
)
#Build static library and include header for mqttPub
add_library(mqttPub STATIC mqttPub.cpp)
target_include_directories(mqttPub
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)

add_library(configManager STATIC configManager.cpp)
target_include_directories(configManager
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(configManager
    PUBLIC
        json
        mbRtuSettings
        mbTcpSettings
        mqttPubSettings
		loggerSettings
)

add_library(application STATIC application.cpp)
target_include_directories(application
		PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(application
		PUBLIC
		spdlog::spdlog
		modbusTCP
		modbusRTU
		mqttPub
		pemData
		configManager
)

add_subdirectory(include/dataclasses)
#add executable for project program
add_executable(${PROJECT_NAME} main.cpp)
#link libraries for project executable
target_link_libraries(${PROJECT_NAME}
        PUBLIC
		application
)
