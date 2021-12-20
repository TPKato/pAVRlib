;;; usart.asm
;;- This program provides basic USART routines.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- In =examples/= you'll find a small test program.
;;-
;;- The software UART is written based on
;;- [[https://www.microchip.com/en-us/application-notes/an0952][Application Note AVR305]].
;;-
;;- * Initialize
;;-
;;- Before you use this routines, you need define ~F_CPU~ (in Hz) and ~USART_BAUD~.
;;-
;;- #+NAME: init_usart
;;- #+BEGIN_SRC asm
;;- .equ F_CPU = 1000000
;;- .equ USART_BAUD = 4800
;;- #+END_SRC
;;-
;;- Furthermore you need to define the ports if you use AVR without a hardware USART (e.g. ATtiny25).
;;-
;;- #+NAME: init_usart_software
;;- #+BEGIN_SRC asm
;;- ; PB3 and PB4 (Pin 2 and 3 of ATtiny25/45/85)
;;- .equ USART_DDR  = DDRB
;;- .equ USART_PORT = PORTB
;;- .equ USART_PIN  = PINB
;;- .equ USART_RXD  = 3
;;- .equ USART_TXD  = 4
;;- #+END_SRC
;;-
;;- See also ~examples/usart-test.asm~.
;;-
;;- * Subroutines
;;-
;;- ** ~void USART_INITIALIZE()~ (in: (none), out: (none))
;;-    set up the port and baudrate.
;;-
;;- ** ~void USART_TRANSMIT(char)~ (in: r24, out: (none))
;;-    send a byte.
;;-
;;- ** ~char USART_RECEIVE()~ (in: (none), out: r24)
;;-    receive a byte.
;;-
;;- * Example
;;-
;;- This is a simple echo program.
;;-
;;- #+NAME: example
;;- #+BEGIN_SRC asm
;;-	rcall	USART_INITIALIZE
;;- loop:
;;-	rcall	USART_RECEIVE
;;-	rcall	USART_TRANSMIT
;;-	rjmp	loop
;;- #+END_SRC
;;-

.ifndef	F_CPU
.error "Specify a frequency of the system clock (F_CPU)."
.endif

.ifndef USART_BAUD
.equ USART_BAUD	= 4800
.message "INFO: USART_BAUD is not defined. The default value (4800) will be used."
.endif

#ifdef UBRR0H

;;; ------------------------------------------------------------
;;; for devices which have UBRR0H (e.g. ATmega48)

.equ UBRRVAL= (F_CPU + 4 * USART_BAUD) / (8 * USART_BAUD) - 1

USART_INITIALIZE:
	push	r16

	ldi	r16, high(UBRRVAL)
	sts	UBRR0H, r16
	ldi	r16, low(UBRRVAL)
	sts	UBRR0L, r16

	;; enable U2X mode
	ldi	r16, (1<<U2X0)
	sts	UCSR0A, r16

	;; Enable receiver and transmitter
	ldi	r16, (1<<RXEN0)|(1<<TXEN0)
	sts	UCSR0B, r16

	;; Set frame format: 8N1
	ldi	r16, (3<<UCSZ00)
	sts	UCSR0C,r16

	pop	r16
	ret

USART_TRANSMIT:
	push	r16

_USART_TRANSMIT_wait:
 	lds	r16, UCSR0A
 	sbrs	r16, UDRE0
	rjmp 	_USART_TRANSMIT_wait

	sts	UDR0, r24
	pop	r16

_USART_TRANSMIT_exit:
	ret

USART_RECEIVE:
	push	r16

_USART_RECEIVE_wait:
 	lds	r16, UCSR0A
 	sbrs	r16, RXC0
	rjmp 	_USART_RECEIVE_wait

	lds	r24, UDR0
	pop	r16
	ret

#else
#ifdef UBRRH

;;; ------------------------------------------------------------
;;; for devices which have UBRRH (e.g. ATmega8)

.equ UBRRVAL= (F_CPU + 4 * USART_BAUD) / (8 * USART_BAUD) - 1

USART_INITIALIZE:
	push	r16

	ldi	r16, high(UBRRVAL)
	out	UBRRH, r16
	ldi	r16, low(UBRRVAL)
	out	UBRRL, r16

	;; enable U2X mode
	ldi	r16, (1<<U2X)
	out	UCSRA, r16

	;; Enable receiver and transmitter
	ldi	r16, (1<<RXEN)|(1<<TXEN)
	out	UCSRB, r16

	;; Set frame format: 8N1
	ldi	r16, (1<<URSEL)|(3<<UCSZ0)
	out	UCSRC,r16

	pop	r16
	ret

USART_TRANSMIT:
_USART_TRANSMIT_wait:
	sbis 	UCSRA, UDRE
	rjmp 	_USART_TRANSMIT_wait

	out	UDR, r24
_USART_TRANSMIT_exit:
	ret

USART_RECEIVE:
	sbis	UCSRA, RXC
	rjmp	USART_RECEIVE

	in	r24, UDR
	ret

#else

;;; ------------------------------------------------------------
;;; for devices which have no hardware USART (e.g. ATtiny25)
;;; (based on AVR Application Note AVR305)

#ifndef USART_DELAY_VALUE
;; Note: "+3" is added for rounding (instead of rounding down)
#define USART_DELAY_VALUE (((F_CPU / USART_BAUD) - 23 + 3) / 6)
#endif

USART_INITIALIZE:
	sbi	USART_DDR, USART_TXD
	ret

USART_TRANSMIT:
	push	r16
 	ldi	r16, 10		; 1 + 8 + 1 stop bit (8N1)
	com	r24
	sec
_USART_putchar0:
	brcc	_USART_putchar1
	cbi	USART_PORT, USART_TXD
	rjmp	_USART_putchar2
_USART_putchar1:
	sbi	USART_PORT, USART_TXD
	nop
_USART_putchar2:
	rcall	_USART_DELAY
	rcall	_USART_DELAY
	lsr	r24
	dec	r16
	brne	_USART_putchar0
	pop	r16
	ret

USART_RECEIVE:
	push	r16
	ldi	r16, 9		; 8 + 1 stop bit
_USART_getchar1:
	sbic	USART_PIN, USART_RXD
	rjmp	_USART_getchar1
	rcall	_USART_DELAY
_USART_getchar2:
	rcall	_USART_DELAY
	rcall	_USART_DELAY
	clc
	sbic	USART_PIN, USART_RXD
	sec
	dec	r16
	breq	_USART_getchar3
	ror	r24
	rjmp	_USART_getchar2
_USART_getchar3:
	pop	r16
	ret

_USART_DELAY:
	push	r16
	ldi	r16, USART_DELAY_VALUE
_USART_DELAY1:
	dec	r16
	brne	_USART_DELAY1
	pop	r16
	ret

#endif
#endif
