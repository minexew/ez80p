; test line doubling in 256 colours
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

bm_datafetch	equ 640
bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ 0

begin_app		ld a,0010b
				ld (video_control),a				;256 colours, no pixel doubling, line doubling:on
				ld a,0
				ld (bgnd_palette_select),a
				ld a,99
				ld (right_border_position),a
				
				ld ix,bitmap_parameters				; set up bitmap mode parameters 
				ld de,bm_base
				ld (ix),de
				ld de,bm_pixel_step
				ld (ix+04h),de
				ld de,0
				ld (ix+08h),de
				ld de,0
				ld (ix+0ch),de
				ld (ix+10h),0+(bm_datafetch/8)-1		
				
				ld hl,pic							;copy pic to vram
				ld de,vram_a_addr
				ld bc,640*240
				ldir
				ld hl,colours						;copy palette data to palette 0
				ld de,hw_palette
				ld bc,256*2
				ldir	

				ld hl,sprites						;copy sprite data vramb
				ld de,vram_b_addr
				ld bc,96*96
				ldir
				ld hl,spr_colours					;copy sprite colours to palette 1
				ld de,hw_palette+512
				ld bc,256*2
				ldir
				ld a,1
				ld (sprite_control),a
				ld a,1
				ld (sprite_palette_select),a
							
				ld ix,hw_sprite_registers				;set up sprite registers
				ld a,6
				ld hl,(xcoord1)
				ld de,(def1)
boing1lp		ld (ix),l
				ld (ix+1),h
				ld bc,(ycoord1)
				ld (ix+2),c
				ld (ix+3),b
				ld bc,(height_ctrl1)
				ld (ix+4),c
				ld (ix+5),b
				ld (ix+6),e
				ld (ix+7),d
				lea ix,ix+8
				ld bc,16
				add hl,bc
				ld bc,96
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jr nz,boing1lp

				ld a,kr_wait_key
				call.lil prose_kernal
				
				ld a,0ffh
				jp prose_return						;restart prose on exit

;----------------------------------------------------------------------------------------------

include	'joystick_640x240_chunky.asm'

include 'joystick_640x240_12bit_palette.asm'

include 'boing_96x96_sprites.asm'
include 'boing_96x96_12bit_palette.asm'

xcoord1			dw 160
ycoord1 		dw 100
def1			dw 0
height_ctrl1	dw 060h

;------------------------------------------------------------------------------------------------
