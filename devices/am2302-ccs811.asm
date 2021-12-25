;;; am2302-ccs811.asm
;;-
;;- Subroutines to convert the values of AM2302 for CCS811 sensor.
;;- This code is a part of [[../][pAVRlib]].
;;-

#ifdef __GNUC__
.global CONVERT_TEMPERATURE_FOR_CCS811
.global CONVERT_HUMIDITY_FOR_CCS811
#define low(x) lo8(x)
#define high(x) hi8(x)
#endif

;;- * Subroutines
;;-
;;- ** ~unsigned int CONVERT_TEMPERATURE_FOR_CCS811(unsigned int)~ (in: r25:r24, out: r25:r24)
;;-    converts the temperature data in AM2302 format to CCS811 format.
;;-    The behavior for $T \lt -25\,{}^\circ\mathrm{C}$ is undefined.
;;-

CONVERT_TEMPERATURE_FOR_CCS811:
	;; check if T < 0
	sbrs	r25, 7
	rjmp	_CONV_TEMP_PLUS

	;; if T < 0
	andi	r25, 0x7f
	;; 2's complement
	com	r25
	com	r24
	subi	r24, -1
	sbci	r25, -1

_CONV_TEMP_PLUS:
	;; add offset 250 (= 25.0 degC)
	subi	r24, low(-250)
	sbci	r25, high(-250)

;;- ** ~unsigned int CONVERT_HUMIDITY_FOR_CCS811(unsigned int)~ (in: r25:r24, out: r25:r24)
;;-    converts the humidity data in AM2302 format to CCS811 format.
;;-

CONVERT_HUMIDITY_FOR_CCS811:
	push	r18

	rcall	_AC_div10	; [in] r25:r24, [out] r25:r24

	lsl	r25
	cpi	r24, 5
	brmi	_CONV_DEC1
	ori	r25, 1
	subi	r24, 5

_CONV_DEC1:
	tst	r24
	breq	_CONV_exit
	clr	r18

_CONV_DEC_loop:
	subi	r18, -0x33
	dec	r24
	brne	_CONV_DEC_loop
	mov	r24, r18

_CONV_exit:
	pop	r18
	ret


;;; r25:r24 (as a signed value) must >= 0, i.e. r25:r24 must be <= 0x7fff
;;; (_AC_div100: not used in this program)
_AC_div100:
	push	r19
	ldi	r19, 100
	rjmp	_AC_div_main

_AC_div10:
	push	r19
	ldi	r19, 10

_AC_div_main:
	push	r18
	clr	r18

_AC_div_loop:
	inc	r18
	sub	r24, r19
	sbci	r25, 0
	brpl	_AC_div_loop

	dec	r18
	add	r24, r19
	mov	r25, r18
	pop	r18
	pop	r19
	ret

;;-
;;- * See also
;;-   - [[../am2302/][am2302.asm]]
;;-   - [[../ccs811/][ccs811.asm]]
;;-
