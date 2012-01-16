;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
	
			call my_prog
			jp.lil prose_return
			
;---------------------------------------------------------------------------------------------

my_prog

			ld hl,filename
			ld de,append_data
			ld bc,16
			prose_call kr_write_file
			ret
			
;-----------------------------------------------------------------------------------------

filename	db "append.txt",0

append_data	db "TEST TEST TEST",13,10

;-----------------------------------------------------------------------------------------

