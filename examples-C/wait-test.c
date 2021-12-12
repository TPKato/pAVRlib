#include <avr/io.h>

#include <wait.h>
#include "waitconfig.h"

int
main()
{
  int i;

  WAIT_LEDDDR |= _BV(WAIT_LEDPIN);

  while (1) {
    /* 1 ms (500 Hz) */
    for (i = 0; i < 2500; i++) {
      WAIT_LEDPORT |= _BV(WAIT_LEDPIN);
      Wait1ms();
      WAIT_LEDPORT &=~_BV(WAIT_LEDPIN);
      Wait1ms();
    }
    
    /* 500 ms (1 Hz) */
    for (i = 0; i < 5; i++) {
      WAIT_LEDPORT |= _BV(WAIT_LEDPIN);
      Waitmsint(500);
      WAIT_LEDPORT &=~_BV(WAIT_LEDPIN);
      Waitmsint(500);
    }

    /* 10 ms (50 Hz) */
    for (i = 0; i < 250; i++) {
      WAIT_LEDPORT |= _BV(WAIT_LEDPIN);
      Waitms(10);
      WAIT_LEDPORT &=~_BV(WAIT_LEDPIN);
      Waitms(10);
    }
  }

  return 0;
}
