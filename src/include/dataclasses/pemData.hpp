//
// Created by Ludvi on 12/4/2025.
//

#ifndef PEM353_PEMDATA_HPP
#define PEM353_PEMDATA_HPP
#include <iostream>
#include <vector>

class pemData {
public:
    //Phase voltage (V) registers 0000-0005
    float voltageL1_V_ = 0.0;
    float voltageL2_V_ = 0.0;
    float voltageL3_V_ = 0.0;
    //Phase current (Amphere) registers 0016-0021
    float currentL1_A_ = 0.0;
    float currentL2_A_ = 0.0;
    float currentL3_A_ = 0.0;
    //Total power (watts) registers 0030-0031
    float activePowerTotal_W_ = 0.0;
    //System frequenzy (HERTZ) registers 0056-57
    float frequency_Hz_ = 0.0;

    pemData() = default;

    ~pemData() = default;

    //just for testing
    void printData() const {
        std::cout << "pemData: " << std::endl;
        std::cout << "voltageL1_V: " << voltageL1_V_ << std::endl;
        std::cout << "voltageL2_V: " << voltageL2_V_ << std::endl;
        std::cout << "voltageL3_V: " << voltageL3_V_ << std::endl;
        std::cout << "currentL1_A: " << currentL1_A_ << std::endl;
        std::cout << "currentL2_A: " << currentL2_A_ << std::endl;
        std::cout << "currentL3_A: " << currentL3_A_ << std::endl;
        std::cout << "activePowerTotal_W: " << activePowerTotal_W_ << std::endl;
        std::cout << "frequency_Hz: " << frequency_Hz_ << std::endl;
    }

    //gather all float values in to one float vector
    std::vector<float> pemDataToVector() {
        std::vector<float> data{
            voltageL1_V_,
            voltageL2_V_,
            voltageL3_V_,
            currentL1_A_,
            currentL2_A_,
            currentL3_A_,
            activePowerTotal_W_,
            frequency_Hz_
        };

        return data;
    }

private:
};


#endif //PEM353_PEMDATA_HPP
