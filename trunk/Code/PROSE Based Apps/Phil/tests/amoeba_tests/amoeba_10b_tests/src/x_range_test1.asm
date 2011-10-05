; test new x coord range 
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
				ld (video_control),a				;256 colours,  pixel doubling, line doubling etc
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
				
				ld hl,vram_a_addr					;clear vram
				ld (hl),0
				push hl
				pop de
				inc de
				ld bc,640*480
				ldir
				
				ld hl,my_pic_colours				;copy palette data
				ld de,hw_palette
				ld bc,256*2
				ldir	
				
				call show_screen_limits_320x240
				
			
				ld hl,my_sprite						;copy sprite data vramb
				ld de,vram_b_addr
				ld bc,16*64
				ldir
				ld hl,my_sprite_colours				;copy sprite colours to palette 1
				ld de,hw_palette+512
				ld bc,256*2
				ldir
				
				ld a,00001b
				ld (sprite_control),a				;haltgen_mode (4), line double (3),pixel double(2), regset(1) enable(0)
				
				ld a,1
				ld (sprite_palette_select),a		
								
				ld hl,nopriority_mask
				ld bc,16
				ld de,0ff1100h
				ldir
				
spr_loop		prose_call kr_wait_vrt

				ld de,(xcoord1)
				ld bc,(ycoord1)
				ld a,0												; ctrl MSB
				ld ix,hw_sprite_registers+(0*8)
				call set_sprite_regs

				ld hl,(xcoord1)
				ld de,32
				add hl,de
				ex de,hl
				ld bc,(ycoord1)
				ld a,80h											; ctrl MSB
				ld ix,hw_sprite_registers+(1*8)
				call set_sprite_regs
				
				ld hl,(xcoord1)
				inc hl
				ld de,1024
				push hl
				sbc hl,de
				pop hl
				jr c,yok
				ld hl,0
yok				ld (xcoord1),hl

				prose_call kr_wait_key
				cp 076h
				ret z
								
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


show_screen_limits_320x240

				ld hl,vram_a_addr					;just to indicate topmost/bottom line
				ld de,vram_a_addr+(239*320)
				ld b,0
tstlp1			and 15
				ld (hl),a
				ld (de),a
				inc a
				inc hl
				inc de
				djnz tstlp1		
								
				ld hl,vram_a_addr					;just to indicate leftmost pixel
				ld ix,vram_a_addr+319
				ld de,320
				ld b,0
tstlp2			and 15
				ld (hl),a
				ld (ix),a
				inc a
				add hl,de
				add ix,de
				djnz tstlp2		
				ret



show_screen_limits_640x480

				ld hl,vram_a_addr					;just to indicate topmost/bottom line
				ld de,vram_a_addr+(479*640)
				ld bc,640
				ld a,31
tstlp3			ld (hl),a
				ld (de),a
				inc hl
				inc de
				dec bc
				ld a,b
				or c
				jr nz,tstlp3	
								
				ld hl,vram_a_addr					;just to indicate leftmost/rightmost pixel
				ld ix,vram_a_addr+639
				ld de,640
				ld bc,640
				ld a,31
tstlp4			ld (hl),a
				ld (ix),a
				add hl,de
				add ix,de
				dec bc
				ld a,b
				or c
				jr nz,tstlp4		
				ret
					

;----------------------------------------------------------------------------------------------

my_pic 				db 0

my_sprite			include 'test_sprite.asm'

my_pic_colours		include 'test_pattern_palette.asm'

my_sprite_colours	dw 0000h,0fffh
		
;------------------------------------------------------------------------------------------------

xcoord1			dw24 0e0h
ycoord1			dw24 0200h

nopriority_mask	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

;------------------------------------------------------------------------------------------------
