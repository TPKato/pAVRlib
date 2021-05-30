;;; Test program of usart.asm

;;- This is a test program of =usart.asm=.
;;- By default AVR returns a character whose code is 1 + the code of the input character.
;;- (For example, =b= will be echoed if you enter =a=.)


;;; ------------------------------------------------------------
;;; Define your device in device.inc or use
;;;   .include "m8def.inc"
;;; and so on as usual.

.include "device.inc"

;;; Remove this line if you want to make a "normal" echo.
#define CAESAR

;;; ------------------------------------------------------------
RESET:
	ldi	r16, high(RAMEND)
	out	SPH, r16
	ldi	r16, low(RAMEND)
	out	SPL, r16

	rcall	USART_INITIALIZE

	ldi	r24, 'H'
	rcall	USART_TRANSMIT
	ldi	r24, 'E'
	rcall	USART_TRANSMIT
	ldi	r24, 'L'
	rcall	USART_TRANSMIT
	ldi	r24, 'L'
	rcall	USART_TRANSMIT
	ldi	r24, 'O'
	rcall	USART_TRANSMIT
	ldi	r24, '!'
	rcall	USART_TRANSMIT
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

PROMPT:
	ldi	r24, '>'
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

RECV:
	rcall	USART_RECEIVE
	cpi	r24, 0x0d
	brne	TRANS

	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT
	rjmp	PROMPT

TRANS:
#ifdef CAESAR
	;; "(pseudo) Caesar cipher"
	inc	r24
#endif

	rcall	USART_TRANSMIT
	rjmp	RECV

.include "usart.asm"
