#ifndef PEM353_APPLICATION_HPP
#define PEM353_APPLICATION_HPP
#include "spdlog/spdlog.h"
#include "spdlog/sinks/daily_file_sink.h"
#include "memory"
#include "configManager.hpp"
#include "pemData.hpp"
#include "modbusRTU.hpp"

class application {
public:
    std::string configFilePath_;
    std::unique_ptr<configManager> config_;
    std::unique_ptr<modbusRTU> modbusRtu_;
    std::shared_ptr<spdlog::logger> logger_;
    pemData pemData_;


    application(const std::string& configFilePath_);
    ~application() = default;


    int modbusRtuSetup();

    int modbusRtuRun();

private:
};


#endif //PEM353_APPLICATION_HPP
