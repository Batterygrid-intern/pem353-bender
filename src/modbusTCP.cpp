#include "modbusTCP.hpp"

//constructor initializes settings
modbusTCP::modbusTCP(const mbTcpSettings &settings) : settings_(settings) {
    //@modbus_new_tcp initialize modbus connection context
    //@modbus_mapping_new map holding registers (creates an array to store bits in the registers)
    ctx_ = modbus_new_tcp(settings_.HOST.c_str(), settings_.PORT);
    if (ctx_ == nullptr) {
        throw std::runtime_error("modbusTCP: unable to create new context: " + std::string(modbus_strerror(errno)));
    }
    mb_mapping_ = modbus_mapping_new(0, 0, settings.NB_REGISTERS, 0);
    if (mb_mapping_ == nullptr) {
        throw std::runtime_error("Failed to map modbus registers: " + std::string(modbus_strerror(errno)));
    }
}

//start the thread
void modbusTCP::start() {
    if (running_) return;
    running_ = true;
    worker_ = std::thread(&modbusTCP::run, this);
}

//stop and cleanup thread
void modbusTCP::stop() {
    if (!running_) return;
    running_ = false;
    //close and cleanup socket
    if (server_socket_ >= 0) {
        close(server_socket_);
        server_socket_ = -1;
    }
    //close the thread if it's running
    if (worker_.joinable()) {
        worker_.join();
    }
}


//listen for connection
void modbusTCP::listen() {
    server_socket_ = modbus_tcp_listen(ctx_, settings_.NB_CONNS);
    if (server_socket_ == -1) {
        throw std::runtime_error("modbusTCP: unable to listen: " + std::string(modbus_strerror(errno)));
    }
}


//Destructor that frees upp memory of modbus struct ptrs
//stop() the server runing on the thread
modbusTCP::~modbusTCP() {
    stop();
    if (mb_mapping_ != nullptr) {
        modbus_mapping_free(mb_mapping_);
    }
    if (ctx_ != nullptr) {
        modbus_close(ctx_);
        modbus_free(ctx_);
        ctx_ = nullptr;
    }
    if (server_socket_ >= 0) {
        close(server_socket_);
        server_socket_ = -1;
    }
}
