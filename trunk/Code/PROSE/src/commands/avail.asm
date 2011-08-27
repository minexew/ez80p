;-----------------------------------------------------------------------------------------------
; "Avail" = Show OS / Hardware version v0.02 - ADL mode
;-----------------------------------------------------------------------------------------------

os_cmd_avail	ld a,(hl)
				cp '#'
				jr nz,avnoenv
				
				call clear_output_envars
				ld ix,free_sysram_base
				ld b,6
				ld c,0
				call os_output_to_envars
								
avnoenv			ld ix,free_sysram_base
				ld hl,sysram_txt
				call os_print_string
				call show_range
				
				ld hl,vram_a_txt
				call os_print_string
				call show_range
				
				ld hl,vram_b_txt
				call os_print_string
				call show_range
				
				call os_new_line
				call os_new_line	
				xor a
				ret
				
				
show_range		ld de,(ix)
				call os_show_hex_address
				ld a,'-'
				call os_print_char
				ld de,(ix+3)
				call os_show_hex_address
				call os_new_line
				lea ix,ix+6
				ret

			

sysram_txt		db 11,'System  RAM: ',0
vram_a_txt		db    'Video   RAM: ',0
vram_b_txt		db    'Spr/Aud RAM: ',0


;-----------------------------------------------------------------------------------------------
	