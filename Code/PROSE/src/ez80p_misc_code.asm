;-------------------------------------------------
;Misc eZ80p specific routines v0.05 (ADL version)
;-------------------------------------------------

hwsc_default_hw_settings

; Set up eZ80 Wait states

					ld a,01001000b					; Set CS0 = 2 wait states/for memory/enabled
					out0 (CS0_CTL),a
					ld a,000h						; default memory range for CS0 (entire 16MB)
					out0 (CS0_LBR),a
					ld a,0ffh	
					out0 (CS0_UBR),a				; default memory range for CS0 (entire 16MB)

					ld a,01011000b
					out0 (CS1_CTL),a				; set CS1 = 2 wait states / for IO ports/enabled					
					ld a,0
					out0 (CS1_LBR),a				; set CS1 applicable to IO port range $0000-$007f

;set up eZ80 GPIO ports

					ld a,0ffh
					out0 (PC_DDR),a					; set eZ80 GPIO port C [7:0] (joy directions) to inputs mode (mode 2)	
					xor a
					out0 (PC_ALT1),a
					out0 (PC_ALT2),a
					
					ld a,0ffh						; set eZ80 GPIO port D [7:4] (joy fire buttons) to inputs (mode 2)
					out0 (PD_DDR),a					; and [3:0] to mode 7 (peripheral control: UART)
					xor a	
					out0 (PD_ALT1),a					
					ld a,00fh				
					out0 (PD_ALT2),a				;PD0 = UART0_TX, PD1 = UART0_RX, PD2 = UART0_RTS, PD3 = UART0_CTS					

;set up eZ80 timer

					in0 a,(TMR_ISS)
					and 11111100b
					or  00000001b
					out0 (TMR_ISS),a				; timer 0 to use the RTC as source clock (32768 Hz)
					
					
;AMOEBA default settings

					xor a
					ld (hw_audio_registers+3),a		; Disable audio playback

					ret

;-----------------------------------------------------------------------------------------------

hwsc_get_version	ld de,0
					ld b,16
gethwvlp			ld a,b
					dec a
					out0 (port_selector),a			;set address of ID bit
					in a,(port_hw_flags)			;ID bit read into bit 7
					sla a
					rl e
					rl d
					djnz gethwvlp					;DE = h/w version
									
					ld hl,prose_version
					cp a							;returns with zero flag set, no error
					ret



;---------------------------------------------------------------------------------------------
; Timer related 
;---------------------------------------------------------------------------------------------

hwsc_time_delay

; set DE to 32768Hz ticks to wait

					call set_timeout
twaitlp				call test_timeout
					jr z,twaitlp
					xor a							; zero flag set, no error
					ret			

;---------------------------------------------------------------------------------------------

set_timeout			ld a,e							
					out0 (TMR0_RR_L),a				; set count value lo
					ld a,d
					out0 (TMR0_RR_H),a				; set count value hi
					ld a,00000011b							
					out0 (TMR0_CTL),a				; enable and start timer 0 (prescale apparently ignored for RTC)
					in0 a,(TMR0_CTL)				; ensure count complete flag is clear
					ret
			
test_timeout		in0 a,(TMR0_CTL)				; bit 7 set if timed out				
					bit 7,a
					ret
			
;-----------------------------------------------------------------------------------------------

hwsc_read_rtc
					push de
					push bc
hwsc_rtc_rlp		ld c,RTC_SEC
					ld b,8
					ld hl,time_data
					inimr									; read ports E0->E7 to HL to HL+7
					ld c,RTC_SEC
					ld b,0
					ld e,8
					ld hl,time_data
timevloop			in a,(bc)								; now read the ports again making sure the
					cp (hl)									; values are the same, this prevents mid-read roll-overs
					jr nz,hwsc_rtc_rlp						; causing problems.
					inc hl
					inc c
					dec e
					jr nz,timevloop
					ld hl,time_data
					pop bc
					pop de
					cp a									; set zero flag, no error
					ret


hwsc_write_rtc	

