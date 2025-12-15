#ifndef MQTTPUB_HPP
#define MQTTPUB_HPP
#include <iostream>
#include "mqtt/async_client.h"
#include <atomic>
#include <cstdlib>
#include <cstring>
#include <string>
#include <thread>
#include "mqttPubSettings.hpp"
#include "mqttPubSettings.hpp"

// call back functions used by the mqttpub class
class callback : public virtual mqtt::callback {
public:
    void connection_lost(const std::string &cause) override {
        if (!cause.empty()) {
            std::cout << "Cause: " << cause << std::endl;
        }
    }

    void delivery_complete(mqtt::delivery_token_ptr tok) override {
        std::cout << "Delivery complete for toke: " << (tok ? tok->get_message_id() : -1) << std::endl;
    }
};

class action_listener : public virtual mqtt::iaction_listener {
protected:
    void on_failure(const mqtt::token &tok) override {
        std::cout << "Listener for token : " << tok.get_message_id() << " failed\n";
    }

    void on_success(const mqtt::token &tok) override {
        std::cout << "Listener for token : " << tok.get_message_id() << " succeeded\n";
    }
};

class delivery_action_listener : public action_listener {
    std::atomic<bool> done_;

    void on_failure(const mqtt::token &tok) override {
        action_listener::on_failure(tok);
        done_ = true;
    }

    void on_success(const mqtt::token &tok) override {
        action_listener::on_success(tok);
        done_ = true;
    }

public:
    delivery_action_listener() : done_(false) {
    }

    bool is_done() const { return done_; }
};


class mqttPub {
private:
    mqttPubSettings settings_;
    std::unique_ptr<mqtt::async_client> client_;
    mqtt::connect_options conn_opts_;
    callback cb_;
    std::string payload_ = "hello from publisher";
    std::string topic_ = "test/topic";

public:
    mqttPub(const mqttPubSettings &settings) : settings_(settings) {
        const mqtt::persistence_type PERSIST_DIR{settings_.PRESIST_DIR};
        client_ = std::make_unique<mqtt::async_client>(settings_.URI, settings_.CLIENT_ID);
        client_->set_callback(cb_);
        conn_opts_ = mqtt::connect_options_builder()
                .connect_timeout(std::chrono::seconds(5))
                .clean_session(true)
                .will(mqtt::message("hej", "goodbye", 1, false))
                .finalize();
    }

    //connect
    void connect() const {
        std::cout << "\nConnecting to broker: " << settings_.URI << "...";
        mqtt::token_ptr conntok = client_->connect(conn_opts_);
        conntok->wait();
        std::cout << " ..ok" << std::endl;
    };

    //message pointer
    int message() {

     try {
         //message pointer
         std::cout << "sending message: " << std::endl;
         mqtt::message_ptr pubmsg = mqtt::make_message(topic_, payload_);
         pubmsg->set_qos(settings_.QOS);
         client_->publish(pubmsg)->wait_for(5);
         std::cout << " ..ok" << std::endl;

         //itemized publish
         std:: cout << "\nSending next message..." << std::endl;
         mqtt::delivery_token_ptr pubtok;
         pubtok = client_->publish(topic_,payload_,1,false);
         std::cout << "... with token: " << pubtok->get_message_id() << std::endl;
         std::cout << " ...for message with " << pubtok->get_message()->get_payload().size() << " bytes" << std::endl;
         pubtok->wait_for(50);
         std::cout << " ...ok" << std::endl;

         //listener
         std::cout << "\nSending next message..."<< std::endl;
         action_listener listener;
         pubmsg = mqtt::make_message(topic_, payload_);
         pubtok = client_->publish(pubmsg,nullptr,listener);
         pubtok->wait();
         std::cout << "... ok" << std::endl;

         //listener with no token
         std::cout << "\nSending final message.." << std::endl;
         delivery_action_listener deliveryListener;
         pubmsg = mqtt::make_message(topic_, payload_);
         client_->publish(pubmsg,nullptr,deliveryListener);
         while (!deliveryListener.is_done()) {
             std::this_thread::sleep_for(std::chrono::milliseconds(100));
         }
         std::cout << "... ok" << std::endl;

         //double check that there are no pending tokens
         auto toks = client_->get_pending_delivery_tokens();
         if (!toks.empty()) {
             std::cout << "Error:  there are pending delivery tokens!"<< std::endl;
         }
         //disconnect
         client_->disconnect()->wait();
         std::cout << " ...ok" << std::endl;
     }catch (std::exception& e) {
         std::cout << "Error: " << e.what() << std::endl;
         return -1;
     }
        return 0;
    };
};
#endif //MQTTPUB_HPP
