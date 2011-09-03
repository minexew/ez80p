;-----------------------------------------------------------------------
; FAT16 'dir' - show directory command. v0.04
;-----------------------------------------------------------------------

os_cmd_dir		call os_check_volume_format	
				ret nz
				
				call os_cache_original_vol_dir
				call do_dir
				call os_restore_original_vol_dir
				ret
				
do_dir			call os_scan_for_non_space						; path supplied?
				jr z,dir_no_args
				
				ld a,1											; A=1, interpret all as dirs
				call os_parse_path_string
				ret nz
										
dir_no_args		call div_line
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
				
				call show_capacity								;KB free is in xDE
				ld hl,free_txt
				call os_print_string
				xor a
				ret
				
;-------------------------------------------------------------------------------------------------------

show_capacity	

; set xDE = capacity in KB
; (trashed all other registers!)

				ld ix,dir_kb_txt
				xor a
				push de
				pop hl
				ld bc,1024h
				sbc hl,bc
				jr c,showresinkb
				ld b,10
				call shr_de
				ld ix,dir_mb_txt
showresinkb		call show_xde_decimal
				push ix
				pop hl
				call os_print_string
				ret
				
;--------------------------------------------------------------------------------------------------------

; Set xDE = value to shift
; Set B = number of places to shift right (0-23)
	
shr_de			push hl
				ld a,24
				sub b
				ld b,a
				ld hl,0
				ex de,hl
divde_lp		add hl,hl
				ex de,hl
				adc hl,hl
				ex de,hl
				djnz divde_lp
				pop hl
				ret
				
;-------------------------------------------------------------------------------------------------

show_xde_decimal

				call os_hex_to_decimal							;pass xde longword to decimal convert routine
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

dir_kb_txt		db ' KB ',0
dir_mb_txt		db ' MB ',0
free_txt		db 'Free',11,0

;-----------------------------------------------------------------------------------------------------
	