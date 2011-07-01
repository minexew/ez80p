;**************************
; Load a pic direct to VRAM
;**************************

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

bm_datafetch	equ 640
bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ 0

begin_app		ld a,0
				ld (video_control_regs),a			;switch off 16 colour mode
				ld (video_control_regs+1),a			;sprites off
				ld a,1
				ld (video_control_regs+2),a			;use alternate palette
				
				ld ix,bitmap_parameters					; set up bitmap mode for OS window
				ld (ix),bm_base
				ld (ix+04h),bm_pixel_step
				ld (ix+08h),0
				ld (ix+0ch),bm_modulo
				ld (ix+10h),0+(bm_datafetch/8)-1			
				
				ld a,kr_find_file
				ld hl,filename_pal
				call.lil prose_kernal
				jr nz,load_error
				ld hl,palette_regs+400h				;alternate background palette
				ld a,kr_read_file
				call.lil prose_kernal
				jr nz,load_error
				
				ld a,kr_find_file
				ld hl,filename_data
				call.lil prose_kernal
				jr nz,load_error
				ld hl,vram_a_addr
				ld a,kr_read_file
				call.lil prose_kernal
				jr nz,load_error
				
				ld a,kr_wait_key
				call.lil prose_kernal
				jr done

load_error		ld hl,load_error_txt
				ld a,kr_print_string
				call.lil prose_kernal
				
done			ld a,0ffh
				jp prose_return						;restart prose on exit

;----------------------------------------------------------------------------------------------

load_error_txt	db "Load error.",11,0
filename_pal	db "palette.bin",0
filename_data	db "picture.bin",0

;------------------------------------------------------------------------------------------------
