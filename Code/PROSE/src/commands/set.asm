;-----------------------------------------------------------------------
;"set" - set an environment variable v0.03
;
; Command should be in format:
;
; SET BLAH = SOMETHING
; SET BLAH = "THIS THAT"
; SET BLAH + (if numeric) to increment 24 bit value
; SET BLAH - ("        ") to decrement 24 bit value
; SET BLAH # to delete envar
;-----------------------------------------------------------------------

new_val		equ scratch_pad
value_loc	equ scratch_pad+3
arg_name	equ scratch_pad+6

os_cmd_set		ld a,(hl)						; if no args, just show envars list
				or a
				jr z,show_envars
		
				ld de,arg_name					; copy name to scratch pad
				call os_copy_ascii_run
				xor a
				ld (de),a
				inc de
				ld (value_loc),de
				
				call os_scan_for_non_space
				jr z,set_bad_args
				ld a,(hl)
				cp '+'
				jr z,set_inc
				cp '-'
				jr z,set_dec
				cp '#'
				jr z,del_env
				cp '='
				jr nz,set_bad_args
							
				call os_next_arg				; find arg value 
				jr z,set_bad_args
				ld a,(hl)
				ld c,0
				cp 022h							; is it in quotes?		
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
				
				ld hl,arg_name
				ld de,(value_loc)
				call os_set_envar
				ret

set_bad_args	ld a,82h
				or a
				ret
				

del_env			ld hl,arg_name				
				call os_delete_envar
				ret
			

set_dec			call incdec_pre
				ret nz
				dec de
				call incdec_post
				ret
				
set_inc			call incdec_pre
				ret nz
				inc de
				call incdec_post
				ret
				
incdec_pre		ld hl,arg_name				
				call os_get_envar
				ret nz
				ex de,hl
				call ascii_to_hexword		;get original value of envar in de
				ret
								
incdec_post		ld (new_val),de				;the envar must be remade in case it was originally fewer digits
				ld b,3
				ld de,new_val+2				;most signficant byte of value
				ld hl,(value_loc)
				call n_hexbytes_to_ascii
				ld (hl),0
				ld hl,arg_name				;name of envar
				push hl
				call os_delete_envar
				pop hl
				ld de,(value_loc)
				call os_set_envar
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
