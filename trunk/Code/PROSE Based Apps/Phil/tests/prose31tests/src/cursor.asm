
; test cursor

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 31h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_text
			ld a,kr_print_string
			call.lil prose_kernal			

			ld e,5fh
			ld a,kr_set_cursor_image
			call.lil prose_kernal
			

main_loop	ld a,kr_draw_cursor				; Show cursor
			call.lil prose_kernal
			
			ld a,kr_wait_key				; Wait for keypress
			call.lil prose_kernal
			
			push af							; Remove cursor
			ld a,kr_remove_cursor
			call.lil prose_kernal
			pop af
			
			
			cp 076h							; ESC pressed?
			jr nz,not_esc
			xor a
			jp prose_return

not_esc		cp 29h							; Space Pressed?
			jr nz,not_space
			ld a,kr_get_cursor_position
			call.lil prose_kernal		
			inc b							; move cursor right
			ld a,kr_set_cursor_position
			call.lil prose_kernal
			jr main_loop
			
not_space	cp 70h							; INS pressed?
			jr nz,main_loop
			ld a,(my_cursor_mode)		
			or a
			jr nz,go_ins
			ld a,1							;change to overwrite type cursor
			ld (my_cursor_mode),a
			ld e,7fh
			ld a,kr_set_cursor_image
			call.lil prose_kernal
			jr main_loop
go_ins		xor a							; change to insert type cursor
			ld (my_cursor_mode),a
			ld e,5fh
			ld a,kr_set_cursor_image
			call.lil prose_kernal
			jr main_loop
		
			
;---------------------------------------------------------------------------------------------

my_cursor_mode	db 0

msg_text	db 'Press SPACE to move cursor and INS to swap mode',13,0
			
;---------------------------------------------------------------------------------------------
