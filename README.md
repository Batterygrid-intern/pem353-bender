# Goal of project
Implement a networking layer on a pem353-bender using a raspberryPi 4.
1. Connect a raspberry pi to the pem353 over RS-485.
2. Read modbus [registers](#registers).
3. Make the data read available to be read from the raspberry pi over Modbus tcp/ip. 
4. Publish data read to a mqtt-broker. 
5. Reads from pem353 every 50-100 ms.

## Flowchart 

```mermaid  
  flowchart TD
    A[PEM353-Bender] -->|RS-485| B[Raspberry Pi 4]
    B -->|Read Modbus Registers<br/>50-100ms| A
    B --> C{Data Processing}
    C -->|Modbus TCP/IP| D[Local Network Clients]
    C -->|MQTT Publish| E[MQTT Broker]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#bfb,stroke:#333,stroke-width:2px
    style D fill:#fbb,stroke:#333,stroke-width:2px
    style E fill:#ffb,stroke:#333,stroke-width:2px
```

# pem353
## registers
**Reads following registers:**

- **0000-0005:**
  - 0000-0001: U1 (Voltage L1-N) – float
  - 0002-0003: U2 (Voltage L2-N) – float
  - 0004-0005: U3 (Voltage L3-N) – float
- **0016-0021:**
  - 0016-0017: P1 (Active Power L1) – float
  - 0018-0019: P2 (Active Power L2) – float
  - 0020-0021: P3 (Active Power L3) – float
- **0030-0031:**
  - 0030-0031: Total Active Energy (Wh) – float
- **0056-0057:**
  - 0056: Status Digital Inputs – UINT16
  - 0057: Status Digital Outputs – UINT16

# Project structure
## source code
All source code are located in **./src**
**placeholder chatgpt display tree structure**

## Headers

## Build tools

### cmake
#### Toolchains
**cmake/toolchains/raspberryPi.cmake**
Toolchain file to be able to cross compile from host machine to rpi4 64bit.
### cross compiling

## Testing and debugging 

### Google test

## Deployment


## External libraries
- [Libmodbus](#Libmodbus)
- [spdlog](#spdlog)
- [nlohmann::json](#nlohmann::json)
- [Pahomqttcpp](#Pahomqttcpp)



### Libmodbus

### spdlog

### nlohmann::json

### Pahomqttcpp

# Goal of project
Put a networking layer on a pem353-bender
1. Read from the modbus registers 