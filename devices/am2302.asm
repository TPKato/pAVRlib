;;; am2302.asm

;;- Subroutines for AM2303 (aka DHT22) relative humidity (RH) and temperature sensor
;;- This code is a part of [[../][pAVRlib]].

;;-
;;- * Requirement
;;- - [[../../wait][wait.asm]] (a part of pAVRlib)
;;-
;;- * How to use
;;-   Define ~F_CPU~ (frequency of CPU), ~AM_DDR~, ~AM_PORT~, ~AM_PIN~
;;-   and ~AM_SDA~ before you call ~AM2302_READ~.
;;-
;;-   For example, to use PB0 as SDA for AM2302:
;;-
;;- #+BEGIN_SRC asm
;;- .equ F_CPU	= 1000000	; 1 MHz
;;-
;;- .equ AM_DDR	= DDRB
;;- .equ AM_PORT	= PORTB
;;- .equ AM_PIN	= PINB
;;- .equ AM_SDA	= 0
;;- #+END_SRC
;;-
;;- Note that ~F_CPU~ must be > 100000 (100 kHz) (theoretically. But practically > 300 kHz ?).
;;- (This module was tested only at 1 MHz.)
;;-

;;; HIGH_THRESHOLD:
;;;   The high time for "0" is 22-30us (typ. 26us) and for "1" is 68-75us (typ. 70us)
;;;   (See datasheet of AM2302).
;;;   It takes 5 clocks @ 1 MHz to read a "H" in the subroutine `_readHi'.
;;;   In this program 50us is chosen as the threshold.

#ifdef __GNUC__
.global AM2302_READ
#define __SFR_OFFSET 0
#include <avr/io.h>

#define HumH r25
#define HumL r24
#define TmpH r23
#define TmpL r22

#define HIGH_THRESHOLD (10 * F_CPU / 1000000)
#else
.def HumH = r25
.def HumL = r24
.def TmpH = r23
.def TmpL = r22

.equ HIGH_THRESHOLD = (10 * F_CPU / 1000000)
#endif

;;- * Subroutine
;;-
;;- ** ~long AM2302_READ()~ (in: (none), out: r25-r22 (HumH, HumL, TmpH, TmpL))
;;-    reads data from AM2302.
;;-    This returns r25:r24:r23:r22 = ff:ff:ff:ff ($-1$ as long) if parity error occured.
;;-    This returns also a raw parity value in r21 if the program is assembled with ~AM2303_DEBUG~.
;;-
AM2302_READ:
	push	r18		; parity
	push	r19		; loop counter
	push	r20		; pulse length

	sbi	AM_DDR,  AM_SDA
	sbi	AM_PORT, AM_SDA

	rcall	Wait1sec
	rcall	Wait1sec

	;; start signal
	cbi 	AM_PORT, AM_SDA	; output '0'

	rcall	Wait1ms

	sbi	AM_PORT, AM_SDA	; output '1'
	cbi	AM_DDR,  AM_SDA	; set port as input
	cbi	AM_PORT, AM_SDA	; Hi-Z

	;; response signal
	;; wait for '0'
_am2303_wait_rel:
	sbic	AM_PIN, AM_SDA
	rjmp	_am2303_wait_rel

	;; wait for '1'
_am2303_wait_reh:
	sbis	AM_PIN, AM_SDA
	rjmp	_am2303_wait_reh

_am2303_wait_low:
	sbic	AM_PIN, AM_SDA
	rjmp	_am2303_wait_low

	;; main
	ldi	r19, 40		; the number of bits to read

_am2302_read_loop1:
_am2302_wait_high:
	sbis	AM_PIN, AM_SDA
	rjmp	_am2302_wait_high

	rcall	_am2302_readHi

	cpi	r20, HIGH_THRESHOLD
	;; C = 1 if r20 < HIGH_THRESHOLD
	;; i.e. inverted values are stored in the registers.
	rol	r18
	rol	TmpL
	rol	TmpH
	rol	HumL
	rol	HumH

	dec	r19
	brne	_am2302_read_loop1

	com	HumH
	com	HumL
	com	TmpH
	com	TmpL
	com	r18

.ifdef AM2303_DEBUG
	mov	r21, r18	; raw parity value
.endif

	;; parity check
	sub	r18, HumH
	sub	r18, HumL
	sub	r18, TmpH
	sub	r18, TmpL
	breq	_am2302_read_exit

	ldi	r18, 0xff
	mov	HumH, r18
	mov	HumL, r18
	mov	TmpH, r18
	mov	TmpL, r18

_am2302_read_exit:
	pop	r20
	pop	r19
	pop	r18
	ret

_am2302_readHi:
	ldi	r20, 0		; 1 clock
_am2302_rH_loop1:
	sbis	AM_PIN, AM_SDA	; 1 clock if not skip / 2 clock if skip
	ret
	inc	r20		; 1 clock
	rjmp	_am2302_rH_loop1	; 2 clock

;;; ------------------------------------------------------------
;;; for debug
;;; (requires usart.asm)

.ifdef AM2303_DEBUG
.ifdef AM2303_DEBUG_USE_USART
AM2302_USART_RAWDATA:
	push	r16
	mov	r16, r24	; save the value of r24

	push	r31
	push	r30
	clr	r31
	ldi	r30, 26		; from r25 (to r21)

	ldi	r24, '['
	rcall	USART_TRANSMIT

_am2302_rawdata_loop:
	mov	r24, r16	; restore r24
	ld	r24, -Z
	rcall	USART_PUTHEX

	cpi	r30, 21
	breq	_am2302_rawdata_exit

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	rjmp	_am2302_rawdata_loop

_am2302_rawdata_exit:
	ldi	r24, ']'
	rcall	USART_TRANSMIT

	pop	r30
	pop	r31

	mov	r24, r16
	pop	r16

	ret
.endif
.endif

;;-
;;- * Examples
;;-
;;- !see ../examples/am2302-test.asm
;;-
;;- !see ../examples-C/am2302-test.c
;;-
