
#ifndef MODBUSTCP_HPP
#define MODBUSTCP_HPP
#include <modbus/modbus.h>
#include "configManager.hpp"
#include "mbTcpSettings.hpp"
#include <thread>
#include <chrono>
#include <atomic>

class modbusTCP {
private:
    //settings will be initialized in constructor
    mbTcpSettings settings_;
    //@ctx_ modbus connection context(ip,port)
    //@mb_mapping
    modbus_t *ctx_ = nullptr;
    modbus_mapping_t *mb_mapping_ = nullptr;
    int server_socket_ = -1;
    std::atomic<bool> running_{false};
    std::thread worker_;
    void run();
public:
   explicit modbusTCP(const mbTcpSettings& settings);
    ~modbusTCP();
    void listen();
    void start();
    void stop();
};



#endif //MODBUSTCP_HPP
