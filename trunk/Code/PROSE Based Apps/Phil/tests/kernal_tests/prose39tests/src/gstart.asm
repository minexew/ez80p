; G start args test - should show string that followed the address
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 39h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'


;--------------------------------------------------------------------------------------

				ld a,kr_print_string
				call.lil prose_kernal

				xor a
				jp.lil prose_return				; back to OS


;--------------------------------------------------------------------------------------
