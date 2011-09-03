
; test allocate call

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 38h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_text
			ld a,kr_print_string
			call.lil prose_kernal			

			ld bc,100h
			ld e,0
			ld a,kr_allocate_ram
			call.lil prose_kernal
			
			ld bc,200h
			ld e,1
			ld a,kr_allocate_ram
			call.lil prose_kernal
			
			ld bc,300h
			ld e,2
			ld a,kr_allocate_ram
			call.lil prose_kernal
			
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

msg_text	db "Allocate memory test",11,0
