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
int application::mqttPubSetup() {
    try {
        config_->loadMqttSettings(mqttSettings_);
        mqttPub_ = std::make_unique<mqttPub>(mqttSettings_);
        logger_->info("mqttPub setup succesfully");
        return 0;
    } catch (std::exception &e) {
        logger_->critical("critical failure: mqttPubSetup {}", e.what());
        return -1;
    }
}
int application::mqttConnect() {
    try {
        mqttPub_->connect();
        logger_->info("mqtt connected succesfully");
        return 0;
    }
    catch (std::exception &e) {
        logger_->critical("critical failure: mqttConnect {}", e.what());
        return -1;
    }
}

/*int application::mqttPublish() {

    try {

    }catch ()
}*/


int application::modbusTcpSetup() {
    try {
        config_->loadMbTcpSettings(tcpSettings_);
        modbusTcp_ = std::make_unique<modbusTCP>(tcpSettings_);
        return 0;
    } catch (std::exception &e) {
        logger_->critical("critical failure: modbusTcpSetup {}", e.what());
        return -1;
    }
}

int application::modbusTcpStart() {
    try {
        modbusTcp_->start();
        logger_->info("modbus tcp server started");
        return 0;
    } catch (std::exception &e) {
        logger_->critical("critical failure: modbus Start {}", e.what());
        return -1;
    }
}

int application::modbusTcpWriteRegs() {
    try {
        modbusTcp_->write_floats_to_holding_registers(0, pemData_.pemDataToVector());
        logger_->info("modbus write registers successfully");
        return 0;
    } catch (std::exception &e) {
        logger_->critical("critical failure: Write modbus registers {}", e.what());
        return -1;
    }
}


int application::modbusRtuSetup() {
    try {
        modbusRtu_ = std::make_unique<modbusRTU>(config_);
        logger_->info("modbusRTU setup succesfully");
        modbusRtu_->connect();
        logger_->info("modbus connected to serial port");
    } catch (std::exception &e) {
        logger_->critical("critical failure: failed to setup modbusRTUconnection {}", e.what());
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
    } catch (std::runtime_error &e) {
        logger_->critical("{}", e.what());
        return -1;
    }
    return 0;
}
