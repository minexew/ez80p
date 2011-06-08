; Mouse test
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

				call my_prog
				
				xor a
				jp.lil prose_return				; back to OS

;--------------------------------------------------------------------------------------
; Displays mouse coordinates and mouse displacements
;--------------------------------------------------------------------------------------

my_prog			ld hl,640
				ld de,480
				ld a,kr_set_mouse_window
				call.lil prose_kernal

				ld a,kr_clear_screen
				call.lil prose_kernal
					
lp1				ld a,kr_get_mouse_position
				call.lil prose_kernal
				jr nz,ms_error					; mouse not connected

				ex de,hl
				push af
				push hl
				ld hl,text1
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii
				pop hl
				ex de,hl
				ld hl,text2
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii
				pop af
				ld hl,text3
				call hex_byte_to_ascii
					
					
				ld a,kr_get_mouse_motion
				call.lil prose_kernal
				jr nz,ms_error
				
				ex de,hl
				push hl
				ld hl,disp1
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii
				pop hl
				ex de,hl
				ld hl,disp2
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii

				ld bc,0
				ld a,kr_set_cursor_position
				call.lil prose_kernal
				ld hl,mytext
				ld a,kr_print_string			
				call.lil prose_kernal	

				ld a,kr_get_key
				call.lil prose_kernal
				cp 076h
				jr nz,lp1
				xor a
				ret

ms_error		ld hl,error_txt
				ld a,kr_print_string
				call.lil prose_kernal
				xor a
				ret

;--------------------------------------------------------------------------------------

hex_byte_to_ascii

				push bc
				ld b,a						;puts ASCII version of hex byte value in A at HL (two chars)
				srl a						;then hl = hl + 2
				srl a
				srl a
				srl a
				call hxdigconv
				ld (hl),a
				inc hl
				ld a,b
				and 0fh
				call hxdigconv
				ld (hl),a
				inc hl
				pop bc
				ret

hxdigconv		add a,30h
				cp 3ah
				jr c,hxdone
				add a,7
hxdone			ret

;--------------------------------------------------------------------------------------

mytext		db "Mouse x: $"
text1		db "xxxx",11,"Mouse y: $"
text2		db "yyyy",11,"Mouse buttons :$"
text3		db "bb",11,11

			db "Disp x: $"
disp1		db "xxxx",11,"Disp y: $"
disp2		db "yyyy",11,11,0 


error_txt	db "Mouse not installed.",11,11,0

;--------------------------------------------------------------------------------------










;-----------------------------------------------------------------------------------------------

message_txt

		db 'Hello (ADL mode) world!',11,0

;-----------------------------------------------------------------------------------------------
		
		