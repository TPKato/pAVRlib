;;; bin2ascii.asm
;;- converts a value to ascii code.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- * Subroutines
;;-
;;- ** ~char B2AH(char val)~ (in: r24, out: r24)
;;-    converts the upper nibble of r24 to ASCII code.
;;-    The next code will result '4' (0x34).
;;-
;;- #+NAME: example_B2AH
;;- #+BEGIN_SRC asm
;;-	ldi	r24, 0x4f
;;-	rcall	B2AH
;;- #+END_SRC
;;-
;;- ** ~char B2AL(char val)~ (in: r24, out: r24)
;;-    converts the lower nibble of r24 to ASCII code.
;;-    The next code will result 'F' (0x46).
;;-
;;- #+NAME: example_B2AH
;;- #+BEGIN_SRC asm
;;-	ldi	r24, 0x4f
;;-	rcall	B2AL
;;- #+END_SRC
;;-
;;- * Example
;;-
;;- This program requires [[../usart][~usart.asm~]].
;;- (See also: [[../usart-puthex][~usart-puthex.asm~]])
;;-
;;- #+NAME: example
;;- #+BEGIN_SRC asm
;;-	ldi 	r24, 0x4f
;;-
;;-	push	r24
;;-	rcall	B2AH
;;-	rcall	USART_TRANSMIT
;;-	pop	r24
;;-
;;-	;; push and pop can be omitted if you don't
;;-	;; need to preserve the value of r24
;;-	push	r24
;;-	rcall	B2AL
;;-	rcall	USART_TRANSMIT
;;-	pop	r24
;;- #+END_SRC

#ifdef __GNUC__
.global B2AH
.global B2AL
#endif

B2AH:
	swap	r24
B2AL:
	andi	r24, 0x0f
	cpi	r24, 0x0a
	brlo	_B2A_NUM
_B2A_ALPHA:
	subi	r24, -0x07		; 'A' - '0' - 0x0a
_B2A_NUM:
	subi	r24, -0x30		; '0'
	ret
