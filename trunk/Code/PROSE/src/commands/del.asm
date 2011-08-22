;------------------------------------------------------------------------------------
;"del" delete file command. V0.02 - ADL mode
;------------------------------------------------------------------------------------


os_cmd_del
	
				call os_check_volume_format	
				ret nz
			
				call filename_or_bust
				
				jp os_erase_file			;no point it being a call, nothing follows
				
				
;-------------------------------------------------------------------------------------
			
filename_or_bust
			
				ld a,(hl)					;is the char here zero, return in not
				or a
				ret nz
				pop hl						;otherwise pop the parent return address of the stack
				jp os_no_fn_error			;so eventual return is made to grandparent

;------------------------------------------------------------------------------------
