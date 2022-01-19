;;; max31855.asm
;;-
;;- A device driver of MAX31855 Cold-Junction Compensated
;;- Thermocouple-to-Digital Converter for AVR.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- * Requirement
;;-   - [[../../wait][wait.asm]] (a part of pAVRlib)
;;-   - [[../../bin2bcd16][bin2bcd16.asm]] (a part of pAVRlib)
;;-   - [[../../frac2bcd][frac2bcd.asm]] (a part of pAVRlib)
;;-
;;-   The followings are also required if you use this program with ~USE_USART~:
;;-
;;-   - [[../../usart][usart.asm]] (a part of pAVRlib)
;;-   - [[../../usart-puthex][usart-puthex.asm]] (a part of pAVRlib)
;;-   - [[../../bin2ascii][bin2ascii.asm]] (a part of pAVRlib)
;;-
;;- * How to use
;;-
;;-   Define ~F_CPU~ (frequency of CPU) and the port settings of CK (clock),
;;-   CS (chip select) and DO (data output) before you call the functions.
;;-
;;-   - ~MAX_CK_DDR~, ~MAX_CK_PORT~, ~MAX_CK_PIN~, ~MAX_CK~
;;-   - ~MAX_CS_DDR~, ~MAX_CS_PORT~, ~MAX_CS_PIN~, ~MAX_CS~
;;-   - ~MAX_DO_DDR~, ~MAX_DO_PORT~, ~MAX_DO_PIN~, ~MAX_DO~
;;-
;;-   ~max31855-config.h~ will be included if you define ~USE_MAX31855_CONFIG~.
;;-
;;-   For example:
;;-   #+begin_src C
;;-   #ifndef __MAX31855_CONFIG_H__
;;-   #define __MAX31855_CONFIG_H__
;;-
;;-   #define	MAX_CK_DDR	DDRD
;;-   #define	MAX_CK_PORT	PORTD
;;-   #define	MAX_CK_PIN	PIND
;;-   #define	MAX_CK		7
;;-
;;-   #define	MAX_CS_DDR	DDRD
;;-   #define	MAX_CS_PORT	PORTD
;;-   #define	MAX_CS_PIN	PIND
;;-   #define	MAX_CS		6
;;-
;;-   #define	MAX_DO_DDR	DDRD
;;-   #define	MAX_DO_PORT	PORTD
;;-   #define	MAX_DO_PIN	PIND
;;-   #define	MAX_DO		5
;;-
;;-   #endif /* __MAX31855_CONFIG_H__ */
;;-   #+end_src
;;-

#ifdef USE_MAX31855_CONFIG
#include "max31855-config.h"
#endif

#ifdef __GNUC__
#define __SFR_OFFSET 0
#include <avr/io.h>

.global MAX31855_INIT_PORTS
.global MAX31855_READDATA

.global MAX31855_FORMAT_TEMP

.global MAX31855_TCTEMP_BCD
.global MAX31855_INTTEMP_BCD

#ifdef USE_USART
.global MAX31855_USART_TCTEMP
.global MAX31855_USART_INTTEMP
#endif
#endif /* __GNUC__ */


;;- * Subroutine
;;-
;;-   In this section "TCTemp" means a thermocouple temperature and
;;-   "IntTemp" an internal (cold-junction) temperature.
;;-
;;- ** ~void MAX31855_INIT_PORTS()~ (in: (none), out: (none))
;;-    initializes the ports (pins).
;;-    You need define ~MAX_CK_DDR~ etc. (see above) before you call this function.
;;-
MAX31855_INIT_PORTS:
	;; set as output
	sbi	MAX_CS_DDR, MAX_CS
	sbi	MAX_CS_PORT, MAX_CS
	sbi	MAX_CK_DDR, MAX_CK
	cbi	MAX_CK_PORT, MAX_CK

	;; set as input
	cbi	MAX_DO_DDR, MAX_DO
	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned long MAX31855_READDATA()~ (in: (none), out: r25:r24:r23:r22)
