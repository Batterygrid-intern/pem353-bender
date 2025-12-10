#include <iostream>
#include <thread>

#include "configManager.hpp"
#include "pemData.hpp"
#include "modbusRTU.hpp"
#include "memory"


int main() {
    /*@ set config file path
      @ instantiating configManager object(writes config data to settings classes )*/

    std::string configFilePath = "./configs/pemConfigs.json";
    configManager config(configFilePath);


    //@ instantiate a logger object and use it for all info debug warning and error information

    //@ instantiate data object which will hold all data read from the pem353
    pemData data;

    //@ instantiate ModbusRtu master(client) which will read data from pem353,
    //load it with configs

    std::unique_ptr<modbusRTU> modbus;
    try {
        modbus = std::make_unique<modbusRTU>(config);
    } catch (std::exception &e) {

    }
    std::cout << "ModbusRTU object created" << std::endl;
    if (modbus != nullptr) {
        try {
            modbus->connect();
        } catch (std::exception &e){
        }
    }
    std::cout << "ModbusRTU connected" << std::endl;

    //@ instantiate modbusTCP slave(server) which will store data from the data object

    //@ instantiate mqtt_publish client which will publish data from dataObject

    //while loop for
    while(true) {
        //read data from pem353 every 50 ms
        modbus->readRegisters();
        //transform data to floats save in data object
        modbus->updatePemData(data);
        //sleep
        std::this_thread::sleep_for(std::chrono::milliseconds());
        //print data recived.
        data.printData();

        //publish mqtt data

        //update modbus slave registers with data from data object

        //if program breaks or terminate, terminate it gracefully
        //}
    }
    return 0;
}
