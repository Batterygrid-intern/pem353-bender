#ifndef PEM353_APPLICATION_HPP
#define PEM353_APPLICATION_HPP
#include "spdlog/spdlog.h"
#include "spdlog/sinks/daily_file_sink.h"
#include "memory"
#include "configManager.hpp"
#include "pemData.hpp"
#include "modbusRTU.hpp"
#include "modbusTCP.hpp"
#include "mbTcpSettings.hpp"

class application {
public:
    mbTcpSettings tcpSettings_;
    std::string configFilePath_;
    std::unique_ptr<configManager> config_;
    std::unique_ptr<modbusRTU> modbusRtu_;
    std::unique_ptr<modbusTCP> modbusTcp_;
    std::shared_ptr<spdlog::logger> logger_;
    pemData pemData_;


    application(const std::string& configFilePath_);
    ~application() = default;

    //mqttPub
    int mqttPubSetup();
    int mqttConnect();
//    int mqttPublish();

    //modbusTCP
    int modbusTcpSetup();
    int modbusTcpStart();
    int modbusTcpWriteRegs();
    //modbusRTU
    int modbusRtuSetup();
    int modbusRtuRun();

private:
};


#endif //PEM353_APPLICATION_HPP
