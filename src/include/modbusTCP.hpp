
#ifndef MODBUSTCP_HPP
#define MODBUSTCP_HPP
#include <modbus/modbus.h>
#include "configManager.hpp"
#include "mbTcpSettings.hpp"


class modbusTCP {
private:
    //settings will be initialized in constructor
    mbTcpSettings settings;
    //modbus context struct will be initilized in constructor
    modbus_t *ctx;

public:
    modbusTCP(configManager& config);

};



#endif //MODBUSTCP_HPP
