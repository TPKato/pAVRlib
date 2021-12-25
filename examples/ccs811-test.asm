;;; Test program of devices/ccs811.asm

;;- The test program for ccs811-asm (asm version).
;;-
;;- This program reads data from CCS811 and show the received data via USART like this:
;;-
;;- #+begin_src sh
;;- $ dterm /dev/ttyUSB0 4800
;;- # Hallo CCS811
;;- # CCS811 found at 0x5A
;;- # Waiting for the first data ....
;;- # Entering interrupt mode
;;- eCO2:   406 ppm, eTVOC:     0 ppb [ 01 96 00 00 98 00 07 23 ]
;;- eCO2:   409 ppm, eTVOC:     1 ppb [ 01 99 00 01 98 00 07 21 ]
;;- eCO2:   413 ppm, eTVOC:     1 ppb [ 01 9D 00 01 98 00 07 20 ]
;;- eCO2:   413 ppm, eTVOC:     1 ppb [ 01 9D 00 01 98 00 07 20 ]
;;- eCO2:   406 ppm, eTVOC:     0 ppb [ 01 96 00 00 98 00 07 23 ]
;;- eCO2:   408 ppm, eTVOC:     1 ppb [ 01 98 00 01 98 00 07 22 ]
;;-  :
;;-  :
;;- #+end_src
;;-
;;- To compile this file, the following files are required
;;- (These files are parts of the pAVRlib).
;;-
;;- - [[../../devices/ccs811][devices/ccs811.asm]]
;;- - [[../../twi-controller][twi-controller.asm]]
;;- - [[../../usart][usart.asm]]
;;- - [[../../usart-puts][usart-puts.asm]]
;;- - [[../../usart-puthex][usart-puthex.asm]]
;;- - [[../../bin2ascii][bin2ascii.asm]]
;;- - [[../../bin2bcd16][bin2bcd16.asm]]
;;- - [[../../wait][wait.asm]]
;;-
;;- See also: ~examples/README.org~
;;-

;;; ------------------------------------------------------------
;;; Define your device in device.inc or use
;;;   .include "m8def.inc"
;;; and so on as usual.

.include "device.inc"

;;; ------------------------------------------------------------
.def	CCS811ADDR = r27

	; interrupt vectors
	rjmp	RESET
#ifdef	CCS811TEST_USE_INTERRUPT_MODE
	rjmp	NewData	;rjmp	EXT_INT0
#else
	reti
#endif
	reti		;rjmp	EXT_INT1
	reti		;rjmp	TIM2_COMP
	reti		;rjmp	TIM2_OVF
	reti		;rjmp	TIM1_CAPT
	reti		;rjmp	TIM1_COMPA
	reti		;rjmp	TIM1_COMPB
	reti		;rjmp	INT_TIM1_OVF
	reti		;rjmp	TIM0_OVF
	reti		;rjmp	SPI_STC
	reti		;rjmp	USART_RXC
	reti		;rjmp	USART_UDRE
	reti		;rjmp	USART_TXC
	reti		;rjmp	ADC
	reti		;rjmp	EE_RDY
	reti		;rjmp	ANA_COMP
	reti		;rjmp	TWI
	reti		;rjmp	SPM_RDY

RESET:
	; set stack pointer
	ldi	r16, low(RAMEND)
	out	SPL, r16
	ldi	r16, high(RAMEND)
	out	SPH, r16

	rcall	USART_INITIALIZE
	ldi	r25, high(STR_HELLO)
	ldi	r24, low (STR_HELLO)
	rcall	USART_PUTS

	rcall	TWI_INITIALIZE

#ifdef CCS811_USE_RESET
	rcall	CCS811_RESET
	ldi	r24, 250
	rcall	Waitms
#endif
	rcall	CCS811_SEARCH

	sbrc	r24, 7
	rjmp	ERROR_NO_DEVICE

	;; found CCS811
	mov	CCS811ADDR, r24

	ldi	r25, high(STR_CCS811ADDR)
	ldi	r24, low (STR_CCS811ADDR)
	rcall	USART_PUTS
	mov	r24, CCS811ADDR
	rcall	USART_PUTHEX
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

	;; initialize
	mov	r24, CCS811ADDR
	rcall	CCS811_INITIALIZE

	;; error check
	sbrc	r25, 7
	;; initialize error
	rjmp	ERROR_INITIALIZE

