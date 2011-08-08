;raster test - simple polling of flip/flop

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	109h			; 0 = dont care about HW version
prose_version_req	equ 31h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------------

			ld a,90h
			ld (0ff1805h),a
			ld a,0
			ld (0ff1806h),a
			
			ld a,01100000b
			out0 (9),a					;clear NMI interrupt flip-flops
			out0 (5),a					;ensure NMI interrupts are disabled
			
wait_rast	in0 a,(5)					;raster irq flip-flop set?
			bit 5,a
			jr z,test_key
			ld hl,77fh
			ld (hw_palette),hl			;change background colour
			ld a,00100000b
			out0 (9),a					;clear raster irq flip-flop
			ld b,100
lp1			djnz lp1			
			ld hl,0	
			ld (hw_palette),hl			;set background colour back to black
			
			
test_key	ld a,kr_get_key
			call.lil prose_kernal
			cp 76h
			jr nz,wait_rast
			
			xor a
			jp.lil prose_return
			
;------------------------------------------------------------------------------------------------