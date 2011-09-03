;-----------------------------------------------------------------------------------------------
; "FI" = Show file info.  v0.02
;-----------------------------------------------------------------------------------------------

os_cmd_fi		call os_scan_for_non_space				; filename supplied?
				jp z,missing_args
								
				call os_check_volume_format	
				ret nz

				call os_cache_original_vol_dir
				call do_fi
				call os_restore_original_vol_dir
				ret

do_fi			push hl
				call os_next_arg
				ld a,(hl)	
				ld (scratch_pad+34),a					; additional # arg?
				pop hl

				xor a									; A=0, expecting file at end of path
				call os_parse_path_string
				ret nz

				call os_find_file						; get header info
				jr z,fi_filexists
				push af									; file does not exist..
				ld a,(scratch_pad+34)					; If # mode, remove OUTxx vars
				cp '#'
				jr z,fi_remove
				pop af
				ret
				
fi_remove		call clear_output_envars
				pop af
				xor a									;[fi .. #] does not return an error code
				ret
				
				
				
fi_filexists	ld hl,scratch_pad+38
				ld (hl),c
				ld (scratch_pad+35),de					;store file length
				
				ld de,16
				call os_set_load_length					;16 bytes to load
				
				ld hl,scratch_pad+16					;load first 16 bytes of file to a buffer
				call os_read_bytes_from_file
				ret nz

				ld iy,scratch_pad+16+5					;arrange in scratchpad for simple 24bit each
				ld ix,scratch_pad+48					;words for envars				
				call fi_conv_w24						;loc
				call fi_conv_w24						;tru
				call fi_conv_w16						;pro
				call fi_conv_w16						;amo
				ld de,0
				ld e,(iy)
				ld (ix),de								;adl	

				ld a,(scratch_pad+34)
				cp '#'
				jr z,fi_quiet
				
				call fi_show_length						;show length of file (unless # mode)
				
				call test_ezp
				jr nz,not_ezp_file
				
				ld hl,fi_txt2							;show other parameters
				ld b,5
				ld ix,scratch_pad+48	
fi_sptlp		call os_print_string
				push hl
				ld de,(ix+0)
				call os_show_hex_address
				call os_new_line
				pop hl
				lea ix,ix+3
				djnz fi_sptlp
				
not_ezp_file	call os_new_line
				xor a
				ret
				


fi_quiet		push hl
				call clear_output_envars
				pop hl	

				ld de,scratch_pad+38					;set file length in OUT00
				ld hl,scratch_pad+40
				push hl
				ld b,4
				call n_hexbytes_to_ascii
				ld (hl),0
				pop de
				ld ix,envar_out_n_txt
				ld (ix+3),'0'
				ld (ix+4),'0'
				push ix
				pop hl
				call os_set_envar
				
				call test_ezp
				jr z,q_ezp_file
				xor a
				ret
				
q_ezp_file		ld ix,scratch_pad+48					;set rest of paramters in OUT01+ 
				ld b,5
				ld c,1
				call os_output_to_envars				
				xor a
				ret



fi_show_length	ld hl,fi_txt
				call os_print_string
				ld a,(scratch_pad+38)
				call os_show_hex_byte
				ld de,(scratch_pad+35)
				call os_show_hex_address
				call os_new_line
				ret


;-----------------------------------------------------------------------------------------------------------------

fi_conv_w24		ld de,(iy)
				ld (ix),de
				lea ix,ix+3
				lea iy,iy+3
				ret
				
fi_conv_w16		ld de,0
				ld e,(iy)
				ld d,(iy+1)
				ld (ix),de
				lea ix,ix+3
				lea iy,iy+2
				ret

;-----------------------------------------------------------------------------------------------------------------


test_ezp		ld hl,(scratch_pad+16+2)				;is this an .ezp file?
				xor a
				ld de,04f5250h	
				sbc hl,de
				ret
					
;-----------------------------------------------------------------------------------------------------------------
				
fi_txt			db "Total Length  : ",0
fi_txt2			db "Load Location : ",0
				db "Truncate to   : ",0
				db "PROSE Reqd    : ",0
				db "AMOEBA Reqd   : ",0
				db "ADL mode      : ",0

;-----------------------------------------------------------------------------------------------------------------

