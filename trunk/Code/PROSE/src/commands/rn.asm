;-------------------------------------------------------------------------------------------
;"rn" - Rename command. V0.03
;-------------------------------------------------------------------------------------------

os_cmd_rn		call os_check_volume_format	
				ret nz
			
				call os_cache_original_vol_dir
				call do_rn
				call os_restore_original_vol_dir
				ret
			
do_rn			call os_scan_for_non_space				; filename supplied?
				jp z,missing_args
				
				xor a									; A=0, last element is file (dir) name
				call os_parse_path_string
				ret nz

				push hl
				pop de
				call os_next_arg
				ld a,(hl)								;is the char here zero?
				or a
				jp z,missing_args
				
				ex de,hl
				jp os_rename_file						;no point it being a call, nothing follows
		
;-------------------------------------------------------------------------------------------
