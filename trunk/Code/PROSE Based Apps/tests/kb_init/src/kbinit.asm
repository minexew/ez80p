; keyboard init code
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
				
				call init_kb					; ZF set if all OK, else A = error code
				jr z,mok
				
				ld a,kr_print_string
				ld hl,timeout_txt
				call.lil prose_kernal
								
mok				xor a
				jp.lil prose_return				; back to OS


;----------------------------------------------------------------------------------------------
; RESET Keyboard ROUTINE 
;----------------------------------------------------------------------------------------------

init_kb
			ld de,32768							; wait for any scancodes to cease
			call time_delay
			
			di
			
			call purge_keyboard
			
			call reset_keyboard
			
			ei
			
			ret nc
			ld a,08bh							; "device error" 
			or a
			ret
			
			
reset_keyboard

; If on return carry flag is set, keyboard init failed

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
			
rec_kbyte	in0 a,(port_keyboard_data)				; get byte sent by mouse
			or a
			call log_byte
			ret


;-----------------------------------------------------------------------------------------------

purge_keyboard
			
			in0 a,(port_ps2_ctrl)
			bit 4,a
			ret z
			in0 a,(port_keyboard_data)				;read the keyboard port to purge buffer
			jr purge_keyboard

;-----------------------------------------------------------------------------------------------
				
write_to_keyboard

; Put byte to send to keyboard in A

			call log_byte

			ld c,a								; copy output byte to c
			ld a,01b							; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,10
			call time_delay						; wait at least 100 microseconds

			ld a,11b
			out0 (port_ps2_ctrl),a				; pull data line low also
			
			ld a,10b
			out0 (port_ps2_ctrl),a				; release clock line
			
			call wait_kb_clk_high
			
			ld d,1								; initial parity count
			ld b,8								; loop for 8 bits of data
mdoloop		call wait_kb_clk_low	
			ret c
			xor a
			set 1,a
			bit 0,c
			jr z,mdbzero
			res 1,a
			inc d
mdbzero		out0 (port_ps2_ctrl),a				; set data line according to output byte
			call wait_kb_clk_high
			ret c
			rr c
			djnz mdoloop

			call wait_kb_clk_low
			ret c
			xor a
			bit 0,d
			jr nz,parone
			set 1,a
parone		out0 (port_ps2_ctrl),a				; set data line according to parity of byte
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
			
log_byte
			
			ld de,(mtraffic_addr)				; TEST!
			ld (de),a							; TEST!
			inc de								; TEST!
			ld (mtraffic_addr),de				; TEST!
			
			ret
			
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
timeout_txt			db "KB error!",11,0

mtraffic_addr		dw24 mtraffic_data
	
;-----------------------------------------------------------------------------------------------

	org 11000h

mtraffic_data		blkb 256,0

