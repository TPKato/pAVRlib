;;; usart-puts.asm
;;;
;;- This program provides a small subroutine to put a string via USART.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- In =examples/= you'll find a small test program.
;;-
;;- * Requirement
;;-
;;-   - [[../usart][usart.asm]]
;;-
;;- * Subroutine
;;-
;;- ** ~void USART_PUTS(char *str)~ (in: r25:r24, out: (none))
;;-    puts a string via USART.
;;-    r25:r24 is a start address of the string to be sent.
;;-    The string must be null-teminated.
;;-
;;- * Example
;;-
;;- #+NAME: example
;;- #+BEGIN_SRC asm
;;-	ldi	r25, high(STR_HELLO)
;;-	ldi	r24, low (STR_HELLO)
;;-	rcall	USART_PUTS
;;-
;;- STR_HELLO:
;;-	.db	"Hello, World!", 0x0d, 0x0a, 0
;;- #+END_SRC
;;-

USART_PUTS:
	push	r24
	push	r31
	push	r30

	mov	r31, r25
	mov	r30, r24
	lsl	r30
	rol	r31

_put_string_loop:
	lpm	r24, Z+
	tst	r24
	breq	_put_string_exit
	rcall	USART_TRANSMIT
	rjmp	_put_string_loop

_put_string_exit:
	pop	r30
	pop	r31
	pop	r24

	ret
