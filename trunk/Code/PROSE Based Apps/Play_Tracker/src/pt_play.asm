; Play Protracker Module V1.01 (sample data can be up to about 400K)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

;			ld hl,test_fn
					
			ld a,(hl)						; get filename from command string
			or a
			jr z,no_args
			
			ld a,kr_find_file				; look for file on disk
			call.lil prose_kernal
			jr nz,load_error
			ld (pt_mod_length),de			; note the file length
			
			ld hl,loading_txt						 
			call print_string

			ld hl,music_module
			ld a,kr_read_file
			call.lil prose_kernal
			jr nz,load_error
			
			xor a
			ld (relocated_samples),a
			call init_tracker				; init the module to get the start address of the samples in "sample_base"
			
			ld hl,music_module			
			ld bc,(pt_mod_length)
			add hl,bc						; hl = end address of music module
			xor a
			ld bc,(sample_base)
			sbc hl,bc						; subtract location of samples
			push hl
			pop bc							; bc = length of sample data
			ld hl,(sample_base)
			ld de,vram_b_addr
			ldir							; copy sample data to audio RAM
			
			ld a,1							; init the module with the relocated sample base
			ld (relocated_samples),a
			ld hl,0							; offset in VRAM_B
			ld (sample_base),hl
			call init_tracker
					
			ld hl,playing_txt						 
			call print_string
						
;---------------------------------------------------------------------------------------------------

			ld de,655							; set count to 655 ticks (50Hz)
			ld a,e							
			out0 (TMR0_RR_L),a					; set count value lo
			ld a,d
			out0 (TMR0_RR_H),a					; set count value hi
			ld a,00010011b							
			out0 (TMR0_CTL),a					; enable and start timer 0 (continuous mode)

wait_50hz	in0 a,(TMR0_CTL)					; has 50Hz timer count looped?			
			bit 7,a
			call nz,do_tracker_update			
		
			ld a,kr_get_key						; Quit if ESC pressed
			call.lil prose_kernal
			cp 076h
			jr nz,wait_50hz

endit		ld a,0
			ld.lil (hw_audio_registers+3),a		; Disable audio playback
			xor a
			jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

no_args		ld hl,no_args_txt
			call print_string
			jr endit

load_error	ld hl,fnf_txt
			call print_string
			jr endit

;----------------------------------------------------------------------------------------------


do_tracker_update

; call this routine every 50 Hz

			ld a,08h							; for testing only
			ld (hw_palette+1),a					; for testing only
			
			call play_tracker					
			
			ld a,00h							; for testing only
			ld (hw_palette+1),a					; for testing only
			
			call update_audio_hardware			
			ret
			
;---------------------------------------------------------------------------------------------------

print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret


waitkey		ld a,kr_wait_key
			call.lil prose_kernal
			ret


;-----------------------------------------------------------------------------------------------
		
loading_txt		db 'Loading Protracker module.. ',0
playing_txt		db 'Playing! Press ESC to quit..',11,0

no_args_txt		db 'Usage PTPLAY [module name]',11,0

fnf_txt			db 'File not found',11,0

pt_mod_length	dw24 0

test_fn			db 'interfer.mod',0

;-----------------------------------------------------------------------------------------------
		
			include "routines/ADL_mode_Protracker_Player_v101.asm"
	
			include "routines/ADL_mode_Protracker_to_EZ80P_audio.asm"

;-----------------------------------------------------------------------------------------------

ALIGN 2

music_module	db 0

;------------------------------------------------------------------------------------------------

		