


//class to hold all the RTU settings.
#pragma once
#include "configManager.hpp"

class mbRtuSettings {
    public:
    //settings for the modbus_t structure used with modbus_new_rtu();
    std::string device;
    int baud = 0;
    char parity ;
    int dataBits = 0;
    int stopBits = 0;
    //id setting for which slave to connect to(server);
    int slaveId = 0;
    //settings for the registers to read;
    int regStart = 0;
    int regEnd = 0;
    //Setting for timeout between reads
    int TIMEOUT = 0;

    mbRtuSettings() = default;
    private:

};
