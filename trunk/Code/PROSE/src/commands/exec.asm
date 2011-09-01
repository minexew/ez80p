;---------------------------------------------------------------------------------------------------------------
;"exec" - execute script V0.04 - ADL mode
;
; Notes: Changing drives within a script not supported yet.
;        Scripts cannot launch scripts as this would require nested script filenames
;		 Abort with CRTL + C
;
;        Supports: IF [CONDITION] jumps. Syntax as follows:
;        
;          "IF ENVAR = STRING LABEL" (or IF ENVAR <> STRING LABEL) 
;          (goto LABEL must be declared as [LABEL] at start of a line, with no other characters on that line.)
;----------------------------------------------------------------------------------------------------------------

max_if_chars		equ 16 ;(string size for envar name, value and label)

scr_in_script		equ 0
scr_find_new_line	equ 1
scr_if_condition	equ 2
scr_end				equ 3


os_cmd_exec		call do_script
				ld hl,script_flags
				res scr_in_script,(hl)
				ret
				
do_script		ld hl,script_flags	
				set scr_in_script,(hl)
						
				call fs_get_dir_cluster				;store location of dir that holds the script
				ld (script_dir),de
				
				call os_check_volume_format			;make sure volume is vaiid
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
					

no_quit_script	call open_script					;open script file
				ret nz
				call read_script					;move to offset location and read in a line from script file
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
				
				ld de,end_command_txt				;is command an "END" instruction?
				ld b,4
				call os_compare_strings
				jr z,scr_done
			
				call os_parse_cmd_chk_ps			;attempt to launch commands (check for spawn progs)
				
exec_scr_next	ld hl,script_flags
				set scr_find_new_line,(hl)
				jr scrp_loop
	
;-----------------------------------------------------------------------------------------------

; Handle "IF" instructions in the format:

; "IF ENVAR = VALUE LABLE"
; "IF ENVAR <> VALUE LABLE"
;  (LABEL must be declared at start of a script line in
;  square brackets ([label]) with no other data on that line)

do_exec_if		ld hl,commandstring+2			;move to envar name following "IF"
				call os_scan_for_non_space
				jr z,script_error				;give up if encountered zero (didn't find name)
				ld de,if_name_txt
				ld b,max_if_chars
				call os_copy_ascii_run			;save envar name string
				xor a
				ld (de),a
				
				call os_scan_for_non_space		;look for "=" (anything else is taken as "<>")
				jr z,script_error
				ld ix,script_flags
				res scr_if_condition,(ix)
				ld a,(hl)
				cp '='
				jr z,if_equals
				set scr_if_condition,(ix)		;if flag is set, the condition is "not same"

if_equals		call os_scan_for_space			;look for space following "="
				call os_scan_for_non_space		;look for specified envar value 
				jr z,script_error
				ld de,if_value_txt				;save envar value string
				ld b,max_if_chars
				call os_copy_ascii_run
				xor a
				ld (de),a
				
				call os_scan_for_non_space
				jr z,script_error
				ld de,if_label_txt				;look for label
				ld b,max_if_chars
				call os_copy_ascii_run			;copy label to a buffer
				xor a
				ld (de),a						;null terminate goto label
								
				ld hl,if_name_txt				;does this envar even exist? 
				call os_get_envar				;if it does return "value" string location in DE
				jp nz,exec_scr_next				;if it does not exist, ignore the "IF.." line of the script
								
				ld hl,if_value_txt
				ld ix,script_flags
				bit scr_if_condition,(ix)
				jr nz,if_cond_diff
				call os_compare_strings			;we want the strings to match 
				jp nz,exec_scr_next				;if they do not, ignore the "IF.." line of script
				jr if_cond_met
if_cond_diff	call os_compare_strings			;we want the strings to be different
				jp z,exec_scr_next				;if they are not, ignore the "IF.." line of the script

if_cond_met		call new_script					;Condition met. Go to start of script and find label..

find_if_label	call open_script				
				ret nz

				call read_script
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
								
;---------------------------------------------------------------------------------------------------------------------

open_script		call fs_get_dir_cluster				;store current dir
				push de
				ld de,(script_dir)					;return to dir that contains the script
				call fs_update_dir_cluster
				
				ld hl,script_fn						;locate the script file - this needs to be done every
				call os_find_file					;script line as external commands will have opened files
				ld (script_length),de				;save the script length
				pop de
				ret nz
				ld a,c								;if script filesize is over 16MB: error!
				or a
				jr z,scr_flok
				
script_error	ld a,08ch
				or a
				ret
				
scr_flok		call fs_update_dir_cluster			;return to dir selected prior to script
				xor a
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

		
				
				
				
				
				