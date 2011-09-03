
;read/write rtc for time

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld a,(hl)						;if no args just show current time
			or a
			jr z,no_args
			
			push hl
			ld a,kr_read_rtc
			call.lil prose_kernal			;get existing time/date data
			pop ix
			push hl
			pop iy
			
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+2),a
			inc ix
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+1),a
			inc ix
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+0),a
			
			ld a,kr_write_rtc
			call.lil prose_kernal
			xor a
			jp prose_return
			
ascii_to_bcd

			ld a,(ix)
			inc ix
			sub a,30h
			ret c
			cp 10
			jr nc,bcderr
			rrca
			rrca
			rrca
			rrca
			and 0f0h
			ld b,a
			ld a,(ix)
			inc ix
			sub a,30h
			ret c
			cp 10
			jr nc,bcderr
			or b
			ret
bcderr		scf
			ret
			
			
bad_bcd		ld hl,bad_bcd_txt
			ld a,kr_print_string
			call.lil prose_kernal
			xor a
			jp prose_return
			



no_args		ld a,kr_read_rtc
			call.lil prose_kernal
			
			push hl
			pop ix
			ld hl,time_string
			ld a,(ix+2)					;hour
			call bcd_to_dec
			call addcolon
			ld a,(ix+1)					;min
			call bcd_to_dec
			call addcolon
			ld a,(ix)					;second
			call bcd_to_dec
			ld (hl),11
			inc hl
			ld (hl),0
			
			ld a,kr_print_string
			ld hl,time_string
			call.lil prose_kernal
			xor a
			jp prose_return

bcd_to_dec	ld b,a
			rrca
			rrca
			rrca
			rrca
			and a,15
			add a,30h
			ld (hl),a
			inc hl
			ld a,b
			and 15
			add a,30h
			ld (hl),a
			inc hl
			ret
			
addcolon	ld (hl),':'
			inc hl
			ret
			
;---------------------------------------------------------------------------------------------

bad_bcd_txt	db 'Bad arguments!',11,0

time_string db 0								; dont put anything after here

;---------------------------------------------------------------------------------------------
