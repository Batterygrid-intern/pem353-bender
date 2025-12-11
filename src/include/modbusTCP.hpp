
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

    //declare set of file descriptors(sockets)
    //@master_set and read_set, set of file descriptors in this case sockets a new connection generates a new socket
    fd_set master_set_;
    fd_set read_set_;
    //@server_socket_ && highset numbered fildescriptor
    int server_socket_ = -1;
    int socket_ = 0;
    int fd_max_ = server_socket;
    //thread variables
    std::atomic<bool> running_{false};
    std::thread worker_;
    //privates methods used by run method
    void run();
    void setupFdSets();
    void listen();
    bool waitForActivity();
public:

   explicit modbusTCP(const mbTcpSettings& settings);
    ~modbusTCP();
    void start();
    void stop();
};



#endif //MODBUSTCP_HPP
