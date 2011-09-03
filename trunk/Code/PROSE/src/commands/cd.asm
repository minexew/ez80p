;-----------------------------------------------------------------------
;'cd' - Change Dir command. V0.03 - ADL mode
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
				
				
cd_nogor		cp '%'									
				jr nz,cd_no_assign
				xor a
				ret
				
cd_no_assign	call os_cache_original_vol_dir
				ld a,1
				call os_parse_path_string
				ret z
				call os_restore_original_vol_dir
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
				pop bc
				dec c
				jr z,cd_sp_done
				dec hl
				dec hl
				ld a,(hl)
				cp ':'
				jr z,shdir_lp				;no fwd slash if volx: previously shown
				ld hl,cd_fwdslash_txt
				call os_print_string
				jr shdir_lp
			
cd_sp_done		call os_new_line	
				xor a
				ret
			
cd_fwdslash_txt	db '/',0	
			
;--------------------------------------------------------------------------------------------------
