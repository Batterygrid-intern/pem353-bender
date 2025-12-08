
#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "mbRtuSettings.hpp"
#include "libomdbus"
using namespace nlohmann;
class modbusRTU {
    private:
    //settings will be assigned in the constructor initialisation.
    mbRtuSettings settings;
    modbus_t *ctx;
    public:
    //load configs from configManager and initialize the object.
    explicit modbusRTU(configManager& configs);

};



#endif //MODBUSRTU_HPP
