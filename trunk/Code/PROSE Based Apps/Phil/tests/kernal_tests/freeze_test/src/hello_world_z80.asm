; Example of Z80 mode program at $010000 calling a PROSE routine (with a pointer)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 0				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; Z80-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld sp,0fffeh						; init Z80 SP stack pointer

		ld d,0
loop2	ld e,d
		ld bc,0
		ld.lil hl,vram_a_addr
		
loop1	ld.lil (hl),e
		inc.lil hl
		inc e
		dec bc
		ld a,b
		or c
		jr nz,loop1

		inc d
		jr loop2
		
;-----------------------------------------------------------------------------------------------
