;-----------------------------------------------------------------------
;"?" - List commands. V0.03 - ADL mode
;-----------------------------------------------------------------------

os_cmd_help		
				xor a
				ld (os_linecount),a
				
				ld hl,packed_help1
show_page		call os_show_packed_text
				push hl
				call os_new_line
				pop hl
				inc hl						;skip end of line byte ($00)
				ld a,(hl)
				cp 0ffh						;last line in help file
				jr z,last_help_page
				
				call os_count_lines
				ld a,b
				cp 'y'
				jr z,show_page

last_help_page
				xor a
				ret	
	
;-----------------------------------------------------------------------
	