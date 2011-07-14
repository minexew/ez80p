
; Command: Echo "string" - shows an ascii string (for scripts mainly) - V1.01 Phil 2011

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;------------------------------------------------------------------------------------------------

			call my_prog
			
			jp.lil prose_return
			
;------------------------------------------------------------------------------------------------
; App starts here..
;------------------------------------------------------------------------------------------------

my_prog		ld a,(hl)					;if no args just show usage
			or a
			jr nz,got_args
			
			ld a,kr_print_string
			ld hl,usage_txt
			call.lil prose_kernal
			xor a
			ret
			
got_args	ld a,(hl)					;is char a quote?
			cp 22h
			jr nz,got_string
			
			ld de,echo_string
			ld b,80
lp1			inc hl
			ld a,(hl)
			cp 22h
			jr z,got_string
			ld (de),a
			inc de
			djnz lp1

got_string	ld a,11
			ld (de),a					;add a <CR/LF>
						
			ld a,kr_print_string
			ld hl,echo_string
			call.lil prose_kernal
			xor a
			ret
			
;------------------------------------------------------------------------------------------------

usage_txt		db 'Command: ECHO.EZP (v1.01) Displays ASCII chars',11
				db 'Usage  : ECHO ',22h,'string',22h,11,0

echo_string		blkb 82,0

;-------------------------------------------------------------------------------------------

