;---------------------------------------------------------------------------------------------
; eZ80P Specific SD card low-level routines v0.02 (ADL mode)
;----------------------------------------------------------------------------------------------

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
