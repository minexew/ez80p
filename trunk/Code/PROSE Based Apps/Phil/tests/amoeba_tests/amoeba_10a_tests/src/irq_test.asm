; Test audio output - AMOEBA 0A config, irq flag test (no actual interrupt occurs)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	010ah			; (0 = dont care about HW version)
prose_version_req	equ 0000h			; (0 = dont care about OS version)

ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

					include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

chan equ 7											;channel number to test..

			
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
			ld a,100b
			out0 (port_irq_ctrl),a					;disable audio IRQs to CPU

			ld hl,msg_txt				
			prose_call kr_print_string
			prose_call kr_wait_key


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

			call simple_loop
			
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

wait_audlp	ld a,chan
			out0 (port_selector),a					;set selector to read loop status flag of channnel "b"
			
			in0 a,(port_hw_flags)					
			bit 6,a									;Is this channel's loop flag set?
			jr z,wait_audlp	
			
			ld hl,0
			ld (hw_palette),hl
			ret
			
;----------------------------------------------------------------------------------------------------
			
show_loop_flags
			
			in0 a,(port_irq_flags)					;audio interrupt?
			bit 2,a
			ret z
			
			ld hl,irq_txt
			prose_call kr_print_string			
			
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
			
			ld a,100b
			out0 (port_clear_flags),a				;clear audio IRQ flag - do this after loop flags cleared
			
			ret
			
;----------------------------------------------------------------------------------------------------

simple_loop

; This test plays one sample, looping continuously

			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,1<<chan
			ld (hw_audio_registers+80h),a			;lock channel
			
			call get_chan_base
			ld de,40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0fh),101b						;restart channel / no swap on loop / contribute to audio irq 
			
			ld a,ffh-(1<<chan)
			ld (hw_audio_registers+80h),a			;unlock channel
						
			ret
			
;----------------------------------------------------------------------------------------------------

one_shot

; This test plays one sample, then automatically switches to another sample when the first
; reaches the end. The second sample then loops continuously. (If the second sample is silence
; the effect is that of playing one sample and then stopping.)

			ld hl,first_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			call get_chan_base						;set up first sample to play
			ld de,0h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound2-sound1
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0fh),111b						;restart channel(b0), swap on loop (b1), irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)


			call wait_audio_loop					;wait for hw to latch new values - this means the loc/len can be reloaded


			ld hl,second_sample_txt
			prose_call kr_print_string

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			call get_chan_base						;set up second sample, this plays when the first has reached the end
			ld de,vram_b_addr+40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
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

			call get_chan_base						;set up first sample to play
			ld de,0h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound2-sound1
			ld (ix+04h),de							;length
			ld de,07fffh
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0fh),111b						;restart channel (b0), swap on loop (b1), irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)


			call wait_audio_loop					;wait for hw to latch new values - this means the loc/len can be reloaded


			ld hl,second_sample_txt
			prose_call kr_print_string
				
			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock channel(s)

			call get_chan_base						;set up second sample			
			ld de,vram_b_addr+40000h
			ld (ix+00h),de							;location (from start of vram_b)
			ld de,sound_end-sound2
			ld (ix+04h),de							;length
			ld (ix+0fh),110b						;do not restart channel (b0), swap on loop (b1), irq enable (b2)
			
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
			
			ret
						
;----------------------------------------------------------------------------------------------------

get_chan_base
			
			ld ix,hw_audio_registers
			ld de,16
			ld d,chan
			mlt de
			add ix,de
			ret

;----------------------------------------------------------------------------------------------------
		
			
msg_txt		db 'Sound test - Press a key to start',11,0

loop_txt	db 'Channel: '
chan_txt	db 'x has looped',11,0

first_sample_txt

		db "Writing sample parameters to hardware regs..",11,0

second_sample_txt

		db "Writing second sample parameters to hardware regs..",11,0

irq_txt	db "IRQ flag set..",11,0


;-----------------------------------------------------------------------------------------------

sound1
		include 'ding.asm'
sound2		
		include 'notify.asm'

sound_end

		