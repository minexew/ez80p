;---------------------------------------------------------------------------------------------------------------
; PROSE script routines V0.05
;
; Notes: Changing drives within a script not supported yet.
;        Scripts cannot launch scripts as this would require nested script filenames
;		 Abort with CRTL + C
;
;       About: IF statement.. Syntax = IF envar condition [VAL] string [GOTO] label
;
;		condition can be "=" / "<>" for string comparisons or "=" / "<>" / "<" or ">" for numeric comparisons
;		if string is within (brackets), it is interpreted as another environment variable
;		if "VAL" is included, string is interpreted as a 24bit number
;		"GOTO" can be omitted if desired.
;       (destination labels must be declared as "[xyz]" IE: with square brackets at start of a line, with no other characters on that line.)
;----------------------------------------------------------------------------------------------------------------

max_if_chars		equ 16 ;(string size for envar name, value and label)

scr_in_script		equ 0
scr_find_new_line	equ 1
scr_numeric_comp	equ 2
scr_end				equ 3


os_do_script	call run_script
				ld hl,script_flags
				res scr_in_script,(hl)
				ret
				
run_script		ld hl,script_flags	
				set scr_in_script,(hl)

				call os_check_volume_format			; going in, make sure volume is vaiid
				ret nz
				
				call new_script

;-----------------------------------------------------------------------------------------------------------


scrp_loop		ld a,(key_mod_flags)				; exit script if CTRL-C is pressed
				and 2
				jr z,no_quit_script	
				call os_get_key_press
				cp 021h								; scancode for "C"
				jr nz,no_quit_script

				ld hl,script_aborted_msg
				call os_show_packed_text
				xor a								; script aborted error message
				ret
					

no_quit_script	call get_script_line	
				ret nz
				ld hl,script_flags					;check to see if we're at the end of the script file
				bit scr_end,(hl)
				jr z,scr_to_do
scr_done		xor a
				ret
				
scr_to_do		ld hl,commandstring					;is command a label? skip it if so..
				ld a,(hl)
				cp '['
				jr z,exec_scr_next

				ld de,if_command_txt				;is command an "IF" instruction?
				ld b,3
				call os_compare_strings
				jr z,do_exec_if
				
				ld de,goto_txt						;is command an "GOTO" instruction?
				ld b,5
				call os_compare_strings
				jr z,scr_goto
				
				ld de,end_command_txt				;is command an "END" instruction?
				ld b,4
				call os_compare_strings
				jr z,scr_done
			
				call os_parse_cmd_chk_ps			;attempt to launch commands (check for spawn progs)
				
exec_scr_next	ld hl,script_flags
				set scr_find_new_line,(hl)
				jr scrp_loop

scr_goto		call os_next_arg
				call copy_goto_label
				jp if_cond_met
				
;-----------------------------------------------------------------------------------------------

; Handle "IF" instructions


