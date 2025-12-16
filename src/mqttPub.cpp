//
// Created by Ludvi on 12/15/2025.
//

#include "mqttPub.hpp"

//constructor for mqtt object..
//construct mqtt client_
//set callback for asyncronous connecting
//conn_opts_ setup connection options
mqttPub::mqttPub(const mqttPubSettings &settings) : settings_(settings) {
    client_ = std::make_unique<mqtt::async_client>(settings_.URI, settings_.CLIENT_ID);
    client_->set_callback(cb_);
    basetopic_ = settings_.TOPIC + "/" + settings_.SITE + "/" + settings_.CLIENT_ID;
    conn_opts_ = mqtt::connect_options_builder()
            .connect_timeout(std::chrono::seconds(settings_.CONN_TIMEOUT))
            .clean_session(true)
            .will(mqtt::message(basetopic_ + "/" + "will", "disconnecting", 0, false))
            .finalize();
}

mqttPub::~mqttPub() {
    client_->disconnect();
}

void mqttPub::connect() {
    try {
        std::cout << "\nConnecting to broker: " << settings_.URI << "....";
        mqtt::token_ptr conntok = client_->connect(conn_opts_);
        conntok->wait();
        std::cout << "Connected\n";
    } catch (std::exception &e) {
        throw std::runtime_error("MQTT connection failed: " + std::string(e.what()));
    }
}

std::string mqttPub::buildTopic(std::string &subTopic) {
    std::string topic = basetopic_ + "/" + subTopic;
    return topic;
}

void mqttPub::publish(std::string& topic, std::string& payload) {
   try {
       mqtt::message_ptr pubmsg = mqtt::make_message(topic, payload);
       pubmsg->set_qos(settings_.QOS);
       client_->publish(pubmsg)->wait_for(std::chrono::milliseconds(settings_.CONN_TIMEOUT));
   }catch (std::exception &e) {
       throw std::runtime_error("MQTT publish failed: " + std::string(e.what()));
   }

}
