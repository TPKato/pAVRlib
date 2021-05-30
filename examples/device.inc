;;; -*- asm -*-

.include	"m328Pdef.inc"
;;; .include	"m8def.inc"
;;; .include	"tn85def.inc"

.equ F_CPU	= 1000000

;;; options for USART related programs
.equ USART_BAUD	= 4800

;;; You need to define the following constants to make USART related
;;; programs, if you use AVRs which have no hardware USART (e.g. ATtiny25).
.equ USART_DDR  = DDRB
.equ USART_PORT = PORTB
.equ USART_PIN  = PINB
.equ USART_RXD  = 3		; PB3 (Pin 2 of ATtiny25/45/85)
.equ USART_TXD  = 4		; PB4 (Pin 3 of ATtiny25/45/85)