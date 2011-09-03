;----------------------------------------------------------------------------------------------
;test 640x480 character mode 
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------


tile_map_addr	  equ 810000h						; address of tilemap in VRAM
tile_map_width	  equ 80							; x map size in tiles
tile_window_width equ 80							; x display size in tiles
tile_step		  equ 2								; each map location = 2 bytes


begin_app		ld a,00011000b
				ld (video_control),a				;tile mode:on, charmode:on, no pixel doubling, no line doubling
				ld a,0
				ld (bgnd_palette_select),a
				ld a,99
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


				ld hl,vram_a_addr					;clear first 16KB of VRAM (font location)
				ld (hl),0
				ld bc,16383
				push hl
				pop de
				inc de
				ldir

				ld hl,font							;place font in VRAM, converting linear to tile format
				ld ix,vram_a_addr
				ld c,0
font_lp2		ld b,8
font_lp1		ld a,(hl)
				ld (ix),a
;				ld (ix+1),a
;				ld (ix+2),a
;				ld (ix+3),a
;				ld (ix+4),a
;				ld (ix+5),a
;				ld (ix+6),a
;				ld (ix+7),a
				inc hl
				lea ix,ix+8
				djnz font_lp1
				dec c
				jr nz,font_lp2

				ld a,0
				call update_charmap
				

			
				ld hl,hw_palette+32
				ld b,240
pal_lp1			ld (hl),b
				inc hl
				ld a,b
				rrca
				ld (hl),a
				inc hl
				djnz pal_lp1
				
			

loopit			ld a,kr_wait_vrt
				call.lil prose_kernal
				

				ld hl,55fh							;contention indicator
				ld (hw_palette),hl
				ld bc,4000h
				ld hl,vram_a_addr
loop1			ld (hl),255
				dec bc
				ld a,b
				or c
				jr nz,loop1
				ld hl,0h
				ld (hw_palette),hl
				
				
				ld a,kr_get_key
				call.lil prose_kernal
				cp 76h
				jr z,quit

				ld a,(count)
;				inc a
				ld (count),a
;				call update_charmap
				jr loopit


quit			ld a,0ffh
				jp prose_return						;restart prose on exit


;----------------------------------------------------------------------------------------------

update_charmap

				push af
				and a,7
;				ld (tilemap_parameters+12h),a		 ; y pixel scroll position
				pop af
				
;				xor a

				ld hl,tile_map_addr					;fill 80x60 charmap 
				ld bc,80*50
				ld d,1h
				ld e,a
map_lp1			ld a,e
;				and 1
				ld (hl),a							;character number (low byte)
				inc hl
				ld (hl),7							;attribute colour (high byte)
				inc hl
				inc e
				ld a,d
				add a,1h
				cp 6h
				jr nz,dok
				ld a,1h
dok				ld d,a
				dec bc
				ld a,b
				or c
				jr nz,map_lp1
				ret
				
;----------------------------------------------------------------------------------------------				

count	db 0

		include "font.asm"

;------------------------------------------------------------------------------------------------
