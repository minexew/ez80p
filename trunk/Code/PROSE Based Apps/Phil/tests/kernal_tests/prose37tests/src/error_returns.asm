
; test error returns

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 37h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_text
			ld a,kr_print_string
			call.lil prose_kernal			
			
			ld e,2
			ld hl,input_txt
			ld a,kr_get_string
			call.lil prose_kernal
			
			ld hl,input_txt
			ld a,kr_ascii_to_hex_word
			call.lil prose_kernal
			
			ld a,e
			jp prose_return

;---------------------------------------------------------------------------------------------

msg_text	db 11,'Error return test.',11,'Input an error value:',0

input_txt	blkb 80,0
			
;---------------------------------------------------------------------------------------------
