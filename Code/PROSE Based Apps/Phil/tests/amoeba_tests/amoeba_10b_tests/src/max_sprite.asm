; test max sprite count
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	10bh			; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

				call my_prog
				
				ld a,0ffh
				jp.lil prose_return

;---------------------------------------------------------------------------------------------
my_prog
;---------------------------------------------------------------------------------------------


bm_datafetch	equ 320
bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ 0

begin_app		ld a,0110b
				ld (video_control),a				;256 colours,  pixel doubling:on line doubling:on
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
				
				ld hl,my_pic						;copy pic to vram
				ld de,vram_a_addr
				ld bc,320*240
				ldir
				ld hl,my_colours					;copy palette data
				ld de,hw_palette
				ld bc,256*2
				ldir	
				

				ld hl,vram_a_addr					;just to indicate top line
				ld b,0
				ld a,15
tstlp1			ld (hl),a
				inc a
				inc hl
				djnz tstlp1		
								
				
				ld hl,my_sprite						;copy sprite data vramb
				ld de,vram_b_addr
				ld bc,16*64
				ldir
				ld hl,my_sprite_colours				;copy sprite colours to palette 1
				ld de,hw_palette+512
				ld bc,2*2
				ldir
				
				ld a,0001b
				ld (sprite_control),a
				
				ld a,1
				ld (sprite_palette_select),a		
				
				ld hl,nopriority_mask
				ld bc,16
				ld de,0ff1100h
				ldir
				
				ld a,2
				ld (sprite_gen_stop_pos),a
				
spr_loop		prose_call kr_wait_vrt

				ld ix,hw_sprite_registers
				ld b,64
				ld hl,(xcoord1)
spreglp			ld de,(ycoord1)
				ld a,0												; ctrl MSB
				call set_sprite_regs
				ld de,16
				add hl,de
				lea ix,ix+8
				djnz spreglp
				
				ld hl,(ycoord1)
;				inc hl
				ld de,0400h
				push hl
				sbc hl,de
				pop hl
				jr c,yok
				ld hl,0200h
yok				ld (ycoord1),hl

				prose_call kr_get_key
				cp 076h
				jr nz,spr_loop
				
				ret
				
;----------------------------------------------------------------------------------------------

set_sprite_regs	ld (ix),l		;x
				ld (ix+1),h		;x msb
				ld (ix+2),e		;y
				ld (ix+3),d		;y msb
				ld (ix+4),40h	;height
				ld (ix+5),a		;height/ctrl msb
				ld (ix+6),00h	;definition
				ld (ix+7),00h	;def msb
				ret
				
;----------------------------------------------------------------------------------------------

my_pic 				include	'test_pattern_chunky.asm'

my_sprite			include 'test_sprite.asm'

my_colours			include 'test_pattern_palette.asm'

my_sprite_colours	dw 0000h,0fffh
		
;------------------------------------------------------------------------------------------------

xcoord1			dw24 09ah
ycoord1 		dw24 200h

nopriority_mask	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0


;------------------------------------------------------------------------------------------------
