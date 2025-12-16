#include "modbusTCP.hpp"
#include <stdexcept>
#include <unistd.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <iostream>
#include <algorithm>
#include <cstring>


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


std::vector<uint16_t> modbusTCP::float_to_regs(const std::vector<float> &fdata) {
    std::vector<uint16_t> regs;
    regs.reserve(fdata.size()*2);

    for (float f : fdata) {
        static_assert(sizeof(float) == 4, "float must be 32-bit");
        std::uint32_t u32 = 0;
        std::memcpy(&u32, &f, sizeof(u32));

        std::uint16_t hi = static_cast<std::uint16_t>(u32 >> 16);
        std::uint16_t lo = static_cast<std::uint16_t>(u32 & 0xffff);
        if (settings_.BIG_ENDI) {
            regs.push_back(hi);
            regs.push_back(lo);
        }
        else {
            regs.push_back(lo);
            regs.push_back(hi);
        }
    }
    return regs;
}

bool modbusTCP::write_floats_to_holding_registers(int startAddr, const std::vector<float> &fdata) {
    if (startAddr < 0) return false;
    if (mb_mapping_ == nullptr || mb_mapping_ ->tab_registers == nullptr) return false;

    const auto regs = float_to_regs(fdata);
    const int needed = static_cast<int>(regs.size());
    const int endAddrExclusive = startAddr + needed;

    if (endAddrExclusive > mb_mapping_->nb_registers) return false;

    std::lock_guard<std::mutex> lock(mapping_mutex_);
    std::copy(regs.begin(), regs.end(), mb_mapping_->tab_registers + startAddr);
    return true;


}


//listen for connection
void modbusTCP::listen() {
    //creates a server_socket_ with maximum of 10 connections in que
    server_socket_ = modbus_tcp_listen(ctx_, settings_.NB_CONNS);
    if (server_socket_ == -1) {
        throw std::runtime_error("modbusTCP: unable to listen: " + std::string(modbus_strerror(errno)));
    }
}
//setup Set of FD
void modbusTCP::setupFdSets() {
    fd_max_ = server_socket_;
    //@FD_ZERO clean up current master_set_ of sockets
    //@FD_SET adds server_socket_ socket to master_set
    FD_ZERO(&master_set_);
    FD_SET(server_socket_, &master_set_);
}

//wait for activity on any of the sockets
bool modbusTCP::waitForActivity() {
    /* select() blocks until at least one file descriptor in read_set_ is ready to read.
    When it returns, read_set_ contains only the descriptors that are ready. */
    //@read_set_ = master_set_ select will destroy the fdset of filedescriptor we pass to it so we copy to temporary so that
    //We keep the structure of the other file_descriptors in master_set_
    read_set_ = master_set_;
    if (select(fd_max_ + 1, &read_set_, NULL, NULL, NULL) == -1) {
        if (!running_) {
            return false;
        }
        throw std::runtime_error("modbusTCP: select error: " + std::string(strerror(errno)));
    }
    return true;
}
bool modbusTCP::acceptConnection() {
    sockaddr_in clientaddr{};
    socklen_t addr_len = sizeof(clientaddr);
    int newfd = accept(server_socket_, reinterpret_cast<sockaddr *>(&clientaddr), &addr_len);
    if (newfd == -1) {
        throw std::runtime_error("modbusTCP: accept error: " + std::string(strerror(errno)));
    }
    FD_SET(newfd, &master_set_);
    if (newfd > fd_max_) {
        fd_max_ = newfd;
    }
    std::cout << "New client connected: socket " << newfd << std::endl;
    return true;
}
void modbusTCP::replyQuery() {
    modbus_set_socket(ctx_, socket_);
    uint8_t query[MODBUS_TCP_MAX_ADU_LENGTH];
    int rc = modbus_receive(ctx_, query);
    if (rc > 0) {
        std::lock_guard<std::mutex> lock(mapping_mutex_);
        modbus_reply(ctx_, query, rc, mb_mapping_);
    } else {
        std::cout << "Client disconnected: socket " << socket_<< "\n";
        close(socket_);
        FD_CLR(socket_, &master_set_);
    }
}
//multiclient server loop.
void modbusTCP::run() {
    //listen for connection on created socket
    listen();

    //setup Fd SETS
    setupFdSets();

    while (running_) {
        //block thread until activ connection querys information
        if (!waitForActivity()) {
            continue;
        }
        //loop over the possible sockets and pick socket to perfom action on.
        for ( socket_ = 0; socket_ <= fd_max_; socket_++) {
            if (!FD_ISSET(socket_, &read_set_)) {
                continue;
            }
            //new client connection
            if (socket_ == server_socket_) {
              if (!acceptConnection()) {
                  continue;
              }
            } else {
                //reply to modbus query
                replyQuery();
            }
        }
    }
    //close socket after queries complete
    for (socket_ = 0; socket_ <= fd_max_; socket_++) {
        if (FD_ISSET(socket_, &master_set_)) {
            close(socket_);
        }
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
