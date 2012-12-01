;----------------------------------
;Misc eZ80p specific routines v0.07
;----------------------------------

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
					
					xor a
					ret


;-----------------------------------------------------------------------------------------------

hwsc_reset_sprites	xor a
					ld (sprite_control),a			; Disable sprites globally
					ld a,4
					ld (sprite_gen_stop_pos),a		; use 32 registers
					
					ld hl,hw_sprite_registers		; also zero all registers
					ld bc,2048
					xor a
					call os_bchl_memfill
					ret
					
;-----------------------------------------------------------------------------------------------


hwsc_update_pointer_sprite
					
					ld a,(os_pointer_enable)			; dont write to sprite registers if pointer not enabled
					and 1
					ret z

					push ix
					ld ix,hw_sprite_registers+(31*8)	; use sprite 31 for pointer
					ld hl,(mouse_abs_x)
					ld bc,x_display_offset
					add hl,bc
					ld (ix),l
					ld (ix+1),h
					ld hl,(mouse_abs_y)
					ld bc,y_display_offset
					add hl,bc
					ld (ix+2),l
					ld (ix+3),h
					ld bc,(os_pointer_height)
					ld (ix+4),c
					ld (ix+5),b
					ld bc,(os_pointer_definition)
					ld (ix+6),c
					ld (ix+7),b
					pop ix
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
; Timer0 related 
;---------------------------------------------------------------------------------------------

hwsc_time_delay

; set DE to 32768Hz ticks to wait

					call hwsc_set_timeout
twaitlp				call hwsc_test_timeout
					jr z,twaitlp
					xor a							; zero flag set, no error
					ret			

;---------------------------------------------------------------------------------------------

; Set DE to 32768 Hz ticks to allow before timeout flag becomes set

hwsc_set_timeout	ld a,e							
					out0 (TMR0_RR_L),a				; set count value lo
					ld a,d
					out0 (TMR0_RR_H),a				; set count value hi
					ld a,00000011b							
					out0 (TMR0_CTL),a				; enable and start timer 0 (prescale apparently ignored for RTC)
					in0 a,(TMR0_CTL)				; ensure count complete flag is clear
					ret
			
hwsc_test_timeout	in0 a,(TMR0_CTL)				; bit 7 set if timed out				
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

;---------------------------------------------------------------------------------------------
; Timer1 related 
;---------------------------------------------------------------------------------------------

os_init_msec_counter

; set E = 1 enable, E = 0 disable

; 1 tick = 50MHz/4, EG:  Reload value = 12500, IRQ period = 0.001 seconds
			
				push hl

				xor a
				out0 (TMR1_CTL),a				;disable timer1
				
				bit 0,e
				jr z,disable_tmr1
				
				ld hl,prt1_irq_handler
				ld (074h),hl
				
				in0 a,(TMR_ISS)
				and 11110011b
				out0 (TMR_ISS),a
				
				ld hl,30d4h
				out0 (TMR1_RR_H),h
				out0 (TMR1_RR_L),l

				ld hl,0
				ld (seconds_counter),hl
				ld (milliseconds_counter),hl

				ld a,01010011b
				out0 (TMR1_CTL),a				;enable timer1
			
disable_tmr1	pop hl
				xor a
				ret



os_read_msec_counter
			
			di
			ld de,(milliseconds_counter)
			ld hl,(seconds_counter)
			ei
			xor a
			ret
			

;----------------------------------------------------------------------------------------------
; INIT KEYBOARD ROUTINE 
;----------------------------------------------------------------------------------------------

; ZF set and A = 0 if all OK, else error code in A

init_keyboard

			ld de,16384								; wait for any scancodes to cease
			call hwsc_time_delay
			di
			call purge_keyboard
			call rs_keyboard
			ei
			ret nc
			ld a,08bh								; "device error" 
			or a
			ret
			
			
rs_keyboard

			ld a,0ffh
			call write_to_keyboard
			jr nc,kb_connected
			ld a,08ah							;no keyboard ("device not detected") error
			or a
			ret

kb_connected
			
			ld b,5
kb_initlp	push bc
			call wait_kb_byte					;wait for response $AA = Self test complete
			pop bc
			ret c
			cp 0aah
			jr z,kb_postok
			djnz kb_initlp						
			scf									;force "device error" if no POST OK returned
			ret
			
			
kb_postok	xor a
			ret
	
	
;-----------------------------------------------------------------------------------------------
				
write_to_keyboard

; Put byte to send to keyboard in A

			ld c,a								; copy output byte to c
			ld a,01b							; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,10
			call hwsc_time_delay				; wait at least 100 microseconds

			ld a,11b
			out0 (port_ps2_ctrl),a				; pull data line low also
			
			ld a,10b
			out0 (port_ps2_ctrl),a				; release clock line
			
			call wait_kb_clk_high
			
			ld d,1								; initial parity count
			ld b,8								; loop for 8 bits of data
