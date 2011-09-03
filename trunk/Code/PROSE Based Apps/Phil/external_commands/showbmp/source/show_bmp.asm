; Show_BMP command, v 0.01 - By Phil Ruston

;----------------------------------------------------------------------------------------------
; ADL mode PROSE executable header
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

;			ld hl,test_fn
					
			ld a,(hl)						; get filename from command string. If 0, no filename supplied
			or a
			jr z,no_args
			
			call load_header
			jr nz,load_error
			
			call test_bmp_parameters
			jr nz,bmp_bad
			
			call load_pic
			jr nz,load_error
			
			call clear_vram_buffer
			
			call copy_pic_to_vram
			
			call set_video_mode
			
			ld a,kr_wait_key
			call.lil prose_kernal
			
			ld a,kr_os_display
			call.lil prose_kernal
			
			xor a							; Restart PROSE on exit
			jp.lil prose_return			


;------------------------------------------------------------------------------------------

no_args		ld hl,no_args_em
			jr text_exit


load_error
			ld hl,load_em
			jr text_exit



bmp_bad		ld e,3							;show relevant error message
			dec a
			ld d,a
			mlt de
			ld ix,err_msg_table
			add ix,de
			ld hl,(ix)

text_exit	ld a,kr_print_string
			call.lil prose_kernal
			xor a
			ret
			
;-------------------------------------------------------------------------------------------


load_header	ld a,kr_find_file				; look for file on disk
			call.lil prose_kernal
			ret nz

			ld de,1024+54					; just load the header for now
			ld a,kr_set_load_length
			call.lil prose_kernal

			ld hl,pic_buffer				; load data to buffer
			ld a,kr_read_file
			call.lil prose_kernal
			ret


load_pic	ld hl,loading_txt						 
			ld a,kr_print_string
			call.lil prose_kernal

			ld de,640*480					; load 307200 bytes max
			ld a,kr_set_load_length
			call.lil prose_kernal
			
			ld hl,pic_buffer				; load rest of pic data to buffer
			ld a,kr_read_file
			call.lil prose_kernal
			ret z
			cp 0cch							; will have attempted load beyond end of file
			ret								; this is fine, dont want it to return an error

;-------------------------------------------------------------------------------------------

test_bmp_parameters

			ld hl,(pic_buffer)			; check header info
			ld de,04d42h
			xor a
			sbc.sis hl,de
			jp z,bmp_id_ok
			ld a,1						;error 1 = no BMP ID bytes
			ret

bmp_id_ok	ld hl,(pic_buffer+28)
			ld de,8
			xor a
			sbc.sis hl,de
			jr z,coldep_ok
			ld a,2						;error 2 = not 256 colours
			ret
			
coldep_ok	ld hl,(pic_buffer+30)
			ld a,h
			or l
			jr z,cmpr_ok
			ld a,3						;error 3 = pic has compression
			ret

cmpr_ok		ld hl,(pic_buffer+18)
			ld (pic_width),hl
			ld a,l	
			and 7
			jr z,wmult8_ok
			ld a,4						;error 4 = pic is not a multiple of x pixels wide
			ret

wmult8_ok	ld hl,(pic_width)
			ld de,641
			xor a
			sbc.sis hl,de
			jr c,width_ok
			ld a,5						;error 5 = pic is too wide
			or a
			ret
			
width_ok	ld hl,(pic_buffer+22)
			ld (pic_height),hl
			ld de,481
			xor a
			sbc.sis hl,de
			jr c,height_ok
			ld a,6						;error 6 = pic is too tall
			or a
			ret

height_ok	

			ld de,hw_palette+(2*256)	;convert palette from 24bit to 12bit
			ld hl,pic_buffer+54			;start of 24 bit palette
			ld b,0						;256 colours to do
palclp		ld c,(hl)
			inc hl
			srl c
			srl c
			srl c
			srl c						;12 bit blue
			ld a,(hl)
			inc hl
			and 0f0h					;12 bit green << 4
			or c
			ld (de),a
			inc de
			ld a,(hl)
			inc hl
			inc hl
			srl a
			srl a
			srl a
			srl a
			ld (de),a
			inc de
			djnz palclp

			xor a
			ret

;-------------------------------------------------------------------------------------------

clear_vram_buffer

			ld hl,bm_base
			ld (hl),0
			push hl
			pop de
			inc de
			ld bc,640*480
			dec bc
			ldir
			ret
			

copy_pic_to_vram

			ld hl,640/2					;find offset to centre pic on display x
			ld de,(pic_width)
			srl d
			rr e
			xor a
			sbc.sis hl,de
			ld bc,0
			ld c,l
			ld b,h

			ld hl,480/2					;find offset to centre pic on display y
			ld de,(pic_height)
			srl d
			rr e
			xor a
			sbc.sis hl,de
			
			ld h,640/8					;calculate first pixel plot address
			mlt hl
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,bc
			ld bc,bm_base
			add hl,bc
			push hl						;vram dest address
						
			ld hl,pic_buffer			;start of bmp pixel data (but last line since bmps are upside down)
			ld de,(pic_width)
			ld bc,(pic_height)
			dec bc
lp1			add hl,de
			dec bc
			ld a,b
			or c
			jr nz,lp1
			
			pop de						;hl = source addres, de = dest address
			ld bc,(pic_height)
ctvlp		push bc
			ld bc,(pic_width)
			push de
			push hl
			ldir
			pop hl
			pop de
			ld bc,(pic_width)
			xor a
			sbc hl,bc
			ex de,hl
			ld bc,640
			add hl,bc					;next line of display
			ex de,hl
			pop bc
			dec bc
			ld a,b
			or c
			jr nz,ctvlp
			ret
		

;-------------------------------------------------------------------------------------------

bm_datafetch	equ 640
bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ vram_a_addr+35000h

set_video_mode

			ld a,kr_wait_vrt					; display swap when raster is off-screen
			call.lil prose_kernal
			
			ld a,0000b							; set up bitmap display  
			ld (video_control),a				; 256 colours, no pixel doubling, no line doubling
			ld a,1
			ld (bgnd_palette_select),a			; use palette 1
			ld a,99
			ld (right_border_position),a		; right border in normal location
				
			ld ix,bitmap_parameters				; set bitmap mode parameters 
			ld hl,bm_base
			ld (ix),hl
			ld hl,bm_pixel_step
			ld (ix+04h),hl
			ld hl,0
			ld (ix+08h),hl
			ld hl,bm_modulo
			ld (ix+0ch),hl
			ld (ix+10h),0+(bm_datafetch/8)-1			
			ret
			

;-------------------------------------------------------------------------------------------

test_fn			db "640x480.bmp",0

pic_height		dw24 0
pic_width		dw24 0

em1				db "Not a .BMP file",11,0
em2				db "Not a 256 colour .BMP file",11,0
em3				db "Cannot display compressed .BMP files",11,0
em4				db "Pic must be multiple of 8 pixels wide",11,0
em5				db "Pic is too wide (640 pixels max)",11,0
em6				db "Pic is too tall (480 pixels max)",11,0

err_msg_table	dw24 em1,em2,em3,em4,em5,em6

loading_txt		db "Loading..",11,0

load_em			db "Load error - file not found?",11,0

no_args_em		db 11,"SHOWBMP.EZP - V0.01. Displays .BMP format graphics files.",11,11
				db "Usage:",11,"SHOWBMP [filename]",11,11,0

pic_buffer		db 0

;--------------------------------------------------------------------------------------------
