;---------------------------------------------------------------------------------------------------------------
; echo v0.01
;----------------------------------------------------------------------------------------------------------------

os_cmd_echo

			ld a,(hl)					;if no args just show usage
			or a
			jr nz,got_args
			ld a,81h					;no data error
			or a
			ret


got_args	ld de,scratch_pad
			ld a,(hl)					;is char a quote?
			cp 22h
			jr nz,got_string
						
			ld b,80
echolp1		inc hl
			ld a,(hl)
			cp 22h
			jr z,got_string
			ld (de),a
			inc de
			djnz echolp1

got_string	ld a,11
			ld (de),a					;add a <CR/LF>
			inc de
			xor a
			ld (de),a
			
			ld hl,scratch_pad
			call os_print_string
			xor a
			ret
			
;------------------------------------------------------------------------------------------------

