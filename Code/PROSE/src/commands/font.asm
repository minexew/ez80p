;-----------------------------------------------------------------------
;"font" - replace font. V0.01 - ADL mode
;-----------------------------------------------------------------------

os_cmd_font
	
				call os_check_volume_format	
				ret nz
				
				call filename_or_bust					; filename supplied?
				ld (scratch_pad),hl

				call fs_get_dir_cluster					; stash current dir position
				ld (scratch_pad+3),de
				
				call os_root_dir						; change to root dir, look for fonts dir
				ret nz
				ld hl,fonts_fn
				call os_change_dir
				jr nz,no_font
				
				ld hl,(scratch_pad)
				call os_find_file						;get header info
				jr nz,no_font
				
				ld de,700h
				call os_set_load_length					;make sure more than 700h bytes are not loaded

				ld hl,(font_addr)						;load the font file
				call os_read_bytes_from_file
						
no_font			push af
				ld de,(scratch_pad+3)					;restore original dir
				call fs_update_dir_cluster
				pop af
				ret

;-----------------------------------------------------------------------------------------------

fonts_fn		db "fonts",0

;-----------------------------------------------------------------------------------------------