; set HL to location of BCD data for RTC: sec/min/hr/dow/date/mon/year/cent

					push hl
					push bc
					ld a,00100001b						; unlock RTC / BCD mode
					out0 (RTC_CTRL),a
					ld c,RTC_SEC
					ld b,8
					otimr
					ld a,00100000b						; lock RTC / BCD mode
					out0 (RTC_CTRL),a
					pop bc
					pop hl
					cp a								; set zero flag, no error
					ret	


;----------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;----------------------------------------------------------------------------------------------

reset_keyboard

; If on return carry flag is set, keyboard init failed

			ld a,0001b						; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,8							; wait 250 microseconds
			call hwsc_time_delay
						
			ld a,0011b
			out0 (port_ps2_ctrl),a			; pull data line low 
			ld a,0010b
			out0 (port_ps2_ctrl),a			; release clock line

			ld l,9							; 8 data bits + 1 parity bit	
kb_byte		call wait_kb_clk_low	
			ret c
			xor a
			out0 (port_ps2_ctrl),a			; KB data line = 1 (command = $FF)
			call wait_kb_clk_high
			ret c
			dec l
			jr nz,kb_byte

			call wait_kb_clk_low			; wait for keyboard to pull clock low (ack)	
			ret c
			call wait_kb_data_low			; wait for keyboard to pull data low (ack)
			ret c
			call wait_kb_clk_high			; wait for keyboard to release data and clock
			ret c
			call wait_kb_data_high
			ret c

			xor a
			ret
			


wait_kb_clk_low

			ld a,1
			jr ps2_test_lo

wait_kb_data_low
		
			ld a,2

ps2_test_lo	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_lw		ld b,4							; must be steady for a few loops (noise immunity)
kb_lnlp		call test_timeout				; timer reached zero?
			jr z,kb_lnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
kb_lnto		in0 a,(port_ps2_ctrl)
			and c
			jr nz,kb_lw
			djnz kb_lnlp		
			pop de
			pop bc
			xor a
			ret								; carry clear = op was ok


wait_kb_clk_high

			ld a,1
			jr ps2_test_hi

wait_kb_data_high
		
			ld a,2
			
ps2_test_hi	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_hw		ld b,4							; must be steady for a few loops (noise immunity)
kb_hnlp		call test_timeout				; timer reached zero?
			jr z,kb_hnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
kb_hnto		in0 a,(port_ps2_ctrl)
			and c
			jr z,kb_hw
			djnz kb_hnlp		
			pop de
			pop bc
			xor a							; carry clear = op was ok
			ret


;-----------------------------------------------------------------------------------------------

purge_keyboard
			
			in0 a,(port_ps2_ctrl)
			bit 4,a
			ret z
			in0 a,(port_keyboard_data)				;read the keyboard port to purge buffer
			jr purge_keyboard

;-----------------------------------------------------------------------------------------------

reset_mouse
			
			call mouse_init
			ret nc
			ld a,08ah								;device not detected error
			or a
			ret


mouse_init			

; Returns with carry flag set if mouse did not initialize

			ld a,00000010b
			out0 (port_irq_ctrl),a					;disable mouse interrupts

			ld a,3
			ld (mouse_packet_size),a
			xor a
			ld (mouse_id),a
			

			ld a,0ffh								;send "reset" command to mouse
			call write_to_mouse_absorb_loopback		
			ret c
			ld b,5
ms_initlp	push bc
			call wait_mouse_byte					;wait for response $AA = Self test complete
			pop bc
			ret c
			cp 0aah
			jr z,ms_postok
			djnz ms_initlp
			jr bad_mouse
			
