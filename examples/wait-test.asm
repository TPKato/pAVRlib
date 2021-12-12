;;; Test program of wait.asm

;;; ------------------------------------------------------------
;;; Define your device in device.inc or use
;;;   .include "m8def.inc"
;;; and so on as usual.

.include "device.inc"

;; .equ	WAIT_LEDPIN = 1
;; .equ	WAIT_LEDPORT = PORTB
;; .equ	WAIT_LEDDDR = DDRB

;;; ------------------------------------------------------------
RESET:
	ldi	r16, high(RAMEND)
	out	SPH, r16
	ldi	r16, low(RAMEND)
	out	SPL, r16

	;; set WAIT_LEDDDR:WAIT_LEDPIN as output
	sbi 	WAIT_LEDDDR, WAIT_LEDPIN

MAIN:

;; 1 ms (500 Hz)
Test_500Hz:
	ldi	r17, 10
_Test_500Hz_1:
	ldi	r16, 250	; for 5 s (2500 loops)
_Test_500Hz:
	sbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Wait1ms
	cbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Wait1ms
	subi	r16, 1
	brne	_Test_500Hz
	subi	r17, 1
	brne	_Test_500Hz_1

;; 10 ms (50 Hz)
Test_50Hz:
	ldi	r24, 10		; 10 ms high + 10 ms low
	ldi	r16, 250	; for 5 s (250 loops)
_Test_50Hz:
	sbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Waitms
	cbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Waitms
	subi	r16, 1
	brne	_Test_50Hz

;; 500 ms (1 Hz)
Test_1Hz:
	ldi	r24, low(500)	; 500 ms high + 500 ms low
	ldi	r25, high(500)
	ldi	r16, 5		; for 5 s (5 loops)
_Test_1Hz:
	sbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Waitmsint
	cbi	WAIT_LEDPORT, WAIT_LEDPIN
	rcall	Waitmsint
	subi	r16, 1
	brne	_Test_1Hz

	rjmp	MAIN

.include "wait.asm"
