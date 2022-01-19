;;; Test program of devices/am2302.asm
;;;
;;- This program reads data from AM2302 and shows the data via USART like this:
;;-
;;- #+begin_src sh
;;- $ dterm /dev/ttyUSB0 4800
;;- # Hallo AM2302
;;- 59.6 %RH, 24.0 C [02 54 00 F0 46] (77 33, 62 00)
;;- 59.7 %RH, 23.9 C [02 55 00 EF 46] (77 66, 61 CC)
;;- 59.8 %RH, 23.9 C [02 56 00 EF 47] (77 99, 61 CC)
;;-  :
;;-  :
;;- #+end_src
;;- where:
;;- - values in [...]: raw data from AM2302
;;- - values in (...): converted humidity and temperature for CCS811
;;-
;;- To compile this file, the following files are required
;;- (These files are parts of the pAVRlib).
;;-
;;- - [[../../devices/am2302][devices/am2302]]
;;- - [[../../devices/am2302-ccs811][devices/am2302-ccs811.asm]]
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

;; ------------------------------------------------------------

        ; interupt vectors
	rjmp    RESET
	reti            ;rjmp   EXT_INT0
	reti            ;rjmp   EXT_INT1
	reti            ;rjmp   TIM2_COMP
	reti            ;rjmp   TIM2_OVF
	reti            ;rjmp   TIM1_CAPT
	reti            ;rjmp   TIM1_COMPA
	reti            ;rjmp   TIM1_COMPB
	reti		;rjmp	INT_TIM1_OVF
	reti            ;rjmp   TIM0_OVF
	reti            ;rjmp   SPI_STC
	reti            ;rjmp   USART_RXC
	reti            ;rjmp   USART_UDRE
	reti            ;rjmp   USART_TXC
	reti            ;rjmp   ADC
	reti            ;rjmp   EE_RDY
	reti            ;rjmp   ANA_COMP
	reti            ;rjmp   TWI
	reti            ;rjmp   SPM_RDY

RESET:
	ldi	r16, high(RAMEND)
	out	SPH, r16
	ldi	r16, low(RAMEND)
	out	SPL, r16

	rcall	USART_INITIALIZE

hello:
	ldi	r25, high(STR_HELLO)
	ldi	r24, low (STR_HELLO)
	rcall	USART_PUTS

	;; dummy read to acquire the latest values
	;; (It doesn't really matter, because this program reads the
	;; data in short enough intervals.)
	rcall	AM2302_READ

main:
	rcall	Wait1sec
	rcall	Wait1sec
	rcall	Wait1sec

	rcall	AM2302_READ

	inc	r25
	tst	r25
	brne	showinfo

	;;  parity error
	ldi	r25, high(STR_PERROR)
	ldi	r24, low (STR_PERROR)
	rcall	USART_PUTS
	rjmp	main

showinfo:
	dec	r25

	;; ----------------------------------------
	;; show humidity
	rcall	USART_Humidity

	;; ----------------------------------------
	;; show temperature
	push	r25
	push	r24

	ldi	r24, ','
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

	mov	r25, r23
	mov	r24, r22
	rcall	USART_Temperature

	ldi	r24, ' '
	rcall	USART_TRANSMIT

	pop	r24
	pop	r25

	;; ----------------------------------------
	;; show rawdata
 	rcall 	AM2302_USART_RAWDATA

	;; ----------------------------------------
	;; show converted humidity for CCS811
	push	r24
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, '('
	rcall	USART_TRANSMIT
	pop	r24

	;; push	r25		; if you want to keep the original values
	;; push	r24

	rcall	CONVERT_HUMIDITY_FOR_CCS811

	push	r24
	mov	r24, r25
	rcall	USART_PUTHEX
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	pop	r24

	rcall	USART_PUTHEX
	ldi	r24, ','
	rcall	USART_TRANSMIT
	ldi	r24, ' '
	rcall	USART_TRANSMIT

	;; pop	r24
	;; pop	r25

	;; ----------------------------------------
	;; show converted temperature for CCS811

	;; push	r25		; if you want to keep the original values
	;; push	r24

	mov	r25, r23
	mov	r24, r22
	rcall	CONVERT_TEMPERATURE_FOR_CCS811

	push	r24
	mov	r24, r25
	rcall	USART_PUTHEX
	ldi	r24, ' '
	rcall	USART_TRANSMIT
	pop	r24

	rcall	USART_PUTHEX
	ldi	r24, ')'
	rcall	USART_TRANSMIT

	;; pop	r24
	;; pop	r25

	;;  ----------------------------------------
	;; push	r24		; if you want to keep the original values
	ldi	r24, 0x0d
	rcall	USART_TRANSMIT
	ldi	r24, 0x0a
	rcall	USART_TRANSMIT
	;; pop	r24

	rjmp	main


;;; ------------------------------------------------------------
USART_Humidity:
	push	r25
	push	r24

	rcall	_USART_value

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, '%'
	rcall	USART_TRANSMIT
	ldi	r24, 'R'
	rcall	USART_TRANSMIT
	ldi	r24, 'H'
	rcall	USART_TRANSMIT

	pop	r24
	pop	r25

	ret

USART_Temperature:
	push	r25
	push	r24

	sbrs	r25, 7
	rjmp	_show_temp1

	andi	r25, 0x7f
	ldi	r24, '-'
	rcall	USART_TRANSMIT

_show_temp1:
	rcall	_USART_value

	ldi	r24, ' '
	rcall	USART_TRANSMIT
	ldi	r24, 'C'
	rcall	USART_TRANSMIT

	pop	r24
	pop	r25

	ret

;;; [in] r25:r24
_USART_value:
	push	r19
	clr	r19

	;; BIN2BCD16: [in] r25:r24 [out] r25:r24:r23
	push	r23
	rcall	BIN2BCD16

	andi	r25, 0x0f
	tst	r25
	breq	_show_1
	ldi	r19, '0'
_show_1:
	add	r25, r19
	push	r24
	mov	r24, r25
	rcall	USART_TRANSMIT
	pop	r24

	push	r24
	swap	r24
	andi	r24, 0x0f
	tst	r24
	breq	_show_2
	ldi	r19, '0'
_show_2:
	add	r24, r19
	rcall	USART_TRANSMIT
	pop	r24

	andi	r24, 0x0f
	tst	r24
	breq	_show_3
	ldi	r19, '0'
_show_3:
	add	r24, r19
	rcall	USART_TRANSMIT

	push	r23
	swap	r23
	mov	r24, r23
	andi	r24, 0x0f
	subi	r24, -'0'
	rcall	USART_TRANSMIT
	pop	r23

	ldi	r24, '.'
	rcall	USART_TRANSMIT

	mov	r24, r23
	andi	r24, 0x0f
	subi	r24, -'0'
	rcall	USART_TRANSMIT

	pop	r23
	pop	r19
	ret

;;;  ------------------------------------------------------------
#define AM2303_DEBUG
#define AM2303_DEBUG_USE_USART

.include "devices/am2302.asm"
.include "devices/am2302-ccs811.asm"

.include "usart.asm"
.include "usart-puts.asm"
.include "usart-puthex.asm"
.include "bin2ascii.asm"
.include "bin2bcd16.asm"
.include "wait.asm"

;;; ------------------------------------------------------------
STR_HELLO:	.db	"# Hallo AM2302", 0x0d, 0x0a, 0, 0
STR_PERROR:	.db	"# Parity Error", 0x0d, 0x0a, 0, 0
