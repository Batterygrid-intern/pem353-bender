#pragma once


class mqttPubSettings {
public:
    std::string HOST;
    int PORT = 0;
    std::string TOPIC;
    std::string QOS;
    std::string RETAIN;
    std::string CLIENT_ID;
    std::string USERNAME;
    std::string PASSWORD;
private:
};