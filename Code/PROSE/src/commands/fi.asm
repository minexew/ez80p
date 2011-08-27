;-----------------------------------------------------------------------------------------------
; "FI" = Show file info.  v0.01 - ADL mode
;-----------------------------------------------------------------------------------------------

os_cmd_fi		call filename_or_bust					; filename supplied?
				
				push hl
				call os_check_volume_format	
				pop hl
				ret nz

				push hl
				call os_next_arg
				ld a,(hl)	
				ld (scratch_pad+34),a					; additional # arg?
				pop hl

				call os_find_file						; get header info
				jr z,fi_filexists
				push af
				ld a,(scratch_pad+34)
				cp '#'
				jr z,fi_remove
				pop af
				ret
fi_remove		call clear_output_envars
				pop af
				ret
				
fi_filexists	ld hl,scratch_pad+38
				ld (hl),c
				ld (scratch_pad+35),de
				
				ld de,16
				call os_set_load_length					;16 bytes to load
				
				ld hl,scratch_pad+16					;load first 16 bytes of file to a buffer
				call os_read_bytes_from_file
				ret nz
	
				call fi_show_length						;no so just show length
				
				ld hl,(scratch_pad+16+2)				;is this an .ezp file?
				xor a
				ld de,04f5250h	
				sbc hl,de
				jr z,ezp_file
fi_nezp_hash	ld b,1
				jr fi_envtest
				
				
ezp_file		ld iy,scratch_pad+16+5				;show values and arrange in scratchpad for simple 24bit each
				ld ix,scratch_pad+48				;words for envars
				ld hl,fi_txt2
				call fi_show_w24					;loc
				call fi_show_w24					;tru
				call fi_show_w16					;pro
				call fi_show_w16					;amo
				call os_print_string				;adl
				ld de,0
				ld e,(iy)
				ld (ix),de
				call os_show_hex_address
				call os_new_line
				
				ld b,6
fi_envtest		ld a,(scratch_pad+34)
				cp '#'
				jr z,fi_envars
				xor a
				ret
				
fi_envars		push hl
				call clear_output_envars
				pop hl	

				push bc
				
				ld de,scratch_pad+38
				ld hl,scratch_pad+40
				push hl
				ld b,4
				call n_hexbytes_to_ascii
				pop de
				ld ix,envar_out_n_txt
				ld (ix+3),'0'
				ld (ix+4),'0'
				push ix
				pop hl
				call os_set_envar
				
				pop bc
				dec b
				ret z
				
				ld ix,scratch_pad+48
				ld c,1
				call os_output_to_envars				
				ret



fi_show_length	ld hl,fi_txt
				call os_print_string
				ld a,(scratch_pad+38)
				call os_show_hex_byte
				ld de,(scratch_pad+35)
				call os_show_hex_address
				call os_new_line
				ret


fi_show_w24		call os_print_string
				ld de,(iy)
				ld (ix),de
				push hl
				call os_show_hex_address
				call os_new_line
				pop hl
				lea ix,ix+3
				lea iy,iy+3
				ret
				
fi_show_w16		call os_print_string
				ld de,0
				ld e,(iy)
				ld d,(iy+1)
				ld (ix),de
				push hl
				call os_show_hex_address
				call os_new_line
				pop hl
				lea ix,ix+3
				lea iy,iy+2
				ret
				
;-----------------------------------------------------------------------------------------------------------------
				
fi_txt			db "Total Length  : ",0
fi_txt2			db "Load Location : ",0
				db "Truncate to   : ",0
				db "PROSE Reqd    : ",0
				db "AMOEBA Reqd   : ",0
				db "ADL mode      : ",0
				
;-----------------------------------------------------------------------------------------------------------------
	