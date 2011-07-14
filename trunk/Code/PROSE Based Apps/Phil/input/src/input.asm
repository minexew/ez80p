
; Command: Input "string" envar - prompts for an ascii string 
; and sets an environment variable with the data supplied (for
; scripts mainly) - V1.02 Phil 2011

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
			jr nz,bad_line

			inc hl
			
			ld de,prompt_string			;if so skip it and copy prompt string up to next quote
			ld b,80
lp1			ld a,(hl)
			cp 20h
			jr c,bad_line
			cp 22h
			jr z,got_string
			ld (de),a
			inc de
			inc hl
			djnz lp1
			jr bad_line
			
got_string	ld a,':'					;add a colon to prompt string 
			ld (de),a
			push hl
			ld a,kr_print_string		;show prompt
			ld hl,prompt_string
			call.lil prose_kernal
			pop hl
			
no_string	inc hl						;skip 2nd quote
			ld a,(hl)
			or a
			jr z,bad_line
			cp ' '						;find a space
			jr nz,no_string
			
fnspc		inc hl						;skip the space
			ld a,(hl)
			or a
			jr z,bad_line				;find non-space (the envar name)		
			cp ' '				
			jr z,fnspc
			
copy_envn	ld b,80
			ld de,envar_name
fevn		ld a,(hl)
			cp 21h
			jr c,gotevn
			ld (de),a
			inc de
			inc hl
			djnz fevn

bad_line	ld a,82h					;bad data error
			or a
			ret

gotevn		ld a,kr_get_display_size
			call.lil prose_kernal
			push bc
			ld a,kr_get_cursor_position
			call.lil prose_kernal
			pop de
			ld a,d
			sub b
			ld e,a						;max chars for value
			dec e
			ld hl,envar_value						
			ld a,kr_get_string
			call.lil prose_kernal
			push af
			ld hl,new_line
			ld a,kr_print_string
			call.lil prose_kernal
			pop af
			ret nz
			
			ld hl,envar_name
			ld de,envar_value
			ld a,kr_set_envar
			call.lil prose_kernal
			ret
				
;------------------------------------------------------------------------------------------------

new_line		db 11,0

envar_name		blkb 82,0

envar_value		blkb 82,0

usage_txt		db 'Command: INPUT.EZP (v1.02) Requests data for environment variable.',11
				db 'Usage  : INPUT ', 22h, 'string', 22h,' envar_name',11,0

prompt_string	blkb 82,0

;-------------------------------------------------------------------------------------------

