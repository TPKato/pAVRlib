;;; usart-puthex.asm
;;;
;;- a small subroutine to print a hexadecimal value via USART.
;;- This code is a part of [[../][pAVRlib]].
;;- 
;;- * Requirement
;;-   - [[../usart][usart.asm]]
;;-   - [[../bin2ascii][bin2ascii.asm]]
;;-
;;- * Subroutine
;;- 
;;- ** ~void USART_HEX(char)~ (in: r24, out: (none))
;;-    send the value of r24 as a hexadecimal value (two ASCII characters) via USART.
;;- 

USART_PUTHEX:
	push	r24
	rcall	B2AH
	rcall	USART_TRANSMIT
	pop	r24
	push	r24
	rcall	B2AL
	rcall	USART_TRANSMIT
	pop	r24

	ret
