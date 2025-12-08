#include "configManager.hpp"
#include <iostream>
#include <fstream>

#include "modbusRTU.hpp"

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
    try {
       this->config = json::parse(configFile);
    }
    catch (std::exception& e) {
        throw std::runtime_error("Parse error at byte: " + std::string(e.what()) + "\n");
    }
    //close config file and throw runtime error if failed.
    configFile.close();
    if (configFile.fail()) {
        throw std::runtime_error("Failed to close config file");
    }
}

//loads all configs read into settings class for modbusRTU
void configManager::loadMbRtuSettings(mbRtuSettings &mbRtuSettings) {
    //if json object doesnot contain HEADKEAY it will throw runtime error
    if(!this->config.contains("MODBUS_RTU")){
        throw std::runtime_error("MODBUS_RTU settings not found in config file");
    }
    //set all the settings and convert the types needed.
    mbRtuSettings.DEVICE = this->config["MODBUS_RTU"]["DEVICE"];
    mbRtuSettings.BAUD = this->config["MODBUS_RTU"]["BAUD"];
    const std::string parityStr= this->config["MODBUS_RTU"]["PARITY"];
    mbRtuSettings.PARITY = parityStr[0];
    mbRtuSettings.DATABITS = this->config["MODBUS_RTU"]["DATA_BITS"];
    mbRtuSettings.STOPBITS = this->config["MODBUS_RTU"]["REGSTART"];
    mbRtuSettings.SLAVEID = this->config["MODBUS_RTU"]["SLAVEID"];
    mbRtuSettings.REGSTART = this->config["MODBUS_RTU"]["SLAVEID"];
    mbRtuSettings.REGEND = this->config["MODBUS_RTU"]["REGEND"];
    mbRtuSettings.TIMEOUT = this->config["MODBUS_RTU"]["TIMEOUT"];

}





