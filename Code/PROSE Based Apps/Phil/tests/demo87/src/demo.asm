; test tilemap mode with audio + sprites - Requires AMOEBA v87+

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0087h			; (0 = dont care about HW version)
prose_version_req	equ 001eh			; (0 = dont care about OS version)
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------
		
			call demo_code
		
			ld a,0ffh							; Restart PROSE
			jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-------------------------------------------------------------------------------------------
; Main code
;-------------------------------------------------------------------------------------------

tilemap_location	equ 60000h					; in VRAM

tilemap_width		equ 256*2

demo_code
			
;---- Set up Protracker module -------------------------------------------------------------

			xor a
			ld (relocated_samples),a
			call init_tracker				; init the module to get the start address of the samples in "sample_base"
			
			ld hl,pt_mod_end				; hl = end address of music module
			xor a
			ld bc,(sample_base)
			sbc hl,bc						; subtract location of samples
			push hl
			pop bc							; bc = length of sample data
			ld hl,(sample_base)
			ld de,vram_b_addr+40000h
			ldir							; copy sample data to audio RAM
			
			ld a,1							; init the module with the relocated sample base
			ld (relocated_samples),a
			ld hl,40000h					; offset in VRAM_B
			ld (sample_base),hl
			call init_tracker
	
;---- Set up GFX ----------------------------------------------------------------------------
						
			ld hl,tile_palette
			ld de,hw_palette
			ld bc,64*2
			ldir
			ld hl,spr_colours
			ld de,hw_palette+200h+(64*2)
			ld bc,192*2
			ldir

			ld hl,tiles							;copy 64 tiles tile set1 to tile location 0
			ld de,vram_a_addr
			ld bc,4096
			ldir
			ld hl,pointy_tile					;copy extra tile to tile location 64
			ld bc,4096
			ldir

			ld ix,vram_a_addr+tilemap_location	;make a 256x256 map in VRAM
			ld d,32
lp4			push ix
			pop hl
			ld e,32

lp3			push hl
			push de
			ld de,0								;begin with tile 0 
			ld c,8
lp2			ld b,8
lp1			ld (hl),e							;tile lsb
			inc hl
			ld (hl),d							;tile msb
			inc hl
			inc de
			djnz lp1
			push de
			ld de,tilemap_width-16
			add hl,de
			pop de
			dec c
			jr nz,lp2
			pop de
			pop hl

			ld bc,16
			add hl,bc
			dec e
			jr nz,lp3
			ld bc,tilemap_width*8
			add ix,bc
			dec d
			jr nz,lp4


			ld hl,testmap						;overlay with some other testmap data
			ld ix,tilemap_location+vram_a_addr
			ld e,0
ntline		ld b,32
ntbyte		ld c,80h
mtmlp		ld a,(hl)
			and c
			jr z,notile
			ld (ix),64							;LSB of tile def
			ld (ix+1),0							;MSB of tile def
notile		inc ix
			inc ix
			srl c
			jr nz,mtmlp
			inc hl
			djnz ntbyte
			dec e
			jr nz,ntline
			
skip
			
			ld ix,tilemap_parameters
			ld hl,tilemap_location				; set tilemap control registers 
			ld (ix),hl							; start of tilemap in VRAM

			ld hl,2
			ld (ix+04h),hl						; tilemap address increment per tile (2 bytes)

			ld hl,80000h-160
			ld (ix+08h),hl						; same tilemap line offset (80000h-160)

			ld hl,tilemap_width-160
			ld (ix+0ch),hl						; next tilemap line offset (modulo)

			ld (ix+10h),79						; set datafetch (IE: tiles - 1)
			ld (ix+11h),0						; set x hardware scroll position
			ld (ix+12h),0						; set y hw scroll position
			
			ld a,98
			ld (right_border_position),a		; mask the rightmost 8 pixels
			
;---- Set up Sprites ----------------------------------------------------------------------------
			
			ld hl,boing_sprites						; Upload sprites to vram b
			ld de,vram_b_addr
			ld bc,boing_sprites_end-boing_sprites
			ldir								
			
			ld hl,boing_sprites
			ld bc,boing_sprites_end-boing_sprites
splp1		ld a,(hl)
			or a
			jr z,zpix1
			add a,64	
zpix1		ld (de),a
			inc hl
			inc de
			dec bc									; upload version of sprites + pixel index 64
			ld a,b
			or c
			jr nz,splp1
			
			ld hl,boing_sprites						; upload version of sprites + pixel index 128
			ld bc,boing_sprites_end-boing_sprites
splp2		ld a,(hl)
			or a
			jr z,zpix2
			add a,128	
zpix2		ld (de),a
			inc hl
			inc de
			dec bc
			ld a,b
			or c
			jr nz,splp2	
			
