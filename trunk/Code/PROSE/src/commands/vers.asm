;-----------------------------------------------------------------------------------------------
; "Vers" = Show OS / Hardware version v0.03 - ADL mode
;-----------------------------------------------------------------------------------------------

os_cmd_vers		
				push hl
				
				ld hl,os_version_txt
				call os_print_string
			
				call hwsc_get_version
				ld (scratch_pad+10h),hl
				ld (scratch_pad+13h),de
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
				
				pop hl
				ld a,(hl)
				cp '#'
				jr z,vers_env
				xor a
				ret
				
vers_env		call clear_output_envars
				ld ix,scratch_pad+10h
				ld b,2
				ld c,0
				call os_output_to_envars
				ret
				
	
;-----------------------------------------------------------------------------------------------
	