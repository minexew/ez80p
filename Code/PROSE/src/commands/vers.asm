;-----------------------------------------------------------------------------------------------
; "Vers" = Show OS / Hardware version v0.02 - ADL mode
;-----------------------------------------------------------------------------------------------

os_cmd_vers

				ld hl,os_version_txt
				call os_print_string
			
				call hwsc_get_version
				push de
				ex de,hl
				call os_show_hex_word
				
				ld hl,fwd_slash_txt
				call os_print_string
				
				ld hl,hw_version_txt
				call os_print_string
				pop de
				call os_show_hex_word
				
				call os_new_line
				call os_new_line	
				xor a
				ret
	
;-----------------------------------------------------------------------------------------------
	