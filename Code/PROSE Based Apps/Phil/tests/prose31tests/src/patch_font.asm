; patch font test
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 31h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------

			ld hl,new_chars				;patch PROSE font with 8 new characters
			ld e,128					;first ascii char to patch
			ld b,8
lp1			push bc
			push de
			push hl
			ld a,kr_char_to_font
			call.lil prose_kernal			
			pop hl
			ld bc,8
			add hl,bc
			pop de
			pop bc
			inc e
			djnz lp1			
			
;----------------------------------------------------------------------------------------------

			ld b,0						;display new chars - draw a box 80x60
lp2			ld e,129
			ld c,0
			ld a,kr_plot_char
			call.lil prose_kernal
			ld e,134
			ld c,59
			ld a,kr_plot_char
			call.lil prose_kernal
			inc b
			ld a,b
			cp 80
			jr nz,lp2
					
			ld c,0
lp3			ld e,131
			ld b,0
			ld a,kr_plot_char
			call.lil prose_kernal
			ld e,132
			ld b,79
			ld a,kr_plot_char
			call.lil prose_kernal
			inc c
			ld a,c
			cp 60
			jr nz,lp3
			
			ld b,0
			ld c,0
			ld e,128
			ld a,kr_plot_char
			call.lil prose_kernal
			ld b,79
			ld c,0
			ld e,130
			ld a,kr_plot_char
			call.lil prose_kernal
			ld b,0
			ld c,59
			ld e,133
			ld a,kr_plot_char
			call.lil prose_kernal
			ld b,79
			ld c,59
			ld e,135
			ld a,kr_plot_char
			call.lil prose_kernal
				
;			ld a,kr_wait_key				; Wait for keypress
;			call.lil prose_kernal

quit		xor a
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

new_chars	db 0ffh,080h,080h,080h,080h,080h,080h,080h
			db 0ffh,000h,000h,000h,000h,000h,000h,000h
			db 0ffh,001h,001h,001h,001h,001h,001h,001h
			db 080h,080h,080h,080h,080h,080h,080h,080h
			db 001h,001h,001h,001h,001h,001h,001h,001h
			db 080h,080h,080h,080h,080h,080h,080h,0ffh
			db 000h,000h,000h,000h,000h,000h,000h,0ffh
			db 001h,001h,001h,001h,001h,001h,001h,0ffh
;---------------------------------------------------------------------------------------------
