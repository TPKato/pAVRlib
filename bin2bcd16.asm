;;; bin2bcd16.asm
;;;
;;- converts a 2 byte-integer to BCD.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- This program is based on [[https://www.microchip.com/en-us/application-notes/an0938][AVR Application Note 204]].
;;-
;;- * Subroutine
;;-
;;- ** ~BIN2BCD16~ (in: r25:r24, out: r25,r24,r23)
;;-
;;-    converts a 2 byte-integer (r25:r24) to BCD.
;;-
;;- * Example
;;-
;;- #+BEGIN_SRC asm
;;-	ldi	r25, 0x7f
;;-	ldi	r24, 0xff
;;-	rcall	BIN2BCD16
;;- #+END_SRC
;;-
;;- This code results r25:r24:r23 = 0x03:0x27:0x67
;;- (0x7fff = 32767_{10}).
;;-

.equ	AtBCD0	= 21		; address of tBCD0
.equ	AtBCD2	= 23		; address of tBCD2

.def	tBCD0	= r21		; BCD value digits 1 and 0
.def	tBCD1	= r22		; BCD value digits 3 and 2
.def	tBCD2	= r23		; BCD value digit 4

.def	fbinL	= r24		; binary value low byte
.def	fbinH	= r25		; binary value high byte

.def	cnt16a	= r18		; loop counter
.def	tmp16a	= r19		; temporary value

BIN2BCD16:
	;; Note: These 6 registers are not needed to be restored (according to the avr-gcc ABI).
	push	r21
	push	r22
	push	r18
	push	r19
	push	r30
	push	r31

	ldi	cnt16a, 16
	clr	tBCD2
	clr	tBCD1
	clr	tBCD0
	clr	ZH
_bBCDx_1:
	lsl	fbinL
	rol	fbinH
	rol	tBCD0
	rol	tBCD1
	rol	tBCD2
	dec	cnt16a
	brne	_bBCDx_2
	rjmp	_bBCD_EXIT
_bBCDx_2:
	ldi	r30, AtBCD2+1
_bBCDx_3:
	ld	tmp16a, -Z
	subi	tmp16a, -0x03
	sbrc	tmp16a, 3
	st	Z, tmp16a
	ld	tmp16a, Z
	subi	tmp16a, -0x30
	sbrc	tmp16a, 7
	st	Z, tmp16a
	cpi	ZL, AtBCD0
	brne	_bBCDx_3
	rjmp	_bBCDx_1
_bBCD_EXIT:
	mov	r25, tBCD2
	mov	r24, tBCD1
	mov	r23, tBCD0

	pop	r31
	pop	r30
	pop	r19
	pop	r18
	pop	r22
	pop	r21
	ret
