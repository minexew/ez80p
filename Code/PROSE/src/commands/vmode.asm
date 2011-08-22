;-----------------------------------------------------------------------------------------
;"vmode" - Change video mode - ADL mode 0.3
;-----------------------------------------------------------------------------------------

os_cmd_vmode
	
				call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr nz,vm_data						;any data?
				ld a,81h							;no data error
				or a
				ret

vm_data			ld a,e
				call os_set_vmode
				ret
				
;-----------------------------------------------------------------------------------------
