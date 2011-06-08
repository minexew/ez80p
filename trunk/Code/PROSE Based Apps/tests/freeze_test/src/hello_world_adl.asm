;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld d,0
loop2	ld e,d
		ld bc,0
		ld hl,vram_a_addr
		
loop1	ld (hl),e
		inc hl
		inc e
		dec bc
		ld a,b
		or c
		jr nz,loop1

		inc d
		jr loop2
		
;-----------------------------------------------------------------------------------------------
