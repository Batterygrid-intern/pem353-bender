#include "modbusTCP.hpp"
#include <stdexcept>
#include <unistd.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <iostream>

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

//if worker is not already running server application on thread run it
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

//multiclient server loop.
void modbusTCP::run() {
    //listen for connection on created socket
    listen();
    //create master_set (controls the initial file descriptor?
    fd_set master_set;
    fd_set read_set;
    FD_ZERO(&master_set);
    FD_SET(server_socket_, &master_set);
    //holds the largest file descriptor number
    int fdmax = server_socket_;

    while (running_) {
        //copy master_set;(original to read_set which will be modifed.
        //reads_set keeps control on file descritpors.??
        read_set = master_set;

        if (select(fdmax + 1, &read_set, NULL, NULL, NULL) == -1) {
            if (!running_) break;
            throw std::runtime_error("modbusTCP: select error: " + std::string(strerror(errno)));
            continue;
        }

        for (int s = 0; s < fdmax; s++) {
            if (!FD_ISSET(s, &read_set)) {
                continue;
            }
            //new client connection
            if (s == server_socket_) {
                sockaddr_in clientaddr{};
                socklen_t addr_len = sizeof(clientaddr);
                int newfd = accept(server_socket_, reinterpret_cast<sockaddr *>(&clientaddr), &addr_len);
                if (newfd == -1) {
                    throw std::runtime_error("modbusTCP: accept error: " + std::string(strerror(errno)));
                    continue;
                }
                FD_SET(newfd, &read_set);
                if (newfd > fdmax) {
                    fdmax = newfd;
                }
                std::cout << "New client connected: socket " << newfd << std::endl;
            } else {
                modbus_set_socket(ctx_, s);
                uint8_t query[MODBUS_TCP_MAX_ADU_LENGHT];
                int rc = modbus_receive(ctx_, query);
                if (rc > 0) {
                    modbus_reply(ctx_, query, rc, mb_mapping_);
                } else {
                    std::cout << "Client disconnected: socket " << s << "\n";
                    close(s);
                    FD_CLR(s, &master_set);
                }
            }
        }
    }
    for (int s = 0; s <= fdmax; s++) {
        if (FD_ISSET(s, &master_set)) {
            close(s);
        }
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
//close serial port connection and free allocated memory for context ptrs
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
}
