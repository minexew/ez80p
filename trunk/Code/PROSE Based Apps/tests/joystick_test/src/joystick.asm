
; display joystick (port C 0:7 and port D: 7:4) status

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

joy_loop	
			
			ld a,kr_get_key
			call.lil prose_kernal
			jr nz,nokey
			cp 076h
			jr nz,nokey
			xor a
			jp prose_return

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
			
			in0 a,(PC_DR)				
			bit 0,a						; up for joystick 0
			jr nz,noj0u
			ld (ix),'U'

noj0u		bit 1,a						; down for joystick 0
			jr nz,noj0d
			ld (ix+1),'D'

noj0d		bit 2,a						; left for joystick 0
			jr nz,noj0l
			ld (ix+2),'L'

noj0l		bit 3,a						; right for joystick 0
			jr nz,noj0r
			ld (ix+3),'R'
			

noj0r		bit 4,a						; up for joystick 1
			jr nz,noj1u
			ld (iy),'U'

noj1u		bit 5,a						; down for joystick 1
			jr nz,noj1d
			ld (iy+1),'D'

noj1d		bit 6,a						; left for joystick 1
			jr nz,noj1l		
			ld (iy+2),'L'

noj1l		bit 7,a						; right for joystick 1
			jr nz,noj1r
			ld (iy+3),'R'


noj1r		in0 a,(PD_DR)				; fire1 for joystick 1
			bit 4,a
			jr nz,noj0b1
			ld (iy+5),'1'

noj0b1		bit 5,a						; fire0 for joystick 1
			jr nz,noj0b0
			ld (iy+4),'0'


noj0b0		bit 6,a						; fire1 for joystick 0
			jr nz,noj1b1
			ld (ix+5),'1'

noj1b1		bit 7,a						; fire0 for joystick 0
			jr nz,noj1b0
			ld (ix+4),'0'

noj1b0		

			ld hl,joy_text
			ld a,kr_print_string
			call.lil prose_kernal			

			jp joy_loop
			
;---------------------------------------------------------------------------------------------

msg_text	db 'Displaying status of joystick ports',11
			db '-----------------------------------',11,11,0

joy_text 	db 13,'Joy 0: '
joy0		db '------ Joy 1: '
joy1		db '------',0

;---------------------------------------------------------------------------------------------
