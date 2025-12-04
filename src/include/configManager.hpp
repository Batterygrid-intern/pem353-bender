
#ifndef CONFIGMANAGER_HPP
#define CONFIGMANAGER_HPP
#include <iostream>
#include <nlohmann/json.hpp>

using namespace nlohmann;

class configManager {
    private:
        //json objects that will hold configs for all different objects used in the main program.
        json modbusRtuConf;
        json modbusTcpConf;
        json mqttPubConf;

    public:
    //Constructor will read a json object from a config file and initialise the config attributes list above.
    configManager();
    ~configManager();

    //each setter will take a object as argument and set the object with its required configs.
    void setModbusRtuConfig(modbusRtu& object);
    void setModbusTcpConfig(modbusTcp& object);
    void setModbusPubConfig(mqttPub& object);

};




#endif
