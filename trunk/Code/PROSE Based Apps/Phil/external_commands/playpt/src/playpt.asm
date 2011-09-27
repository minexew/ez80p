; Play Protracker Module V1.03 (sample data can be up to about 400K)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	10ah			; 0 = dont care about HW version
prose_version_req	equ 03ch			; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			push hl
			ld a,kr_get_volume_info		;store original vol/dir
			call.lil prose_kernal
			ld (orig_volume),a
			ld a,kr_get_dir_cluster
			call.lil prose_kernal
			ld (orig_dir_cluster),de
 			pop hl
			
			call my_prog
			
			push af						;restore original vol/dir
			ld a,(orig_volume)
			ld e,a
			ld a,kr_change_volume
			call.lil prose_kernal
			ld de,(orig_dir_cluster)
			ld a,kr_set_dir_cluster
			call.lil prose_kernal
			pop af
			jp.lil prose_return


orig_volume			db 0
orig_dir_cluster	dw24 0

;---------------------------------------------------------------------------------------------
					
my_prog		ld a,(hl)						; get filename from command string
			or a
			jr nz,got_args

			ld hl,no_args_txt				; show usage if no filename supplied
			prose_call kr_print_string
			xor a
			ret

got_args	ld e,0
			prose_call kr_parse_path

			prose_call kr_find_file			; look for file on disk
			ret nz
			ld (pt_mod_length),de			; note the file length
			
			ld hl,loading_txt						 
			prose_call kr_print_string

			ld hl,music_module
			prose_call kr_read_file
			ret nz
			
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
					
;---------------------------------------------------------------------------------------------------

			ld hl,playing_txt						 
			prose_call kr_print_string
						
			ld a,81h
			out0 (port_hw_enable),a				; ensure audio hw is enabled
			
			ld de,655							; set count to 655 ticks (50Hz)
			prose_call kr_set_timeout
			
			
wait_50hz	prose_call kr_test_timeout			; have 655 ticks occured?
			jr z,not_timedout

			ld de,655							; reset count to 655 ticks (50Hz)
			prose_call kr_set_timeout
			call protracker_update			
			

not_timedout
				
			prose_call kr_get_key				; Quit if ESC pressed
			cp 076h
			jr nz,wait_50hz


			ld ix,hw_audio_registers			; silence all channels upon exit
			ld b,8
quiet_lp	ld (ix+0ch),0
			lea ix,ix+16
			djnz quiet_lp
		
			xor a
			ret			


;----------------------------------------------------------------------------------------------

protracker_update

; call this routine every 50 Hz

;			ld a,08h							; for testing only - show cpu time
;			ld (hw_palette),a					; for testing only - show cpu time
			
			call play_tracker					
			
;			ld a,80h							; for testing only - show cpu time
;			ld (hw_palette),a					; for testing only - show cpu time
			
			call update_audio_hardware			
			
;			ld a,00h							; for testing only - show cpu time
;			ld (hw_palette),a					; for testing only - show cpu time 		
			ret
			
;-----------------------------------------------------------------------------------------------
		
loading_txt		db 'Loading Protracker module.. ',11,0
playing_txt		db 'Playing. Press ESC to quit.',11,0

no_args_txt		db 'Usage PLAYPT [protracker module name]',11,0

pt_mod_length	dw24 0

;-----------------------------------------------------------------------------------------------
		
			include "routines/ADL_mode_Protracker_Player_v101.asm"
	
			include "routines/ADL_mode_Protracker_to_AMOEBA_audio_v102.asm"

;-----------------------------------------------------------------------------------------------

ALIGN 2

music_module	db 0

;------------------------------------------------------------------------------------------------

		