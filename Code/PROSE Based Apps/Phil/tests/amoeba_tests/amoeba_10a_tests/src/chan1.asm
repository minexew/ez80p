; Test audio output - AMOEBA 0A config

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	010ah			; (0 = dont care about HW version)
prose_version_req	equ 0000h			; (0 = dont care about OS version)

ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

					include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

chan equ 7										;channel number to test..

			ld hl,msg_txt				
			prose_call kr_print_string

			ld hl,sound1							;copy the sound sample to start of vram_b
			ld de,vram_b_addr
			ld bc,sound2-sound1
			ldir

			ld hl,sound2							;copy the sound sample to middle of vram_b
			ld de,vram_b_addr+40000h
			ld bc,sound_end-sound2
			ldir

			ld a,81h								;ensure sound system is enabled
			out0 (port_hw_enable),a				
			ld a,4h
			out0 (port_irq_ctrl),a					;disable audio IRQs to CPU

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;all channels locked
			ld ix,hw_audio_registers					
			ld b,8
init_audlp	ld (ix+0ch),0							;volume = 0
			ld (ix+0fh),0							;no irq from this channel
			ld (ix+0eh),0							;clear any loop flag
			lea ix,ix+16
			djnz init_audlp
			ld a,0h
			ld (hw_audio_registers+80h),a			;unlock all channels


;			call simple_loop
			
;			call once_then_loop
			
			call once_then_stop
			
;			call ping_pong


loop_it		call show_loop_flags
	
			prose_call kr_get_key
			cp 076h
			jr nz,loop_it
			
			xor a
			jp.lil prose_return						; back to OS

			
;----------------------------------------------------------------------------------------------------

wait_audio_loop

			ld hl,0f0h
			ld (hw_palette),hl						;indicate wait period with background colour

;			ld bc,4000
;lp1		dec bc
;			ld a,b
;			or c
;			jr nz,lp1
			

wait_audlp	ld a,chan
			out0 (port_selector),a					;set selector to read loop status flag of channnel
			
			in0 a,(port_hw_flags)					
			bit 6,a									;Is this channel's loop flag set?
			jr z,wait_audlp	
			
			ld ix,hw_audio_registers+(chan*16)
			ld (ix+0eh),0							;clear the channel's loop flag

			ld hl,0
			ld (hw_palette),hl
			ret
			
;----------------------------------------------------------------------------------------------------
			
show_loop_flags
			
			ld ix,hw_audio_registers+070h
			ld b,8									
scanchans	ld a,b
			dec a
			out0 (port_selector),a					;set selector to 0-7 to read loop status flag of channnel "b"
			in0 a,(port_hw_flags)					
			bit 6,a									;Is this channel's loop flag set?
			jr z,next_chan

			ld (ix+0eh),0							;this chan has looped - write to chan's base reg+0eh to clear loop flag
			push bc
			push ix
			ld a,b
			add a,2fh
			ld (chan_txt),a		
			ld hl,loop_txt
			prose_call kr_print_string				;say which channel has looped
			pop ix
			pop bc
			
next_chan	lea ix,ix-16
			djnz scanchans
			ret
			
;----------------------------------------------------------------------------------------------------

simple_loop

; This test plays one sample, looping continuously

			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)
			
			ld ix,hw_audio_registers+(16*chan)
			ld de,40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0eh),0							;clear the channel's loop flag
			ld (ix+0fh),001b						;restart channel = bit 0 set, no swap on loop = bit 1 clr, no irq = bit 2 clr
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
						
			ret
			
;----------------------------------------------------------------------------------------------------

once_then_loop

; This test plays one sample, then automatically switches to another sample when the first
; reaches the end. The second sample then loops continuously.

			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up first sample to play
			ld de,0h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound2-sound1
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0eh),0							;clear the channel's loop flag
			ld (ix+0fh),011b						;restart channel(b0), swap on loop (b1), no irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)


			call wait_audio_loop					;wait for hw to latch new values - this means the loc/len can be reloaded


			ld hl,second_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up second sample, this plays when the first has reached the end
			ld de,vram_b_addr+40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
			ld (ix+0fh),000b						;do not restart channel (b0), no swap on loop (b1), no irq (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
			
			ret
			
			
;----------------------------------------------------------------------------------------------------

once_then_stop

; This test plays one sample, then automatically switches to another sample when the first
; reaches the end. The second sample then loops continuously. The second sample is silence
; so the effect is that of playing one sample and then stopping.

			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up first sample to play
			ld de,0h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound2-sound1
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0eh),0							;clear the channel's loop flag
			ld (ix+0fh),011b						;restart channel(b0), swap on loop (b1), no irq (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)


			call wait_audio_loop					;wait for hw to latch new values - this means the loc/len can be reloaded


			ld hl,second_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up second sample, this plays when the first has reached the end
			ld de,0+(sound2-sound1)-1
			ld (ix+00h),de							;location (end of original sample)
			ld de,1
			ld (ix+04h),de							;length = 1 (repeat same byte over and over = silence)
			ld (ix+0fh),000b						;do not restart channel (b0), no swap on loop (b1), no irq (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
			
			ret
			
			
;----------------------------------------------------------------------------------------------------

ping_pong

; This test plays two alternating samples continually. This would normally be used to play
; samples longer than availble audio memory, using the interrupt flag to syncronize the
; reloading of alternate buffers (Note: once playing the audio registers do not need to
; updating, apart from clearing the individual channel irq flags).


			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up first sample to play
			ld de,0h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound2-sound1
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0eh),0							;clear the channel's loop flag
			ld (ix+0fh),011b						;restart channel (b0), swap on loop (b1), no irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)


			call wait_audio_loop					;wait for hw to latch new values - this means the loc/len can be reloaded


			ld hl,second_sample_txt
			prose_call kr_print_string
				
			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			ld ix,hw_audio_registers+(16*chan)		;set up second sample			
			ld de,vram_b_addr+40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
			ld (ix+0fh),010b						;do not restart channel (b0), swap on loop (b1), no irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
			
			ret

;----------------------------------------------------------------------------------------------------
		
			
msg_txt		db 'Sound test - Press a key to quit',11,0

loop_txt	db 'Channel: '
chan_txt	db 'x has looped',11,0

first_sample_txt

		db "Writing first sample parameters to hardware..",11,0

second_sample_txt

		db "Writing second sample parameters to hardware..",11,0

;-----------------------------------------------------------------------------------------------

sound1
		include 'ding.asm'
sound2		
		include 'notify.asm'

sound_end

		