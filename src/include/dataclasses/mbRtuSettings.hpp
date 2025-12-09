

//class to hold all the RTU settings.
#pragma once
#include <string>
class mbRtuSettings {
    public:
    //settings for the modbus_t structure used with modbus_new_rtu();
    std::string DEVICE;
    int BAUD = 0;
    char PARITY;
    int DATABITS = 0;
    int STOPBITS = 0;
    //id setting for which slave to connect to(server);
    int SLAVEID = 0;
    //settings for the registers to read;
    int REGSTART = 0;
    int NBREGS = 0;
    int REGEND = 0;
    //Setting for timeout between reads
    int TIMEOUT = 0;

    mbRtuSettings() = default;

    private:

};