CCS811_SET_MEAS:
	;; set measure mode
	ldi	r16, (DRIVE_MODE_1s | INT_DATARDY)
	mov	r0, r16
	mov	r24, CCS811ADDR
	ldi	r22, MEAS_MODE
	ldi	r20, 1
	clr	r19
	clr	r18
	rcall	CCS811_WRITE

	rcall	Wait1ms

	;; read STATUS (0x00)
	mov	r24, CCS811ADDR
	ldi	r22, STATUS
	ldi	r20, 1
	clr	r19
	clr	r18
	rcall	CCS811_READ

	ldi	r25, high(STR_FIRSTDATA)
	ldi	r24, low (STR_FIRSTDATA)
	rcall	USART_PUTS

_first_data:
	;; Wait for the first data
	rcall	Wait1sec

	;; read STATUS (0x00)
	mov	r24, CCS811ADDR
	ldi	r22, STATUS
	ldi	r20, 1
	clr	r19
	clr	r18
	rcall	CCS811_READ

	ldi	r24, '.'
	rcall	USART_TRANSMIT

	sbrs	r0, sDATA_READY
	rjmp	_first_data

	;; the first data is ready
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

	;; read ALG_RESULT_DATA to reset interrupt
	mov	r24, CCS811ADDR
	ldi	r22, ALG_RESULT_DATA
	ldi	r20, 8
	clr	r19
	clr	r18
	rcall	CCS811_READ

#ifdef CCS811TEST_USE_INTERRUPT_MODE
	ldi	r25, high(STR_INTR)
	ldi	r24, low (STR_INTR)
	rcall	USART_PUTS

	;; enable interrupt
	push	r16
	ldi	r16, (0<<ISC00)
	out	MCUCR, r16

	in	r16, GICR
	ori	r16, (1<<INT0)
	out	GICR, r16
	pop	r16

	sei

WaitNewData:
	rjmp	WaitNewData
#else				; ifndef CCS811TEST_USE_INTERRUPT_MODE
POLLING:
	rcall	Wait1sec

	;; read STATUS (0x00)
	mov	r24, CCS811ADDR
	ldi	r22, STATUS
	ldi	r20, 1
	clr	r19
	clr	r18
	rcall	CCS811_READ

	;; check if data is ready
	sbrs	r0, sDATA_READY
	rjmp	POLLING

	;; read ALG_RESULT_DATA (0x02)
	mov	r24, CCS811ADDR
	ldi	r22, ALG_RESULT_DATA
	ldi	r20, 8
	clr	r19
	clr	r18
	rcall	CCS811_READ

	rcall	SHOW_DATA
	rcall	DUMP_RAWDATA

	rjmp	POLLING
#endif

;;; ------------------------------------------------------------
;;; error

ERROR_NO_DEVICE:
	ldi	r25, high(STR_ERRNODEV)
	ldi	r24, low (STR_ERRNODEV)
	rcall	USART_PUTS
	rjmp	loop_error

ERROR_INITIALIZE:
	ldi	r25, high(STR_ERRINIT)
	ldi	r24, low (STR_ERRINIT)
	rcall	USART_PUTS

	rcall	USART_PUTHEX
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT
	rjmp	loop_error

;;; not used (yet)
ERROR_TWI:
	push	r25
	ldi	r25, high(STR_ERROR)
	ldi	r24, low (STR_ERROR)
	rcall	USART_PUTS

	ldi	r24, ':'
	rcall	USART_TRANSMIT
	pop	r25

	mov	r24, r25	; TWI status
	rcall	USART_PUTHEX
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

loop_error:
	rjmp	loop_error

;;; ------------------------------------------------------------
NewData:
	mov	r24, CCS811ADDR
	ldi	r22, ALG_RESULT_DATA
	ldi	r20, 8
	clr	r19
	clr	r18
	rcall	CCS811_READ

	rcall	SHOW_DATA
	rcall	DUMP_RAWDATA

	reti

