; raster test - nmi 
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	108h				; 0 = dont care about HW version
prose_version_req	equ 31h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------------
			
			ld hl,(067h)
			ld (old_nmi_vector),hl			;save OS NMI vector
			ld hl,my_nmi_handler
			ld (067h),hl					;set new NMI vector
			
			ld a,90h						;set interrupt scanline
			ld (0ff1805h),a
			ld a,0
			ld (0ff1806h),a

			ld a,01100000b
			out0 (5),a						;ensure all NMI interrupts are disabled
			out0 (9),a						;clear all NMI interrupt flip-flops
			ld a,10100000b
			out0 (5),a						;enable raster NMI

;-----------------------------------------------------------------------------------------------

main_loop	ld a,kr_wait_vrt
			call.lil prose_kernal
			ld hl,0							;set background colour black at top of screen
			ld (hw_palette),hl
		
			ld a,kr_get_key					;loop around until ESC is pressed
			call.lil prose_kernal
			cp 76h
			jr nz,main_loop

;------------------------------------------------------------------------------------------------

			ld a,00100000b
			out0 (port_irq_ctrl),a			;disable raster NMI
			ld hl,(old_nmi_vector)
			ld (067h),hl					;restore OS NMI vector
			
			xor a
			jp.lil prose_return
			
;================================================================================================

my_nmi_handler

			push hl
			push af
			ld hl,77fh
			ld (hw_palette),hl				;change background colour
			ld a,00100000b
			out0 (9),a						;clear raster interrupt flip-flop
			pop af
			pop hl		
			retn.l

;------------------------------------------------------------------------------------------------

old_nmi_vector	dw24 0
