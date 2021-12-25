;;; -*- asm -*-

.include	"m328Pdef.inc"
;;; .include	"m8def.inc"
;;; .include	"tn85def.inc"

.equ F_CPU	= 1000000

;;; options for USART related programs
.equ USART_BAUD	= 4800

;;; for TWI
.equ F_SCL	= 100000

;;; You need to define the following constants to make USART related
;;; programs, if you use AVRs which have no hardware USART (e.g. ATtiny25).
.equ USART_DDR  = DDRB
.equ USART_PORT = PORTB
.equ USART_PIN  = PINB
.equ USART_RXD  = 3		; PB3 (Pin 2 of ATtiny25/45/85)
.equ USART_TXD  = 4		; PB4 (Pin 3 of ATtiny25/45/85)

;;; ------------------------------------------------------------
;;; Parameters for wait-test
.equ WAIT_LEDPIN  = 1
.equ WAIT_LEDPORT = PORTB
.equ WAIT_LEDDDR  = DDRB

;;; ------------------------------------------------------------
;;; for twi-controller-test
#undef TWITEST_SHOW_NOTFOUND

;;; ------------------------------------------------------------
;;; for am2303-test
.equ AM_DDR	= DDRB
.equ AM_PORT	= PORTB
.equ AM_PIN	= PINB
.equ AM_SDA	= 0
