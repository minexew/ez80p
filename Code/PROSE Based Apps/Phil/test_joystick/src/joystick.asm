
; display joystick status using kernal call

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_text
			ld a,kr_print_string
			call.lil prose_kernal			


joy_loop	ld a,kr_get_key
			call.lil prose_kernal
			jr nz,nokey
			
			cp 076h						;quit if escape pressed
			jr nz,nokey
			ld hl,new_line
			ld a,kr_print_string
			call.lil prose_kernal
			xor a
			jp.lil prose_return

nokey		ld ix,joy0
			ld iy,joy1
			push ix
			push iy
			ld b,6
djlp1		ld (ix),'-'
			ld (iy),'-'
			inc ix
			inc iy
			djnz djlp1
			pop iy
			pop ix
			
			ld a,kr_get_joysticks
			call.lil prose_kernal
			
			ld a,e
			ld ix,joy0
			call show_dir
			ld a,d
			ld ix,joy1
			call show_dir
			
			ld hl,joy_text
			ld a,kr_print_string
			call.lil prose_kernal			

			jp joy_loop



show_dir	bit 0,a
			jr z,notup
			ld (ix),'U'
			
notup		bit 1,a
			jr z,notdown
			ld (ix+1),'D'

notdown		bit 2,a
			jr z,notleft
			ld (ix+2),'L'

notleft		bit 3,a
			jr z,notright
			ld (ix+3),'R'

notright	bit 4,a
			jr z,notfire0
			ld (ix+4),'0'

notfire0	bit 5,a
			jr z,notfire1
			ld (ix+5),'1'
notfire1	ret

			
;---------------------------------------------------------------------------------------------

msg_text	db 11,'Displaying status of joystick ports',11
			db '-----------------------------------',11,11,0

joy_text 	db 13,'Joy 0: '
joy0		db '------ Joy 1: '
joy1		db '------',0

new_line	db 11,0

;---------------------------------------------------------------------------------------------
