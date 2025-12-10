//
// Created by Ludvi on 12/10/2025.
//

#include "application.hpp"


application::application(const std::string &configFilePath) : configFilePath_(configFilePath) {
    //@config_ initialize config manager
    //@loggerSettings && logger_ get the logger settings and implement settings to the logger_
    config_ = std::make_unique<configManager>(configFilePath_);
    loggerSettings loggSettings;
    config_->loadLoggerSettings(loggSettings);
    logger_ = spdlog::daily_logger_mt("daily_logger",
                                      loggSettings.filePath_,
                                      loggSettings.hour_,
                                      loggSettings.minute_,
                                      loggSettings.max_files_
    );
}
//try to set upp the modbusRTU context needed for serial communication
//if it fails logg and return -1
int application::modbusRtuSetup() {
    try {
        modbusRtu_ = std::make_unique<modbusRTU>(config_);
        logger_->info("modbus setup succesfully");
        modbusRtu_->connect();
        logger_->info("modbus connected");
    } catch (std::exception &e) {
        logger_->critical("critical failure: {}", e.what());
        std::cerr << "Critical failure: !" << e.what() << std::endl;
        return -1;
    }
    return 0;
}
//@modbusRtuRun reads registers and updates
int application::modbusRtuRun() {
    try {
        modbusRtu_->readRegisters();
        logger_->info("modbus read registers successfully");
        modbusRtu_->updatePemData(pemData_);
        logger_->info("modbus update pem data successfully");
    } catch (std::exception &e) {
        logger_->critical("critical failure: {}", e.what());
        return -1;
    }
    return 0;
}