ms_postok	call wait_mouse_byte					;response = Mouse ID ($00 if standard mouse)
			ret c
			or a
			jr nz,bad_mouse							;error return if not standard mouse
			
			
			ld a,0f3h								;attempt to activate (Intellimouse) wheel with special sequence
			call write_to_mouse_absorb_loopback		;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,200								;srate = 200
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c
			
			ld a,0f3h
			call write_to_mouse_absorb_loopback		;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,100								;srate = 100 
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f3h
			call write_to_mouse_absorb_loopback		;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,80									;srate = 80 
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f2h
			call write_to_mouse_absorb_loopback		;send "get device type"
			ret c
			call wait_mouse_byte					;response should be FA: ACK
			ret c
			call wait_mouse_byte					;response = 03 if intellimouse (scroll wheel mouse)
			ret c
			ld (mouse_id),a
			or a									;response = 00 if standard mouse
			jr z,standard_mouse
			cp 3
			jr nz,bad_mouse							;if not 00 or 03, mouse is not supported
			ld a,4
			ld (mouse_packet_size),a

standard_mouse

			ld a,0e8h								;send "set resolution"
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,(mouse_resolution)				 
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c
	
			ld a,(mouse_scaling)					;send "set scaling" - no args, command is e6 or e7
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
				
			ld a,0f3h								;send "set sample rate"
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,(mouse_sample_rate)				 
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f4h								;send "enable data reporting" command to mouse
			call write_to_mouse_absorb_loopback
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			xor a									;zero flag set, mouse initialized OK
			ret

bad_mouse	ld a,089h								;unsupported device error
			or a
			ret



write_to_mouse_absorb_loopback
			
			call write_to_mouse
			ret c
			call wait_mouse_byte					;same byte written is looped back to input buffer
			ret
			
;-----------------------------------------------------------------------------------------------
				
write_to_mouse

; Put byte to send to mouse in A

			ld c,a								; copy output byte to c
			ld a,0100b							; pull clock line low
			out0 (port_ps2_ctrl),a
			ld de,8
			call hwsc_time_delay				; wait ~100 microseconds
			ld a,1100b
			out0 (port_ps2_ctrl),a				; pull data line low also
			ld a,1000b
			out0 (port_ps2_ctrl),a				; release clock line
			
			ld d,1								; initial parity count
			ld b,8								; loop for 8 bits of data
mdoloop		call wait_mouse_clk_low	
			ret c
			xor a
			set 3,a
			bit 0,c
			jr z,mdbzero
			res 3,a
			inc d
mdbzero		out0 (port_ps2_ctrl),a				; set data line according to output byte
			call wait_mouse_clk_high
			ret c
			rr c
			djnz mdoloop

			call wait_mouse_clk_low
			ret c
			xor a
			bit 0,d
			jr nz,parone
			set 3,a
parone		out0 (port_ps2_ctrl),a				; set data line according to parity of byte
			call wait_mouse_clk_high
			ret c
			
			call wait_mouse_clk_low
			ret c
			xor a
			out0 (port_ps2_ctrl),a				; release data line

			call wait_mouse_data_low			; wait for mouse to pull data low (ack)
			ret c
			call wait_mouse_clk_low				; wait for mouse to pull clock low
			ret c
				
			call wait_mouse_data_high			; wait for mouse to release data
			ret c
			call wait_mouse_clk_high			; wait for mouse to release clock
			ret 

;-----------------------------------------------------------------------------------------------


wait_mouse_byte

			ld de,8000h
			call set_timeout					; Allow 1 second for mouse response

wait_mloop	in0 a,(port_ps2_ctrl)
			bit 5,a
			jr nz,rec_mbyte
			
			call test_timeout
			jr z,wait_mloop
			scf									; carry flag set = timed out
			ret
			
rec_mbyte	in0 a,(port_mouse_data)				; get byte sent by mouse
			or a
			ret
			
;-----------------------------------------------------------------------------------------------

wait_mouse_clk_low

			ld a,4
			jp ps2_test_lo

wait_mouse_data_low
		
			ld a,8
			jp ps2_test_lo	

wait_mouse_clk_high

			ld a,4
			jp ps2_test_hi

wait_mouse_data_high
		
			ld a,8
			jp ps2_test_hi			
			

;-----------------------------------------------------------------------------------------------

purge_mouse	in0 a,(port_ps2_ctrl)
			bit 5,a
			ret z
			in0 a,(port_mouse_data)					;read the mouse port to purge buffer
			jr purge_mouse

;-----------------------------------------------------------------------------------------------
