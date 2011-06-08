;-----------------------------------------------------------------------
;"exec" - execute script V0.03 - ADL mode
;
; Notes: Changing drives within a script not supported yet.
;        Scripts cannot launch scripts
;		 Abort with CRTL + C
;-----------------------------------------------------------------------

os_cmd_exec

				ld hl,in_script_flag				;test if already in a script
				bit 0,(hl)
				jr z,oktlscr
				xor a
				ret
oktlscr			set 0,(hl)
			
				ld hl,(os_args_loc)					;copy the script filename (scripts cannot launch
				ld de,script_fn						;scripts as this would require nested script filenames)
				ld b,13
				call os_copy_ascii_run
				call fs_get_dir_cluster				;store location of dir that holds the script
				ld (script_dir),de
				
				call os_check_volume_format	
				ret nz
				
				ld hl,0
				ld (script_file_offset),hl
				
			
scrp_loop		ld a,(key_mod_flags)				; skip boot script if L-CTRL is pressed
				and 2
				jr z,noskip_script	
				ld d,0
chk_c			call os_get_key_press
				cp 021h
				jr nz,no_cpr
wkend			ld d,25								; wait for key repeats to stop for a while
wkend2			call hwsc_wait_vrt					; before continuing	
				call os_get_key_press		
				or a
				jr nz,wkend
				dec d
				jr nz,wkend2
				ld hl,script_aborted_msg
				call os_show_packed_text
				xor a								; script aborted error message
				ret
no_cpr			dec d
				jr nz,chk_c
			
			
noskip_script
		
				ld hl,script_buffer					;clear bootscript buffer and command string		
				ld de,commandstring
				ld b,max_buffer_chars+1
				ld a,020h							;fill 'em with spaces
scrp_flp		ld (hl),a
				ld (de),a
				inc hl
				inc de
				djnz scrp_flp
				
				call fs_get_dir_cluster				;store current dir
				push de
				ld de,(script_dir)					;return to dir that contains the script
				call fs_update_dir_cluster
				ld hl,script_fn						;locate the script file - this needs to be done every
				call fs_hl_to_filename				;script line as external commands will have opened files
				call fs_open_file_command		
				jr c,pop_ret
				or a
				jr nz,pop_ret
				pop de
				call fs_update_dir_cluster			;return to dir selected prior to script
			
				ld de,max_buffer_chars				;only load enough chars for one line 
				call os_set_load_length
				xor a
				ld de,(script_file_offset)			;index from start of file = A:xDE
				call os_set_file_pointer
					
				ld hl,script_buffer					;load in part of the script	
				call os_read_bytes_from_file
				or a			
				jr z,scrp_ok						;file system error?
				cp 0cch			
				ret nz								;Dont mind if attempted to load beyond end of file
				
scrp_ok			ld iy,(script_file_offset)
				ld hl,script_buffer					;copy ascii from script buffer to command string
				ld de,commandstring
				ld a,max_buffer_chars
				ld b,a
scrp_cmd		ld a,(hl)
				cp 020h
				jr c,scrp_eol
				ld (de),a
				inc hl
				inc de
				inc iy
				djnz scrp_cmd
				
scrp_eol		xor a
				ld (de),a							;null terminate command string 
				ld (script_file_offset),iy
				ld (script_buffer_offset),hl
			
				call os_parse_cmd_chk_ps			;attempt to launch commands (check for spawn progs)
				
				ld iy,(script_file_offset)			;skip <CR> etc when repositioning file pointer
				ld hl,(script_buffer_offset)
scrp_fnc		ld a,(hl)		
				or a
				ret z								;if encounter a zero, its the end of the file
				cp 020h
				jr nc,scrp_gnc						;if a space or higher, we have the next command
				inc hl		
				inc iy								;otherwise keep looking
				jr scrp_fnc
			
scrp_gnc		ld (script_file_offset),iy			;update file offset and loop
				jp scrp_loop	
			
			
			
pop_ret			pop de
				ret
				
			
;-----------------------------------------------------------------------------------------------