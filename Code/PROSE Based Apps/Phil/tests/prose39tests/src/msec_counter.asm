; Millisecond / second counter test
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 39h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'


;--------------------------------------------------------------------------------------
; Displays timer1 counter claues
;--------------------------------------------------------------------------------------

my_prog			ld e,1
				ld a,kr_init_msec_counter
				call.lil prose_kernal


loop1			ld a,kr_read_msec_counter
				call.lil prose_kernal
				
				push hl
				
				ld hl,text1
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii
				
				pop de
				ld hl,text2
				ld a,d
				call hex_byte_to_ascii
				ld a,e
				call hex_byte_to_ascii
				
				ld hl,text1
				ld a,kr_print_string
				call.lil prose_kernal

				ld a,kr_get_key
				call.lil prose_kernal
				cp 076h
				jr nz,loop1
				

				ld e,0
				ld a,kr_init_msec_counter
				call.lil prose_kernal

				xor a
				jp.lil prose_return				; back to OS


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

text1		db "xxxx <- milliseconds. "
text2		db "yyyy <- seconds",13,0

;--------------------------------------------------------------------------------------
