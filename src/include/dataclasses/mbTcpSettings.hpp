#pragma once
#include <string>




class mbTcpSettings {
public:
   std::string HOST;
   int PORT = 0;
   int NB_CONNS = 0;
   int NB_REGISTERS = 0;
   int BIG_ENDI = 0;

   mbTcpSettings() = default;
private:

};