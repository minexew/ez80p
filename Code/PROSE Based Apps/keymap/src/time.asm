; keymap command
;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

fnd_param		ld a,(hl)						; examine argument text, if encounter 0: give up
				or a			
				jr z,no_param
				cp " "							; ignore leading spaces...
				jr nz,par_ok
skp_spc			inc hl
				jr fnd_param

par_ok			ld (filename_loc),hl

				ld a,kr_get_dir_cluster
				call.lil prose_kernal
				ld (original_dir),de

				call kjt_root_dir				; change to root dir, look for keymaps dir
				ld hl,keymaps_fn
				ld a,kr_change_dir
				call.lil prose_kernal
				jr c,hw_err
				jr nz,quit
				ld hl,(filename_loc)			; try loading specified file
				ld a,kr_change_dir
				call.lil prose_kernal
				ret c
				jr nz,quit	

got_km			ld ix,0
				ld iy,62h*3						; max load length
				ld a,kr_kjt_set_load_length
				call.lil prose_kernal
				
				ld hl,unshifted_keymap
				ld a,kr_load_file
				call.lik prose_kernal			; overwrite default keymap
				jr c,hw_err

				ld de,(original_dir_cluster)
				ld a,kr_set_dir_cluster
				call.lil prose_kernal

				ld hl,km_set_txt
all_done		ld a,kr_print_string
				call.lil prose_kernal
				
				xor a							; all OK
				ret


no_param		ld hl,no_param_txt
				jr all_done
				

	
;-------------------------------------------------------------------------------------------		

orig_dir_cluster	dw24 0
filename_loc		dw24 0

keymaps_fn			db "keymaps",0
km_set_txt			db "Keymap set",11,0
no_param_txt		db "USE: KEYMAP [filename]",11,0

;-------------------------------------------------------------------------------------------
