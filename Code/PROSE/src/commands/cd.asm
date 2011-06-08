;-----------------------------------------------------------------------
;'cd' - Change Dir command. V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_cd	

				call os_check_volume_format	
				ret nz
			
			
				ld a,(hl)								; if no args, just show dir path		
				or a				
				jp z,cd_show_path		
			
			
				ld a,(hl)								;'..' = goto parent dir
				inc hl
				ld b,(hl)
				dec hl
				cp '.'			
				jr nz,cd_nual
				cp b
				jr nz,cd_nual
				call os_parent_dir	
				ret
			
			
cd_nual			cp 02fh			
				jr nz,cd_nogor							; '/' char = go root
				call os_root_dir	
				ret
				
				
cd_nogor		cp '%'									; '%' char = go assigned dir
				jr nz,cd_no_assign
				call os_get_envar
				jr z,cd_evok
				ld a,0d1h								; return fs error - dir not found
				or a
				ret
cd_evok			ld de,0
				ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
				ld a,(hl)
				push de
				call os_change_volume
				pop de
				ret nz
				call fs_update_dir_cluster
				ret
				
				
cd_no_assign
			
				ld a,(current_volume)
				ld (original_vol_cd_cmd),a
			
				push hl
				pop ix
				ld a,(ix+4)
				cp ':'								; wish to change volume?
				jr nz,cd_nchvol
				ld de,vol_txt+1
				ld b,3
				call os_compare_strings
				jr nz,cd_nchvol
				ld de,5
				add hl,de
				ld (os_args_loc),hl					; update args position
				ld a,(ix+3)							; volume digit char
				sub 030h
				call os_change_volume
				ret nz								; error if new volume is invalid
				call os_root_dir					; go to new drive's root block as drive has changed
				jr cd_mol							; look for additional paths in args
				
			
cd_nchvol		call fs_get_dir_cluster
				ld (original_dir_cd_cmd),de
			
cd_mollp		push hl
				call os_change_dir					;step through args changing dirs as apt
				pop hl
				jr nz,cd_dcherr
cd_mol			ld a,(hl)							;move to next dir name in args (after '/') if no more found, quit
				inc hl
				or a
				ret z
				cp 02fh
				jr z,cd_mollp
				jr cd_mol
					
cd_dcherr	
			
				push af								;if a dir is not found go back to original dir and drive 
				ld de,(original_dir_cd_cmd)
				call fs_update_dir_cluster
				ld a,(original_vol_cd_cmd)
				call os_change_volume	
				pop af
				or a
				ret
				
;--------------------------------------------------------------------------------------------------
			
cd_show_path
			
			
max_dirs	equ 16
			
				ld b,max_dirs
				ld c,0
lp1				push bc
				call fs_get_dir_cluster
				pop bc
				push de
				inc c
				push bc
				call os_parent_dir
				pop bc
				jr nz,shdir_lp
				djnz lp1
				
shdir_lp		pop de
				push bc
				call fs_update_dir_cluster
				call os_get_current_dir_name
				call os_print_string
				ld hl,cd_fwdslash_txt
				call os_print_string
				pop bc
				dec c
				jr nz,shdir_lp
			
				call os_new_line	
				xor a
				ret
			
cd_fwdslash_txt	db '/',0	
			
;--------------------------------------------------------------------------------------------------
			
original_dir_cd_cmd		equ scratch_pad 
original_vol_cd_cmd	 	equ scratch_pad+3
					
;--------------------------------------------------------------------------------------------------