;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0h				; 0 = dont care about HW version
prose_version_req	equ 0h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_text
			ld a,kr_print_string
			call.lil prose_kernal			

			call sd_initialize
			jr z,no_error
			
			ld e,a
			ld a,kr_hex_byte_to_ascii
			ld hl,error_txt
			call.lil prose_kernal
			ld hl,error_txt
			ld a,kr_print_string
			call.lil prose_kernal

no_error	xor a
			jp.lil prose_return

msg_text	db 'Testing card init routine',11,11,0

error_txt	db 'xx <- Error',11,11,0

;---------------------------------------------------------------------------------------------

include "PROSE_sdcard_driver_v110.asm"

;---------------------------------------------------------------------------------------------

sector_lba0		db 0,0,0,0

sector_buffer	blkb 512,0
