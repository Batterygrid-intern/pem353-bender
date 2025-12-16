//
// Created by Ludvi on 12/15/2025.
//

#ifndef PEM353_MQTTPUB_HPP
#define PEM353_MQTTPUB_HPP
#include <mqtt/async_client.h>
#include "mqttPubSettings.hpp"
//callback function for lost connection and to check if delivery is complete
class callback : public virtual mqtt::callback {
public:
    void connection_lost(const std::string &cause) override {
        if (!cause.empty()) {
            throw std::runtime_error("Cause: " + cause) ;
        }
    }
    void delivery_complete(mqtt::delivery_token_ptr tok) override {
        std::cout << "Delivery complete for toke: " << (tok ? tok->get_message_id() : -1) << std::endl;

    }
};
class mqttPub {
private:
    mqttPubSettings settings_;
    std::unique_ptr<mqtt::async_client> client_;
    mqtt::connect_options conn_opts_;
    callback cb_;
    std::string payload_;
    std::string basetopic_;

public:
    mqttPub(const mqttPubSettings &settings);
    ~mqttPub();

    void connect();
    void publish(std::string& topic,std::string& payload);
    std::string buildTopic(std::string& sub_topic);

};


#endif //PEM353_MQTTPUB_HPP