kdoloop		call wait_kb_clk_low	
			ret c
			xor a
			set 1,a
			bit 0,c
			jr z,kdbzero
			res 1,a
			inc d
kdbzero		out0 (port_ps2_ctrl),a				; set data line according to output byte
			call wait_kb_clk_high
			ret c
			rr c
			djnz kdoloop

			call wait_kb_clk_low
			ret c
			xor a
			bit 0,d
			jr nz,kparone
			set 1,a
kparone		out0 (port_ps2_ctrl),a				; set data line according to parity of byte
			call wait_kb_clk_high
			ret c
			
			call wait_kb_clk_low
			ret c
			xor a
			out0 (port_ps2_ctrl),a				; release data line

			call wait_kb_data_low				; wait for mouse to pull data low (ack)
			ret c
			call wait_kb_clk_low				; wait for mouse to pull clock low
			ret c
				
			call wait_kb_data_high				; wait for mouse to release data
			ret c
			call wait_kb_clk_high				; wait for mouse to release clock
			ret 


;-----------------------------------------------------------------------------------------------


wait_kb_byte

			ld de,8000h
			call hwsc_set_timeout					; Allow 1 second for kb response

wait_kloop	in0 a,(port_ps2_ctrl)
			bit 4,a
			jr nz,rec_kbyte
			
			call hwsc_test_timeout
			jr z,wait_kloop
			scf									; carry flag set = timed out
			ret
			
rec_kbyte	in0 a,(port_keyboard_data)			; get byte sent by mouse
			or a
			ret


;-----------------------------------------------------------------------------------------------

purge_keyboard
			
			in0 a,(port_ps2_ctrl)
			bit 4,a
			ret z
			in0 a,(port_keyboard_data)			; read the keyboard port to purge buffer
			jr purge_keyboard



;----------------------------------------------------------------------------------------------
; INIT MOUSE ROUTINE 
;----------------------------------------------------------------------------------------------

; ZF set and A = 0 if all OK, else error code in A

init_mouse		
			di
			call purge_mouse
			call rs_mouse
			ei
			ret nc
			ld a,08bh								; "device error"
			or a
			ret


rs_mouse
			ld a,0ffh								;send "reset" command to mouse
			call write_to_mouse		
			jr nc,mouse_connected
			ld a,08ah								;no mouse ("device not detected") error
			or a
			ret


mouse_connected

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
			
			ld a,3
			ld (mouse_packet_size),a

			ld hl,intellimouse_seq
			ld b,6
			call mouse_sequence
			ret c
			
			ld a,0f2h
			call write_mouse_wait_ack				;send "get device type"
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
		
			ld hl,mouse_settings_seq
			ld b,6
			call mouse_sequence
			ret c
			xor a									;zero flag set, mouse initialized OK
			ret


bad_mouse	ld a,089h								;unsupported device error
			or a
			ret


mouse_sequence

mseqlp		ld a,(hl)
			push hl
			push bc
			call write_mouse_wait_ack
			pop bc
			pop hl
			ret c
			inc hl
			djnz mseqlp
			xor a
			ret


write_mouse_wait_ack
			
			call write_to_mouse
			ret c
			call wait_mouse_byte					;response should be 0FAh: ACK
			ret c
			cp 0fah									;if response is not ack, set carry flag
			ret z
			scf
			ret
			
;-----------------------------------------------------------------------------------------------
				
write_to_mouse

; Put byte to send to mouse in A

			ld c,a								; copy output byte to c
			ld a,0100b							; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,10
			call hwsc_time_delay				; wait at least 100 microseconds

			ld a,1100b
			out0 (port_ps2_ctrl),a				; pull data line low also
			
			ld a,1000b
			out0 (port_ps2_ctrl),a				; release clock line
			
			call wait_mouse_clk_high
			
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
			call hwsc_set_timeout				; Allow 1 second for mouse response

wait_mloop	in0 a,(port_ps2_ctrl)
			bit 5,a
			jr nz,rec_mbyte
			
			call hwsc_test_timeout
			jr z,wait_mloop
			scf									; carry flag set = timed out
			ret
			
rec_mbyte	in0 a,(port_mouse_data)				; get byte sent by mouse
			or a
			ret

;-----------------------------------------------------------------------------------------------

purge_mouse
			
			in0 a,(port_ps2_ctrl)
			bit 5,a
			ret z
			in0 a,(port_mouse_data)			; read the mouse port to purge buffer
			jr purge_mouse


;-----------------------------------------------------------------------------------------------