;-------------------------------------------------------------------------------------------------
			
			call wait_vrt
			
			ld a,00001000b						
			ld (video_control),a				; tilemap mode 
			ld a,00000001b
			ld (video_control+1),a				; enable sprites
			ld a,0
			ld (video_control+2),a				; use palette 0 for background
			ld a,1
			ld (video_control+3),a				; use palette 1 for sprites
			
;----Set up timer for 50Hz-----------------------------------------------------------------------
			
			ld de,655							; set count to 655 ticks (50Hz)
			ld a,e							
			out0 (TMR0_RR_L),a					; set count value lo
			ld a,d
			out0 (TMR0_RR_H),a					; set count value hi
			ld a,00010011b							
			out0 (TMR0_CTL),a					; enable and start timer 0 (continuous mode)

;---------------------------------------------------------------------------------------------

my_loop		in0 a,(port_hw_flags)				; Has the VRT latch become set?
			bit 5,a
			call nz,vrt_routines
			
			in0 a,(TMR0_CTL)					; has 50Hz timer count looped?			
			bit 7,a
			call nz,do_tracker_update			
			
			ld a,kr_get_key
			call.lil prose_kernal
			cp 76h
			jr nz,my_loop
			ret

;-----------------------------------------------------------------------------------------------

vrt_routines

			call tilemap_stuff
			call sprite_stuff
			ld a,1								; Clear the latch flip-flop
			out0 (port_clear_flags),a
			ret

;----------------------------------------------------------------------------------------------

do_tracker_update

;			ld a,08h							; for testing only
;			ld (hw_palette+1),a					; for testing only
			
			call play_tracker					
			
;			ld a,00h							; for testing only
;			ld (hw_palette+1),a					; for testing only
			
			call update_audio_hardware			
			ret
			
;-----------------------------------------------------------------------------------------------

tilemap_stuff

			ld ix,tilemap_parameters

			ld hl,(sine)
			ld de,1
			add.sis hl,de
			ld (sine),hl
			ld a,h
			and 3									;sine table has 1024 entries
			ld h,a
			add hl,hl
			ld de,big_sine_table
			add hl,de
			ld de,0
			ld e,(hl)
			inc hl
			ld d,(hl)
			ex de,hl
			ld de,704							
			add.sis hl,de							;range is -703 to +703
			ld a,l
skip2		and 7
			ld (ix+11h),a							;set x hw scroll register
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			xor a
			add hl,hl
			push hl
			pop bc									;x map location


			ld hl,(cos)
			ld de,2
			xor a
			sbc hl,de
			jr nc,cosok
			ld de,1024								;sine table has 1024 entries
			add hl,de
cosok		ld (cos),hl
			add hl,hl
			ld de,big_sine_table
			add hl,de
			ld e,(hl)
			inc hl
			ld d,(hl)
			ex de,hl
			ld de,704							;range is -703 to +703
			add.sis hl,de
			ld a,l
			and 7
			ld (ix+12h),a						;set y hw scroll register
			ld a,l
			and 0f8h
			ld l,a
			add hl,hl							;convert y to map lines
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl							;y map location

;			ld hl,0
			add hl,bc							;add x coord
			ld bc,tilemap_location
			add hl,bc
			ld (ix),hl							; set map start register
			ret


;---------------------------------------------------------------------------------------------

sprite_stuff

			ld a,(spr_sine)
			ld d,a
			ld a,(spr_cosine)
			ld e,a

			ld a,7
			ld ix,xcoord1
			
makecoords	ld hl,0
			ld l,d
			add hl,hl
			ld bc,spr_sine_table
			add hl,bc
			ld hl,(hl)
			ld bc,400
			add hl,bc
			ld (ix),l
			ld (ix+1),h
			
			ld hl,0
			ld l,e
			add hl,hl
			ld bc,spr_sine_table
			add hl,bc
			ld hl,(hl)
			ld bc,240
			add hl,bc
			ld (ix+2),l
			ld (ix+3),h
			
			push af
			ld a,e
			add a,15
			ld e,a
			ld a,d
			add a,20
			ld d,a
			lea ix,ix+8

			pop af
			dec a
			jr nz,makecoords

			ld a,(spr_sine)
			add a,2
			ld (spr_sine),a
			ld a,(spr_cosine)
			sub a,1
			ld (spr_cosine),a
			
			ld hl,(frame_base)
			ld de,96*6
			add hl,de
			push hl
			ld de,96*6*7
			xor a
			sbc hl,de
			pop hl
			jr nz,noanlp
			ld hl,0
noanlp		ld (frame_base),hl
			ld ix,def1
			ld b,7
