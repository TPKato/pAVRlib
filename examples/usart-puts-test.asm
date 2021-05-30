;;; Test program of usart-puts.asm

;;- This program sends "Hello, World!" and "Bye." via USART.

;;; ------------------------------------------------------------
;;; Define your device in device.inc or use
;;;   .include "m8def.inc"
;;; and so on as usual.

.include "device.inc"

;;; ------------------------------------------------------------
RESET:
	ldi	r16, high(RAMEND)
	out	SPH, r16
	ldi	r16, low(RAMEND)
	out	SPL, r16

	rcall	USART_INITIALIZE

	ldi	r25, high(STR_HELLO)
	ldi	r24, low (STR_HELLO)
	rcall	USART_PUTS

	ldi	r25, high(STR_BYE)
	ldi	r24, low (STR_BYE)
	rcall	USART_PUTS

LOOP:
	rjmp	LOOP

STR_HELLO:	.db	"Hello, World!", 0x0d, 0x0a, 0
STR_BYE:	.db	"Bye.", 0x0d, 0x0a, 0, 0

.include "usart.asm"
.include "usart-puts.asm"
