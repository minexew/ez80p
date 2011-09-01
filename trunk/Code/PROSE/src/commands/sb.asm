;-----------------------------------------------------------------------
;'SB' - Save binary file command. V0.03
;-----------------------------------------------------------------------

os_cmd_sb
	
				call os_check_volume_format				;disk ok?
				ret nz
				
				call os_cache_original_vol_dir
				call do_sb
				call os_restore_original_vol_dir
				ret
				
do_sb			call os_scan_for_non_space				;filename supplied?
				jp z,missing_args
				ld (sb_save_name_addr),hl	

				call os_next_arg
				call ascii_to_hexword					
				jp nz,os_no_start_addr					;get the save location from command string
				ld (sb_save_addr),de
				
				call os_next_arg
				call ascii_to_hexword					;find file length		
				jp nz,os_no_filesize
				ld (sb_save_length),de
				
				ld hl,(sb_save_name_addr)				;filename loc
				xor a
				call os_parse_path_string
				ld (sb_save_name_addr),hl				;dont want path from now on
				ret nz

				call os_find_file						;does the file already exist?						
				jr z,sb_file_exists
				cp 0c6h									;if the filename is a directory go no further
				jr nz,sb_makefile
				or a
				ret

sb_file_exists	ld hl,save_append_msg					;ask if want to append data to exisiting file
				call os_show_packed_text
				call os_wait_key_press
				ld a,'y'
				cp b
				jr z,os_sfapp
				ld a,2ch								;file unchanged message
				or a
				ret

sb_makefile		ld hl,(sb_save_name_addr)				;otherwise try to make file
				call os_create_file
				ret nz
						
os_sfapp		ld hl,(sb_save_name_addr)				;filename address
				ld de,(sb_save_addr)					;address of source data
				ld bc,(sb_save_length)					;xDE = length of save
				call os_write_bytes_to_file
				ret nz	
				
				ld a,020h								;ok msg
				or a
				ret
			
				
;-------------------------------------------------------------------------------------------------

sb_save_addr		equ scratch_pad
sb_save_length		equ scratch_pad+3
sb_save_name_addr	equ scratch_pad+6

;--------------------------------------------------------------------------------------------------
