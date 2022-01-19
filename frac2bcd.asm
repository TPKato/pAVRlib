;;; frac2bcd.asm
;;;
;;- converts a fractional number to BCD.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- * Subroutine
;;-
;;- ** ~unsigned int FRAC2BCD(unsigned char frac)~ (in: r24, out: r25:r24)
;;-
;;-    converts a fractional number (0.8) to BCD.
;;-    In r25 the result (BCD) will be stored.
;;-    r24 will be the remainder and you can obtain more digits by calling
;;-    this function repeatedly.
;;-
;;- * Example
;;-
;;- #+BEGIN_SRC asm
;;-	ldi	r24, 0xd0	; 0.11010000(b) = 0.8125(d)
;;-	rcall	FRAC2BCD	; result: r25 = 0x81
;;-				;	  r24 = 0x40 (= 0b0100 0000)
;;-	mov	r17, r25	; store r25 in r17
;;-	rcall	FRAC2BCD	; result: r25 = 0x25
;;-				;	  r24 = 0x00 (= 0b0000 0000)
;;-	mov	r16, r25	; now r17:r16 = 0x81:0x25
;;- #+END_SRC
;;-

#ifdef __GNUC__
.global FRAC2BCD
#endif

FRAC2BCD:
	push	r26
	clr	r25

	;; first digit
	mov	r26, r24

	lsl	r24
	rol	r25
	lsl	r24
	rol	r25
	add	r24, r26	; r25:r24 = r24 * 5
	clr	r26
	adc	r25, r26	; add carry
	lsl	r24
	rol	r25		; r25:r24 = r24 * 10

	rol	r25

	;; next digit
	mov	r26, r24

	lsl	r24
	rol	r25
	lsl	r24
	rol	r25
	add	r24, r26
	clr	r26
	adc	r25, r26
	lsl	r24
	rol	r25

	pop	r26
	ret
