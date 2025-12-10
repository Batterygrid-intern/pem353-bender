#include "modbusRTU.hpp"
//"NOTE maby dont want to load settings here. maby in main application
//constructor will be take config object as argument and load all the needed settings from the settings class.
modbusRTU::modbusRTU(std::unique_ptr<configManager> const &configs) : settings() {
    //Load all settings into modbusRTU object if fails throw exception to main loop
    try {
        configs->loadMbRtuSettings(this->settings);
    } catch (std::exception &e) {
        throw std::runtime_error(e.what());
    }
    //@modbus_new_rtu return a modbus_t context object for modbus RTU backend r
    //@modbus_rtu_set_serial_mode set the serial mode to rs485

    this->ctx = modbus_new_rtu(settings.DEVICE.c_str(), settings.BAUD, settings.PARITY, settings.DATABITS,
                               settings.STOPBITS);
    if (this->ctx == nullptr) {
        throw std::runtime_error("Failed to create modbus context");
    }
    //allocate memory for reading registers
    this->buffer = new uint16_t[settings.NBREGS];
}

//when destructor called, close open connection and free all memory allocated
modbusRTU::~modbusRTU() {
    if (this->ctx != nullptr) {
        modbus_close(this->ctx);
        modbus_free(this->ctx);
    }
    delete[] this->buffer;
}

//establishes a modbus connection defined by the ctx object.
void modbusRTU::connect() const {
    if (modbus_connect(this->ctx) == -1) {
        throw std::runtime_error("Failed to connect to modbus server");
    }

    //check if needed might not need might be controlled and mapped to the tx rx pins on the hat.
    /* if (modbus_rtu_set_serial_mode(this->ctx,MODBUS_RTU_RS485) == -1) {
         throw std::runtime_error("Failed to set serial mode");
     }*/
    /*if (modbus_rtu_set_rts(this->ctx,MODBUS_RTU_RTS_UP) == -1) {
        throw std::runtime_error("Failed to set rts");
    }*/
}

//read the modbus registers and store them in buffer.
void modbusRTU::readRegisters() {
    // @modbus_set_slave set slave id for the modbus server to read from
    // @modbus_read_registers reads register from -> to -> into.
    if (modbus_set_slave(this->ctx, this->settings.SLAVEID) == -1) {
        throw std::runtime_error("Failed to set slave id");
    }

    if (modbus_read_registers(this->ctx, settings.REGSTART, settings.NBREGS, this->buffer) == -1) {
        throw std::runtime_error("Failed to read registers");
    }
}

void modbusRTU::updatePemData(pemData &data) {
    //@Loop, iterate over the whole intervall of registers read by readRegisters
    //@Switch case, to easly only store the data we want from that offset
    //@modbus_get_float_abcd pass address of the first of 2 addresses we want to combine into one float
    for (int i = 0; i < settings.NBREGS; i++) {
        int registerAddr = settings.REGSTART + i;
        switch (registerAddr) {
            case 0:
                data.voltageL1_V = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 2:
                data.voltageL2_V = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 4:
                data.voltageL3_V = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 16:
                data.currentL1_A = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 18:
                data.currentL2_A = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 20:
                data.currentL3_A = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 30:
                data.activePowerTotal_W = modbus_get_float_abcd(&this->buffer[i]);
                break;
            case 56:
                data.frequency_Hz = modbus_get_float_abcd(&this->buffer[i]);
                break;
            default:
                //ignore the addresses that we dont want to store data from.
                continue;
        }
    }
}