wait_kb_data_low

			ld a,2
			jr test_lo_ps2
			
wait_kb_clk_low

			ld a,1
			jr test_lo_ps2			

wait_mouse_data_low

			ld a,8
			jr test_lo_ps2

wait_mouse_clk_low

			ld a,4

test_lo_ps2	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call hwsc_set_timeout

nkb_lw		call hwsc_test_timeout			; timer reached zero?
			jr z,nkb_lnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
nkb_lnto	in0 a,(port_ps2_ctrl)
			and c
			jr nz,nkb_lw
					
			pop de
			pop bc
			xor a
			ret					




wait_kb_data_high

			ld a,2
			jr test_hi_ps2
			
wait_kb_clk_high

			ld a,1
			jr test_hi_ps2


wait_mouse_data_high
			
			ld a,8
			jr test_hi_ps2
			 
wait_mouse_clk_high

			ld a,4

test_hi_ps2	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call hwsc_set_timeout

nkb_hw		call hwsc_test_timeout			; timer reached zero?
			jr z,nkb_hnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
nkb_hnto	in0 a,(port_ps2_ctrl)
			and c
			jr z,nkb_hw
					
			pop de
			pop bc
			xor a							; carry clear = op was ok
			ret


;=====================================================================================================

hwsc_play_audio

; set HL register to location of an audio data structure:

; 0 - start 
; 3 - length
; 6 - loop start
; 9 - loop length
; c - frequency constant
; e - volume

; set C register to set channels wave is to play on

				
				push hl
				push hl
				pop iy

				ld a,c
				ld l,c
				ld (hw_audio_registers+80h),a			;lock the applicable channels
				
				ld ix,hw_audio_registers
				ld b,8
audchanloop		srl c
				jr nc,not_this_chan
				
				ld de,(iy)
				ld (ix),de								;location (from start of vram_b)

				ld de,(iy+3)
				ld (ix+04h),de							;length
				
				ld de,(iy+0ch)
				ld (ix+08h),de							;frequency constant
				
				ld a,(iy+0eh)
				ld (ix+0ch),a							;volume
				
				xor a
				ld (ix+0eh),a							;clear swap flag
				
				ld a,011b
				ld (ix+0fh),a							;restart channel and swap on loop
				
				ld a,8
				sub a,b
				out0 (port_selector),a					;select this (affected) channel for loop flag read
				
not_this_chan	lea ix,ix+10h			
				djnz audchanloop
						
				xor a
				ld (hw_audio_registers+80h),a			;unlock all channels
				
wait_aud_start	in0 a,(port_hw_flags)					;wait for an affected channel to begin playing
				bit 6,a
				jr z,wait_aud_start

				ld a,l
				ld (hw_audio_registers+80h),a			;lock the applicable channels
				
				ld ix,hw_audio_registers
				ld b,8
audchanloop2	srl l
				jr nc,not_this_chan2
						
				ld de,(iy+6)
				ld (ix+0h),de							;loop location
				
				ld de,(iy+9)
				ld (ix+4h),de							;loop length
								
				xor a
				ld (ix+0eh),a							;clear swap flag
				
				ld a,000b
				ld (ix+0fh),a							;dont restart channel and dont swap on loop
				
not_this_chan2	lea ix,ix+10h			
				djnz audchanloop2
						
				xor a
				ld (hw_audio_registers+80h),a			;unlock all channels
				
				pop hl
				ret


;-----------------------------------------------------------------------------------------------	
				
hwsc_disable_audio

				ld a,01h
				out0 (port_hw_enable),a			    ; disable entire sound system		
				
				ld ix,hw_audio_registers		    ; also mute all channels' volume
				ld b,8
chvolszero_lp	ld (ix+0ch),0
				lea ix,ix+10h
				djnz chvolszero_lp
				
				xor a
				ret
				
;--------------------------------------------------------------------------------------------

hwsc_get_joysticks

				in0 a,(PC_DR)				
				cpl
				ld b,a
				and 0fh
				ld e,a
				ld a,b
				rrca
				rrca
				rrca
				rrca
				and 0fh
				ld d,a
				
				in0 a,(PD_DR)	
				bit 4,a						; fire1 for joystick 1
				jr nz,noj1b1
				set 5,d

noj1b1			bit 5,a						; fire0 for joystick 1
				jr nz,noj1b0
				set 4,d
				
noj1b0			bit 6,a						; fire1 for joystick 0
				jr nz,noj0b1
				set 5,e

noj0b1			bit 7,a						; fire0 for joystick 0
				jr nz,noj0b0
				set 4,e

noj0b0			xor a
				ret
				
				
;--------------------------------------------------------------------------------------------
			
				
				
