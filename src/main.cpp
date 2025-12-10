#include "application.hpp"
#include "thread"
#include "chrono"



int main() {
    // initialize application
    std::string configFilePath = "configs/pemConfigs.json";
    application app(configFilePath);

    if (app.modbusRtuSetup() == -1) {
        return EXIT_FAILURE;
    }
    //Run main loop while modbusRtu runs without critical errors
    while (app.modbusRtuRun() != -1) {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));

        //@modbusTCP, update modbusTCP registers

        //@MQTT publish to broker
    }
    app.logger_->critical("main loop broken, program will exit");
    //clean upp code before exit
    return 0;
};