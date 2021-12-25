/*
 *- The test program for am2302.asm (C version).
 *-
 *- To compile this file, the following files are required
 *- (These files are parts of the pAVRlib).
 *-
 *- - [[../../devices/am2302][devices/am2302.asm]]
 *- - [[../../wait][wait.asm]]
 *-
 *- See also: ~examples-C/README.org~
 *-
 */

#define USE_2X 1

#include <avr/io.h>
#include <util/setbaud.h>
#include <stdio.h>

#include "am2302config.h"

union am2302data {
  long raw;	/* r25:r24:r23:r22 */
  int data[2];  /* r23:r22, r25:r24 */
};
union am2302data AM2302_READ();

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
uart_puts(char *str)
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
  uart_putchar(0x0d);
  uart_putchar(0x0a);
}

int
main()
{
  char str[100];
  union am2302data d;
  int Tint, Tdec;

  uart_init();
  uart_puts("# Hello AM2302 (C-Version)");

  while (1) {
    d = AM2302_READ();

    /* if T < 0 */
    if (d.data[0] & 0x8000) {
      Tint = - (d.data[0] & 0x7fff) / 10;
    } else {
      Tint = d.data[0] / 10;
    }
    Tdec = (d.data[0] & 0x7fff) % 10;

    sprintf(str, "%d.%01d %%RH, %d.%01d C [%08lx]", d.data[1] / 10, d.data[1] % 10, Tint, Tdec, d.raw);
    uart_puts(str);
  }

  return 0;
}
