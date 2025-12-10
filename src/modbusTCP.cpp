#include "modbusTCP.hpp"

modbusTCP::modbusTCP(configManager &configs) : settings() {
    configs.loadMbTcpSettings(this->settings);
    this->ctx = modbus_new_tcp(this->settings.HOST.c_str(), this->settings.PORT);
}

