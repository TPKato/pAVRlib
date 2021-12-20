;;; Test program of twi-controller.asm
;;;
;;- This program scans I²C devices and shows if a device on each address exists.
;;-
;;- To compile this file, the following files are required
;;- (These files are parts of the pAVRlib).
;;-
;;- - [[../twi-controller][twi-controller.asm]]
;;- - [[../usart][usart.asm]]
;;- - [[../usart-puts][usart-puts.asm]]
;;- - [[../usart-puthex][usart-puthex.asm]]
;;- - [[../bin2ascii][bin2ascii.asm]]
;;-
;;- See also: ~examples/README.org~
;;-

;;; ------------------------------------------------------------
;;; Define your device in device.inc or use
;;;   .include "m8def.inc"
;;; and so on as usual.

.include "device.inc"

;;; .equ F_CPU      = 1000000
;;; .equ USART_BAUD = 4800
;;; .equ F_SCL      = 100000

;; ------------------------------------------------------------
.def	SLA = r21

;;; ------------------------------------------------------------
RESET:
	ldi	r16, low(RAMEND)
	out	SPL, r16
	ldi	r16, high(RAMEND)
	out	SPH, r16

	rcall	USART_INITIALIZE

	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

	ldi	r25, high(STR_SEARCHING)
	ldi	r24, low (STR_SEARCHING)
	rcall	USART_PUTS

	rcall	TWI_INITIALIZE

.equ	IICSTART = 0b0001000
.equ	IICEND	 = 0b1110111

	ldi	SLA, IICSTART

SEARCH:
 	push	r24
	mov	r24, SLA
	rcall	USART_PUTHEX
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, '('
	rcall	USART_TRANSMIT

	mov	r24, SLA
	lsl	r24
	rcall	USART_PUTHEX

	ldi	r24, ')'
	rcall	USART_TRANSMIT

 	pop	r24

	; send start bit
	rcall	TWI_SEND_S

	cpi	TWISTAT, $08
	brne	ERROR

	; send slave address
	mov	r24, SLA
	rcall	TWI_SEND_SLA_R

	; send stop bit
	rcall	TWI_SEND_P

	cpi	TWISTAT, $40
	breq	FOUND

NOTFOUND:
#ifdef TWITEST_SHOW_NOTFOUND
	ldi	r25, high(STR_NOTFOUND)
	ldi	r24, low (STR_NOTFOUND)
	rcall	USART_PUTS
#else
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
#endif

	rjmp	NEXTLOOP

FOUND:
	ldi	r25, high(STR_FOUND)
	ldi	r24, low (STR_FOUND)
	rcall	USART_PUTS

NEXTLOOP:
	inc	SLA
	cpi	SLA, (IICEND + 1)
	breq	EXIT

	rjmp	SEARCH

EXIT:
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, $0d
	rcall	USART_TRANSMIT

	ldi	r25, high(STR_FINISH)
	ldi	r24, low (STR_FINISH)
	rcall	USART_PUTS

END:
	rjmp	END

ERROR:
	ldi	r25, high(STR_ERROR)
	ldi	r24, low (STR_ERROR)
	rcall	USART_PUTS

	ldi	r24, ':'
	rcall	USART_TRANSMIT

	mov	r24, TWISTAT
	rcall	USART_PUTHEX
	ldi	r24, $0d
	rcall	USART_TRANSMIT
	ldi	r24, $0a
	rcall	USART_TRANSMIT

	rjmp	END

; ------------------------------------------------------------
.include "twi-controller.asm"

.include "usart.asm"
.include "usart-puts.asm"
.include "usart-puthex.asm"
.include "bin2ascii.asm"

; ------------------------------------------------------------
STR_SEARCHING:	.db	"searching i2c devices...", 0x0d, 0x0a, 0, 0
STR_ERROR:	.db	"Error", 0

STR_FOUND:	.db	": Found", 0x0d, 0x0a, 0
STR_NOTFOUND:	.db	": Not Found", 0x0d, 0x0a, 0

STR_FINISH:	.db	"Scan finished", 0x0d, 0x0a, 0
