
; Command: "Type [filename]" - shows text files - v1.02 By Phil 2011

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------------

			call my_prog
			
			jp.lil prose_return
			
;------------------------------------------------------------------------------------------------
; App starts here..
;------------------------------------------------------------------------------------------------

my_prog
			ld a,(hl)					;if no args just show usage
			or a
			jr nz,got_args
		
			ld a,kr_print_string
			ld hl,usage_txt
			call.lil prose_kernal
			xor a
			ret
			
got_args	push hl						; copy args to working filename string
			ld de,filename
			ld b,16
fnclp		ld a,(hl)
			or a
			jr z,fncdone
			cp ' '
			jr z,fncdone
			ld (de),a
			inc hl
			inc de
			djnz fnclp
fncdone		xor a
			ld (de),a					; null terminate filename
			pop hl
			
			ld hl,filename				; does filename exist?
			ld a,kr_find_file
			call.lil prose_kernal
			ret nz
			ld a,c
			or a 
			jr z,fs_ok
			
			ld a,kr_print_string		;if file is > 16MB, show error (no good reason for
			ld hl,too_big_txt			;this, just using 24bit filepointer here for simplicity).
			call.lil prose_kernal
			xor a
			ret
			
fs_ok		ld a,kr_get_cursor_position
			call.lil prose_kernal
			ld (cursor_pos),bc

			ld a,kr_get_display_size
			call.lil prose_kernal
			ld a,b
			ld (display_columns),a
			ld a,c
			ld (display_rows),a

			ld hl,0ffff00h
			ld (textfile_offset),hl
			ld a,0ffh
			ld (buffer_offset),a
			xor a
			ld (line_count),a
			
			ld a,kr_get_pen
			call.lil prose_kernal
			ld (original_pen),a

			call main_loop

			ld bc,(cursor_pos)
			ld a,kr_set_cursor_position
			call.lil prose_kernal
			
			ld a,(original_pen)
			ld e,a
			ld a,kr_set_pen
			call.lil prose_kernal
			
			ld hl,new_line
			ld a,kr_print_string
			call.lil prose_kernal
			xor a
			ret
			
;============================================================================================

			
main_loop	call get_next_char
			or a						;if its a zero, then quit app
			ret z

			cp 9
			jr nz,not_tab
tab_spc		ld a,' '					;if tab, output spaces until x pos = mod 8
			call output_char
			ld (cursor_pos),bc
			ld a,b
			and 7
			jr nz,tab_spc
			jr main_loop
			
not_tab		cp 10
			jr nz,not_lf
			call line_feed
			jr z,main_loop				;check line feed result, if ZF not set quit (more? response was "no")
			xor a
			ret
			
not_lf		cp 13
			jr nz,not_cr
			call carriage_return
			jr main_loop
			
not_cr		cp 11
			jr nz,not_crlf
			call carriage_return
			call line_feed
			jr z,main_loop				;check line feed result, if ZF not set quit (more? response was "no")
			xor a
			ret
			
not_crlf	call output_char
			jr z,main_loop				;check result, if ZF not set then quit (more? response was "no")
			xor a
			ret
			
;============================================================================================

output_char

			ld bc,(cursor_pos)
			ld e,a
			ld a,kr_plot_char
			call.lil prose_kernal
			
			ld bc,(cursor_pos)				;move cursor right
			inc b
			ld (cursor_pos),bc
			ld a,(display_columns)
			cp b							;reached last column?
			jr z,last_col
			xor a							;ZF set for all OK.
			ret
			
last_col	call carriage_return
			call line_feed
			ret
	
;--------------------------------------------------------------------------------------------

line_feed	ld bc,(cursor_pos)
			inc c
			ld a,(display_rows)			
			cp c							;reached last line?
			jr nz,noscroll
			dec c
			push bc
			ld a,kr_scroll_up
			call.lil prose_kernal
			pop bc
			
noscroll	ld a,(line_count)
			inc a
			ld (line_count),a
			
			ld e,a
			ld a,(display_rows)
			dec a
			cp e
			jr nz,sameline
			xor a
			ld (line_count),a
			call more_prompt		
			ret nz
			
sameline	ld (cursor_pos),bc
			xor a
			ret
			
;---------------------------------------------------------------------------------------------

carriage_return

			ld bc,(cursor_pos)
			ld b,0
			ld (cursor_pos),bc
			xor a
			ret
			
;---------------------------------------------------------------------------------------------

get_next_char
			
			push hl
			push de
			push bc
			
			ld a,(buffer_offset)			;chars still in load buffer?
			inc a
			ld (buffer_offset),a
			jr nz,ltb_ok
			
			ld hl,(textfile_offset)			;fill load buffer with new data
			ld de,256
			add hl,de
			ld (textfile_offset),hl
			
nochhi		ld hl,text_buffer				;zero text buffer
			ld b,0
ztblp		ld (hl),0
			inc hl
			djnz ztblp
			
			ld de,256						;only load enough chars to fill buffer
			ld a,kr_set_load_length
			call.lil prose_kernal
			
			ld c,0
			ld de,(textfile_offset)			;index from start of file
			ld a,kr_set_file_pointer
			call.lil prose_kernal
			
			ld hl,text_buffer				;load in part of the file	
			ld a,kr_read_file
			call.lil prose_kernal
			jr z,ltb_ok						;file system error?
			cp 0cch			
			jr z,ltb_ok						;Dont care if attempted to load beyond end of file
ltb_fail	pop bc
			pop de
			pop hl
			xor a							;if fail, return a zero (EOF) byte
			ret
				
ltb_ok		ld hl,text_buffer
			ld de,0
			ld a,(buffer_offset)
			ld e,a
			add hl,de
			ld a,(hl)
			
			pop bc
			pop de
			pop hl
			ret
			

;-------------------------------------------------------------------------------------------

more_prompt

			push bc
			ld b,0
			ld a,(display_rows)
			dec a
			ld c,a
			ld a,kr_set_cursor_position
			call.lil prose_kernal
			ld a,(original_pen)
			rrca
			rrca
			rrca
			rrca
			ld e,a
			ld a,kr_set_pen
			call.lil prose_kernal
			ld hl,more_txt
			ld a,kr_print_string
			call.lil prose_kernal

			ld a,kr_wait_key
			call.lil prose_kernal
			ld a,b
			cp 'y'

			push af
			ld e,0
			ld a,kr_set_pen
			call.lil prose_kernal
			ld hl,more_gone_txt
			ld a,kr_print_string
			call.lil prose_kernal
			ld a,(original_pen)
			ld e,a
			ld a,kr_set_pen
			call.lil prose_kernal
			pop af

			pop bc
			ret
	
;-------------------------------------------------------------------------------------------

test_filename	db 'testfile.txt',0

usage_txt		db 'Command: TYPE.EZP (v1.02) Displays ASCII files.',11
				db 'Usage  : TYPE filename',11,0
too_big_txt		db 'File must be smaller than 16MB.',11,0

display_rows	db 0
display_columns	db 0

more_txt		db " More? (y/n) ",13,0
more_gone_txt	db "             ",0
	
filename		blkb 32,0
			
cursor_pos		dw24 0

original_pen	db 0
line_count		db 0

textfile_offset	dw24 0

buffer_offset	db 0

new_line		db 11,0

text_buffer		blkb 258,0

;-------------------------------------------------------------------------------------------

