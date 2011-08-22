;-----------------------------------------------------------------------
; FAT16 'dir' - show directory command. v0.03 - ADL mode
;-----------------------------------------------------------------------

os_cmd_dir

				call os_check_volume_format	
				ret nz
				
				call div_line
				call fs_get_current_dir_name					;show dir name
				ret c
				ret nz
				call os_print_string
				call fs_get_dir_cluster							;if at root also show volume label
				ld a,d
				or e
				jr nz,dcmdnr
				call fs_get_volume_label
				call os_print_string
dcmdnr			call os_new_line
				
nrootdir		call div_line
				call fs_goto_first_dir_entry
				ret c
				jr nz,os_dlr
				xor a
				ld (os_linecount),a
				
os_dfllp		call fs_get_dir_entry							;line list loop starts here
				ret c
				jr nz,os_dlr									;end of dir?
				push bc
				call os_print_string							;show filename
				call os_get_cursor_position						;move cursor to x = 20
				ld b,14
				call os_set_cursor_position	
				pop bc
				bit 0,b											;is this entry a file?
				jr z,os_deif		
				ld hl,dir_txt									;write [dir] next to name
				jr os_dpl
				
os_deif			ld hl,os_hex_prefix_txt							;its a file - write length next to name
				call os_print_string
				ld (scratch_pad),de
				ld a,c
				ld (scratch_pad+3),a
				ld hl,output_line
				push hl
				ld de,(scratch_pad+2)
				call hexword_to_ascii
				ld de,(scratch_pad)
				call hexword_to_ascii
				ld (hl),0
				pop hl
				ld b,7											;skip only 7 out of 8 hex digits
				call os_skip_leading_ascii_zeros
os_dpl			call os_print_string
				call os_new_line
				
				call fs_goto_next_dir_entry
				jr nz,os_dlr									;end of dir?
				call os_count_lines
				ld a,'y'
				cp b
				jr z,os_dfllp
				
os_dlr			call div_line									;now show remaining disk space
				call fs_calc_free_space
				ret c	
				call show_hlde_decimal
				ld hl,kb_spare_txt
				call os_print_string
				xor a
				ret

;-------------------------------------------------------------------------------------------------

show_hlde_decimal

				call os_hex_to_decimal							;pass hl:de longword to decimal convert routine
				ld de,7
				add hl,de										;move to MSB of decimal digits
				ld b,e
				ld de,output_line
				push de
dec2strlp		ld a,(hl)										;scan for non-zero MSB
				or a
				jr nz,foundlnz
				dec hl
				djnz dec2strlp
foundlnz		inc b
ndecchar		ld a,(hl)										;convert to ascii
				add a,030h
				ld (de),a
				inc de
				dec hl
				djnz ndecchar
				xor a
				ld (de),a
				pop hl											;output line address
				call os_print_string
				ret

;----------------------------------------------------------------------------------------------------
			
div_line		ld c,'-'
				ld b,19
				call os_print_multiple_chars
				call os_new_line
				ret

;-----------------------------------------------------------------------------------------------------

dir_txt			db '[DIR]',0

kb_spare_txt	db ' KB Free',11,0

;-----------------------------------------------------------------------------------------------------
	