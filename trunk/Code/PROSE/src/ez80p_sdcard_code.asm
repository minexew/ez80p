;---------------------------------------------------------------------------------------------
; eZ80P Specific SD card low-level routines v1.10 (ADL mode)
;----------------------------------------------------------------------------------------------

sd_send_byte

;Put byte to send to card in A

					out0 (port_sdc_data),a
					nop
					nop
sd_wb_loop			tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wb_loop					; ie: test bit in port (c)
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
					ld b,0								; loop count
					ld c,port_hw_flags
					
					out0 (port_sdc_data),e				; send out 8 clocks for first byte
					nop									; just to ensure serial busy latch is set
					nop									; ""
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

					ld b,0
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
					ld a,80h+(1<<sdc_power)+(1<<sdc_cs)		; bit 7 = set bits high / sdc power / cs bits selected
					jr sd_wr_sdc_ctrl						; CS: inactive, Power: ON


sd_power_off		push af
					ld a,00h+(1<<sdc_power)+(1<<sdc_cs)		; bit 7 = reset bits: sdc power and cs
					jr sd_wr_sdc_ctrl


sd_spi_port_fast	push af
					ld a,80h+(1<<sdc_speed)					; bit 7 = set bits: sdc speed
					jr sd_wr_sdc_ctrl


;---------------------------------------------------------------------------------------------
