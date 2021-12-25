;;; ccs811.asm
;;-
;;- A device driver of CCS811-Air quality sensor for AVR.
;;- This code is a part of [[../][pAVRlib]].
;;-
;;- * Requirement
;;- - [[../../twi-controller][twi-controller.asm]] (a part of pAVRlib)
;;- - [[../../wait][wait.asm]] (a part of pAVRlib)
;;-

#ifdef __GNUC__
.global read_am2302
#define __SFR_OFFSET 0
#include <avr/io.h>
#include "devices/ccs811.h"

#ifdef CCS811_USE_RESET
.global CCS811_RESET
#endif

.global CCS811_SEARCH
.global CCS811_INITIALIZE
.global CCS811_WRITE
.global CCS811_READ

#else

;;; CCS811 registers (bytes, direction)
.equ STATUS		= 0x00 ; 1 Read
.equ MEAS_MODE		= 0x01 ; 1 Read / Write
.equ ALG_RESULT_DATA	= 0x02 ; 8 Read
.equ RAW_DATA		= 0x03 ; 2 Read
.equ ENV_DATA		= 0x05 ; 4 Write
.equ THRESHOLDS		= 0x10 ; 5 Write
.equ BASELINE		= 0x11 ; 2 Read / Write
.equ HW_ID		= 0x20 ; 1 Read
.equ HW_VERSION		= 0x21 ; 1 Read
.equ FW_Boot_Version	= 0x23 ; 2 Read
.equ FW_App_Version	= 0x24 ; 2 Read
.equ ERROR_ID		= 0xe0 ; 1 Read
.equ APP_ERASE		= 0xf1 ; 4 Write
.equ APP_DATA		= 0xf2 ; 9 Write
.equ APP_VERIFY		= 0xf3 ; 0 Write
.equ APP_START		= 0xf4 ; 0 Write
.equ SW_RESET		= 0xff ; 4 Write

;;; STATUS (0x00)
.equ sFW_MODE		= 7
.equ sAPP_ERASE		= 6
.equ sAPP_VERIFY	= 5
.equ sAPP_VALID		= 4
.equ sDATA_READY	= 3
.equ sERROR		= 0

;;; MEAS_MODE (0x01)
.equ DRIVE_MODE_0	= (0<<4)
.equ DRIVE_MODE_1	= (1<<4)
.equ DRIVE_MODE_2	= (2<<4)
.equ DRIVE_MODE_3	= (3<<4)
.equ DRIVE_MODE_4	= (4<<4)
.equ INT_DATARDY	= (1<<3)
.equ INT_THRESH		= (1<<2)
;;; aliases of DRIVE_MODE
.equ DRIVE_MODE_IDLE	= (0<<4)
.equ DRIVE_MODE_1s	= (1<<4)
.equ DRIVE_MODE_10s	= (2<<4)
.equ DRIVE_MODE_60s	= (3<<4)
.equ DRIVE_MODE_250ms	= (4<<4)

;;; ERROR_ID (0xe0)
.equ MSG_INVALID	= (1<<5)
.equ READ_REG_INVALID	= (1<<4)
.equ MEASMODE_INVALID	= (1<<3)
.equ MAX_RESISTANCE	= (1<<2)
.equ HEATER_FAULT	= (1<<1)
.equ HEATER_SUPPLY	= (1<<0)

#endif


;;; ------------------------------------------------------------
;;- * Subroutines
;;-
;;- ** ~void CCS811_RESET()~ (in: (none), out: (none))
;;-   resets CCS811 (via nRESET).
;;-   To use this routine, you need to define ~CCS811_USE_RESET~.
;;-   To define the pin for nRESET, use ~CCS811_RESET_DDR~, ~CCS811_RESET_PORT~ and ~CCS811_RESET_PINNUM~.
;;-
;;-   For example, to use PB6-pin for nRESET:
;;- #+begin_src asm
;;-     .define CCS811_USE_RESET
;;-     .equ CCS811_RESET_DDR	= DDRB
;;-     .equ CCS811_RESET_PORT	= PORTB
;;-     .equ CCS811_RESET_PINNUM	= 6
;;- #+end_src
;;-


#ifdef CCS811_USE_RESET
CCS811_RESET:
	sbi	CCS811_RESET_DDR,  CCS811_RESET_PINNUM
	cbi	CCS811_RESET_PORT, CCS811_RESET_PINNUM
	rcall	Wait1ms		; > 15us
	sbi	CCS811_RESET_PORT, CCS811_RESET_PINNUM
	rcall	Wait1ms
	ret
#endif

;;; ------------------------------------------------------------
;;- ** ~char CCS811_SEARCH()~ (in: (none), out: r24)
;;-    This routine searches CCS811.
;;-    This routine returns
;;-    r24 <  0x80 (positive value as a signed char) as the address of CCS811, or
;;-    r24 >= 0x80 (negative value as a signed char) if CCS811 is not found.
;;-
;;- *** Known Issues
;;-    - Error handling of I2C is not complete.
;;-    - Only one device can be found.
;;-

CCS811_SEARCH:
	push	r0
	push	r17		; temporal
	ldi	r17, 0x81
	ldi	r24, 0x5b	; address to search

_CCS811_SEARCH:
	rcall	TWI_SEND_S
	rcall	TWI_SEND_SLA_R
	rcall	TWI_SEND_P

	cpi	r25, 0x40	; r25: TWI status
	brne	_CCS811_NEXT

	;; I2C device found.
	;; Now check HW_ID.
	ldi	r22, HW_ID
	ldi	r20, 1
	clr	r19
	ldi	r18, 0
	rcall	CCS811_READ

	cp	r0, r17
	breq	_CCS811_FIND_EXIT

