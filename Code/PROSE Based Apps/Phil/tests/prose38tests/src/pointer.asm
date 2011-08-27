
; test pointer (default pointer)

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

			ld a,kr_set_pointer
			ld d,1						; D = 1, default pointer
			ld e,1						; E = 1, enable pointer now
			call.lil prose_kernal	
			jr z,pointer_ok
			
			ld a,kr_print_string
			ld hl,error_msg
			call.lil prose_kernal
			jr quit
			
pointer_ok	ld a,kr_wait_key			
			call.lil prose_kernal
			
quit		ld a,kr_set_pointer
			ld e,0
			call.lil prose_kernal
			
			xor a						;return to PROSE normally
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

msg_text	db 11,'pointer test - default pointer. any key to quit',11,0
			
error_msg	db 11,'Mouse driver not enabled',11,0

;---------------------------------------------------------------------------------------------
