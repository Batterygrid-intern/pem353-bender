#ifndef MODBUSTCP_HPP
#define MODBUSTCP_HPP
#include <modbus/modbus.h>
#include "configManager.hpp"
#include "mbTcpSettings.hpp"
#include <thread>
#include <chrono>
#include <atomic>
#include <vector>
#include <mutex>
#include <cstdint>

class modbusTCP {
private:
    //settings will be initialized in constructor
    mbTcpSettings settings_;
    //@ctx_ modbus connection context(ip,port)
    //@mb_mapping
    modbus_t *ctx_ = nullptr;
    modbus_mapping_t *mb_mapping_ = nullptr;
    //protect mb_mapping acces (server replies and updates from data races between threads trying to access memoryspace)
    std::mutex mapping_mutex_;

    //declare set of file descriptors(sockets)
    //@master_set and read_set, set of file descriptors in this case sockets a new connection generates a new socket
    fd_set master_set_;
    fd_set read_set_;
    //@server_socket_ && highset numbered fildescriptor
    int server_socket_ = -1;
    int socket_ = 0;
    int fd_max_ = server_socket_;

    //thread variables
    std::atomic<bool> running_{false};
    std::thread worker_;

    //privates methods used by run method
    void run();

    void setupFdSets();

    void listen();

    bool waitForActivity();

    bool acceptConnection();

    void replyQuery();

    void handle_Query();

public:
    explicit modbusTCP(const mbTcpSettings &settings);

    ~modbusTCP();

    void start();

    void stop();

    //convert floats to modbus holding registers(2 x uint16_t per float)
    std::vector<uint16_t> float_to_regs(const std::vector<float> &fdata);

    // Write floats into holding registers starting at startADDR(0-based) Returns false if out of range/mapping missing.
    bool write_floats_to_holding_registers(int startAddr, const std::vector<float> &fdata);
};
#endif //MODBUSTCP_HPP
