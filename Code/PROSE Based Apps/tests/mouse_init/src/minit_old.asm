; Mouse init code
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 27h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

				ld a,kr_print_string
				ld hl,text_here
				call.lil prose_kernal
				
				call purge_mouse
				
				call reset_mouse
				jr nc,mok
				
				ld a,kr_print_string
				ld hl,timeout_txt
				call.lil prose_kernal
								
mok				xor a
				jp.lil prose_return				; back to OS


;----------------------------------------------------------------------------------------------
; RESET MOUSE ROUTINE 
;----------------------------------------------------------------------------------------------

reset_mouse_1
			
			call log_mouse
			
			ld a,0100b							; pull clock line low
			out0 (port_ps2_ctrl),a
			
			call log_mouse

			ld de,10
			call time_delay						; wait at least 100 microseconds

			ld a,1100b
			out0 (port_ps2_ctrl),a				; pull data line low also
			
			call log_mouse
			
			ld a,1000b
			out0 (port_ps2_ctrl),a				; release clock line
	
			call log_mouse
			call log_mouse
			call log_mouse
			call log_mouse
			call log_mouse
			call log_mouse

			ret
			
			
			
reset_mouse		
			
			call blah
			ret


blah
			

;			ld a,0f2h
;			call write_to_mouse
;			ret c
;			call wait_mouse_byte	
;			ret c
;			call wait_mouse_byte	
;			ret c
;			call wait_mouse_byte	
;			xor a
;			ret


			ld a,0ffh								;send "reset" command to mouse
			call write_to_mouse		
			ret c
			
			ld de,65535								; pause 2 seconds, so mouse bytes go into FIFO
			call time_delay
			
			
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
			
			ld a,0f2h
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be 0FAh: OK
			ret c
			call wait_mouse_byte					;should be mouse ID
			ret c
			

			ld a,0f3h								;attempt to activate (Intellimouse) wheel with special sequence
			call write_to_mouse						;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,200								;srate = 200
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c
			
			ld a,0f3h
			call write_to_mouse						;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,100								;srate = 100 
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f3h
			call write_to_mouse						;send "set sample rate"
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,80									;srate = 80 
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f2h
			call write_to_mouse						;send "get device type"
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
			call write_to_mouse
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,(mouse_resolution)				 
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c
	
			ld a,(mouse_scaling)					;send "set scaling" - no args, command is e6 or e7
			call write_to_mouse
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
				
			ld a,0f3h								;send "set sample rate"
			call write_to_mouse
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			ld a,(mouse_sample_rate)				 
			call write_to_mouse
			ret c
			call wait_mouse_byte					;should be FA: ACK
			ret c

			ld a,0f4h								;send "enable data reporting" command to mouse
			call write_to_mouse
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			xor a									;zero flag set, mouse initialized OK
			ret

bad_mouse	ld a,089h								;unsupported device error
			or a
			ret



write_to_mouse_absorb_echo
			
			call write_to_mouse
			ret c
			call wait_mouse_byte					;same byte written is looped back to input buffer
			ret
			
;-----------------------------------------------------------------------------------------------
				
write_to_mouse

; Put byte to send to mouse in A

			call log_byte

			ld c,a								; copy output byte to c
			ld a,0100b							; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,10
			call time_delay						; wait at least 100 microseconds

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
			call log_byte
			ret


;-----------------------------------------------------------------------------------------------
			
log_byte
			
			ld de,(mtraffic_addr)				; TEST!
			ld (de),a							; TEST!
			inc de								; TEST!
			ld (mtraffic_addr),de				; TEST!
			
			ret
			
;-----------------------------------------------------------------------------------------------

wait_mouse_data_low

			ld a,8
			jr test_low

wait_mouse_clk_low

			ld a,4

test_low	push bc
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




wait_mouse_data_high
			
			ld a,8
			jr test_high
			 
wait_mouse_clk_high

			ld a,4

test_high	push bc
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




wait_mouse_clk_low_orig

			ld a,4
			jp ps2_test_lo

wait_mouse_clk_high_orig

			ld a,4
			jp ps2_test_hi

wait_mouse_data_low_orig
		
			ld a,8
			jp ps2_test_lo	

wait_mouse_data_high_orig
		
			ld a,8
			jp ps2_test_hi			




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


purge_mouse	in0 a,(port_ps2_ctrl)
			bit 5,a
			ret z
			in0 a,(port_mouse_data)					;read the mouse port until buffer is empty
			jr purge_mouse


;---------------------------------------------------------------------------------------------
; Timer related 
;---------------------------------------------------------------------------------------------

time_delay

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

log_mouse			ld de,(mtraffic_addr)

					ld b,0
lm_loop				in0 a,(port_ps2_ctrl)
					and 0ch
					ld (de),a							
					inc de								
					djnz lm_loop
					
					ld (mtraffic_addr),de				
					ret
					
;-----------------------------------------------------------------------------------------------



text_here			db "Testing..",11,0
timeout_txt			db "Timeout!",11,0

mtraffic_addr		dw24 mtraffic_data

mouse_id				db 0
mouse_packet_size		db 0
				
mouse_sample_rate		db 100			; 100 samples per second, valid: 10,20,40,60,80,100,200
mouse_resolution		db 3			; 8 counts per mm, valid: 00h-03h
mouse_scaling			db 0e6h			; valid commands 0e6h (1:1) / 0e7h (2:1)

;-----------------------------------------------------------------------------------------------


	org 11000h

mtraffic_data		blkb 256,0

