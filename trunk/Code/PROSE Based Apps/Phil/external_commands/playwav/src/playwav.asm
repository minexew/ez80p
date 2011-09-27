
; Command: "Playwav [filename]" -plays .wav files - v1.00 By Phil 2011
;
; Any sample size supported
; wav file must be 8 bit / mono / unsigned 
; Sample rate max 48800 Hz

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	10ah			; 0 = dont care about AMOEBA version
prose_version_req	equ 03bh			; 0 = dont care about PROSE version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;-----------------------------------------------------------------------------------------
			
			call my_prog
			jp.lil prose_return
			
;-----------------------------------------------------------------------------------------

chans equ 8								; number of channels to play sound on 1 - 8

my_prog		ld a,(hl)					; examine argument text, if 0, show command usage
			or a			
			jp z,show_use
			
			ld de,filename				; copy args to working filename string
			ld b,16
fnclp		ld a,(hl)
			or a
			jr z,fncdone
			cp ' '
			jr z,fncdone
			ld (de),a
			inc hl
			inc de
			djnz fnclp
fncdone		xor a
			ld (de),a					; null terminate filename

			ld hl,loading_txt
			prose_call kr_print_string
			
;--------------------------------------------------------------------------------------------

			ld a,081h
			out0 (port_hw_enable),a		; ensure sound hardware is enabled

			call silence_all_channels
	
			ld hl,filename				; does filename exist?
			prose_call kr_open_file
			ret nz
				
			ld c,0
			ld de,44
			prose_call kr_set_load_length
				
			ld hl,wav_header
			prose_call kr_read_file		; load wav file wav_header
			ret nz	
				
			ld ix,wav_header			; check file format
			ld a,(ix+8)					
			cp 'W'
			jp nz,notwav
			ld a,(ix+9)
			cp 'A'
			jp nz,notwav
			ld a,(ix+22)				; 1 = mono
			cp 1
			jp nz,badwavtype
			ld a,(ix+32)				; 1 = 8 bit
			cp 1
			jp nz,badwavtype

			ld hl,0						; convert frequency to period contant (const = 43980 * freq / 32768)
			xor a						; a:hl = 32 bit product
			ld de,43980					; c:de = multiplicand
			ld c,0
			ld b,16
mult_lp		srl (ix+25)					; 24:25 sample rate
			rr (ix+24)
			jr nc,mult_no_add
			add hl,de
			adc a,c
mult_no_add	ex de,hl
			add hl,hl
			rl c
			ex de,hl
			djnz mult_lp
			ld (mult32_result),hl
			ld (mult32_result+3),a
			ld hl,(mult32_result+2)
			add hl,hl
			ld (frequency_constant),hl
			
				
			ld hl,(ix+40)
			ld a,(ix+43)				; a:hl = sample length
			ld (samp_len_lo),hl
			ld (samp_len_hi),a
			or a
			jp nz,long_samp				; is sample > 128KB bytes?
			ld de,20001h
			xor a
			sbc hl,de
			jp nc,long_samp
			
;----------------------------------------------------------------------------------------------------------------

short_samp	ld hl,filename							
			prose_call kr_open_file
			ret nz
			
			ld c,0
			ld de,44
			prose_call kr_set_file_pointer
			
			ld hl,vram_b_addr						; load sample data (continuing from wav_header) 
			prose_call kr_read_file					; at start of audio accessible system RAM
			ret nz
			
			ld hl,vram_b_addr						;convert unsigned to signed sample data		
			call convert_samples
			ld hl,vram_b_addr+10000h			
			call convert_samples

			ld a,0ffh								;lock all chans
			ld (hw_audio_registers+80h),a				
			ld ix,hw_audio_registers				;set up sound parameters in hw registers
			ld b,chans
initchlp1	ld de,vram_b_addr
			ld (ix+00h),de							;location (start of vram_b)
			ld de,(samp_len_lo)
			ld (ix+04h),de							;length
			ld de,(frequency_constant)
			ld (ix+08h),de							;frequency constant
			ld (ix+0ch),40h							;volume
			ld (ix+0eh),0
			ld (ix+0fh),011b						;restart channel(bit0), swap on loop (bit1)
			lea ix,ix+16
			djnz initchlp1
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)

			call wait_audio_swap					;wait for buf flip - this means the loc/len can be reloaded

			ld a,0ffh
			ld (hw_audio_registers+80h),a			;lock all chans
			ld ix,hw_audio_registers				;set up second sample which plays when the first has reached the end			
			ld b,chans
