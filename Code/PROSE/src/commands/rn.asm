;-------------------------------------------------------------------------------------------
;"rn" - Rename command. V0.02 - ADL mode
;-------------------------------------------------------------------------------------------

os_cmd_rn
	
				call os_check_volume_format	
				ret nz
			
				call filename_or_bust
				push hl
				pop de
				call os_next_arg
				ld a,(hl)						;is the char here zero, return in not
				or a
				jr nz,rn_grfn
				ld a,01fh						;missing arguments error
				or a
				ret

rn_grfn			ex de,hl
				jp os_rename_file				;no point it being a call, nothing follows
		
;-------------------------------------------------------------------------------------------
