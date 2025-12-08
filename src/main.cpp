#include <iostream>
#include "configManager.hpp"


 int main(){

    /*@ set config file path
      @ instantiating configManager object(writes config data to settings classes )*/

     std::string configFilePath = "./configs/pemConfigs.json";
     configManager config(configFilePath);


    //@ instantiate a logger object and use it for all info debug warning and error information

    //@ instantiate data object which will hold all data read from the pem353

    //@ instantiate ModbusRtu master(client) which will read data from pem353,
    //load it with configs

    //@ instantiate modbusTCP slave(server) which will store data from the data object

    //@ instantiate mqtt_publish client which will publish data from dataObject

    //while loop for
    //while(true){
        //read data from pem353 every 50 ms

        //transform data to floats save in data object

        //publish mqtt data

        //update modbus slave registers with data from data object

        //if program breaks or terminate, terminate it gracefully
    //}
     return 0;
}