anim1		ld (ix),l
			ld (ix+1),h
			lea ix,ix+8
			djnz anim1
		


			ld ix,hw_sprite_registers
			ld a,6
			ld hl,(xcoord1)
			ld de,(def1)
boing1lp	ld (ix),l
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

			ld a,6
			ld hl,96*6*7
			ld de,(def2)
			add hl,de
			ex de,hl
			ld hl,(xcoord2)
boing2lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord2)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl2)
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
			jr nz,boing2lp
			
			ld a,6
			ld hl,96*6*7*2
			ld de,(def3)
			add hl,de
			ex de,hl
			ld hl,(xcoord3)
boing3lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord3)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl3)
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
			jr nz,boing3lp		
			
			ld a,6
			ld hl,0
			ld de,(def4)
			add hl,de
			ex de,hl
			ld hl,(xcoord4)
boing4lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord4)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl4)
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
			jr nz,boing4lp			
			
			ld a,6
			ld hl,96*6*7
			ld de,(def5)
			add hl,de
			ex de,hl
			ld hl,(xcoord5)
boing5lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord5)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl5)
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
			jr nz,boing5lp			
			
			ld a,6
			ld hl,96*6*7*2
			ld de,(def6)
			add hl,de
			ex de,hl
			ld hl,(xcoord6)
boing6lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord6)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl6)
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
			jr nz,boing6lp			
			
			
			ld a,6
			ld hl,0
			ld de,(def7)
			add hl,de
			ex de,hl
			ld hl,(xcoord7)
boing7lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord7)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl7)
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
			jr nz,boing7lp
			ret

;---------------------------------------------------------------------------------------------

wait_vrt
			
waitvrt1	in0 a,(port_hw_flags)		; wait for the VRT latch to become set
			bit 5,a
			jr z,waitvrt1
			ld a,1						; Clear the latch flip-flop
			out0 (port_clear_flags),a
			ret

;-----------------------------------------------------------------------------------------------

			include "routines/ADL_mode_Protracker_Player_v101.asm"
	
			include "routines/ADL_mode_Protracker_to_EZ80P_audio.asm"
			
;---------------------------------------------------------------------------------------------
; tilemap data and vars
;---------------------------------------------------------------------------------------------

sine		dw24 0
cos			dw24 129

			include 'alt_64_8x8_tiles.asm'
			include 'pointy_tile.asm'
			include 'alt_tiles_palette.asm'
			include 'testmap.asm'
			include 'big_sine_table.asm'
			
;---------------------------------------------------------------------------------------------
; sprites data and vars
;---------------------------------------------------------------------------------------------
				
xcoord1			dw 0
ycoord1			dw 0
def1			dw 0
height_ctrl1	dw 96

xcoord2			dw 0
ycoord2			dw 0
def2			dw 0
height_ctrl2	dw 96

xcoord3			dw 0
ycoord3			dw 0
def3			dw 0
height_ctrl3	dw 96

xcoord4			dw 0
ycoord4			dw 0
def4			dw 0
height_ctrl4	dw 96

xcoord5			dw 0
ycoord5			dw 0
def5			dw 0
height_ctrl5	dw 96

xcoord6			dw 0
ycoord6			dw 0
def6			dw 0
height_ctrl6	dw 96

xcoord7			dw 0
ycoord7			dw 0
def7			dw 0
height_ctrl7	dw 96

spr_sine		db 0
spr_cosine		db 0

frame_count		db 0
frame_base		dw24 0

