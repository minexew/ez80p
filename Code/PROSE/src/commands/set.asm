;-----------------------------------------------------------------------
;"set" - set an environment variable v0.01
;
; Command should be in format: "SET BLAH=SOMETHING" 
;
;-----------------------------------------------------------------------

os_cmd_set		ld a,(hl)					; if no args, just show envars list
				or a
				jr z,show_envars

				ld de,scratch_pad+3			; parse args
evsalp1			ld a,(hl)
				ld (de),a
				or a
				jr z,set_bad_args
				cp '='
				jr z,evsadone1
				inc hl
				inc de
				jr evsalp1
evsadone1		xor a
				ld (de),a
				inc de
				inc hl
				ld (scratch_pad),de

evsalp2			ld a,(hl)
				ld (de),a
				cp ' '
				jr z,evsadone2
				or a
				jr z,set_bad_args
				inc hl
				inc de
				jr evsalp2
evsadone2		xor a
				ld (de),a
				
				ld hl,scratch_pad+3
				ld de,(scratch_pad)
				call os_set_envar
				ret

set_bad_args	ld a,82h
				or a
				ret
				

show_envars		ld hl,envar_list
				
show_envlp		ld a,(hl)
				cp 0ffh
				jr z,set_done
				push hl
				call os_print_string
				call os_new_line
				pop hl
				
set_fnl			inc hl
				ld a,(hl)
				or a
				jr nz,set_fnl
				inc hl
				jr show_envlp
				
set_done		xor a
				ret
								
;-----------------------------------------------------------------------------------------------
