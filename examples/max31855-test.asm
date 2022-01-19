;;; Test program of devices/max31855.asm
;;;
;;- This program reads data from MAX31855 and shows the data via USART for each second.
;;-
;;- See also: ~examples/README.org~
;;-

.include "device.inc"

#define USE_USART

RESET:
	;; set stack pointer
	ldi	r16, low(RAMEND)
	out	SPL, r16
	ldi	r16, high(RAMEND)
	out	SPH, r16

	rcall	USART_INITIALIZE
	ldi	r25, high(STR_HELLO)
	ldi	r24, low (STR_HELLO)
	rcall	USART_PUTS

	rcall	MAX31855_INIT_PORTS

LOOP:
	rcall	MAX31855_READDATA

	sbrs	r24, 0		; read fault bit (D16)
	rjmp	SHOW_TEMP

	;; error
ERROR_OC:
	sbrs	r22, 0		; read OC bit (D0)
	rjmp	ERROR_SCG
	ldi	r25, high(STR_ERROR_OC)
	ldi	r24, low (STR_ERROR_OC)
	rcall	USART_PUTS

ERROR_SCG:
	sbrs	r22, 1		; read SCG bit (D1)
	rjmp	ERROR_SCV
	ldi	r25, high(STR_ERROR_SCG)
	ldi	r24, low (STR_ERROR_SCG)
	rcall	USART_PUTS

ERROR_SCV:
	sbrs	r22, 2		; read SCG bit (D1)
	rjmp	ERROR_EXIT
	ldi	r25, high(STR_ERROR_SCV)
	ldi	r24, low (STR_ERROR_SCV)
	rcall	USART_PUTS

ERROR_EXIT:
	rcall	Wait1sec
	rjmp	LOOP


SHOW_TEMP:
	rcall	MAX31855_FORMAT_TEMP

	push	r25
	push	r24
	movw	r24, r22
	rcall	MAX31855_USART_INTTEMP
	pop	r24
	pop	r25
	rcall	CRLF

	rcall	MAX31855_USART_TCTEMP
	rcall	CRLF
	rcall	CRLF

	rcall	Wait1sec
	rjmp	LOOP

CRLF:
	push	r24
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT
	pop	r24
	ret

;;; ------------------------------------------------------------
.include "devices/max31855.asm"

.include "wait.asm"
.include "bin2bcd16.asm"
.include "frac2bcd.asm"

.include "usart.asm"
.include "usart-puts.asm"
.include "usart-puthex.asm"
.include "bin2ascii.asm"

STR_HELLO:	.db	"# Hallo MAX31855",       0x0d, 0x0a, 0, 0
STR_ERROR_OC:	.db	"Error: open circuit",    0x0d, 0x0a, 0
STR_ERROR_SCG:	.db	"Error: short to ground", 0x0d, 0x0a, 0, 0
STR_ERROR_SCV:	.db	"Error: short to Vcc",    0x0d, 0x0a, 0
