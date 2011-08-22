
; test timeout

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

			ld a,kr_set_timeout			;set timeout period at 2 seconds (max) and start 
			ld de,65536
			call.lil prose_kernal
			
not_timed_out_yet

			ld hl,0f0fh					;stripes!
			ld (hw_palette),hl
			ld b,0
lp1			djnz lp1
			ld hl,0
			ld (hw_palette),hl
			ld b,0
lp2			djnz lp2
			
			ld a,kr_test_timeout		;has timer timed out yet?
			call.lil prose_kernal
			jr z,not_timed_out_yet		;loop until it does
			
			xor a						;return to PROSE normally
			jp prose_return

;---------------------------------------------------------------------------------------------

msg_text	db 11,'2 second time out test',11,0
			
;---------------------------------------------------------------------------------------------
