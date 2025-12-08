
#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "mbRtuSettings.hpp"
#include "configManager.hpp"

using namespace nlohmann;
class modbusRTU {
    private:
    //settings will be assigned in the constructor initialisation.
    mbRtuSettings Setting;
    public:
    //load configs from configManager and initialize the object.
    explicit modbusRTU(configManager& config);

};



#endif //MODBUSRTU_HPP
