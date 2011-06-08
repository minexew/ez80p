;--------------------------------------------------------------------------------------------
; ez80p low level RS232 code v0.03 (ADL mode)
;---------------------------------------------------------------------------------------------
		
receive_serial_byte

; If zero flag set on return OK, A = received byte
; Else timed out (and also A = error $83: time out)

				push bc
				ld a,(serial_timeout)
				ld b,a
rx_set_timer	ld a,cch
				out0 (TMR0_RR_L),a						; set timer count to 3276 ticks (0.1 second)
				ld a,0ch
				out0 (TMR0_RR_H),a						
				ld a,00000011b							
				out0 (TMR0_CTL),a						; enable and start timer 0 (prescale apparently ignored for RTC)
				in0 a,(TMR0_CTL)						; ensure count complete flag is clear
				
rx_byte_lp		ld c,UART0_LSR							; loop until a byte has been received..
				tstio 1									; bit 0 of UART0_LSR is 1 when a char is ready
				jr nz,rx_in_buffer
				xor a
				or b
				jr z,rx_time_out
				ld c,TMR0_CTL	
				tstio 128								; bit 7 = countdown completed flag
				jr z,rx_byte_lp		
				dec b
				jr rx_set_timer

rx_in_buffer	ld bc,UART0_RBR
				in a,(bc)								; read the character from buffer (read clears UART0_LSR [0])
				pop bc
				cp a									; set ZF, no error
				ret

rx_time_out		pop bc
				ld a,083h								; A = $83 = timed out error
				or a									; ZF IS NOT SET
				ret



;------------------------------------------------------------------------------------------------

send_serial_byte

; set A to the byte to send

				push bc
				ld c,UART0_LSR							; ensure no byte is still being transmitted
rs232_swait		tstio 020h								; bit 5 = serializer busy
				jr z,rs232_swait
				ld bc,UART0_THR
				out (c),a								; send  byte 
				pop bc
				ret

;--------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

				ld a,d
				call send_serial_byte
				ld a,e
				call send_serial_byte
				ret

;-------------------------------------------------------------------------------------------------

hwsc_flush_serial_buffer

				push bc
				ld bc,UART0_RBR
				in a,(bc)								; read the character from buffer (read clears UART0_LSR [0])
				pop bc
				ret

;-------------------------------------------------------------------------------------------------
		