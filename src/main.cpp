#include "application.hpp"


int main() {
    // initialize application
    std::string configFilePath = "configs/pemConfigs.json";
    application app(configFilePath);

    if (app.modbusRtuSetup() == -1) {
        return EXIT_FAILURE;
    }
    //setup modbusTcp settings and start server running on another thread
    /*if (app.modbusTcpSetup() == -1) {
        return EXIT_FAILURE;
    }
    if (app.modbusTcpStart() == -1) {
        return EXIT_FAILURE;
    }

    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds(10));
        app.modbusTcpWriteRegs();
    }*/
    app.modbusRtuRun();
    app.pemData_.printData();
    //Run main loop while modbusRtu runs without critical errors
    /*while (app.modbusRtuRun() != -1) {
        //print data for test purpose
        //app.pemData_.printData();
        //load data to vector to make it accessibale for modbus regsiter transformation
        //need to fix correct error handling
        //app.modbusTcpWriteRegs();
        //@MQTT publish to broker
    */

    //app.logger_->critical("main loop broken, program will exit");
    //clean upp code before exit
    return 0;
};