;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------
	
	ld hl,test_txt
	ld a,kr_print_string
	call.lil prose_kernal

	ld hl,envar_name
	ld a,kr_get_envar
	call.lil prose_kernal
	jp nz,prose_return
	
	ex de,hl
	ld a,kr_print_string
	call.lil prose_kernal
	jp prose_return
	
		
;-----------------------------------------------------------------------------------------------

test_txt	db "Test..",11,0

envar_name	db "LUMP",0

notfound	db  "Not found",11,0
