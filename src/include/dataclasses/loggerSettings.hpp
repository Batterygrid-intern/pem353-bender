//
// Created by Ludvi on 12/10/2025.
//

#ifndef PEM353_LOGGERSETTINGS_HPP
#define PEM353_LOGGERSETTINGS_HPP
#include <string>

class loggerSettings {
    public:
        //@max_files_ how many max files that will be created will drop fifo
        //@hour which hour the new file should be created
        //@minue which minute of the hour the file will be created
        std::string filePath_;
        uint16_t max_files_ = 0;
        int hour_ = 0;
        int minute_ = 0;

        loggerSettings() = default;
private:
};
#endif //PEM353_LOGGERSETTINGS_HPP