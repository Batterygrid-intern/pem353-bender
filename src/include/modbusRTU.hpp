
#ifndef MODBUSRTU_HPP
#define MODBUSRTU_HPP
#include "configManager.hpp"


class modbusRTU {
    private:
    //attributes will be all the configs
    load configs into data object? keep them here?

    public:
    //load configs from configManager and initialise object.
    modbusRTU();

    void modbusSetConfig(configManager& configManager);
};



#endif //MODBUSRTU_HPP
