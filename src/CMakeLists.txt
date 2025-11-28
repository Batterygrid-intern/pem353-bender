#build static library and include header for modbusRtu
add_library(modbusRtu STATIC modbusRtu.cpp)
target_include_directories(modbusRtu
       PUBLIC ${CMAKE_SOURCE_DIR}/include
)
#build static library and include header for modbusTcp
add_library(modbusTcp STATIC modbusTcp.cpp)
target_include_directories(modbusTcp
        PUBLIC ${CMAKE_SOURCE_DIR}/include
)
#Build static library and include header for mqttPub
add_library(mqttPub STATIC mqttPub.cpp)
target_include_directories(mqttPub
        PUBLIC ${CMAKE_SOURCE_DIR}/include
)

#add executable for project program
add_executable(${PROJECT_NAME} main.cpp)
#link libraries for project executable
target_link_libraries(${PROJECT_NAME}
        PUBLIC
        modbusTcp
        modbusRtu
        mqttPub
)