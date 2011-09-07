; keymap command v0.02 - Phil2011

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 03bh			; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

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

;------------------------------------------------------------------------------------------------

my_prog

fnd_param		ld a,(hl)						; examine argument text, if null show usage
				or a			
				jr nz,got_param
				
				ld hl,no_param_txt
				ld a,kr_print_string
				call.lil prose_kernal
				xor a							
				ret
				
got_param		ld e,0
				ld a,kr_parse_path
				call.lil prose_kernal
				ret nz
				
				ld (filename_loc),hl

				ld a,kr_find_file
				call.lil prose_kernal
				jr z,got_km

				ld a,kr_root_dir
				call.lil prose_kernal			; change to root dir, look for keymaps dir
				ret nz
				ld hl,keymaps_fn
				ld a,kr_change_dir
				call.lil prose_kernal
				ret nz
				ld hl,(filename_loc)			; open specified file
				ld a,kr_find_file
				call.lil prose_kernal
				ret nz

got_km			ld de,62h*3						; max load length
				ld a,kr_set_load_length
				call.lil prose_kernal
				
				ld a,kr_get_keymap_location
				call.lil prose_kernal			; returns OS keymap location in HL

				ld a,kr_read_file
				call.lil prose_kernal			
				ret nz

				ld hl,km_set_txt
				ld a,kr_print_string
				call.lil prose_kernal
				xor a							; all OK
				ret


;-------------------------------------------------------------------------------------------		

filename_loc		dw24 0

keymaps_fn			db "keymaps",0
km_set_txt			db "Keymap set",11,0
no_param_txt		db "USE: KEYMAP [filename]",11,0

;-------------------------------------------------------------------------------------------
