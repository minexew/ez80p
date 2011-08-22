;--------------------------------------------------------------------------------
;"RD" - Remove directory command. V0.02 - ADL mode
;--------------------------------------------------------------------------------

os_cmd_rd

				call os_check_volume_format	
				ret nz
				
				call filename_or_bust
			
				jp os_delete_dir		;no point it being a call, nothing follows


;---------------------------------------------------------------------------------
