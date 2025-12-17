#include "application.hpp"


int main() {
    // initialize application
    std::string configFilePath = "/etc/pem353/configs/pemConfigs.json";
    application app(configFilePath);
    //setup modbusRTU context for port and connect to port
    if (app.modbusRtuSetup() == -1) {
        return EXIT_FAILURE;
    }
    //setup modbusTcp settings and start server running on its own thread
    if (app.modbusTcpSetup() == -1) {
        return EXIT_FAILURE;
    }
    if (app.modbusTcpStart() == -1) {
        return EXIT_FAILURE;
    }
    //Run main loop while modbusRtu runs without critical errors
   while (app.modbusRtuRun() != -1) {
        //write pemData to modbusTCP registers
        app.modbusTcpWriteRegs();
        //@MQTT publish to broker
    }
    app.logger_->critical("main loop broken, program will exit");
    //clean upp code before exit
    return 0;
};