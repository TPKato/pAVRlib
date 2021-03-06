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

;;; ------------------------------------------------------------
;;; for ccs811-test
.define CCS811TEST_USE_INTERRUPT_MODE
.define CCS811_USE_RESET
.equ	CCS811_RESET_DDR	= DDRB
.equ	CCS811_RESET_PORT	= PORTB
.equ	CCS811_RESET_PINNUM	= 6

;;; ------------------------------------------------------------
;;; for max31855-test
.equ	MAX_CK_DDR	= DDRD
.equ	MAX_CK_PORT	= PORTD
.equ	MAX_CK_PIN	= PIND
.equ	MAX_CK		= 7

.equ	MAX_CS_DDR	= DDRD
.equ	MAX_CS_PORT	= PORTD
.equ	MAX_CS_PIN	= PIND
.equ	MAX_CS		= 6

.equ	MAX_DO_DDR	= DDRD
.equ	MAX_DO_PORT	= PORTD
.equ	MAX_DO_PIN	= PIND
.equ	MAX_DO		= 5
