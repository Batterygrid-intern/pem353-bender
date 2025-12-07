
#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "configManager.hpp"

using namespace nlohmann;
class modbusRTU {
    private:
    //settings will be assigned in the constructor initialisation.
    json settings;

    public:
    //load configs from configManager and initialize the object.
    explicit modbusRTU(configManager& configManager);

};



#endif //MODBUSRTU_HPP
