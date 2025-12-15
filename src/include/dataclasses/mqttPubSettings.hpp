#pragma once

class mqttPubSettings {
public:
    std::string URI;
    std::string TOPIC;
    int QOS = 0;
    int RETAIN;
    std::string CLIENT_ID;
    std::string USERNAME;
    std::string PASSWORD;
    std::string PRESIST_DIR;
private:
};
