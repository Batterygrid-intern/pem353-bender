#include "configManager.hpp"
#include <iostream>
#include <fstream>

#include "loggerSettings.hpp"


//constructor object reads json objects and stores data for each attribute in configManager

configManager::configManager(std::string &configFilePath) {
    //define configfile stream that will be used, set the parameters on what exceptions will be catchable on failure
    //try to open the file can throw runtime_error if failed **Covers open failure and read failure**?
    std::ifstream configFile;
    configFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
    try {
        configFile.open(configFilePath);
    } catch (std::ifstream::failure &e) {
        throw std::runtime_error("Can't open config file: " + std::string(configFilePath));
    }
    //try to parse the filestream and store the parsed data as a json object. catch exception and throw runtime_error
    try {
        this->config = json::parse(configFile);
    } catch (std::exception &e) {
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
    if (!this->config.contains("MODBUS_RTU")) {
        throw std::runtime_error("MODBUS_RTU settings not found in config file");
    }
    //set all the settings and convert the types needed.
    //@parity cannot convert type json to char so first we assign a string the value and then we safley typeconvert to char
    //@NBREGS this is for how many registers we want to read in config we pass start and end for easy of use for configurator
    //but to make the syntax more logical to how the functions used preform we transform it to number of registers to read
    mbRtuSettings.DEVICE = this->config["MODBUS_RTU"]["DEVICE"];
    mbRtuSettings.BAUD = this->config["MODBUS_RTU"]["BAUD"];
    const std::string parityStr = this->config["MODBUS_RTU"]["PARITY"];
    mbRtuSettings.PARITY = parityStr[0];
    mbRtuSettings.DATABITS = this->config["MODBUS_RTU"]["DATA_BITS"];
    mbRtuSettings.STOPBITS = this->config["MODBUS_RTU"]["STOP_BITS"];
    mbRtuSettings.SLAVEID = this->config["MODBUS_RTU"]["SLAVE_ID"];
    mbRtuSettings.REGSTART = this->config["MODBUS_RTU"]["REGSTART"];
    mbRtuSettings.REGEND = this->config["MODBUS_RTU"]["REGEND"];
    mbRtuSettings.NBREGS = mbRtuSettings.REGEND - mbRtuSettings.REGSTART + 1;
    mbRtuSettings.TIMEOUT = this->config["MODBUS_RTU"]["TIMEOUT"];
}

void configManager::loadMbTcpSettings(mbTcpSettings &mbTcpSettings) {
    mbTcpSettings.HOST = this->config["MODBUS_TCP"]["HOST"];
    mbTcpSettings.PORT = this->config["MODBUS_TCP"]["PORT"];
}
void configManager::loadLoggerSettings(loggerSettings &loggerSettings) {
    loggerSettings.filePath_ =this->config["LOGGER"]["PATH"];
    loggerSettings.max_files_ = this->config["LOGGER"]["MAX_FILES"];
    loggerSettings.hour_ = this->config["LOGGER"]["HOUR"];
    loggerSettings.minute_ = this->config["LOGGER"]["MINUTE"];

}