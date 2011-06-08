;----------------------------------------------------------------------------------------------
; SERIAL CODE
;-----------------------------------------------------------------------------------------------

s_getblock

; Loads a block of 256 bytes to HL (L must be 0), and 2 extra bytes for CRC checksum
; Zero flag set = All OK. Zero flag not set = CRC error
; Carry flag is set = timed out

				ld c,0
				exx
				ld hl,0ffffh									; initial CRC checksum value
				exx
s_lgb			call receive_serial_byte
				ret c											; timed out if carry = 1	

				ld (hl),a
dwrbyte			call crc_calc
				inc hl											; hl = next dest address for data bytes
				dec c
				jr nz,s_lgb
				exx												; hl = calculated CRC

				call receive_serial_byte						; get 2 more bytes - block checksum in bc
				ret c	
				ld c,a
				call receive_serial_byte
				ret c		
				ld b,a
	
				xor a											; compare checksum
				sbc hl,bc
				exx												; put address back in HL before exit
				ret z

				xor a
				inc a											; Zero flag not set = CRC error
				ret

	
;-------------------------------------------------------------------------------------------


crc_calc
				exx
				xor h											; do CRC calculation from A, to 'HL		
				ld h,a				
				ld b,8
rxcrcbyte		add hl,hl
				jr nc,rxcrcnext
				ld a,h
				xor 10h
				ld h,a
				ld a,l
				xor 021h
				ld l,a
rxcrcnext		djnz rxcrcbyte
				exx
				ret

		
;--------------------------------------------------------------------------------------------


s_goodack		push de
				ld de,04f4bh								; send "OK" ack to host
				call send_serial_bytes
				pop de
				ret


;---------------------------------------------------------------------------------------------
		

receive_serial_byte

				push bc
				push de
				push hl

				ld e,16
				ld hl,0

com_lp			ld bc,UART0_LSR									; loop until a character been received..
				in a,(c)
				and 1											; bit 0 of UART0_LSR is 1 when a char is ready
				jr nz,in_buffer
				inc hl
				ld a,h
				or l
				jr nz,com_lp
				dec e
				jr nz,com_lp
				pop hl									
				pop de
				pop bc
				scf											; timed out	- set carry flag
				ret

in_buffer		ld bc,UART0_RBR
				in a,(c)									; read the character from buffer (read clears UART0_LSR [0])
				pop hl
				pop de
				pop bc
				or a										; clear carry flag
				ret
				
				
;------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

				push bc
				push de
				push hl

s_wait1			ld bc,UART0_LSR							; ensure no byte is still being transmitted
				in a,(c)
				and 020h
				jr z,s_wait1
				ld bc,UART0_THR
				out (c),d								; send first byte 
				
s_wait2			ld bc,UART0_LSR							; ensure no byte is still being transmitted
				in a,(c)
				and 020h
				jr z,s_wait2
				ld bc,UART0_THR
				out (c),e								;send second byte
		
				pop hl							
				pop de
				pop bc
				ret
				
;------------------------------------------------------------------------------------------------
