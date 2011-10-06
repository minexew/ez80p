; demos the 128 sprite registers

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	10bh			; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

				call my_prog

				xor a
				jp.lil prose_return
				
;---------------------------------------------------------------------------------------------

sprite_count	equ 128


my_prog			ld hl,message_txt
				prose_call kr_print_string

				ld hl,my_sprites					;copy sprite data to vram_b
				ld de,vram_b_addr
				ld bc,16*16*8
				ldir
				ld hl,my_sprite_colours				;copy sprite colours to palette 1
				ld de,hw_palette+512
				ld bc,256*3
				ldir

				ld a,1
				ld (sprite_palette_select),a		;use palette 1 for sprites
			
				ld a,10001b
				ld (sprite_control),a				;haltgen_mode (4), line double (3), pixel double(2), regset(1), enable(0)
				
				ld a,7
				ld (sprite_gen_stop_pos),a
				
				ld hl,priority_mask					;set priority mask (all zero, sprite infront of everything)
				ld bc,16
				ld de,0ff1100h
				ldir
				
				ld b,sprite_count					;preset the unchanging sprite registers (height and def)
				ld ix,hw_sprite_registers
				xor a
init_splp		ld (ix+4),16						;height = 16
				ld (ix+5),0							
				ld (ix+6),a							;def = 0-7
				ld (ix+7),0
				add a,10h
				and 07fh
				lea ix,ix+8
				djnz init_splp
				

;-----------------------------------------------------------------------------------------------------------------

frame_loop		prose_call kr_wait_vrt
				prose_call kr_get_key
				cp 76h
				ret z
				call update_sprites
				jr frame_loop
				
;-----------------------------------------------------------------------------------------------------------------

update_sprites

				ld a,(sine_start)
				ld (sine_pos),a
				ld a,(cos_start)
				ld (cos_pos),a
				
				ld de,0
				ld b,sprite_count
				ld ix,hw_sprite_registers

spr_loop		ld a,(sine_pos)
				add a,3
				ld (sine_pos),a
				ld de,0
				ld e,a
				ld hl,sine_table
				add hl,de
				add hl,de
				ld de,(hl)
				ld hl,0100h+320
				add hl,de
				ld (ix),l					;set x coord register
				ld (ix+1),h
				
				ld a,(cos_pos)
				sub 2
				ld (cos_pos),a
				add a,64
				ld de,0
				ld e,a			
				ld hl,sine_table
				add hl,de
				add hl,de
				ld de,(hl)
				ld hl,0200h+232
				add hl,de
				ld (ix+2),l					;set y coord register
				ld (ix+3),h
				
				lea ix,ix+8
				djnz spr_loop
						
				ld a,(sine_start)
				add a,2
				ld (sine_start),a
				ld a,(cos_start)
				add a,1
				ld (cos_start),a
				ret
				

;------------------------------------------------------------------------------------------------

message_txt			db 11,'128 Sprites :)',11,0
			
my_sprites			include 'balls_sprites.asm'

my_sprite_colours	include 'balls_12bit_palette.asm'

priority_mask		db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

sine_start			db 0
cos_start			db 0
sine_pos			db 0
cos_pos				db 0

sine_table  		include 'sine_table.asm'

;------------------------------------------------------------------------------------------------
