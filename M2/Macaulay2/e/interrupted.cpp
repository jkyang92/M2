#include "../system/supervisor.hpp"
#include "../system/supervisorinterface.h"
#define interrupted() \
  test_Field(interrupts_interruptedFlag)

bool system_interrupted() { return interrupted(); }
