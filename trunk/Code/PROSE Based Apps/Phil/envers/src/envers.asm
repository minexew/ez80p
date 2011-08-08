
; Command: envers - makes environment variables PROSE and AMOEBA from vers command

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------------
; App starts here..
;------------------------------------------------------------------------------------------------

my_prog		ld a,kr_get_version
			call.lil prose_kernal

			push hl
			
			ld hl,amoeba_string+2
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			ld hl,amoeba_string
			ld e,d
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			
			pop de

			ld hl,prose_string+2
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			
			ld hl,prose_string
			ld e,d
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			
			ld hl,amoeba_name
			ld de,amoeba_string
			ld a,kr_set_envar
			call.lil prose_kernal
			
			ld hl,prose_name
			ld de,prose_string
			ld a,kr_set_envar
			call.lil prose_kernal

quit			xor a
			jp.lil prose_return
			
;-------------------------------------------------------------------------------------------

prose_name 	  db "PROSE",0
prose_string  db "xxxx",0
amoeba_name	  db "AMOEBA",0
amoeba_string db "xxxx",0

;-------------------------------------------------------------------------------------------

