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

my_tile_map_base 	equ 800000h				; address of tilemap (must be in VRAM_A)
tile_map_width	  	equ 40					; overal width of map
tile_window_width 	equ 40					; display width in tiles 
tile_step		  	equ 2					; each tile map location = 2 bytes

				ld a,01110b
				ld (video_control),a								; set tile mode, pixel and line doubling on, 256 colours
				ld a,0
				ld (bgnd_palette_select),a							; background (non-sprite) data to use palette 0
				ld a,99
				ld (right_border_position),a						; set the right side border at the default location
		
				ld ix,tilemap_parameters			   			  	; set up tilemap mode parameters 
				ld hl,my_tile_map_base
				ld (ix),hl			   			  					; location of tilemap
				ld hl,tile_step
				ld (ix+04h),hl										; map increment per tile
				ld hl,80000h-(tile_window_width*tile_step)
				ld (ix+08h),hl										; scanline modulo
				ld hl,tile_step*(tile_map_width-tile_window_width)
				ld (ix+0ch),hl										; map line modulo
				ld (ix+10h),tile_window_width-1						; datafetch (tiles across window - 1)
				ld a,0
				ld (ix+11h),a										; x pixel scroll position
				ld a,0
				ld (ix+12h),a										; y pixel scroll position
						
				ld hl,tiles_def_data								; copy some tile definition data to vram_a + 40000h (tile 4096 and 4097)
				ld de,vram_a_addr+40000h
				ld bc,8*8*2
				ldir

				ld hl,tile_colours									;copy palette data to palette 0
				ld de,hw_palette
				ld bc,256*2
				ldir	

				ld hl,vram_a_addr									;fill tile map with tile 4096
				push hl
				pop de
				ld bc,4096
				ld (hl),c
				inc hl
				ld (hl),b
				inc hl
				ex de,hl
				ld bc,0+(tile_map_width*30*2)-2
				ldir


;------------------------------------------------------------------------------------------------
; This part just writes a new tile (two bytes) to the tilemap every frame - ESC to quit
;------------------------------------------------------------------------------------------------

				ld bc,4097
				ld hl,vram_a_addr
								
frame_loop		push hl
				push bc
				prose_call kr_wait_vrt								;wait for a new frame (60Hz)
				pop bc
				pop hl
				
				ld (hl),c											;write tile 4093 to display
				inc hl
				ld (hl),b
				inc hl
				
				push hl
				ld de,vram_a_addr+(40*30*2)
				xor a
				sbc hl,de
				pop hl
				jr nz,addr_ok
				ld hl,my_tile_map_base
				ld a,c
				xor 1
				ld c,a
				
addr_ok			push hl
				push bc
				prose_call kr_get_key								;check for a key press
				pop bc
				pop hl
				cp 076h												;if ESC not pressed loop around
				jr nz,frame_loop
				ret

;------------------------------------------------------------------------------------------------
; Some tile data
;------------------------------------------------------------------------------------------------

tiles_def_data

	include	'two_tiles.asm'

tile_colours

	include 'tile_palette.asm'

;------------------------------------------------------------------------------------------------

