;read/write rtc for date

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld a,(hl)
			or a
			jr z,no_args					; in no args, just show date
			
			push hl
			ld a,kr_read_rtc
			call.lil prose_kernal			;get existing time/date data
			pop ix
			push hl
			pop iy
			
			call ascii_to_bcd				;update values
			jr c,bad_bcd
			ld (iy+4),a						;date
			inc ix
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+5),a						;month
			inc ix
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+7),a						;century
			call ascii_to_bcd
			jr c,bad_bcd
			ld (iy+6),a						;year

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
			ld hl,date_string

			ld a,(ix+4)					;date
			call bcd_to_dec
			call addhyphen
			ld a,(ix+5)					;month
			call bcd_to_dec
			call addhyphen
			ld a,(ix+7)					;century
			call bcd_to_dec
			ld a,(ix+6)					;year
			call bcd_to_dec
			ld (hl),11
			inc hl
			ld (hl),0
			
			ld a,kr_print_string
			ld hl,date_string
			call.lil prose_kernal
			xor a
			ret

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
	
			
addhyphen	ld (hl),'-'
			inc hl
			ret

;---------------------------------------------------------------------------------------------

bad_bcd_txt	db 'Bad arguments!',11,0

date_string db 0							;dont put anything after this

;---------------------------------------------------------------------------------------------
