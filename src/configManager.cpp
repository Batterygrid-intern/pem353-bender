#include "configManager.hpp"
#include <iostream>
#include <fstream>

//constructor object reads json objects and stores data for each attribute in configManager

configManager::configManager(std::string& configFilePath) {
    //define configfile stream that will be used, set the parameters on what exceptions will be catchable on failure
    //try to open the file can throw runtime_error if failed **Covers open failure and read failure**?
    std::ifstream configFile;
    configFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
    try {
        configFile.open(configFilePath);
    } catch (std::ifstream::failure& e) {
        throw std::runtime_error("Can't open config file: " + std::string(configFilePath));
    }
    //try to parse the filestream and store the parsed data as a json object. catch exception and throw runtime_error
    //if failed to read.
    json config;
    try {
        config = json::parse(configFile);
    }
    catch (std::exception& e) {
        throw std::runtime_error("Parse error at byte: " + std::string(e.what()) + "\n");
    }

    //extract the data for each attribute declared inside this class and initialise each attribute with that data.
    extract_modbusTCP(config);
    extract_modbusRTU(config);
    extract_mqttPub(config);
}

//getters that return each object.
json configManager::getModbusRtuConfig() {
    return this->modbusRtuConf;
}
json configManager::getModbusTcpConfig() {
    return this->modbusTcpConf;
}
json configManager::getMqttPubConfig() {
    return this->mqttPubConf;
}
//private extract methods to load each attribute with its corresponding configdata
void configManager::extract_modbusTCP(json &config) {
    if(config.contains("MODBUS_TCP")){
        this->modbusTcpConf = config["MODBUS_TCP"];
    }
    else {
        throw std::runtime_error("Modbus TCP config not found");
    }
}
void configManager::extract_modbusRTU(json &config) {
    if (config.contains("MODBUS_RTU")) {
        this->modbusRtuConf = config["MODBUS_RTU"];
    }
    else {
throw std::runtime_error("Modbus RTU config not found");
    }
}
void configManager::extract_mqttPub(json &config){
    if (config.contains("MQTT_PUB")) {
        this->mqttPubConf = config["MQTT_PUB"];
    }
    else {
        throw std::runtime_error("MQTT PUB config not found");
    }
}