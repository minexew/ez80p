;-------------------------------------------------------------------------------------------
;"md" - Make dir command. V0.03
;-------------------------------------------------------------------------------------------

os_cmd_md		call os_check_volume_format	
				ret nz
			
				call os_cache_original_vol_dir
				call do_md
				call os_restore_original_vol_dir
				ret
			
do_md			call os_scan_for_non_space				; filename supplied?
				jp z,missing_args
				
				xor a									; A=0, last element is filename
				call os_parse_path_string
				ret nz
				
				jp os_make_dir							;no point it being a call, nothing follows
				
;-------------------------------------------------------------------------------------------
