#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "mbRtuSettings.hpp"
#include "configManager.hpp"
#include <modbus.h>
#include "pemData.hpp"
#include <memory>


class modbusRTU {
private:
    //settings will be assigned in the constructor initialization.
    mbRtuSettings settings;
    //modbus_t struct* to define the modbus context
    uint16_t *buffer;
    modbus_t *ctx = nullptr;

public:
    //load configs from configManager and initialize the object.
    explicit modbusRTU(std::unique_ptr<configManager>const& configs);
    ~modbusRTU();
    //connect to modbus rtu slave
    void connect() const;
    //read modbus rtu register(defined in the config file)
    void readRegisters();
    //update pem data obje
    void updatePemData(pemData& data);


    //for for testing
    void printbuffer();
};


#endif //MODBUSRTU_HPP