spr_sine_table:
                db 000h,000h,005h,000h,00Ah,000h,00Fh,000h,014h,000h,018h,000h,01Dh,000h,022h,000h
                db 027h,000h,02Ch,000h,031h,000h,035h,000h,03Ah,000h,03Fh,000h,043h,000h,048h,000h
                db 04Dh,000h,051h,000h,056h,000h,05Ah,000h,05Eh,000h,063h,000h,067h,000h,06Bh,000h
                db 06Fh,000h,073h,000h,077h,000h,07Bh,000h,07Fh,000h,083h,000h,086h,000h,08Ah,000h
                db 08Dh,000h,091h,000h,094h,000h,097h,000h,09Bh,000h,09Eh,000h,0A1h,000h,0A4h,000h
                db 0A6h,000h,0A9h,000h,0ACh,000h,0AEh,000h,0B0h,000h,0B3h,000h,0B5h,000h,0B7h,000h
                db 0B9h,000h,0BBh,000h,0BCh,000h,0BEh,000h,0BFh,000h,0C1h,000h,0C2h,000h,0C3h,000h
                db 0C4h,000h,0C5h,000h,0C6h,000h,0C6h,000h,0C7h,000h,0C7h,000h,0C8h,000h,0C8h,000h
                db 0C8h,000h,0C8h,000h,0C8h,000h,0C7h,000h,0C7h,000h,0C6h,000h,0C6h,000h,0C5h,000h
                db 0C4h,000h,0C3h,000h,0C2h,000h,0C1h,000h,0BFh,000h,0BEh,000h,0BCh,000h,0BBh,000h
                db 0B9h,000h,0B7h,000h,0B5h,000h,0B3h,000h,0B0h,000h,0AEh,000h,0ACh,000h,0A9h,000h
                db 0A6h,000h,0A4h,000h,0A1h,000h,09Eh,000h,09Bh,000h,097h,000h,094h,000h,091h,000h
                db 08Dh,000h,08Ah,000h,086h,000h,083h,000h,07Fh,000h,07Bh,000h,077h,000h,073h,000h
                db 06Fh,000h,06Bh,000h,067h,000h,063h,000h,05Eh,000h,05Ah,000h,056h,000h,051h,000h
                db 04Dh,000h,048h,000h,043h,000h,03Fh,000h,03Ah,000h,035h,000h,031h,000h,02Ch,000h
                db 027h,000h,022h,000h,01Dh,000h,018h,000h,014h,000h,00Fh,000h,00Ah,000h,005h,000h
                db 000h,000h,0FBh,0FFh,0F6h,0FFh,0F1h,0FFh,0ECh,0FFh,0E8h,0FFh,0E3h,0FFh,0DEh,0FFh
                db 0D9h,0FFh,0D4h,0FFh,0CFh,0FFh,0CBh,0FFh,0C6h,0FFh,0C1h,0FFh,0BDh,0FFh,0B8h,0FFh
                db 0B3h,0FFh,0AFh,0FFh,0AAh,0FFh,0A6h,0FFh,0A2h,0FFh,09Dh,0FFh,099h,0FFh,095h,0FFh
                db 091h,0FFh,08Dh,0FFh,089h,0FFh,085h,0FFh,081h,0FFh,07Dh,0FFh,07Ah,0FFh,076h,0FFh
                db 073h,0FFh,06Fh,0FFh,06Ch,0FFh,069h,0FFh,065h,0FFh,062h,0FFh,05Fh,0FFh,05Ch,0FFh
                db 05Ah,0FFh,057h,0FFh,054h,0FFh,052h,0FFh,050h,0FFh,04Dh,0FFh,04Bh,0FFh,049h,0FFh
                db 047h,0FFh,045h,0FFh,044h,0FFh,042h,0FFh,041h,0FFh,03Fh,0FFh,03Eh,0FFh,03Dh,0FFh
                db 03Ch,0FFh,03Bh,0FFh,03Ah,0FFh,03Ah,0FFh,039h,0FFh,039h,0FFh,038h,0FFh,038h,0FFh
                db 038h,0FFh,038h,0FFh,038h,0FFh,039h,0FFh,039h,0FFh,03Ah,0FFh,03Ah,0FFh,03Bh,0FFh
                db 03Ch,0FFh,03Dh,0FFh,03Eh,0FFh,03Fh,0FFh,041h,0FFh,042h,0FFh,044h,0FFh,045h,0FFh
                db 047h,0FFh,049h,0FFh,04Bh,0FFh,04Dh,0FFh,050h,0FFh,052h,0FFh,054h,0FFh,057h,0FFh
                db 05Ah,0FFh,05Ch,0FFh,05Fh,0FFh,062h,0FFh,065h,0FFh,069h,0FFh,06Ch,0FFh,06Fh,0FFh
                db 073h,0FFh,076h,0FFh,07Ah,0FFh,07Dh,0FFh,081h,0FFh,085h,0FFh,089h,0FFh,08Dh,0FFh
                db 091h,0FFh,095h,0FFh,099h,0FFh,09Dh,0FFh,0A2h,0FFh,0A6h,0FFh,0AAh,0FFh,0AFh,0FFh
                db 0B3h,0FFh,0B8h,0FFh,0BDh,0FFh,0C1h,0FFh,0C6h,0FFh,0CBh,0FFh,0CFh,0FFh,0D4h,0FFh
                db 0D9h,0FFh,0DEh,0FFh,0E3h,0FFh,0E8h,0FFh,0ECh,0FFh,0F1h,0FFh,0F6h,0FFh,0FBh,0FFh

				include 'red_boings_palette.asm'
				include 'green_boings_palette.asm'
				include 'blue_boings_palette.asm'

				include 'boing_sprites.asm'

boing_sprites_end	db 0

;---------------------------------------------------------------------------------------------------

ALIGN 2				
				include 'stardust_memories.asm'
pt_mod_end		db 0

;----------------------------------------------------------------------------------------------------