;;-    read data from MAX31855 and returns a raw data.
;;-    See the data sheet of MAX31855 for more details.
;;-
MAX31855_READDATA:
	cbi	MAX_CS_PORT, MAX_CS

	push	r16
	ldi	r16, 32		; the number of bits to read

_MAX31855_READDATA_loop:
	sbi	MAX_CK_PORT, MAX_CK

	;; read 1 bit and store in carry flag
	clc
	sbic	MAX_DO_PIN, MAX_DO
	sec

	rol	r22
	rol	r23
	rol	r24
	rol	r25

	cbi	MAX_CK_PORT, MAX_CK
	dec	r16
	brne	_MAX31855_READDATA_loop

	sbi	MAX_CS_PORT, MAX_CS
	pop	r16
	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned long MAX31855_FORMAT_TEMP(unsigned long rawdata)~ (in: r25:r24:r23:r22, out: r25:r24:r23:r22)
;;-    converts a MAX31855 raw data to 14 bit (12.2) and 12 bit (8.4) format temperatures.
;;-    See also the data sheet of MAX31855.
;;-
;;-    - r25:r24 : TCTemp
;;-
;;-      | <c>  | <c>  | <c>          | <c> | <c>          |
;;-      | D15  | D14  | D13          | ... | D0           |
;;-      | Sign | Sign | MSB $2^{10}$ | ... | LSB $2^{-2}$ |
;;-
;;-    - r23:r22 : IntTemp
;;-
;;-      | <c>  | <c>  | <c>  | <c>  | <c>  | <c>         | <c> | <c>          |
;;-      | D15  | D14  | D13  | D12  | D11  | D10         | ... | D0           |
;;-      | Sign | Sign | Sign | Sign | Sign | MSB $2^{6}$ | ... | LSB $2^{-4}$ |
;;-
MAX31855_FORMAT_TEMP:
	;; convert TCTemp
	;; r25:r24 =>> 2
	asr	r25
	ror	r24
	asr	r25
	ror	r24

	;; convert IntTemp
	;; r23:r22 =>> 4
	swap	r22
	andi	r22, 0x0f
	swap	r23
	push	r23
	andi	r23, 0xf0
	add	r22, r23
	pop	r23

	andi	r23, 0x0f
	sbrc	r23, 3
	ori	r23, 0xf0

	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned long MAX31855_TCTEMP_BCD(unsigned int TCTemp)~ (in: r25:r24, out: r25:r24:r23:r22)
;;-    converts a TCTemp of 14 bit format to BCD.
;;-    In r25:r24 will be stored the integer part of *absolute value* of TCTemp in BCD and in
;;-    r23:r22 the fraction part of *absolute value* of TCTemp in BCD.
;;-
;;-    Example:
;;-
;;-    If you call this routine with r25:r24 = 0000 0001 1001 0011 (= +100.75),
;;-    it will return r25:r24:r23:r22 = 0x01:0x00:0x75:0x00 (r22 is always 0x00).
;;-
MAX31855_TCTEMP_BCD:
	;;  check if negative
 	sbrs	r25, 5
 	rjmp	_MAX31855_TCTEMP_BCD1

	;; if negative
 	;; 2's complement of r25:r24
	ori	r25, 0xc0
	com	r25
	com	r24
	adiw	r24, 1		; adiw	r25:r24, 1

_MAX31855_TCTEMP_BCD1:
 	clr	r22

	;; r25:r24:r22 >>= 2
	;; i.e. r25:r24 integer part
	;;	r22	fraction part
	asr	r25
	ror	r24
	ror	r22
	asr	r25
	ror	r24
	ror	r22

 	rcall	BIN2BCD16	; r25:r24 => r25:r24:r23
	push	r24
	push	r23

	;; convert fraction as BCD
	mov	r24, r22
	rcall	FRAC2BCD
	mov	r23, r25
	clr	r22

	pop	r24		; was r23
	pop	r25		; was r24

	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned long MAX31855_INTTEMP_BCD(unsigned int IntTemp)~ (in: r25:r24, out: r25:r24:r23:r22)
