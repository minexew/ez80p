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
			call set_timeout					; Allow 1 second for kb response

wait_kloop	in0 a,(port_ps2_ctrl)
			bit 4,a
			jr nz,rec_kbyte
			
			call test_timeout
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
			call set_timeout

nkb_lw		call test_timeout				; timer reached zero?
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
			call set_timeout

nkb_hw		call test_timeout				; timer reached zero?
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