initchlp2	ld hl,vram_b_addr
			ld de,(samp_len_lo)						;the last byte repeated over and over
			add hl,de
			dec hl
			ld (ix+00h),hl							;location (last byte of original sample)
			ld de,1
			ld (ix+04h),de							;length = 1 byte
			ld (ix+0eh),0
			ld (ix+0fh),000b						;do not restart channel (b0), no swap on loop (b1), no irq (b2)
			lea ix,ix+16
			djnz initchlp2
			xor a
			ld (hw_audio_registers+80h),a			;unlock channel(s)
			ret
						
;-----------------------------------------------------------------------------------------------------------------

long_samp	xor a
			ld (buffer),a
				
			ld hl,filename							
			prose_call kr_open_file
			ret nz
			
			ld c,0
			ld de,44
			prose_call kr_set_file_pointer

			ld c,0								; continuing from wav_header, load in first 128KB of sample data
			ld de,20000h
			prose_call kr_set_load_length
			 
			ld hl,vram_b_addr					; load first 128 KB of sample data
			prose_call kr_read_file				; (both 64KB buffers will be filled)
			ret nz
			ld hl,vram_b_addr
			call convert_samples				; convert unsigned to signed sample data (buffer0)	
			ld hl,vram_b_addr+10000h
			call convert_samples				; convert unsigned to signed sample data (buffer1)
						
			ld hl,(samp_len_lo)					; reduce file length by 128KB
			ld a,(samp_len_hi)
			ld b,0
			ld de,20000h
			xor a
			sbc hl,de
			sbc a,b
			ld (samp_len_lo),hl
			ld (samp_len_hi),a
			
			ld a,0ffh
			ld (hw_audio_registers+80h),a
			ld ix,hw_audio_registers			;set up buffer #0 sound parameters in hw registers 
			ld b,chans
