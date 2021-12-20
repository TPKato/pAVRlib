;;; twi-controller.asm

;;-
;;- TWI related subroutines (as a controller (master)).
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- This program works only on AVRs which have a TWI module.
;;-

#ifdef __GNUC__
#define __SFR_OFFSET 0

#include <avr/io.h>

#ifndef F_CPU
#error "Specify a frequency of the system clock (F_CPU)."
#endif

#ifndef	F_SCL
#error "Specify a SCL frequency (F_SCL)."
#endif

.global TWI_INITIALIZE
.global TWI_SEND_S
.global TWI_SEND_P
.global TWI_SEND_SLA_R
.global TWI_SEND_SLA_W
.global TWI_SEND
.global TWI_RECV_ACK
.global TWI_RECV_NACK

#define	TWIDATA r24
#define	TWISTAT	r25

#else

.ifndef F_CPU
.error "Specify a frequency of the system clock (F_CPU)."
.endif

.ifndef	F_SCL
.error "Specify a SCL frequency (F_SCL)."
.endif

.def	TWIDATA = r24
.def	TWISTAT	= r25

#endif

;;; ------------------------------------------------------------
;;- * Subroutines
;;-
;;- ** ~void TWI_INITIALIZE()~ (in: (none), out: (none))
;;-    initializes TWI Module.
;;-    You must define ~F_CPU~ and ~F_SCL~ before you call this routine.
;;-

TWI_INITIALIZE:
	push	r16
	ldi	r16, (F_CPU/(2*F_SCL)-8)
	out	TWBR, r16
	pop	r16
	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned int TWI_SEND_S()~ (in: (none), out: r25)
;;-    sends a start bit.
;;-    This returns r25:r24. A status code of TWI is stored in r25.
;;-    r24 is unchanged.
;;-    See reference manual from Atmel (Microchip) for more details.
;;-

TWI_SEND_S:
	; send start bit
	ldi	TWISTAT, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
	out	TWCR, TWISTAT

	; wait ack
_TWI_SEND_S_WAIT:
	in	TWISTAT, TWCR
	sbrs	TWISTAT, TWINT
	rjmp	_TWI_SEND_S_WAIT

	; store status
	in	TWISTAT, TWSR
	andi	TWISTAT, 0xf8
	ret

;;; ------------------------------------------------------------
;;- ** ~void TWI_SEND_P()~ (in: (none), out: (none))
;;- sends a stop bit.
;;-

TWI_SEND_P:
	push	r16
	; send stop bit
	ldi	r16, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
	out	TWCR, r16
	pop	r16
	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned int TWI_SEND(char data)~ (in: r24, out: r25:r24)
;;-    sends a byte ~data~ via TWI.
;;-    This returns r25:r24. A status code of TWI is stored in r25.
;;-    r24 is unchanged.
;;-
;;- ** ~unsigned int TWI_SEND_SLA_R(char address)~ (in: r24, out: r25:r24)
;;-    ~address~ is a target (slave) address (7 bits).
;;-    This returns r25:r24. A status code of TWI is stored in r25.
;;-    r24 is unchanged.
;;-
;;- ** ~unsigned int TWI_SEND_SLA_W(char address)~ (in: r24, out: r25:r24)
;;-    ~address~ is a target (slave) address (7 bits).
;;-    This returns r25:r24. A status code of TWI is stored in r25.
;;-    r24 is unchanged.
;;-

TWI_SEND_SLA_R:
	push	TWIDATA
	sec
	rol	TWIDATA
	rjmp	_TWI_SEND_MAIN

TWI_SEND_SLA_W:
	push	TWIDATA
	lsl	TWIDATA
	rjmp	_TWI_SEND_MAIN

TWI_SEND:
	push	TWIDATA

_TWI_SEND_MAIN:
	out	TWDR, TWIDATA
	ldi	TWIDATA, (1<<TWINT)|(1<<TWEN)
	out	TWCR, TWIDATA

	; wait ack
_TWI_SEND_WAIT:
	in	TWIDATA, TWCR
	sbrs	TWIDATA, TWINT
	rjmp	_TWI_SEND_WAIT

	; store status
	in	TWISTAT, TWSR
	andi	TWISTAT, 0xf8

	pop	TWIDATA
	ret

;;- ** ~unsigned int TWI_RECV_ACK()~ (in: (none), out: r25:r24)
;;-    receives a byte and returns an ACK.
;;-    The received data will be stored in r24 and a result code of TWI in r25.
;;-
;;- ** ~unsigned int TWI_RECV_NACK()~ (in: (none), out: r25:r24)
;;-    receives a byte and returns a NACK.
;;-    The received data will be stored in r24 and a result code of TWI in r25.
;;-

TWI_RECV_ACK:
	ldi	TWISTAT, (1<<TWEA)|(1<<TWINT)|(1<<TWEN)
	rjmp	_TWI_RECV_MAIN

TWI_RECV_NACK:
	ldi	TWISTAT, (1<<TWINT)|(1<<TWEN)

_TWI_RECV_MAIN:
	out	TWCR, TWISTAT

	; wait ack
_TWI_RECV_WAIT:
	in	TWISTAT, TWCR
	sbrs	TWISTAT, TWINT
	rjmp	_TWI_RECV_WAIT

	; store data
	in	TWIDATA, TWDR

	; store status
	in	TWISTAT, TWSR
	andi	TWISTAT, 0xf8
	ret

;;-
;;- * Example
;;-
;;- !see examples/twi-controller-test.asm
;;-