;;-    converts a IntTemp of 12 bit format to BCD.
;;-    In r25:r24 will be stored the integer part of *absolute value* of IntTemp in BCD and in
;;-    r23:r22 the fraction part of *absolute value* of IntTemp in BCD.
;;-
;;-    Example:
;;-
;;-    If you call this routine with r25:r24 = 0000 0110 0100 1001 (= +100.5625),
;;-    it will return r25:r24:r23:r22 = 0x01:0x00:0x56:0x25.
MAX31855_INTTEMP_BCD:
	;; check if negative
	sbrs	r25, 3
	rjmp	_MAX31855_INTTEMP_BCD1

	;; if negative

	;; 2's complement of r25:r24
	ori	r25, 0xf0
	com	r25
	com	r24
	adiw	r24, 1		; adiw	r25:r24, 1

_MAX31855_INTTEMP_BCD1:
	;; r22: fraction part
	mov	r22, r24
	swap	r22
	andi	r22, 0xf0

	;; r24: integer part
	swap	r24
	andi	r24, 0x0f
	swap	r25
	andi	r25, 0xf0
	add	r24, r25
	clr	r25

	;; convert integer part
	rcall	BIN2BCD16	; r25:r24 => r25:r24:r23
	push	r24
	push	r23

	;; convert fraction as BCD
	;; first 2 digits (e.g. "06" of "0.0625")
	mov	r24, r22
	rcall	FRAC2BCD
	mov	r23, r25

	;; next 2 digits (e.g. "25" of "0.0625")
	rcall	FRAC2BCD
	mov	r22, r25

	pop	r24		; was r23
	pop	r25		; was r24

	ret

#ifdef USE_USART
;;; ------------------------------------------------------------
;;- ** ~void MAX31855_USART_TCTEMP(int TCTemp)~ (in: r25:r24, out: (none))
;;-    shows TCTemp via USART.
;;-    This routine will be assembled only when ~USE_USART~ is defined.
;;-
;;-    Note that
;;-    - the leading 0s are *not* truncated, and
;;-    - no newline will be sent.
;;-
MAX31855_USART_TCTEMP:
	sbrs	r25, 5
	rjmp	_MAX31855_USART_TCTEMP1

	;; if negative
	push	r24
	ldi	r24, '-'
	rcall	USART_TRANSMIT
	pop	r24

_MAX31855_USART_TCTEMP1:
	push	r25
	push	r24
	push	r23
	push	r22

	rcall	MAX31855_TCTEMP_BCD

	push	r24
	mov	r24, r25
	rcall	USART_PUTHEX
	pop	r24

	rcall	USART_PUTHEX
	ldi	r24, '.'
	rcall	USART_TRANSMIT
	mov	r24, r23
	rcall	USART_PUTHEX

	pop	r22
	pop	r23
	pop	r24
	pop	r25

	ret

;;; ------------------------------------------------------------
;;- ** ~void MAX31855_USART_INTTEMP(int IntTemp)~ (in: r25:r24, out: (none))
;;-    shows IntTemp via USART.
;;-    This routine will be assembled only when ~USE_USART~ is defined.
;;-
;;-    Note that
;;-    - the leading 0s are *not* truncated, and
;;-    - no newline will be sent.
;;-
MAX31855_USART_INTTEMP:
	sbrs	r25, 5
	rjmp	_MAX31855_USART_INTTEMP_1

	;; if negative
	push	r24
	ldi	r24, '-'
	rcall	USART_TRANSMIT
	pop	r24

_MAX31855_USART_INTTEMP_1:
	push	r25
	push	r24
	push	r23
	push	r22

	rcall	MAX31855_INTTEMP_BCD

	push	r24
	mov	r24, r25
	rcall	USART_PUTHEX
	pop	r24
	rcall	USART_PUTHEX
	ldi	r24, '.'
	rcall	USART_TRANSMIT
	mov	r24, r23
	rcall	USART_PUTHEX
	mov	r24, r22
	rcall	USART_PUTHEX

	pop	r22
	pop	r23
	pop	r24
	pop	r25

	ret
#endif

;;-
;;- * Examples
;;-   !see ../examples/max31855-test.asm
;;-
