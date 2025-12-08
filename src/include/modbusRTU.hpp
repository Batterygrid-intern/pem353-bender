#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "mbRtuSettings.hpp"
#include "configManager.hpp"
#include <modbus.h>
#include "pemData.hpp"


class modbusRTU {
private:
    //settings will be assigned in the constructor initialization.
    mbRtuSettings settings;
    //modbus_t struct* to define the modbus context
    uint16_t *buffer;
    modbus_t *ctx;

public:
    //load configs from configManager and initialize the object.
    explicit modbusRTU(configManager &configs);
    ~modbusRTU();
    //connect to modbus rtu slave
    void connect() const;
    //read modbus rtu register(defined in the config file)
    void readRegisters();
    //update pem data obje
    void updatePemData(pemData& data);

};


#endif //MODBUSRTU_HPP
