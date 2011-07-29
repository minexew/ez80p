;-----------------------------------------------------------------------
;"font" - replace font. V0.01 - ADL mode
;-----------------------------------------------------------------------

os_cmd_font
	
				call os_check_volume_format	
				ret nz
				
				call filename_or_bust					; filename supplied?
				ld (scratch_pad),hl

				call fs_get_dir_cluster					; stash current dir position
				ld (scratch_pad+3),de
				
				call os_root_dir						; change to root dir, look for fonts dir
				ret nz
				ld hl,fonts_fn
				call os_change_dir
				jr nz,no_font
				
				ld hl,(scratch_pad)
				call os_find_file						;get header info
				jr nz,no_font
				
				ld de,800h
				call os_set_load_length					;make sure no more than 800h bytes loaded

				ld hl,vram_a_addr						;load the font file to start of video ram
				call os_read_bytes_from_file
				call convert_font
				
no_font			push af
				ld de,(scratch_pad+3)					;restore original dir
				call fs_update_dir_cluster
				pop af
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
