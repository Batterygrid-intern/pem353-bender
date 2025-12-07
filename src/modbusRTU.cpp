#include "modbusRTU.hpp"

//constructor will be passed with the config manager, config manager will initialize the config settings that the
//modbusRTU object will need to connect and to read over the rs-485 line
modbusRTU::modbusRTU(configManager& config) {
    this->settings = config.getModbusRtuConfig();
}