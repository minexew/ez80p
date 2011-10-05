; tilemode test: hi-res + sprites

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

tile_map_addr	  equ 0h							; address of tilemap in VRAM
tile_map_width	  equ 256							; x map size in tiles
tile_window_width equ 80							; x display size in tiles
tile_step		  equ 2								; each map location = 2 bytes

my_prog			ld a,00001000b
				ld (video_control),a				;256 colours, tilemap:on, no pixel doubling, no line doubling
				ld (vc_mirror),a
				ld a,0
				ld (bgnd_palette_select),a
				ld a,98
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
						
				ld hl,tiles											;copy tiles to vram 40000h
				ld de,vram_a_addr+40000h
				ld bc,8*8*64
				ldir
				ld hl,colours										;copy palette data to palette 0
				ld de,hw_palette
				ld bc,256*2
				ldir	

				ld hl,vram_a_addr									;fill charmap with first tile
				push hl
				pop de
				ld bc,1000h
				ld (hl),c
				inc hl
				ld (hl),b
				inc hl
				ex de,hl
				ld bc,0+(tile_map_width*60*2)-2
				ldir

				ld iy,vram_a_addr									;make a tilemap
				ld de,1000h											;first tile number
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
				
				ld hl,my_sprite						;copy sprite data vramb
				ld de,vram_b_addr
				ld bc,16*64
				ldir
				ld hl,my_sprite_colours				;copy sprite colours to palette 1
				ld de,hw_palette+512
				ld bc,256*3
				ldir
				
				ld a,01101b
				ld (sprite_control),a				;haltgen_mode (4), line double (3),pixel double(2), regset(1) enable(0)
				
				ld a,1
				ld (sprite_palette_select),a		
								
				ld hl,nopriority_mask
				ld bc,16
				ld de,0ff1100h
				ldir
				
spr_loop		ld a,(rbord)
				ld (right_border_position),a
				
				ld de,(xcoord)
				ld bc,(ycoord)
				ld a,0												; ctrl MSB
				ld ix,hw_sprite_registers+(0*8)
				call set_sprite_regs

				prose_call kr_wait_key
				cp 076h
				ret z
				
				ld a,b
				cp 'x'
				jr nz,notxinc
				ld hl,(xcoord)
				inc hl
				ld (xcoord),hl

notxinc			cp 'X'
				jr nz,notxdec
				ld hl,(xcoord)
				dec hl
				ld (xcoord),hl

notxdec			cp 'y'
				jr nz,notyinc
				ld hl,(ycoord)
				inc hl
				ld (ycoord),hl

notyinc			cp 'Y'
				jr nz,notydec
				ld hl,(ycoord)
				dec hl
				ld (ycoord),hl

notydec			
				jr spr_loop
				
;----------------------------------------------------------------------------------------------


set_sprite_regs	ld (ix),e		;x LSB
				ld (ix+1),d		;x MSB
				ld (ix+2),c		;y LSB
				ld (ix+3),b		;y MSB
				ld (ix+4),40h	;height LSB
				or 0
				ld (ix+5),a		;height MSB / ctrl bits
				ld (ix+6),00h	;definition LSB
				ld (ix+7),00h	;definition MSB
				ret

;----------------------------------------------------------------------------------------------

my_sprite			include 'test_sprite2.asm'

my_sprite_colours	dw 0000h,0fffh,0ff0h
		
;------------------------------------------------------------------------------------------------

xcoord			dw24 0100h
ycoord			dw24 0200h

nopriority_mask	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

rbord			db 99

;------------------------------------------------------------------------------------------------

vc_mirror	db 0
xhws	db 0
yhws	db 0

tiles 

	include	'8x8_tiles.asm'

colours

	include '8x8_tiles_palette.asm'

;------------------------------------------------------------------------------------------------
