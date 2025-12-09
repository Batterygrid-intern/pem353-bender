#ifndef CONFIGMANAGER_HPP
#define CONFIGMANAGER_HPP

#include <json.hpp>
#include "mbRtuSettings.hpp"
#include "mbTcpSettings.hpp"
#include "mqttPubSettings.hpp"

using namespace nlohmann;

class configManager {
private:
    //json object to store the data read from filestream
    json config;

public:
    //constructor will be provided with configFilepath and store json data in json attribute "config";
    explicit configManager(std::string &configFilePath);

    //do we need to do some cleanup here?
    ~configManager() = default;

    void loadMbRtuSettings(mbRtuSettings &mbRtuSettings);
    void loadMqttSettings(mqttPubSettings& mqttPubSettings);
    void loadMbTcpSettings(mbTcpSettings &mbTcpSettings);
};


#endif
