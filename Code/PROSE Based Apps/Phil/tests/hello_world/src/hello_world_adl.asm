; Example of ADL mode program at $010000 calling a PROSE kernal routine (with a pointer)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld hl,message_txt				; string to print
		prose_call kr_print_string		; "prose_call" is a MACRO defined in "PROSE_header"
										; it is defined as "ld a,<argument> .. call.lil prose_kernal"
		
		xor a							; no error on return
		jp.lil prose_return				; return back to OS

;-----------------------------------------------------------------------------------------------

message_txt

		db 'Hello (ADL mode) world!',11,0

;-----------------------------------------------------------------------------------------------
		
		