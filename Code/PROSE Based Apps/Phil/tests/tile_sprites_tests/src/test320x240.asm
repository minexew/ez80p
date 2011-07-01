; test pixel and line doubling in 256 colours
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

tile_map_addr	  equ 0h							; address of tilemap in VRAM
tile_map_width	  equ 256							; x map size in tiles
tile_window_width equ 40							; x display size in tiles
tile_step		  equ 2								; each map location = 2 bytes

begin_app		ld a,00001110b
				ld (video_control),a				;256 colours, tilemap:on, pixel doubling:on, line doubling:on
				ld (vc_mirror),a
				ld a,0
				ld (bgnd_palette_select),a
				ld a,97
				ld (right_border_position),a

				ld ix,tilemap_parameters			   			  	 ; set up tilemap mode parameters 
				ld hl,tile_map_addr
				ld (ix),hl			   			  					 ; location of tilemap
				ld hl,tile_step
				ld (ix+04h),hl										 ; map increment per tile
				ld hl,80000h-(tile_window_width*tile_step)
				ld (ix+08h),hl										 ; scanline modulo
				ld hl,tile_step*(tile_map_width-tile_window_width)
				ld (ix+0ch),hl										 ; map line modulo
				ld (ix+10h),tile_window_width-1						 ; datafetch (tiles across window - 1)
				ld a,0
				ld (ix+11h),a										 ; x pixel scroll position
				ld a,0
				ld (ix+12h),a										 ; y pixel scroll position
						
				ld hl,tiles							;copy tiles to vram 40000h
				ld de,vram_a_addr+40000h
				ld bc,8*8*64
				ldir
				ld hl,colours						;copy palette data to palette 0
				ld de,hw_palette
				ld bc,256*2
				ldir	

				ld iy,vram_a_addr					;make a tilemap
				ld de,1000h							;first tile number
				ld c,8
mtmlp2			lea ix,iy+0
				ld b,8
mtmlp1			ld (ix),e
				ld (ix+1),d
				inc de
				lea ix,ix+2
				djnz mtmlp1
				push de
				ld de,tile_map_width*tile_step
				add iy,de
				pop de
				dec c
				jr nz,mtmlp2
				

				
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

loopit			ld a,kr_wait_key
				call.lil prose_kernal
				cp 76h
				jr z,quit
				
				ld a,b
				cp 'y'
				jr nz,noty
				ld hl,yhws
				inc (hl)
				ld a,(hl)
				and 7
				ld (hl),a
				ld (tilemap_parameters+12h),a
noty			ld a,b
				cp 'x'
				jr nz,notx
				ld hl,xhws
				inc (hl)
				ld a,(hl)
				and 7
				ld (hl),a
				ld (tilemap_parameters+11h),a
notx			jr loopit
				
quit			ld a,0ffh
				jp prose_return						;restart prose on exit

;----------------------------------------------------------------------------------------------

vc_mirror	db 0
xhws	db 0
yhws	db 0

include	'8x8_tiles_data.asm'
include '8x8_tiles_palette.asm'

include 'boing_96x96_sprites.asm'
include 'boing_96x96_12bit_palette.asm'

xcoord1			dw 160
ycoord1 		dw 100
def1			dw 0
height_ctrl1	dw 060h

;------------------------------------------------------------------------------------------------
