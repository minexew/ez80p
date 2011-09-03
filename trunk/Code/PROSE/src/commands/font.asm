;-----------------------------------------------------------------------
;"font" - replace font. V0.02
;-----------------------------------------------------------------------

os_cmd_font		call os_check_volume_format	
				ret nz
				
				call os_cache_original_vol_dir
				call do_font
				call os_restore_original_vol_dir
				ret

do_font			call os_scan_for_non_space				; filename supplied?
				jp z,missing_args

				xor a									; A=0, expecting file at end of path
				call os_parse_path_string
				ret nz
				ld (scratch_pad),hl						; hl = filename part of path

				call os_find_file						; look for font at this location
				jr z,got_font

				call os_root_dir						; change to root dir, look for fonts dir
				ret nz
				ld hl,fonts_fn
				call os_change_dir
				ret nz
				ld hl,(scratch_pad)
				call os_find_file						;look for file in fonts dir
				ret nz
				
got_font		ld de,800h
				call os_set_load_length					;make sure no more than 800h bytes loaded
				ld hl,vram_a_addr						;load the font file to start of video ram
				call os_read_bytes_from_file
				call convert_font
				xor a
				ret
				
;-----------------------------------------------------------------------------------------------
				
convert_font	ld e,255						;convert linear font to format required by hardware
				ld bc,8
				ld hl,vram_a_addr+07f8h	
conv_allch		call char_to_font
				xor a
				sbc hl,bc
				dec e
				jr nz,conv_allch
				ret

;----------------------------------------------------------------------------------------------

; set E = character number
;     HL = character source def address

char_to_font	push hl
				push bc
				ld bc,64
				ld b,e
				mlt bc
				ld ix,vram_a_addr
				add ix,bc
				call conv_char
				pop bc
				pop hl
				xor a
				ret
	
;----------------------------------------------------------------------------------------------

conv_char		ld b,8
bfontlp1		ld a,(hl)
				ld (ix),a
				inc hl
				lea ix,ix+8
				djnz bfontlp1
				ret	
				
;-----------------------------------------------------------------------------------------------

fonts_fn		db "fonts",0

;-----------------------------------------------------------------------------------------------
