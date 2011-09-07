; Mouse test v0.03
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; if 0 = dont care about HW version
prose_version_req	equ 3bh				; if 0 = dont care about OS version
ADL_mode			equ 1				; if 0 user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

				call my_prog
				
				xor a
				jp.lil prose_return				; back to OS

;--------------------------------------------------------------------------------------
; Displays pointer / mouse coordinates / button status / and mouse counters
;--------------------------------------------------------------------------------------

my_prog			ld a,kr_get_mouse_position		;is the mouse driver aleady active?
				call.lil prose_kernal
				jr z,mouse_already_active

				ld a,kr_init_mouse				;initialize the mouse driver
				call.lil prose_kernal
				jr nz,ms_error					;was a mouse detected?

mouse_already_active

				ld a,kr_set_pointer
				ld d,1							; D = 1, default pointer
				ld e,1							; E = 1, enable pointer now
				call.lil prose_kernal	
				jr nz,ms_error					; mouse driver enabled?
				
				ld a,kr_clear_screen
				call.lil prose_kernal
					
lp1				ld a,kr_get_mouse_position
				call.lil prose_kernal
				jr nz,ms_error					; mouse enabled?

				ex de,hl
				push bc
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
				pop bc
				ld a,b
				ld hl,text5
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
				
all_done		ld a,kr_set_pointer				
				ld e,0									;disable pointer
				call.lil prose_kernal
				xor a
				ret

ms_error		ld hl,error_txt
				ld a,kr_print_string
				call.lil prose_kernal
				jr all_done

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
text2		db "yyyy",11,"Buttons: $"
text3		db "bb",11
text4		db "Wheel: $"
text5		db "ww",11,11

			db "Disp x: $"
disp1		db "xxxx",11,"Disp y: $"
disp2		db "yyyy",11,11,0 


error_txt	db "Mouse not installed.",11,11,0

;--------------------------------------------------------------------------------------
