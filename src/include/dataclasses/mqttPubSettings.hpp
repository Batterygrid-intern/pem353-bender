#pragma once

class mqttPubSettings {
public:
    std::string URI;
    std::string TOPIC;
    std::string CLIENT_ID;
    std::string SITE;
    int RETAIN = 0;
    int QOS = 0;
    int CONN_TIMEOUT = 0;
    std::string USERNAME;
    std::string PASSWORD;
    std::string PRESIST_DIR;

private:
};
