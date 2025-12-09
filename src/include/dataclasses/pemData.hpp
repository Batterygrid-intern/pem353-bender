//
// Created by Ludvi on 12/4/2025.
//

#ifndef PEM353_PEMDATA_HPP
#define PEM353_PEMDATA_HPP
#include <iostream>


class pemData {
public:
    //Phase voltage (V) registers 0000-0005
    float voltageL1_V = 0.0;
    float voltageL2_V = 0.0;
    float voltageL3_V = 0.0;
    //Phase current (Amphere) registers 0016-0021
    float currentL1_A = 0.0;
    float currentL2_A = 0.0;
    float currentL3_A = 0.0;
    //Total power (watts) registers 0030-0031
    float activePowerTotal_W = 0.0;
    //System frequenzy (HERTZ) registers 0056-57
    float frequency_Hz = 0.0;

    pemData() = default;

    ~pemData() = default;
    //just for testing
    void printData() const{
        std::cout << "pemData: " << std::endl;
        std::cout << "voltageL1_V: " << voltageL1_V << std::endl;
        std::cout << "voltageL2_V: " << voltageL2_V << std::endl;
        std::cout << "voltageL3_V: " << voltageL3_V << std::endl;
        std::cout << "currentL1_A: " << currentL1_A << std::endl;
        std::cout << "currentL2_A: " << currentL2_A << std::endl;
        std::cout << "currentL3_A: " << currentL3_A << std::endl;
        std::cout << "activePowerTotal_W: " << activePowerTotal_W << std::endl;
        std::cout << "frequency_Hz: " << frequency_Hz << std::endl;
    }

private:
};


#endif //PEM353_PEMDATA_HPP