_CCS811_NEXT:
	cpi	r24, 0x5a
	breq	_CCS811_NOT_FOUND
	dec	r24
	rjmp	_CCS811_SEARCH

_CCS811_NOT_FOUND:
	ldi	r24, 0xff

_CCS811_FIND_EXIT:
	pop	r17
	pop	r0
	ret

;;; ------------------------------------------------------------
;;- ** ~char CCS811_INITIALIZE(addr)~ (in: r24, out: r24)
;;-   initializes CCS811.
;;-   ~addr~ (r24) is a I2C-Address of CCS811.
;;-   It returns a status value (r24) as a result.
;;-
;;-   Initialize is succeeded if r24 = 0.
;;-   r24 = -1 (0xff) means "no valid application" (see datasheet of CCS811 for more details of "application").
;;-   r24 = -2 (0xfe) means "invalid firmware mode".
;;-

CCS811_INITIALIZE:
	push	r0
	push	r23

	;; read STATUS (0x00)
	ldi	r22, STATUS
	ldi	r20, 1
	clr	r19
	ldi	r18, 0
	rcall	CCS811_READ

	sbrc	r0, sAPP_VALID
	rjmp	_CCS811_INIT2

	;; no valid application
	ldi	r24, 0xff
	rjmp	_CCS811_INIT_EXIT

_CCS811_INIT2:
	;; entering in application mode by writing 0 bytes in register 0xf4.
	ldi	r22, APP_START
	ldi	r20, 0
	clr	r19
	ldi	r18, 0
	rcall	CCS811_WRITE

	rcall	Wait1ms

	;; read STATUS (0x00)
	ldi	r22, STATUS
	ldi	r20, 1
	clr	r19
	ldi	r18, 0
	rcall	CCS811_READ

	ldi	r24, 0
	sbrs	r0, sFW_MODE

	;; invalid firmware mode (not application mode)
	ldi	r24, 0xfe

_CCS811_INIT_EXIT:
	pop	r23
	pop	r0

	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned int CCS811_WRITE(char addr, char ccs811_reg, char bytes, char *data)~
;;-   writes data to CCS811.
;;-   For example, the data in r0, r1, ... will be sent if you call this routine with r19:r18 = 0,
;;-
;;- *** in
;;-
;;- |---------+----------------------------------|
;;- | r24     | I2C-Address of CCS811            |
;;- | r22     | Register of CCS811 to write      |
;;- | r20     | the number of bytes to write     |
;;- | r19:r18 | start address of data to be sent |
;;- |---------+----------------------------------|
;;-
;;- *** out
;;-
;;- |---------+------------------------------|
;;- | r25     | TWI status                   |
;;- | r24     | (unchanged)                  |
;;- |---------+------------------------------|
;;-

CCS811_WRITE:
	push	r31
	push	r30
	push	r24
	push	r20

	rcall	TWI_SEND_S

	;; send address
	rcall	TWI_SEND_SLA_W

	;; send register-address
	mov	r24, r22
	rcall	TWI_SEND

	;; send data
	mov	r31, r19
	mov	r30, r18

_CCS811_WRITE_loop:
	cpi	r20, 0
	breq	_CCS811_WRITE_EXIT

	ld	r24, Z+
	rcall	TWI_SEND

	dec	r20
	rjmp	_CCS811_WRITE_loop

_CCS811_WRITE_EXIT:
 	rcall	TWI_SEND_P

	pop	r20
	pop	r24
	pop	r30
	pop	r31

	ret

;;; ------------------------------------------------------------
;;- ** ~unsigned int CCS811_READ(char addr, char ccs811_reg, char bytes, char *data)~
;;-   reads data from CCS811.
;;-   For example, the received data will be stored in r0, r1, ... if you call this routine with r19:r18 = 0.
;;-
;;- *** in
;;-
;;- |---------+------------------------------------|
;;- | r24     | I2C-Address of CCS811              |
;;- | r22     | Register of CCS811 to read         |
;;- | r20     | the number of bytes to read        |
;;- | r19:r18 | start address of data to be stored |
;;- |---------+------------------------------------|
;;-
;;- *** out
;;-
;;- |---------+-----------------------------|
;;- | r25     | TWI status                  |
;;- | r24     | (unchanged)                 |
;;- |---------+-----------------------------|
;;-

CCS811_READ:
	push	r31
	push	r30
	push	r24
	push	r20

	rcall	TWI_SEND_S

	push	r24
	rcall	TWI_SEND_SLA_W

	mov	r24, r22
	rcall	TWI_SEND

	rcall	TWI_SEND_P
	pop	r24

	rcall	TWI_SEND_S
	rcall	TWI_SEND_SLA_R

	mov	r31, r19
	mov	r30, r18

_CCS811_READ_loop:
	;;  NACK if last
	cpi	r20, 1
	breq	_CCS811_NACK

	rcall	TWI_RECV_ACK
	rjmp	_CCS811_READ_store

_CCS811_NACK:
	rcall	TWI_RECV_NACK

_CCS811_READ_store:
	st	Z+, r24

	dec	r20
	breq	_CCS811_READ_EXIT

	rjmp	_CCS811_READ_loop

_CCS811_READ_EXIT:
 	rcall	TWI_SEND_P

	pop	r20
	pop	r24
	pop	r30
	pop	r31
	ret

;;-
;;- * See also
;;-
;;- - [[../am2302-ccs811][am2302-ccs811.asm]]
;;-

;;-
;;- * Examples
;;-
;;- The following programs reads data from CCS811 and show the received data.
;;-
;;- !see ../examples/ccs811-test.asm
;;-
;;- !see ../examples-C/ccs811-test.c
;;-
