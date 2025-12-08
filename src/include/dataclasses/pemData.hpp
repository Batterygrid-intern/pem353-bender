//
// Created by Ludvi on 12/4/2025.
//

#ifndef PEM353_PEMDATA_HPP
#define PEM353_PEMDATA_HPP


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

private:
};


#endif //PEM353_PEMDATA_HPP