SHOW_DATA:
	;; eCO2
	ldi	r24, 'e'
	rcall	USART_TRANSMIT
	ldi	r24, 'C'
	rcall	USART_TRANSMIT
	ldi	r24, 'O'
	rcall	USART_TRANSMIT
	ldi	r24, '2'
	rcall	USART_TRANSMIT
	ldi	r24, ':'
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

	mov	r25, r0
	mov	r24, r1
	rcall	BIN2BCD16
	rcall	BCDSHOW

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, 'p'
	rcall	USART_TRANSMIT
	ldi	r24, 'p'
	rcall	USART_TRANSMIT
	ldi	r24, 'm'
	rcall	USART_TRANSMIT
	ldi	r24, ','
	rcall	USART_TRANSMIT

	;; eTVOC
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, 'e'
	rcall	USART_TRANSMIT
	ldi	r24, 'T'
	rcall	USART_TRANSMIT
	ldi	r24, 'V'
	rcall	USART_TRANSMIT
	ldi	r24, 'O'
	rcall	USART_TRANSMIT
	ldi	r24, 'C'
	rcall	USART_TRANSMIT
	ldi	r24, ':'
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

	mov	r25, r2
	mov	r24, r3
	rcall	BIN2BCD16
	rcall	BCDSHOW

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, 'p'
	rcall	USART_TRANSMIT
	ldi	r24, 'p'
	rcall	USART_TRANSMIT
	ldi	r24, 'b'
	rcall	USART_TRANSMIT

	ret

;;; ------------------------------------------------------------
BCDSHOW:
	push	r18
	push	r17
	push	r16

	mov	r18, r25
	mov	r17, r24
	mov	r16, r23

	mov	r24, r18

	andi	r18, 0x0f
	brne	_showdata18

	ldi	r18, ' '
	subi	r24, -' '
	rjmp	_showdata17

_showdata18:
	ldi	r18, '0'
	subi	r24, -'0'

_showdata17:
	rcall	USART_TRANSMIT

	push	r17
	swap	r17
	andi	r17, 0x0f
	breq	_showdata17_2
	ldi	r18, '0'

_showdata17_2:
	add	r17, r18
	mov	r24, r17
	rcall	USART_TRANSMIT
	pop	r17

	andi	r17, 0x0f
	breq	_showdata17_1
	ldi	r18, '0'
_showdata17_1:
	add	r17, r18
	mov	r24, r17
	rcall	USART_TRANSMIT

	push	r16
	swap	r16
	andi	r16, 0x0f
	breq	_showdata16_2
	ldi	r18, '0'
_showdata16_2:
	add	r16, r18
	mov	r24, r16
	rcall	USART_TRANSMIT
	pop	r16

	andi	r16, 0x0f
	subi	r16, -'0'
	mov	r24, r16
	rcall	USART_TRANSMIT

	pop	r16
	pop	r17
	pop	r18

	ret

;;;  ------------------------------------------------------------
DUMP_RAWDATA:
	push	r31
	push	r30

	clr	r31
	clr	r30

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, '['
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

_DUMP_RAWDATA_loop:
	ld	r24, Z+
	rcall	USART_PUTHEX
	ldi	r24, ' '
	rcall	USART_TRANSMIT

	cpi	r30, 8
	brne	_DUMP_RAWDATA_loop

	ldi	r24, ']'
	rcall	USART_TRANSMIT

	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT

	pop	r30
	pop	r31
	ret

; ------------------------------------------------------------
.include	"devices/ccs811.asm"

.include	"twi-controller.asm"
.include	"usart.asm"
.include	"usart-puts.asm"
.include	"usart-puthex.asm"
.include	"bin2ascii.asm"
.include	"bin2bcd16.asm"
.include	"wait.asm"

; ------------------------------------------------------------
STR_HELLO:	.db	"# Hallo CCS811", 0x0d, 0x0a, 0, 0
STR_FIRSTDATA:	.db	"# Waiting for the first data ", 0
STR_INTR:	.db	"# Entering interrupt mode", 0x0d, 0x0a, 0
STR_CCS811ADDR:	.db	"# CCS811 found at 0x", 0, 0

STR_ERROR:	.db	"! TWI Error. Status: ", 0
STR_ERRNODEV:	.db	"! No CCS811 found.", 0x0d, 0x0a, 0, 0
STR_ERRINIT:	.db	"! Initialize failed: ", 0
