//
// Created by ludde on 2025-11-28.
//

#ifndef MQTTPUB_HPP
#define MQTTPUB_HPP
#include "mqtt/async_client.h"
#include <atomic>
#include <cstdlib>
#include <cstring>
#include <string>
#include <thread>
#include "mqttPubSettings.hpp"
#include "dataclasses/mqttPubSettings.hpp"
// call back functions used by the mqttpub class
class callback: public virtual mqtt::callback {
public:
    void connection_lost(const std::string& cause) override {
        std::cout << "Connection lost:: " << cause << std::endl;
    }
    void delivery_complete(mqtt::delivery_token_ptr token) override {
        std::cout << "Message delivered\n";
    }
};

class action_listener : public virtual mqtt::iaction_listener {
protected:
    void on_failure(const mqtt::token& tok) override {
        std::cout << "Listener for token : " << tok.get_message_id() << " failed\n";
    }
    void on_success(const mqtt::token& tok) override {
        std::cout << "Listener for token : " << tok.get_message_id() << " succeeded\n";
    }
};

class delivery_action_listener : public action_listener {
    atomic<bool> done_;
    void on_failure(const mqtt::token &tok)override {
        action_listener::on_failure(tok);
        done_ = true;
    }
    void on_success(const mqtt::token &tok)override {
        action_listener::on_success(tok);
        done_ = true;
    }
public:
    delivery_action_listener() : done_(false) {}
    bool is_done() const { return done_; }
};



class mqttPub {
private:
    mqttPubSettings settings_;
    mqtt::async_client client_;
    mqtt::connect_options conn_opts_;
public:
    mqttPub(mqttPubSettings settings);
    //connect
    //build payload
    //publish data
    //disconnect from broker




};



#endif //MQTTPUB_HPP
