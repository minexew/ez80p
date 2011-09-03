;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 31h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;-----------PART 1---------------------------------------------------------------------------------

			ld a,kr_get_os_high_mem
			call.lil prose_kernal			;get DE = highest VRAM_A location used by OS 
			ld (free_vram_start),de

			ld hl,msg1_text
			ld a,kr_print_string			; show message
			call.lil prose_kernal			
			ld a,kr_wait_key				; Wait for keypress
			call.lil prose_kernal
	
			call go_640x480_bitmap
			
			ld de,(free_vram_start)			; fill free vram with some bytes
			ld hl,880000h
			xor a
			sbc hl,de						
			ex de,hl						;DE = free bytes, HL = start address
			push de
			pop bc							;BC = bytes to fill
			dec bc
			dec bc
			ld (hl),1						;fill from this location to end of VRAM_A with $01,$06
			inc hl
			ld (hl),6
			inc hl
			push hl
			pop de
			dec hl
			dec hl
			ldir

			ld a,kr_wait_key				; Wait for keypress
			call.lil prose_kernal


;-----------PART 2----------------------------------------------------------------------------------
			
			ld a,kr_os_display				;return to os display mode
			call.lil prose_kernal
	
			ld hl,msg2_text
			ld a,kr_print_string			;show message
			call.lil prose_kernal	
			ld a,kr_wait_key				; Wait for keypress
			call.lil prose_kernal

			call go_320x240_bitmap			;go 320x240

			ld de,(free_vram_start)
			ld hl,880000h
			xor a
			sbc hl,de						
			ex de,hl						;DE = free bytes, HL = start address
			push de
			pop bc							;BC = bytes to fill
			dec bc
			dec bc
			ld (hl),2						;fill from this location to end of VRAM_A with $02,$07
			inc hl
			ld (hl),7
			inc hl
			push hl
			pop de
			dec hl
			dec hl
			ldir

			ld a,kr_wait_key				; Wait for keypress
			call.lil prose_kernal

			ld a,kr_os_display				;return to os display mode
			call.lil prose_kernal
			ld hl,msg3_text
			ld a,kr_print_string
			call.lil prose_kernal	
	
			xor a
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ 0

go_640x480_bitmap

				ld a,0000b
				ld (video_control),a				; 256 colours, no pixel doubling, no line doubling
				ld ix,bitmap_parameters				; 
				ld (ix+10h),0+(640/8)-1				; for 640 pixels across

common_parameters

				ld a,0
				ld (bgnd_palette_select),a
				ld a,99
				ld (right_border_position),a
				
				ld de,(free_vram_start)
				ld (ix),de
				ld de,bm_pixel_step
				ld (ix+04h),de
				ld de,0
				ld (ix+08h),de
				ld de,bm_modulo
				ld (ix+0ch),de									
				ret

go_320x240_bitmap

				ld a,0110b
				ld (video_control),a				; 256 colours,  pixel doubling:on, line doubling:on
				ld ix,bitmap_parameters				
				ld (ix+10h),0+(320/8)-1				; for 320 pixels across
				jp common_parameters
	

;---------------------------------------------------------------------------------------------

free_vram_start	dw24 0


msg1_text	db '640x480 - Press a key to fill VRAM unused by OS with 55 in 640x480 mode',11
			db 'then press key for next part',11,11,0
msg2_text	db 'OK, Now press a key to fill VRAM unused by OS with AA in 320x240 mode',11
			db 'then press key to quit to PROSE',11,11,0
msg3_text	db 'All done',11,0

;---------------------------------------------------------------------------------------------
