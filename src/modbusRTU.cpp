#include "modbusRTU.hpp"

//constructor will be take config object as argument and load all the needed settings from the settings class.
modbusRTU::modbusRTU(configManager& configs) : settings() {
    configs.loadMbRtuSettings(this->settings);
    
}