initchlp3	ld de,vram_b_addr
			ld (ix+00h),de						;location (buffer #0 @ vram_b)
			ld de,65536
			ld (ix+04h),de						;length (64kb)
			ld de,(frequency_constant)
			ld (ix+08h),de						;frequency constant
			ld (ix+0ch),40h						;volume
			ld (ix+0eh),0
			ld (ix+0fh),011b					;restart channel(b0), swap on loop (b1), no irq (b2)
			lea ix,ix+16
			djnz initchlp3
			xor a
			ld (hw_audio_registers+80h),a		;unlock channel(s)
			
			call wait_audio_swap				;wait for first audio irq (caused by restart) -  loc/len can then be reloaded
			
			ld a,0ffh
			ld (hw_audio_registers+80h),a
			ld ix,hw_audio_registers			;set up buffer #1 sound parameters in hw registers
			ld b,chans
initchlp4	ld de,vram_b_addr+65536
			ld (ix+00h),de						;location (buffer #1 @ vram_b + 64kb)
			ld de,65536
			ld (ix+04h),de						;length = 64kb
			ld (ix+0eh),0
			ld (ix+0fh),010b					;do not restart channel (b0), swap on loop (b1), no irq (b2)
			lea ix,ix+16
			djnz initchlp4
			xor a
			ld (hw_audio_registers+80h),a		;unlock channel(s)
			
ls_loop		call wait_audio_swap				;wait for audio swap flag caused by loop
			jp nz,quit
			
			ld c,0								;attempt to load 64kb
			ld de,10000h
			prose_call kr_set_load_length

			ld hl,vram_b_addr					;select appropriate buffer to load to
			ld a,(buffer)
			or a
			jr z,load_buf0
			ld hl,vram_b_addr+10000h
			
load_buf0	push hl
			prose_call kr_read_file				;load in 64KB of sample data to alternate buffer (buffer 0 on first pass)
			pop hl
			push af
			call convert_samples
			pop af
			jr nz,last_load						; if there's an error, it's most likely just an "End Of File" message
			
			ld hl,(samp_len_lo)					; subtract 64K from sample length
			ld a,(samp_len_hi)
			ld b,0
			ld de,10000h
			xor a
			sbc hl,de
			sbc a,b
			ld (samp_len_lo),hl
			ld (samp_len_hi),a
			
			ld a,(buffer)
			xor 1
			ld (buffer),a						; flip buffer flag and loop around, wait for next irq request etc
			jr ls_loop
					

last_load	ld ix,hw_audio_registers			;shorten buffer play size, as fewer than 64KB bytes were loaded
			ld b,chans
			ld a,0ffh
			ld (hw_audio_registers+80h),a		;lock channel(s)
initchlp5	ld de,(samp_len_lo)
			ld (ix+04h),de						;length (remaining bytes)
			ld (ix+0fh),010b					;dont restart channel (bit0), swap on loop (bit1)
			lea ix,ix+16
			djnz initchlp5
			xor a
			ld (hw_audio_registers+80h),a		;unlock channel(s)
			
es_loop		call wait_audio_swap
			jp nz,quit
							
			ld hl,vram_b_addr					;select appropriate buffer to end on (silence)
			ld a,(buffer)
			or a
			jr z,zero_buf0
			ld hl,vram_b_addr+10000h
zero_buf0	ld (hl),0h

			ld a,0ffh
			ld (hw_audio_registers+80h),a
			ld ix,hw_audio_registers			;reduce buffer size to one byte (silence)
			ld b,chans
initchlp6	ld (ix+00h),hl						;location (buffer #2 @ vram_b + 64kb)
			ld de,1
			ld (ix+04h),de						;length = 3 bytes (silence)
			ld (ix+0eh),0
			ld (ix+0fh),000b					;do not restart channel (b0), no swap on loop (b1), no irq (b2)
			lea ix,ix+16
			djnz initchlp6
			xor a
			ld (hw_audio_registers+80h),a		;unlock channel(s)

			call wait_audio_swap
			
quit		call silence_all_channels
			xor a
			ret


;----------------------------------------------------------------------------------------------------

wait_audio_swap

			xor a
			out0 (port_selector),a
			
			ld (hw_audio_registers+0eh),a		;clear ch0's swap flag

was_lp		prose_call kr_get_key				; quit early if ESC pressed
			cp 76h
			jr nz,nwasquit
			or a
			ret
			
nwasquit	in0 a,(port_hw_flags)				;wait for ch0 swap flag
			bit 6,a
			jr z,was_lp
			xor a
			ret
			

;----------------------------------------------------------------------------------------------------

convert_samples

; set HL to start address of samples in VRAM_B

cslp			ld a,(hl)
				sub 80h
				ld (hl),a
				inc l
				jr nz,cslp
				inc h
				jr nz,cslp
				ret


;--------------------------------------------------------------------------------------

silence_all_channels

				ld a,0ffh
				ld (hw_audio_registers+80h),a	; lock channels
			
				ld ix,hw_audio_registers		; silence all channels			
				ld b,8
				ld de,0
novol_lp		ld (ix+0fh),0					; no swap, no irq, no reset
				ld (ix+0ch),0					; vol = 0
				lea ix,ix+16
				djnz novol_lp

				xor a
				ld (hw_audio_registers+80h),a	; unlock channels
				ret

;--------------------------------------------------------------------------------------

show_use		ld hl,use_txt

msg_exit		prose_call kr_print_string
				xor a
				ret

notwav			ld hl,notwav_txt
				jr msg_exit
				
badwavtype		ld hl,badwav_txt
				jr msg_exit

sampratebad		ld hl,samprate_txt
				jr msg_exit	

;---------------------------------------------------------------------------------------

notwav_txt		db "Error - Not a .wav format file!",11,0

badwav_txt		db "Error - Wav file is not a playable type!",11,0

samprate_txt	db "Error - Wav file sample rate is too high!",11,0

use_txt			db 11,"USE: PLAYWAV [filename]",11,11
				db "Wav file must be 8 bit, mono, PCM with sample rate <= 48828 KHz",11,0 
	
loading_txt		db "Loading...",11,0

filename		blkb 32,0

buffer			db 0

samp_len_lo		dw24 0
samp_len_hi		dw 0

mult32_result		db 0,0,0,0,0			;5 bytes to allow 2 LSBs to be read with a 24bit read

frequency_constant	dw24 0 		

wav_header			blkb 44,0

;--------------------------------------------------------------------------------------
