;-----------------------------------------------------------------------
;"set" - set an environment variable v0.02
;
; Command should be in format: SET BLAH = SOMETHING or SET BLAH = "THIS THAT"
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
				jr z,ev_goteq
				cp ' '
				jr z,set_fequ
				inc hl
				inc de
				jr evsalp1

set_fequ		inc hl						; find the equals sign
				ld a,(hl)
				or a
				jr z,set_bad_args
				cp '='
				jr nz,set_fequ
				
ev_goteq		inc hl
				call os_scan_for_non_space		;at equals, skip to next arg
				jr z,set_bad_args
				
				xor a
				ld (de),a
				inc de
				ld (scratch_pad),de				;address of value
				
				ld a,(hl)
				ld c,0
				cp 022h						
				jr nz,set_noquotes
				inc c
				inc hl

set_noquotes	ld a,(hl)
				ld (de),a
				bit 0,c
				jr z,set_fcs
				cp 022h
				jr z,evsadone2
				jr set_igsp
set_fcs			cp ' '
				jr z,evsadone2
set_igsp		or a
				jr z,set_bad_args
				inc hl
				inc de
				jr set_noquotes
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
