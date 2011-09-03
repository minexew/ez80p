;------------------------------------------------------------------------------------
;"del" delete file command. V0.03
;------------------------------------------------------------------------------------


os_cmd_del		call os_check_volume_format	
				ret nz
			
				call os_cache_original_vol_dir
				call do_del
				call os_restore_original_vol_dir
				ret
			
do_del			call os_scan_for_non_space				; filename supplied?
				jp z,missing_args

				xor a									; expecting file at end of path
				call os_parse_path_string
				ret nz
				jp os_erase_file						; no point it being a call, nothing follows
				
				
;-------------------------------------------------------------------------------------
