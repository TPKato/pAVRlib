;;; wait routines
;;- This program provides basic wait routines.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- In =examples/= and =examples-C/= you'll find small test programs.
;;-
;;- * Initialize
;;-
;;- Define =F_CPU=.
;;-
;;- #+NAME: init_wait
;;- #+BEGIN_SRC asm
;;- .equ F_CPU = XXXXXX	; system frequency in Hz
;;- #+END_SRC
;;-
;;- e.g.
;;- #+NAME: init_wait_example
;;- #+BEGIN_SRC asm
;;- .equ F_CPU = 1000000	; in case of f = 1 MHz
;;- #+END_SRC
;;-
;;- ~F_CPU~ > 30 MHz is not supported (yet).
;;-
;;- * Subroutines
;;-
;;- These routines are not so exact (ca. 1-2 % error).
;;- Use timer if you need exact delays.
;;-
;;- ** ~void Wait1ms()~ (in: (none), out: (none))
;;-    wait ca. 1 ms
;;-
;;- ** ~void Waitms(unsigned char)~ (in: r24, out: (none))
;;-    wait ca. /n/ ms (/n/ = r24)
;;-
;;- ** ~void Waitmsint(unsigned int)~ (in: r25:r24, out: (none))
;;-    wait ca. /n/ ms (/n/ = r25:r24)
;;-
;;- ** ~void Wait1sec()~ (in: (none), out: (none))
;;-    wait ca. 1 s
;;-
;;- ** ~void Waitsec(unsigned char)~ (in: r24, out: (none))
;;-    wait ca. /n/ s (/n/ = r24)
;;-
;;- * Example
;;-
;;- To wait 5 seconds, use:
;;-
;;- #+NAME: example1
;;- #+BEGIN_SRC asm
;;-	ldi	r24, 5
;;- 	rcall	Waitsec
;;- #+END_SRC
;;-

;;- * Using with GCC
;;-
;;- *This program can be used with GCC, but it is recommended to use
;;- [[https://www.nongnu.org/avr-libc/user-manual/group__util__delay.html][the standard library]].*
;;-
;;- See =examples-C/wait-test.c=.

#ifdef __GNUC__
#define __SFR_OFFSET 0
#define low(x) lo8(x)
#define high(x) hi8(x)

.global	Wait1ms
.global Waitms
.global Waitmsint
.global Wait1sec
.global Waitsec
#else
.ifndef	F_CPU
.error "Specify a frequency of the system clock (F_CPU)."
.endif
#endif

Waitms:
	push	r24
_waitms_loop:
	rcall	Wait1ms
	dec	r24
	brne	_waitms_loop
	pop	r24
	ret

Waitmsint:
	push	r25
	push	r24
	subi	r24, 1
	sbci	r25, 0
_waitms_loop_int:
	rcall	Wait1ms
	subi	r24, 1
	sbci	r25, 0
	brpl	_waitms_loop_int
	pop	r24
	pop	r25
	ret

Waitsec:
	push	r24
_waitsec_loop:
	rcall	Wait1sec
	dec	r24
	brne	_waitsec_loop
	pop	r24
	ret

Wait1sec:
 	push	r25
 	push	r24
 	ldi	r25, high(1000)
 	ldi	r24, low(1000)
 	rcall	Waitmsint
 	pop	r24
 	pop	r25
 	ret


#ifdef __GNUC__
#if F_CPU < 7000000
#define	_waitus 100
#elif F_CPU < 15000000
#define _waitus 50
#elif F_CPU <= 30000000
#define _waitus 25
#else
#error "F_CPU > 30MHz is not supported yet."
#endif
#else
.if F_CPU < 7000000
.define	_waitus 100
.elif F_CPU < 15000000
.define _waitus 50
.elif F_CPU <= 30000000
.define _waitus 25
.else
.error "F_CPU > 30MHz is not supported yet."
.endif
#endif

Wait1ms:
	push	r16		; 2 clk
	ldi	r16, 1000 / _waitus ; 1clk
_w1ms:
	rcall	_wus		; 3 clk (or 4 clk)
	dec	r16		; 1 clk
	brne	_w1ms		; 2 clk (if true) / 1 clk (if false)

	pop	r16		; 2 clk
	ret			; 4 clk

_wus:
	push	r16		; 2 clk
	ldi	r16, (_waitus * F_CPU / 1000000 - 8 + 2) / 3 ; (*1)
				; 1 clk
				; +2 to round up

_wus_loop:
	dec	r16		; 1 clk
	brne	_wus_loop	; 2 clk (if true) / 1 clk (if false)
	pop	r16		; 2 clk
	ret			; 4 clk


;;; Note: The value of r16 at (*1)
;;;       (in case of _waitus = 100)
;;;   3 + (3 * r16 - 1) + 6 = 100 * (F_CPU / 1 MHz)
;;;   |    |              |   ~~~~~~~~~~~~~~~~~~~~~ = 100us
;;;   |    dec/brne       pop/ret
;;;   push/ldi
;;;
;;;   n =  30.667 @  1 MHz
;;;   n =  64     @  2 MHz
;;;   n = 130.667 @  4 MHz
