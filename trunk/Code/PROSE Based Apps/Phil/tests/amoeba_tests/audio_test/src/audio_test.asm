; Test audio output (test hardware in ez80p config EZ80P_087)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0087h			; (0 = dont care about HW version)
prose_version_req	equ 001eh			; (0 = dont care about OS version)

ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

					include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld hl,msg_txt				
			call print_string

			ld hl,wave_start						;copy the sound sample to vram_b
			ld de,vram_b_addr
			ld bc,wave_end-wave_start
			ldir

			ld ix,hw_audio_registers
			ld b,8
			
chloop		push bc
			push ix
			
			call audio_reg_wait						;wait until hw has read audio registers
			
			ld de,0
			ld (ix),de								;location (from start of vram_b)

			ld de,wave_end-wave_start
			ld (ix+4),de							;length

			ld de,0ffffh
			ld (ix+8),de							;frequency constant
			
			ld de,040h
			ld (ix+12),de							;volume

			ld de,0
			ld (ix+16),de							;loop location
			
			ld de,2
			ld (ix+20),de							;loop length
						
			ld a,kr_wait_key
			call.lil prose_kernal
			
			pop ix
			pop bc
			ld de,32								;move to base address of next channel
			add ix,de
			djnz chloop
			
			ld a,0
			ld (hw_audio_registers+3),a				;stop audio playback

			xor a
			jp.lil prose_return						; back to OS

			
print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret
		
		
;-----------------------------------------------------------------------------------------------

audio_reg_wait
				ld a,80h
				ld (hw_palette),a

				ld a,1
				ld (hw_audio_registers+3),a		; enable playback / clear audio register status flag
				ld c,port_hw_flags
wait_audreg		tstio 40h						; wait for audio hardware to finish reading registers
				jr z,wait_audreg
				
				ld a,00h
				ld (hw_palette),a
				
				ret
				
				
;-----------------------------------------------------------------------------------------------

msg_txt

		db 'Press a key play sound on each channel',11,0

;-----------------------------------------------------------------------------------------------
		
		include 'ding.asm'
		
		