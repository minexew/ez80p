; Example of Z80 mode program at $010000 calling a PROSE routine (with a pointer)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 0				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; Z80-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld sp,0fffeh						; init Z80 SP stack pointer
		
		ld hl,message_txt					; As it is a Z80 routine, PROSE kernal will use MBASE for [23:16] 
		ld a,kr_print_string				; Desired routine
		call.lil prose_kernal				; calls to PROSE kernal need to be ADL mode
		
		xor a
		jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

message_txt

		db 'Hello (Z80 mode) World!',11,0

;-----------------------------------------------------------------------------------------------
		
		