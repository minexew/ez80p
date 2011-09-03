;--------------------------------------------------------------------------------
;"RD" - Remove directory command. V0.03
;--------------------------------------------------------------------------------


os_cmd_rd		call os_check_volume_format	
				ret nz
				
				call os_cache_original_vol_dir
				call do_rd
				call os_restore_original_vol_dir
				ret
			
do_rd			call os_scan_for_non_space				; filename supplied?
				jp z,missing_args
				
				xor a									; A=0, last element is file (dir) name
				call os_parse_path_string
				ret nz
							
				jp os_delete_dir						; no point it being a call, nothing follows


;---------------------------------------------------------------------------------
