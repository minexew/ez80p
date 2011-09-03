;---------------------------------------------------------------------------------------------
; eZ80P Specific SD card low-level routines v1.10 (ADL mode)
;----------------------------------------------------------------------------------------------

sd_send_byte

;Put byte to send to card in A

					out0 (port_sdc_data),a
					push bc
					ld c,port_hw_flags
sd_wb_loop			tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wb_loop					; ie: test bit in port (c)
					pop bc
					ret

;---------------------------------------------------------------------------------------------

sd_get_byte

; Returns byte read from card in A

					call sd_send_eight_clocks
					in0 a,(port_sdc_data)
					ret

;---------------------------------------------------------------------------------------------

sd_read_513_bytes

; optimized sector read
; set hl = dest location for bytes
; note: The last byte read (CRC) is not put into memory

					push bc
					push de
					ld e,0ffh
					out0 (port_sdc_data),e				; send out 8 clocks for first byte
					ld c,port_hw_flags					; port for tstio instructions		
					ld b,0								; loop count

sd_wser_loop1		tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wser_loop1					; ie: test bit in port (c)
					in a,(port_sdc_data)				; get first byte
					
sd_512_loop			out0 (port_sdc_data),e				; send 8 clocks to serializer
					ld (hl),a							; put previously read byte into memory
					inc hl								; next memory location
					
sd_wser_loop2		tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wser_loop2					; ie: test bit in port (c)
					in a,(port_sdc_data)				; read the contents of the shift register
																
					out0 (port_sdc_data),e				; send 8 clocks to serializer
					ld (hl),a							; put previously read byte into memory
					inc hl								; next memory location	
					
sd_wser_loop3		tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wser_loop3					; ie: test bit in port (c)
					in a,(port_sdc_data)				; read the contents of the shift register
					
					djnz sd_512_loop
					pop de
					pop bc
					ret
					
;------------------------------------------------------------------------------------------------
					
sd_write_512_bytes

;optimized sector write
;set hl = source location for bytes

					ld c,port_hw_flags					; port for tstio instructions
					ld b,0								; loop count
					ld a,(hl)
sd_wr512_loop		out0 (port_sdc_data),a
					inc hl
					ld a,(hl)
sd_wser_loop4		tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wser_loop4			
					out0 (port_sdc_data),a
					inc hl
					ld a,(hl)
sd_wser_loop5		tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wser_loop5
					djnz sd_wr512_loop
					ret

			
;---------------------------------------------------------------------------------------------
; SD Card control
;---------------------------------------------------------------------------------------------

sd_select_card		push af
					ld a,00h+(1<<sdc_cs)					; set card /CS low
sd_wr_sdc_ctrl		out0 (port_sdc_ctrl),a
					pop af
					ret


sd_deselect_card	push af
					ld a,080h+(1<<sdc_cs)					; set card /CS high
					out0 (port_sdc_ctrl),a
					call sd_send_eight_clocks				; send 8 clocks to make card de-assert its D_out line
					pop af
					ret


sd_power_on			push af
					ld a,(1<<sdc_speed)						; bit 7 = set bits low / sdc speed bit selected
					out0 (port_sdc_ctrl),a					; SPEED = LOW
					ld a,80h+(1<<sdc_power)+(1<<sdc_cs)		; bit 7 = set bits high:  sdc power, cs
					jr sd_wr_sdc_ctrl						; CS: inactive, Power: ON


sd_power_off		push af
					ld a,00h+(1<<sdc_power)+(1<<sdc_cs)		; bit 7 = reset bits: sdc power (cs automatically
					jr sd_wr_sdc_ctrl						; pulled low by AMOEBA when card power is off)


sd_spi_port_fast	push af
					ld a,80h+(1<<sdc_speed)					; bit 7 = set bits: sdc speed
					jr sd_wr_sdc_ctrl


;---------------------------------------------------------------------------------------------








;---------------------------------------------------------------------------------------------
;old code only required if using pre v110 routines
;---------------------------------------------------------------------------------------------

sdc_select_card
	
					push bc
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_cs						;set card /CS low
					out (bc),a
					pop bc
					ret


sdc_deselect_card

					push bc
					ld bc,port_sdc_ctrl
					ld a,080h+(1<<sdc_cs)			;set card /CS high
					out (bc),a
					pop bc
				
					ld a,0ffh							; send 8 clocks to make card de-assert its D_out line
					call sdc_send_byte
					ret
	
;---------------------------------------------------------------------------------------------

sdc_power_on

					push bc
					ld bc,port_sdc_ctrl
					ld a,80h+(1<<sdc_power)			;bit 7 = set bits high / sdc power bit selected
					out (bc),a
					pop bc
					ret
	

sdc_power_off
	
					push bc							
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_power					;bit 7 = set bits low / sdc power bit selected
					out (bc),a							;switch power to card off (set line low) - the fpga
					pop bc								;logic automatically pulls /CS and Din low so as not to
					ret									;supply any other current to the card (clock will be low too).
	

;----------------------------------------------------------------------------------------------

sdc_slow_clock

					push bc
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_speed					;bit 7 = set bits low / sdc speed bit selected
					out (bc),a
					pop bc
					ret


sdc_fast_clock
	
					push bc
					ld bc,port_sdc_ctrl
					ld a,080h+(1<<sdc_speed)			;bit 7 = set bits high / sdc speed bit selected
					out (bc),a
					pop bc
					ret

;------------------------------------------------------------------------------------------------


sdc_send_byte

;Put byte to send to card in A

					push bc
					ld bc,port_sdc_data
					out (bc),a							; send byte to serializer
	
					ld c,port_hw_flags					; wait for serialization to end
sdc_wb_loop			tstio 1<<sdc_serializer_busy		; ie: test bit in port (c)
					jr nz,sdc_wb_loop

					pop bc
					ret

;---------------------------------------------------------------------------------------------

sdc_get_byte

; Returns byte read from card in A

					ld a,0ffh
					call sdc_send_byte
					push bc
					ld bc,port_sdc_data
					in a,(bc)							; read the contents of the shift register
					pop bc
					ret
	
;---------------------------------------------------------------------------------------------

sdc_send_eight_clocks

				ld a,0ffh
				call sdc_send_byte
				ret

;---------------------------------------------------------------------------------------------

sdc_send_command

; set A = command, C:DE for sector number, B for CRC

				push af				
				call sdc_send_eight_clocks			; send 8 clocks first - seems necessary for SD cards..
				pop af

				call sdc_send_byte					; command byte
				ld a,c								; then 4 bytes of address [31:0]
				call sdc_send_byte
				ld a,d
				call sdc_send_byte
				ld a,e
				call sdc_send_byte
				ld a,0
				call sdc_send_byte
				ld a,b								; finally CRC byte
				call sdc_send_byte
				ret

;---------------------------------------------------------------------------------------------

sdc_wait_ncr
	
				push bc
				ld bc,0
sdc_wncrl		call sdc_get_byte					; read until valid response from card (skip NCR)
				bit 7,a								; If bit 7 = 0, its a valid response
				jr z,sdc_gcr
				dec bc
			 	ld a,b
				or c
				jr nz,sdc_wncrl
sdc_gcr			pop bc
				ret
	
;---------------------------------------------------------------------------------------------
