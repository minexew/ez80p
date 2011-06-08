;-----------------------------------------------------------------------
;"H" - Hunt in memory command V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_h		call get_start_and_end				;this routine only returns here if start/end data is valid
				ld (find_hexstringascii),hl			;address in command string where search bytes start

				call test_mem_range
				jp c,os_range_error					;abort if end addr <= start addr
			
				xor a
				ld (h_ascii_mode),a
				
				ld hl,(find_hexstringascii)
				ld b,0
h_lfascii		ld a,(hl)							
				or a
				jr z,h_no_text						;scan for a quote, if found look for ascii
				cp 022h
				jr z,h_found_quote
				inc hl
				jr h_lfascii
h_found_quote	inc hl
				ld (find_hexstringascii),hl
h_fasc_len		ld a,(hl)
				or a
				jp z,os_no_args_error				;error if no trailing quote
				cp 022h
				jr z,h_startas
				inc hl
				inc b
				jr h_fasc_len

h_startas		ld a,b
				or a
				jp z,os_no_args_error				;error if two consecutive quotes
				ld a,1
				ld (h_ascii_mode),a
				jr h_start_search
						

h_no_text		ld hl,(find_hexstringascii)
				ld b,0								;count hex bytes in string to find
cntfbyts		call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,gthexstr
				inc b
				inc hl
				jr cntfbyts
gthexstr		ld a,b
				or a
				jp z,os_no_args_error	


h_start_search
	
				ld ix,(cmdop_start_address)			;start the search
fndloop1		push ix
				pop iy
				ld c,b								;renew length of string counter
				ld hl,(find_hexstringascii)
fcmloop			ld a,(h_ascii_mode)
				or a
				jr z,h_hex
				ld a,(iy)
				cp (hl)
				jr nz,nofmatch
				jr h_matched
h_hex			call ascii_to_hexword				;e holds byte on return
				ld a,(iy)
				cp e
				jr nz,nofmatch
h_matched		inc iy
				inc hl
				dec c
				jr nz,fcmloop
			
				push ix								;complete match found, show address
				pop de								;get address in DE
				push ix
				push bc
				call os_show_hex_address
				call os_new_line
				pop bc
				pop ix
				
nofmatch		push ix
				inc ix
				pop de
				ld hl,(cmdop_end_address)
				xor a
				sbc hl,de
				jr nz,fndloop1
							
				ld a,020h							;completion message
				or a
				ret
			
;-----------------------------------------------------------------------

h_ascii_mode	db 0

;-----------------------------------------------------------------------
