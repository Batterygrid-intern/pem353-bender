
#ifndef CONFIGMANAGER_HPP
#define CONFIGMANAGER_HPP

#include <nlohmann/json.hpp>
#include "mqttPub.hpp"
#include "modbusRTU.hpp"
#include "modbusTCP.hpp"

using namespace nlohmann;

class configManager {
    private:
        //json objects that will hold configs for all different objects used in the main program.
        json modbusRtuConf;
        json modbusTcpConf;
        json mqttPubConf;
        //private methods to extract configs into attribute objects of this class.
        void extract_modbusTCP(json &config);
        void extract_modbusRTU(json &config);
        void extract_mqttPub(json &config);

    public:
    //Constructor will read a json object from a config file and initialise the config attributes list above.
        explicit configManager(std::string& configFilePath);

        //~configManager();

    //each setter will take an object as argument and set the object with its required configs.
        void setModbusRtuConfig(modbusRTU& object);
        void setModbusTcpConfig(modbusTCP& object);
        void setMqttPubConfig(mqttPub& object);

};




#endif
