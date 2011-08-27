
; test pointer (custom pointer)

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

			ld d,0						; D = 0, custom pointer
			ld e,1						; E = 1, enable pointer now
			ld c,32						; C = height
			ld b,3						; B = hw palette to use
			ld hl,custom_pointer		; HL = source address of pointer data
			ld a,kr_set_pointer
			call.lil prose_kernal	
			jr z,pointer_ok
			
			ld a,kr_print_string
			ld hl,error_msg
			call.lil prose_kernal
			jr quit
			
pointer_ok	ld a,kr_wait_key			
			call.lil prose_kernal
			
			
quit		ld e,0						;e=0, disable pointer
			ld a,kr_set_pointer			
			call.lil prose_kernal
			
			xor a						;return to PROSE normally
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

msg_text	db 11,'custom pointer test - default pointer. any key to quit',11,0
			
error_msg	db 11,'Mouse driver not enabled',11,0

custom_pointer

			include 'custom_pointer_data.asm'

;---------------------------------------------------------------------------------------------
