/*
 *- The test program for ccs811.asm (C version).
 *-
 *- To compile this file, the following files are required
 *- (These files are parts of the pAVRlib).
 *-
 *- - [[../../devices/ccs811][devices/ccs811.asm]]
 *- - [[../../twi-controller][twi-controller.asm]]
 *- - [[../../wait][wait.asm]]
 *-
 *- See also: ~examples-C/README.org~
 *-
 */

#include "ccs811config.h"
#undef CCS811TEST_DEBUG

#define USE_2X 1

#include <avr/io.h>
#include <util/setbaud.h>
#include <stdio.h>

#include "devices/ccs811.h"
#include "twi-controller.h"

void Wait1ms();
void Wait1sec();

void
uart_init() {
#if USE_2X
  UCSRA |= (1 << U2X);
#else
  UCSRA &= ~(1 << U2X);
#endif

  UCSRB = (1 << RXEN) | (1 << TXEN);
  UCSRC = (3 << UCSZ0);

  UBRRH = UBRRH_VALUE;
  UBRRL = UBRRL_VALUE;
}

char
uart_getchar() {
  while (! (UCSRA & (1 << RXC)));
  return UDR;
}

void
uart_putchar(char c) {
  while (! (UCSRA & (1 << UDRE)));
  UDR = c;
}

void
uart_put(char *str)
{
  while (*str != '\0') {
    if (*str == '\n') {
      uart_putchar(0x0d);
      uart_putchar(0x0a);
    } else {
      uart_putchar(*str);
    }
    str++;
  }
}

void
uart_putln(char *str)
{
  uart_put(str);
  uart_putchar(0x0d);
  uart_putchar(0x0a);
}

int
main()
{
  char str[100];
  /* union am2302data d; */
  /* int Tint, Tdec; */

  char addr;
  char stat;
  char data[8];

  int i;
  for (i = 0; i < 8; i++) {
    data[i] = 0;
  }


  uart_init();
  uart_putln("# Hello CCS811 (C-Version)");

  TWI_INITIALIZE();

#ifdef CCS811_USE_RESET
  CCS811_RESET();
#endif
  addr = CCS811_SEARCH();

  if (addr & 0x80) {
    uart_putln("CCS811 not found");
    return 0;
  }

  sprintf(str, "CCS811 is found at 0x%02x", addr);
  uart_putln(str);

  stat = CCS811_INITIALIZE(addr);
  if (stat & 0x80) {
    uart_putln("CCS811 initialize failed");
    return 0;
  }

  /* set measure mode */
  data[0] = (DRIVE_MODE_1s | INT_DATARDY);
  CCS811_WRITE(addr, MEAS_MODE, 1, data);
  Wait1ms();

  while (1) {
    Wait1sec();
    CCS811_READ(addr, STATUS, 1, data);
#ifdef CCS811TEST_DEBUG
    sprintf(str, "STATUS: %02x %02x %02x %02x %02x %02x %02x %02x",
	    data[0] & 0xff, data[1] & 0xff, data[2] & 0xff, data[3] & 0xff,
	    data[4] & 0xff, data[5] & 0xff, data[6] & 0xff, data[7] & 0xff);
    uart_putln(str);
#endif
    if (data[0] & 1<<sERROR) {
      CCS811_READ(addr, ERROR_ID, 1, data);
      sprintf(str, "ERRORID: %02x %02x %02x %02x %02x %02x %02x %02x",
	      data[0] & 0xff, data[1] & 0xff, data[2] & 0xff, data[3] & 0xff,
	      data[4] & 0xff, data[5] & 0xff, data[6] & 0xff, data[7] & 0xff);
      uart_putln(str);
    }

    if (data[0] & (1<<sDATA_READY)) {
      unsigned int v1, v2;

      /* data ready */
      CCS811_READ(addr, ALG_RESULT_DATA, 8, data);

      v1 = ((data[0] & 0xff) << 8) | (data[1] & 0xff);
      v2 = ((data[2] & 0xff) << 8) | (data[3] & 0xff);
      sprintf(str, "eCO2: %d ppm, eTVOC: %d ppb", v1, v2);
      uart_put(str);

      sprintf(str, " [%02x %02x %02x %02x %02x %02x %02x %02x]",
	      data[0] & 0xff, data[1] & 0xff, data[2] & 0xff, data[3] & 0xff,
	      data[4] & 0xff, data[5] & 0xff, data[6] & 0xff, data[7] & 0xff);
      uart_putln(str);
    }
  }

  return 0;
}
