;----------------------------------------------------------------------------------------------
; minimal code example to set up a 320x240 256 colour display
; (plus example of writing one pixel to vram every frame)
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0h				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

				call my_prog
				
				ld a,0ffh				;restart PROSE upon return
				jp.lil prose_return

my_prog

;---------------------------------------------------------------------------------------------
; Init video mode
;---------------------------------------------------------------------------------------------

bm_datafetch	equ 320			;number of bytes hardware reads from VRAM_A per line
bm_modulo		equ 0			;number of bytes hardware skip at the end of each line
bm_pixel_step	equ 1			;number of bytes hardware increments each pixel
bm_base			equ 0800000h	;address of the first byte of the display

				ld a,00110b
				ld (video_control),a				;set 256 colour mode, pixel and line doubling on
				ld a,0
				ld (bgnd_palette_select),a			;background (non-sprite) data to use palette 0
				ld a,99
				ld (right_border_position),a		;set the right side border at the default location
		
				ld ix,bitmap_parameters				; write bitmap mode parameters to video registers 
				ld de,bm_base
				ld (ix),de
				ld de,bm_pixel_step
				ld (ix+04h),de
				ld de,0
				ld (ix+08h),de
				ld de,0
				ld (ix+0ch),de
				ld (ix+10h),0+(bm_datafetch/8)-1			

				ld ix,hw_palette					; put some colours in the palette
				ld hl,0
				ld de,29
				ld b,0
pal_lp1			ld (ix),l
				ld (ix+1),h
				lea ix,ix+2
				add hl,de
				djnz pal_lp1

				ld hl,bm_base						; clear the 320x240 bitmap
				ld (hl),0
				push hl
				pop de
				inc de
				ld bc,320*240
				ldir


;------------------------------------------------------------------------------------------------
; This part just writes a new pixel to the display every frame - ESC to quit
;------------------------------------------------------------------------------------------------

				ld b,0
				ld hl,bm_base
								
frame_loop		push hl
				push bc
				prose_call kr_wait_vrt				;wait for a new frame (60Hz)
				pop bc
				pop hl
				
				ld (hl),b							;write a pixel to display
				inc hl
				inc b
				
				push hl
				ld de,bm_base+(320*240)
				xor a
				sbc hl,de
				pop hl
				jr nz,addr_ok
				ld hl,bm_base
				
addr_ok			push hl
				push bc
				prose_call kr_get_key				;check for a key press
				pop bc
				pop hl
				cp 076h								;if ESC not pressed loop around
				jr nz,frame_loop
				ret

;------------------------------------------------------------------------------------------------