do_exec_if		ld hl,commandstring				;move to envar name following "IF"
				call os_next_arg
				jr z,script_error				;give up if encountered zero (didn't find name)
				
				ld ix,script_flags
				res scr_numeric_comp,(ix)		;is it "VAL " ? - if so set numeric comparison flag 
				ld de,val_txt
				ld b,4
				call os_compare_strings
				jr nz,not_val
				set scr_numeric_comp,(ix)
				call os_next_arg
				jr z,script_error
				
not_val			ld de,if_name_txt
				ld b,max_if_chars
				call os_copy_ascii_run			;save envar name string (argument 1)
				xor a
				ld (de),a
				
				call os_scan_for_non_space		;look for the condition (already found a space)
				jr z,script_error
			
				ld b,0
				ld a,(hl)
				cp '='
				jr z,got_ifcond					;if cond = "=", cond = 0
				inc b
				cp '>'
				jr z,got_ifcond					;if cond = ">" cond = 1
				inc b
				cp '<'
				jr nz,script_error				;if cond = "<" cond = 2
				inc hl
				ld a,(hl)
				dec hl
				cp '>'							;if cond = "<>" cond = 3	
				jr nz,got_ifcond
				inc b
got_ifcond		ld a,b
				ld (if_condition),a
				
				call os_next_arg				;look for string following the condition
				jr z,script_error
				
				ld b,max_if_chars
				ld de,if_value_txt				;hl @ compare string
				ld a,(hl)
				cp 22h							;is the compare string in quotes?
				jr nz,ifa2nq					;if so copy the string between the quotes
iffq2			inc hl
				ld a,(hl)
				or a
				jr z,script_error
				cp 22h
				jr z,ifctq2
				ld (de),a
				inc de
				djnz iffq2
ifctq2			xor a
				ld (de),a
				call os_scan_for_space
				or a
				jr z,script_error
				jr if_arg2_done
				
ifa2nq			call os_copy_ascii_run			;no quotes, this is another Envar name
				xor a
				ld (de),a
				push hl							;now look up the envar's contents
				ld hl,if_value_txt
				call os_get_envar
				ex de,hl
				jr z,scr_ev2ok
				pop hl
				ret
scr_ev2ok		ld b,max_if_chars
				ld de,if_value_txt
				call os_copy_ascii_run
				xor a
				ld (de),a
				pop hl

if_arg2_done	call os_scan_for_non_space			;is there a "GOTO " before label?
				jr z,script_error
				ld de,goto_txt
				ld b,5
				call os_compare_strings
				jr nz,no_goto
				call os_next_arg					;if so, skip it
				jr z,script_error

no_goto			call copy_goto_label

if_compare_args	ld a,(if_value_txt)					;is the IF merely a test for existence of an ENVAR?
				cp '*'
				jr nz,not_an_exist_test
				ld hl,if_name_txt					;does this envar exist? 
				call os_get_envar
				jr nz,doesnt_exist
				ld a,(if_condition)					;it does exist, does that satisfy condition?
				or a
				jp z,if_cond_met
if_cond_failed  jp exec_scr_next
doesnt_exist	ld a,(if_condition)
				cp 3
				jp z,if_cond_met
				jr if_cond_failed

not_an_exist_test

				ld hl,script_flags
				bit scr_numeric_comp,(hl)
				jr z,not_numeric_if				; is this a numeric comparison?
				
				ld hl,if_name_txt
				call os_get_envar				; DE points to contents on return
				ret nz
				ex de,hl			
				call ascii_to_hexword			; yes, convert strings to hex_numbers (if possible)
				ret nz							; DE = value of first arg
				push de
				ld hl,if_value_txt
				call ascii_to_hexword			; get value of second arg in DE
				pop hl							; get value of first arg in HL
				ret nz
				ld a,(if_condition)
				ld b,a
				xor a
				sbc hl,de
				jr nz,numeric_diff			
				ld a,b							;the values are the same, does that satisfy the condition?
				or a	
				jr z,if_cond_met
				jr if_cond_failed

numeric_diff	jr nc,value_smaller
				ld a,b							;the (2nd) value is bigger, does that satisfy the condition?
				cp 2
				jr z,if_cond_met
				cp 3
				jr z,if_cond_met
				jr if_cond_failed

value_smaller	ld a,b							;the (2nd) value is smaller, does that satisfy the condition?
				cp 1
				jr z,if_cond_met
				cp 3
				jr z,if_cond_met
				jr if_cond_failed
				

not_numeric_if	ld hl,if_name_txt 
				call os_get_envar
				ret nz
				
				ld hl,if_value_txt
				call os_compare_strings			
				jr nz,if_str_diff
				ld a,(if_condition)
				or a
				jr z,if_cond_met
				jr if_cond_failed
if_str_diff		ld a,(if_condition)
				cp 3
				jr z,if_cond_met
				jr if_cond_failed
				
				
				
if_cond_met		call new_script					;Condition met. Go to start of script and find label..

find_if_label	call get_script_line				
				ret nz
				ld hl,script_flags
				bit scr_end,(hl)
				jp nz,scr_done
				
				ld hl,commandstring				;does this line begin with a "[" ?
				ld a,(hl)
				cp '['
				jr nz,not_a_label				;no, so ignore it and move to next line.
				
if_find_csb		inc hl
				ld a,(hl)
				or a
				jr z,not_a_label				
				cp ']'							;find closing square bracket
				jr nz,if_find_csb
				ld (hl),0						;replace bracket with zero for string compare
				ld hl,commandstring+1
				ld de,if_label_txt				;yes, so compare the characters with the goto lable
				ld b,max_if_chars
				call os_compare_strings
				jp z,exec_scr_next				;if correct label go back to executing script, at following line

not_a_label		ld hl,script_flags
				set scr_find_new_line,(hl)		;not correct label, continue looking for labels
				jr find_if_label
											
;---------------------------------------------------------------------------------------------------------------------


new_script		push hl
				ld hl,0
				ld (script_file_offset),hl			;reset to start of script file
				ld hl,script_flags
				res scr_find_new_line,(hl)			
				res scr_end,(hl)
				pop hl
				ret


;-----------------------------------------------------------------------------------------------
	
	
get_script_line
				
				call fs_get_dir_cluster				;store current dir (prior to going back to the script dir)
				ld (script_orig_dir),de				
				ld de,(script_dir)					;return to dir that contains the script
				call fs_update_dir_cluster

				call open_script					;open script file
				jr nz,scr_error
				call read_script					;move to offset location and read in a line from script file
								
scr_error		push af
				ld de,(script_orig_dir)				;go back to the directory we were at before the script line was read
				call fs_update_dir_cluster
				pop af
				ret


;---------------------------------------------------------------------------------------------------------------------


open_script		ld hl,script_fn						;locate the script file - this needs to be done every
				call os_find_file					;script line as external commands will have opened files
				ret nz
				
				ld (script_length),de				;save the script length							
				ld a,c								;if script filesize is over 16MB: error!
				or a
				ret z
				
script_error	ld a,08ch							;else return a script error
				or a
				ret
				

;---------------------------------------------------------------------------------------------------------------------


read_script		ld hl,commandstring					;fill the command string with spaces (in case script is
				ld bc,max_buffer_chars				;shorter)
				ld a,32
				call os_bchl_memfill
				
				ld de,max_buffer_chars				;only load enough chars for to fill command line 
				call os_set_load_length
				
				xor a
				ld hl,(script_length)
				ld de,(script_file_offset)			;index from start of file = A:xDE
				scf
				sbc hl,de							;is the file pointer => script length?
				jr nc,not_eoscr						
				ld hl,script_flags
				set scr_end,(hl)					;note end of script
				xor a
				ret
not_eoscr		call os_set_file_pointer

				ld hl,commandstring					;load in part of the script to command string	
				call os_read_bytes_from_file
				or a			
				jr z,scr_load_ok
				cp 0cch								;OK if attempted to load beyond end of file
				ret nz								

scr_load_ok		ld hl,script_flags
				bit scr_find_new_line,(hl)			;if flag is set, must look for new line in string loaded
				jr nz,scr_fnl						;and reload command string with new line at start

				ld hl,commandstring					;null terminate the commandstring at first char less than 32
				ld b,max_buffer_chars
scr_fcr			ld a,(hl)
				cp 32
				jr c,scr_gotclcr
				inc hl
				djnz scr_fcr
				xor a
				ret
scr_gotclcr		ld (hl),32							;fill rest of line with spaces
				inc hl
				djnz scr_gotclcr
				xor a
				ret

scr_fnl			ld iy,(script_file_offset)
				ld hl,commandstring	
scr_find_cr		ld a,(hl)							;find start of next line (first char after CR,LF etc)
				or a
				jr nz,scr_neocl						;if find zero, we're at the end of the command string buffer
scr_eocl		ld (script_file_offset),iy
				jr read_script				
scr_neocl		cp 20h								;so load in some more data
				jr c,scr_got_cr
				inc hl
				inc iy
				jr scr_find_cr
				
scr_got_cr		ld a,(hl)
				or a								;if find zero, we're at the end of the command string buffer
				jr z,scr_eocl						;so load in some more data
				cp 20h
				jr nc,scr_got_ch					;find first character after CR,LF etc
				inc hl
				inc iy
				jr scr_got_cr

scr_got_ch		ld (script_file_offset),iy
				ld hl,script_flags					;refresh commandstring with the new line aligned to start
				res scr_find_new_line,(hl)
				jr read_script


;-----------------------------------------------------------------------------------------------

copy_goto_label

				ld de,if_label_txt					;store label name
				ld b,max_if_chars
				call os_copy_ascii_run			
				xor a
				ld (de),a							;null terminate label
				ret	
				
;-----------------------------------------------------------------------------------------------
			
				
				
				