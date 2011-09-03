; keymap command

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

fnd_param		ld a,(hl)						; examine argument text, if null show usage
				or a			
				jr z,no_param

				ld (filename_loc),hl

				ld a,kr_get_dir_cluster
				call.lil prose_kernal
				ld (orig_dir_cluster),de

				ld a,kr_root_dir
				call.lil prose_kernal			; change to root dir, look for keymaps dir
				jr nz,disk_err

				ld hl,keymaps_fn
				ld a,kr_change_dir
				call.lil prose_kernal
				jr nz,no_km_dir
				
				ld hl,(filename_loc)			; open specified file
				ld a,kr_find_file
				call.lil prose_kernal
				jr nz,fnf

got_km			ld de,62h*3						; max load length
				ld a,kr_set_load_length
				call.lil prose_kernal
				
				ld a,kr_get_keymap_location
				call.lil prose_kernal			; returns OS keymap location in HL

				ld a,kr_read_file
				call.lil prose_kernal			
				jr nz,disk_err

				call restore_dir

				ld hl,km_set_txt
all_done		ld a,kr_print_string
				call.lil prose_kernal
				
				xor a							; all OK
				ret


no_param		ld hl,no_param_txt
				jr all_done


restore_dir		ld de,(orig_dir_cluster)
				ld a,kr_set_dir_cluster
				call.lil prose_kernal
				ret

disk_err		call restore_dir
				ld hl,disk_error_txt
				jr all_done
				
no_km_dir		call restore_dir
				ld hl,no_km_dir_txt
				jr all_done

fnf				call restore_dir
				ld hl,fnf_txt
				jr all_done
				

;-------------------------------------------------------------------------------------------		

orig_dir_cluster	dw24 0
filename_loc		dw24 0

keymaps_fn			db "keymaps",0
km_set_txt			db "Keymap set",11,0
no_param_txt		db "USE: KEYMAP [filename]",11,0

disk_error_txt		db "Disk Error!",11,0
no_km_dir_txt		db "No Keymaps folder in root!",11,0
fnf_txt				db "The Keymap file specified was not found!",11,0

;-------------------------------------------------------------------------------------------
