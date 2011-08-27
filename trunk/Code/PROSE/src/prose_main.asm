
; PROSE for EZ80P by Phil Ruston 2011
; Compile with Zilog ZDS II

;----------------------------------------------------------------------
	.assume ADL = 1
;----------------------------------------------------------------------

	include	'ez80_cpu_equates.asm'
	include	'amoeba_hardware_equates.asm'
	include 'misc_system_equates.asm'
	
	sector_buffer	equ 800h
	scratch_pad		equ 100h

;----------------------------------------------------------------------

prose_version			equ 38h
amoeba_version_required	equ 107h

sysram_size				equ 080000h			;assume unexpanded 512KB for now
stack_size				equ 512

vram_a_size				equ 080000h
vram_b_size				equ 080000h

;-----------------------------------------------------------------------------------
; Assembly options
;-----------------------------------------------------------------------------------

max_volumes				equ 8

max_buffer_chars		equ 80		; applies to command line string, output line string, temp string etc

;------------------------------------------------------------------------------------
			
			org os_location
			
				blkb 16,0								; first 16 bytes are ID / header data - leave zeroed if desired
			
;------------------------------------------------------------------------------------
			
				jp os_first_run							;os location + 10h		
				jp extcmd_return						;os location + 14h
				jp relativize_hl						;os location + 18h
				jp relative_call						;os location + 1ch
				
;-------------------------------------------------------------------------------------

; External apps can call kernal routines by doing a "CALL.IL prose_kernal"
; Set A to kernal routine number required (see table)
; (this routine is always located at os_location+20h)

				exx
				ld (kernal_ix_cache),ix
				ld ix,kernal_table						
				ld de,3
				ld d,a
				mlt de
				add ix,de								;ix = routines address in table
				ld ix,(ix)								;ix = routine's location
				
				ex (sp),hl
				ld a,l									;get ADL mode byte that was last pushed to SPL
				and 1									;if zero flag = set, calling program was in Z80 mode
				ex (sp),hl
				exx
				push iy
				call kr_jump							;kernal code in ADL mode has normal RETs which do not restore
				pop iy									;the ADL mode. They return here and *this* RET.L restores the mode.
				ld ix,(kernal_ix_cache)
				ret.l									
				
kr_jump			jp (ix)									;jump to kernal routine
						
;-----------------------------------------------------------------------------------------

; *******************
; *   START UP OS   *
; *******************

os_first_run
	
				or a									; if A = 0, the boot drive is in B
				jr nz,os_cold_start		
				ld a,b
				ld (boot_drive),a						; 0=SERIAL, (1=IDE M, 2=IDE S), 3=MMC/SD card,4=EEPROM

os_cold_start
				stmix									; Interrupts to keep track of ADL status
				di										; Disable maskable IRQs
				im 2									; CPU INT = mode 2 (irrelevent on ez80l92 however)
				xor a
				ld MB,a									; MBASE = 0
				ld.sis sp,0ffffh						; Set Z80 Stack pointer to top of MBASE page
				ld sp,sysram_addr+sysram_size-1			; Set ADL stack pointer
				ld hl,sysram_addr+sysram_size-1
				ld de,stack_size
				xor a
				sbc hl,de
				ld (free_sysram_top),hl					; first allocatable RAM address (works downwards)
				ld hl,os_max_addr
				ld (free_sysram_base),hl
				
				ld hl,vram_a_addr
				ld (free_vram_a_base),hl
				ld bc,vram_a_size-1
				add hl,bc
				ld (free_vram_a_top),hl
				
				ld hl,vram_b_addr
				ld (free_vram_b_base),hl
				ld bc,vram_b_size-1-512					;reserve 512 bytes for pointer sprite
				add hl,bc
				ld (free_vram_b_top),hl
								
				call disable_irqs
				call disable_all_nmis
				
				ld a,(first_run)						; reset keyboard first time PROSE loads
				or a
				jr z,dont_resetkb
				call init_keyboard
				jr z,kb_ok
				ld hl,devices_connected
				res 0,(hl)
kb_ok			xor a
				ld (first_run),a
dont_resetkb
				
				ld hl,packed_font_start
				ld de,vram_a_addr
				ld bc,packed_font_end-packed_font_start
				call unpack_rle
				call convert_font

				call test_amoeba_vers
				
				ld hl,os_variables						; Clear all OS system variables
				ld bc,last_os_var-os_variables
				xor a
				call os_bchl_memfill
	
				call hwsc_default_hw_settings
				call hwsc_disable_audio
				
				ld a,(video_mode)
				call os_set_vmode						; this also clears the screen
				
				ld hl,welcome_message					; set up initial os display	
				call os_print_string
				
				call os_cmd_vers						; show OS / HW versions
				
				call os_cmd_remount						; set up drives

				call os_new_line						; skip 1 line

				call purge_keyboard
				
				call set_irq_vectors
				call enable_os_irqs
				ei
				
				ld hl,devices_connected					; warn if no keyboard
				bit 0,(hl)
				jr nz,kb_present
				ld hl,no_keyboard_msg
				call os_show_packed_text
kb_present				
				ld hl,startup_script_fn
				ld (os_args_loc),hl
				call os_cmd_exec						; any start-up commands?
									
				ld a,(frozen)							; if OS was restarted with an NMI, show registers
				or a
				jr z,os_main_loop
				xor a
				ld (frozen),a
				ld hl,nmi_freeze_txt
				call os_print_string
				call os_cmd_r
				

;============================================================================================

os_main_loop	call hwsc_wait_vrt					; flash cursor whilst waiting for key press

				call os_cursor_flash

				call os_get_key_press
				jr nz,os_main_loop
	
				ld (current_scancode),a
				ld a,b
				ld (current_asciicode),a			; store ascii version
	
				call hwsc_remove_cursor
				ld a,24								; ensures cursor is mainly visible 
				ld (cursorflashtimer),a				; during held key operations etc
				xor a
				ld (cursor_status),a
				
				ld a,(current_scancode)				; insert/overwrite mode?
				cp 70h
				jr nz,os_notins
 				ld a,(overwrite_mode)
				xor 1
				ld (overwrite_mode),a
				jr os_main_loop

os_notins		cp 6ch
				jr nz,not_homekey
				xor a
				ld (cursor_x),a
				jr os_main_loop
								
not_homekey		cp 69h
				jr nz,not_endkey
				ld a,(cursor_y)						;b = x, c = y
				ld c,a
				ld a,(charmap_columns)
				ld b,a
fendloop		dec b
				call hwsc_get_charmap_addr_xy
				ld a,(hl)
				cp 20h
				jr z,fendloop
				inc b
				ld a,(charmap_columns)
				cp b
				jr nz,endxposok
				dec b
endxposok		ld a,b
				ld (cursor_x),a
				jr os_main_loop

not_endkey		ld hl,cursor_x						; arrow key moving cursor left?
				cp 06bh			
				jr nz,os_ntlft
				dec (hl)
				ld a,(hl)
				cp 0ffh	
				jr nz,os_main_loop
				ld a,(charmap_columns)
				dec a
				ld (hl),a							; wrapped around
				jr os_main_loop

os_ntlft		cp 074h								; arrow key moving cursor right?
				jr nz,os_ntrig
				inc (hl)
				ld a,(charmap_columns)
				cp (hl)
				jr nz,os_main_loop
				ld (hl),0							; wrapped around
				jr os_main_loop

os_ntrig		ld hl,cursor_y
				cp 075h								; arrow key moving cursor up?
				jr nz,os_ntup
				dec (hl)
				bit 7,(hl)
				jr z,os_main_loop
				ld (hl),0							; top limit reached
				jr os_main_loop

os_ntup			cp 072h
				jr nz,os_ntdwn						; arrow key moving cursor down?
				inc (hl)
				ld a,(charmap_rows)
				cp (hl)
				jr nz,os_main_loop
				dec a
				ld (hl),a							; bottom limit reached, scroll the screen
				call hwsc_scroll_up
				jr os_main_loop

os_ntdwn		cp 071h								; delete pressed?
				jr nz,os_nodel		
				ld a,(cursor_x)						; shift chars of this line back onto cursor pos
				ld b,a
				inc b
				jr os_chrbk

os_nodel		cp 066h								; backspace pressed?
				jr nz,os_nbksp
				ld a,(cursor_x)						; shift chars of this line back from cursor pos
				or a								; (unless at column 0)
				jp z,os_main_loop
				ld b,a
				dec a
				ld (cursor_x),a						; shift cursor back a char
os_chrbk		call hwsc_chars_left				; b = x position of source char
				jp os_main_loop

os_nbksp		cp 05ah								; pressed enter?
				jp z,os_enter_pressed
	
				ld a,(current_asciicode)			; not a direction, bkspace, del or enter. 
				cp 32								; if scancode is not an ascii char dont plot anything
				jr c,os_nvdun						

				cp 07bh								; upper <-> lower case are flipped in OS 
				jr nc,os_gtcha						; to make unshifted = upper case
				cp 061h
				jr c,os_ntupc
				sub 020h
				jr os_gtcha
os_ntupc		cp 05bh
				jr nc,os_gtcha
				cp 041h
				jr c,os_gtcha
				add a,020h
os_gtcha		ld d,a								; need to print character on screen 
				ld a,(overwrite_mode)				; check for cursor mode
				or a
				call z,hwsc_chars_right
				
os_schi			ld bc,(cursor_pos)					; b = x, c = y
				ld a,d								; a = ASCII char code
				call hwsc_plot_char		
				ld hl,cursor_x						; move cursor right after char displayed
				inc (hl)
				ld a,(charmap_columns)
				cp (hl)								; wrapped around?
				jr nz,os_nvdun
				ld (hl),0

os_nvdun		jp os_main_loop
	

;---------------------------------------------------------------------------------------------

os_enter_pressed
	
				call hwsc_charline_to_command_string	

				xor a
				ld (cursor_x),a						; home the cursor at the left
				ld hl,cursor_y						; move cursor down a line
				inc (hl)
				ld a,(charmap_rows)
				cp (hl)
				jr nz,os_esdok
				dec a
				ld (hl),a
				call hwsc_scroll_up

os_esdok		call os_parse_cmd_chk_ps			; interpret the command

post_csb		jp os_main_loop

	
;---------------------------------------------------------------------------------------------


os_parse_cmd_chk_ps

				call os_parse_command_line
				cp 0feh								; was a new command issued by exiting program?
				ret nz
				ld bc,max_buffer_chars				; max string length = width of window in chars
				ld de,commandstring					; copy string at HL to command string and reparse it
				ldir
				jr os_parse_cmd_chk_ps

	
;---------------------------------------------------------------------------------------------
	
os_parse_command_line

				ld a,1
				ld (store_registers),a				; by default (external) commands store CPU registers on return

				ld hl,commandstring					; attempt to interpret command
				ld b,max_buffer_chars				; max string length = width of window in chars
				call os_scan_for_non_space			; scan from hl until encounter a non-space or zero
				or a								; if its a zero, give up parsing line
				ret z
				ld de,dictionary-1					; scan dictionary for command names
				push de
compcstr		pop de
				push hl
				pop iy
notacmd			inc de
				ld a,(de)
				cp 1								; last dictionary entry?
				jp z,os_no_kernal_command_found
				bit 7,a
				jr z,notacmd						; command names have marker bytes > $7f
				and 07fh
				ld c,a								; command's start location word index 
				push de
cmdnscan		inc de
				ld a,(iy)							; get ascii char from command line
				call os_uppercasify
				ld b,a
				ld a,(de)							; compare with command name in dictionary
				cp b
				inc iy
				jr z,cmdnscan						; this char matches - test the next
nomatch			ld a,(de)							; this char doesnt match (but previous chars did)
				or a
				jr z,posmatch						; is it the end of a command dictionary entry (0 or $80+)?
				bit 7,a			
				jr z,compcstr						; look for next command in dictionary
posmatch		ld a,(iy-1)							; if command string char is a space, the command matches
				cp 32
				jr nz,compcstr						; look for next command in dictionary
	
				pop de				
				push iy								; INTERNAL OS command found! Move arg location to end of command	
				pop hl
				call os_scan_for_non_space
				ld (os_args_loc),hl					; hl = 1st non-space char after command 
	
				ld hl,os_cmd_locs
				ld de,3
				ld d,c
				mlt de								; multiple command index by 3
				add hl,de
				ld ix,(hl)							; get INTERNAL command routine address

				ld hl,(os_args_loc)					; hl = first non-space char after command 
				call os_run_command					; call internal command

				or a
				ret z								; <- FIRST INSTRUCTION FOLLOWING RETURN FROM INTERNAL COMMAND
				cp 1
				jr nz,show_erm
os_hwe1			ld a,b								; If A = 1, show hardware error code from B
os_hwerr		ld hl,hex_byte_txt		
				call hexbyte_to_ascii	
				call os_new_line
				ld hl,hw_err_msg
				call os_show_packed_text
				xor a
				ret

show_erm		ld bc,0								; the program reported an error - show the error message
				ld c,a
				sub 080h							; if error code is $80 or above, it needs to be translated
				jr c,no_trans						; to a message number
				ld hl,kernal_error_code_translation	; if $80-$bf, use kernal translation table
				bit 6,a								; if $c0-$ff, use file system translation table
				jr z,not_fs_err						
				ld hl,fs_error_code_translation
				sub 040h
not_fs_err		ld c,a
				add hl,bc
				ld c,(hl)
no_trans		ld b,0
				ld hl,packed_msg_list
findmsg			ld a,(hl)
				cp 0ffh
				ret z								; quit if cant find message
				inc hl
				or a
				jr nz,findmsg						; is this an index marker?
				inc b
				ld a,c								; compare index count - is this the right message?
				cp b
				jr nz,findmsg
				call os_new_line
				call os_show_packed_text
				call os_new_line
				xor a
				ret
	

os_no_kernal_command_found

				ld a,030h							; was 'VOLx:' entered? This is a special case to avoid	
fvolcmd			ld (vol_txt+4),a					; having a seperate command name for each volume.
				push af			
				ld de,vol_txt+1		
				ld b,5			
				call os_compare_strings	
				jr z,gotvolcmd		
				pop af				
				inc a			
				cp 030h+max_volumes		
				jr nz,fvolcmd		
				jr novolcmd		
gotvolcmd		pop af
				sub 030h
				call os_change_volume
				jp extcmderf						; treat error codes as if external command as routine use ZF error system	
		


novolcmd		ld a,(hl)							; special case for 'G' command, this is internal but the code it
				cp 'G'								; will be executing will be external, so it should treated as
				jr nz,not_g_cmd						; an external command
				inc hl
				ld a,(hl)
				dec hl
				cp ' '
				jr nz,not_g_cmd
				inc hl
				call os_scan_for_non_space
				ld (os_args_loc),hl					; hl = 1st non-space char after command 
				or a
				jr nz,gotgargs
				ld a,01fh							; quit with error message
				jr show_erm
gotgargs		call ascii_to_hex_no_scan			; returns DE = goto address
				or a
				jr nz,show_erm
				call enable_button_nmi				; allow program to be stopped via NMI button
				call test_de
				jr nz,not_reset
				xor a
				out (port_memory_paging),a			; enable ROM if "G 0"
not_reset		push de
				pop ix			
				jp os_run_command					; run external command
				
				

not_g_cmd		ld (os_args_loc),hl					; attempt to load external OS command
				ld (os_args_pos_cache),hl
				call os_args_to_fn_append_ezp		; note: this moves the arg location to end of command
	
				call cache_dir_block				; cache dir pos in case we have to look in 'root/os_commands'

				call fs_check_disk_format			; System looks on the ACTIVE SELECTED drive only
				jr c,os_ndfxc						; make sure disk is available
				jr nz,os_ndfxc
	
				call fs_open_file_command			; get header info, test file exists in current dir
				jp c,os_hwerr			 			; h/w error?
				jr z,os_gecmd						; 0 = got external command

				call fs_goto_root_dir_command		; cant find it, so move to root dir
				ld hl,os_dos_cmds_txt
				call fs_hl_to_filename
				call fs_change_dir_command			; try to move to dir 'commands'
				jp c,os_hwerr
				jr nz,os_ndfxc						; 'unknown command' if that dir isnt there
	
				ld hl,(os_args_pos_cache)			; put original command filename back	
				ld (os_args_loc),hl
				call os_args_to_fn_append_ezp		; note: this moves the arg location to end of command
				call fs_open_file_command			; try to find the command in the new dir
				jp c,os_hwerr
				jr z,os_gecmd
os_ndfxc		call restore_dir_block				; jump back to original dir
				ld a,0bh							; return 'unknown command' error
				jp show_erm

os_gecmd		ld hl,(os_args_loc)					; Found external command!
				call os_scan_for_non_space			; args start is first non-space character after command
				ld (os_args_loc),hl

				ld de,16
				call os_set_load_length				; load the first 16 bytes into a buffer
				ld hl,scratch_pad
				ld (fs_ez80_address),hl
				call fs_read_data_command
				jp c,os_hwerr						; hardware error?	
				jp nz,show_erm						; file sys error?
				ld hl,(scratch_pad+2)
				ld de,04f5250h						; does it have the PROSE "PRO" file header ID?
				xor a	
				sbc hl,de
				jr z,loc_header
				call restore_dir_block				; jump back to original dir
				ld a,01ah							
				jp show_erm							; return 'not a prose executable' error
				
loc_header		ld a,(scratch_pad+15)				; store default ADL mode of command (for R "show registers" command)
				ld (store_adl),a			
				call fs_open_file_command			; OK, file has special PROSE header, open file again	
				jp c,os_hwerr
				jr nz,os_ndfxc
				ld hl,(scratch_pad+5)				; set load address from previously loaded header
				ld (fs_ez80_address),hl
				
				ld de,(scratch_pad+11)				; is there a minimum version of PROSE specified?
				ld a,e
				or d
				jr z,noprov_spec					
				ld hl,prose_version
				xor a
				sbc.sis hl,de						; 16 bit substract
				jr nc,noprov_spec
				call restore_dir_block
				ld a,01bh							;if above current prose, state OS error
				jp show_erm
				
noprov_spec		call hwsc_get_version				; get DE = h/w version (trashes HL)
				ld hl,(scratch_pad+13)				; is there a minimum version of AMOEBA HW specified?
				ex de,hl							; HL = AMEOBA version, DE = min required version
				ld a,e
				or d
				jr z,nohwv_spec					
				xor a
				sbc.sis hl,de						; 16 bit substract
				jr nc,nohwv_spec
				call restore_dir_block
				ld a,02bh							; if needs version above current HW, state error
				jp show_erm

nohwv_spec		ld de,(scratch_pad+8)				; is there a load length specified?
				ld a,(scratch_pad+10)				; if 0, load entire file as normal.
				or d
				or e
				jr z,readcode						
				call os_set_load_length				; set the load length
		
readcode		ld bc,(fs_ez80_address)				; is it going to overwrite protected memory?
				push bc
				pop hl
				ld de,(fs_file_transfer_length)
				add hl,de
				ex de,hl
				call os_protected_ram_test
				call nz,os_protected_ram_query
				jr z,ezp_loadpm_ok
				push af
				call restore_dir_block
				pop af
				jp show_erm

ezp_loadpm_ok	ld hl,(scratch_pad+5)
				ld (os_extcmd_jmp_addr),hl			; store code execution address
				call fs_read_data_command
				push af
				call restore_dir_block				; put original dir pos back	
				pop af
				jp c,os_hwerr						; drive error?
				jp nz,show_erm						; file system error?
	
				call enable_button_nmi				; allow NMI freezer button
				ld ix,(os_extcmd_jmp_addr)			; xIX = addr of command subroutine code	
				ld hl,(os_args_loc)					; hl = first non-space character after command 
				jp os_run_command					; run external command

extcmd_return	push af								; <-FIRST INSTRUCTION UPON RETURN FROM EXTERNAL COMMAND	
				call hwsc_default_hw_settings		; restore critical system settings for OS
				ld a,(store_registers)
				or a
				jr z,skp_strg
				pop af
				call os_store_CPU_regs				; store registers and flags on return
				push af
skp_strg		pop af

cntuasr			push af
				push bc								; protect any driver error code in B
				ld hl,scratch_pad					; update "error" envar on exit of previous program
				call hexbyte_to_ascii
				ld (hl),0
				ld de,scratch_pad
				ld hl,error_txt
				call os_set_envar
				call disable_button_nmi				; prevent NMI button taking any action				
				pop bc
				pop af
extcmderf		or a								; If A = 0, there was no error
				ret z	
				cp 1								; If A = 1, there was a hardware error
				jp z,os_hwe1						
				cp 0ffh								; If = FF, restart?
				jp z,os_cold_start
				cp 0feh								; if command wants to spawn a new command, return now
				ret z
				jp show_erm							; else show the relevent error code message 	
				
;---------------------------------------------------------------------------------------------------------------

os_run_command										
				out0 (port_nmi_ack),a				; ensure NMI F/F is reset for freezer
				ld (com_start_addr),ix				; temp store start address of executable
				jp (ix)								; jump to command's code

;---------------------------------------------------------------------------------------------------------------

cache_dir_block

	
				push de
				call fs_get_dir_cluster	
				ld (os_dir_block_cache),de
				pop de	
				ret
		

restore_dir_block

				push de
				ld de,(os_dir_block_cache)
				call fs_update_dir_cluster
				pop de
				ret
		
;==================================================================================================
; Routines called by command line
;==================================================================================================

; Set:-
; HL to address of string
; c = y
; b = x

ext_print_string

				call z,mbase_hl
				jr os_print_string

os_print_string_cond

				call test_quiet_mode
				ret nz

os_print_string

				push de
				push bc
				ld bc,(cursor_pos)						; Prints string at cursor position
prstr_lp		ld a,(hl)
				inc hl
				or a
				jr nz,prstr_ne
				ld (cursor_pos),bc
				pop bc
				pop de
				xor a									; ZF set, no error
				ret

prstr_ne		cp 13
				jr nz,not_cr
				ld b,0
				jr prstr_lp
not_cr			cp 10
				jr z,line_feed				
				cp 11
				jr z,next_line
				call hwsc_plot_char
				inc b
				ld a,(charmap_columns)
				cp b
				jr nz,prstr_lp
next_line		ld b,0
line_feed		inc c
				ld a,(charmap_rows)
				cp c
				jr nz,prstr_lp
				dec c
				call hwsc_scroll_up
				jr prstr_lp

;-------------------------------------------------------------------------------------------------

os_print_char	ld hl,char_to_print
				ld (hl),a
				jr os_print_string

;-------------------------------------------------------------------------------------------------

home_cursor		push af
				xor a
				ld (cursor_x),a
				pop af
				ret
				
;-------------------------------------------------------------------------------------------------

os_cursor_flash

				ld hl,cursorflashtimer
				inc (hl)
				ld a,(hl)
				cp 25
				ret nz
				ld (hl),0
				ld a,(cursor_status)
				xor 1
				ld (cursor_status),a
				jr z,no_cursor
				ld a,05fh
				ld hl,overwrite_mode
				bit 0,(hl)
				jr z,cursor_selected
				ld a,07fh
				
cursor_selected	call os_set_cursor_image
				call hwsc_draw_cursor						
				ret

no_cursor		call hwsc_remove_cursor
				ret


;-------------------------------------------------------------------------------------------------

ext_set_cursor_image

				ld a,e
				
os_set_cursor_image
			
				ld (cursor_image_char),a
				cp a
				ret

;---------------------------------------------------------------------------------------------

os_next_arg

				call os_scan_for_space
				or a
				ret z
				call os_scan_for_non_space
				or a
				ret


;------------------------------------------------------------------------------------------
	

os_scan_for_space

os_sfspl 		ld a,(hl)							; hl = source text, hl = space char on exit	
				or a								; or location of zero if encountered first
				ret z
				cp ' '
				ret z
				inc hl
				jr os_sfspl
	

;-----------------------------------------------------------------------------------------
	

os_scan_for_non_space

				dec hl							; hl = source text, hl = 1st non-space char on exit			
os_nsplp		inc hl			
				ld a,(hl)			
				or a			
				ret z							; if zero flag set on return end of line was encountered
				cp ' '
				jr z,os_nsplp
				ret
	
	
;----------------------------------------------------------------------------------------

os_args_to_alt_filename

				call os_atfn_pre					; find non-space char	
				ret z
				call fs_hl_to_alt_filename
				jr os_atfrl
	
	
	
		
os_args_to_filename

				call os_atfn_pre					; find non-space char	
				ret z
				call fs_hl_to_filename	

os_atfrl		ld a,(hl)							;look for a space or '/' after the filename ascii
				or a								;(stop looking if reach $00)
				jr z,os_cfne
				cp 32
				jr z,os_cfne
				cp 02fh
				jr z,os_cfne
				inc hl
				jr os_atfrl	
os_cfne			ld (os_args_loc),hl					;update arg position for next parameter
				ld a,c			
				or a								;a=number of chars in filename (ZF set if none)
				ret




os_args_to_fn_append_ezp

	
				call os_atfn_pre					; find non-space char	
				ret z
				ld de,temp_string
ccmdtlp			ld a,(hl)							; copy argument (command name) to temp string
				or a
				jr z,goteocmd
				cp ' '
				jr z,goteocmd
				cp '.'
				jr z,goteocmd
				ld (de),a
				inc de
				inc hl
				jr ccmdtlp
	
goteocmd		push hl
				ld hl,ezp_extension_txt
				ld bc,5
				ldir 
				ld hl,temp_string
				call fs_hl_to_filename
				pop hl
				jr os_atfrl
	



os_atfn_pre

				ld hl,(os_args_loc)					; find non-space char
				call os_scan_for_non_space
				or a
				ret z
				ld a,(hl)
				cp 02fh								; if forward slash, skip it
				jr nz,notfsl1
				inc hl
notfsl1			xor a
				inc a
				ret


;--------- Number <-> String functions -----------------------------------------------------


os_clear_output_line

				push bc
				push hl			
				ld hl,output_line
				ld bc,max_buffer_chars
				ld a,32
				call os_bchl_memfill
				pop hl
				pop bc
				ret
	
	
	
os_skip_leading_ascii_zeros

slazlp			ld a,(hl)							; advances HL past leading zeros in ascii string
				cp '0'								; set b to max numner of chars to skip
				ret nz
				inc hl
				djnz slazlp
				ret
	


os_leading_ascii_zeros_to_spaces

				push hl
clazlp			ld a,(hl)							; leading zeros in ascii string (HL) are replaced by spaces
				cp '0'								; set b to max numbner of chars
				jr nz,claze	
				ld (hl),' '
				inc hl
				djnz clazlp
claze			pop hl
				ret
	


		
n_hexbytes_to_ascii

				ld a,(de)							; set b to number of bytes
				call hexbyte_to_ascii				; set de to most significant byte address
				dec de
				djnz n_hexbytes_to_ascii
				ret
			
			

ext_hexbyte_to_ascii

				call z,mbase_hl
				ld a,e

hexbyte_to_ascii

				push bc
				ld b,a								; puts ASCII version of hex byte value in A at HL (two chars)
				srl a								; then hl = hl + 2
				srl a
				srl a
				srl a
				call hxdigconv
				ld (hl),a
				inc hl
				ld a,b
				and 0fh
				call hxdigconv
				ld (hl),a
				inc hl
				pop bc
				xor a								; zero flag set = no error
				ret
				
hxdigconv		add a,030h
				cp 03ah
				jr c,hxdone
				add a,7
hxdone			ret




hexword_to_ascii	

				ld a,d								; ascii version of DE is stored at hl to hl+3
				call hexbyte_to_ascii
				ld a,e
				call hexbyte_to_ascii
				ret
	



ext_ascii_to_hexword
		
				call z,mbase_hl

ascii_to_hexword
	
				call os_scan_for_non_space			; set text address in hl, xDE = hex word (24 bit) on return
				or a
				jr nz,ascii_to_hex_no_scan
				ld a,081h							; if a=0, set 'no data' return code $81
				or a
				ret	

	
ascii_to_hex_no_scan

				push ix
				push bc
				ld ix,0
				ld b,6									; 6 characters maximum
athlp			call ascii_to_hex_digit
				cp 0f0h									; is char a space?	
				jr z,athend
				cp 0d0h
				jr z,athend								; or 0 terminator?
				cp 16
				jr nc,badhex							; is it not a hex char?
				add ix,ix								; shift bits across to make room for new digit 
				add ix,ix
				add ix,ix
				add ix,ix
				or a,ixl
				ld ixl,a
				inc hl
				djnz athlp
athend			push ix
				pop de
				xor a
ath_quit		pop bc
				pop ix									; zero flag set on return, all ok. xDE = 24 bit word
				ret
		
badhex			ld a,82h								; if ascii is not correct, error $82 = BAD DATA
				or a
				jr ath_quit
				
	
		
ascii_to_hex_digit

				ld a,(hl)								; source char at hl
				cp 061h
				jr c,hc_uppercase
				sub 020h								; if char > $61, make it upper case
hc_uppercase	sub 03ah								; a = returned nybble
				jr c,zeronine
				add a,0f9h
zeronine		add a,0ah
				ret


;--------- Text Input / Non-numeric string functions ------------------------------------

; Waits for user to enter a string of characters followed by Enter (ESC to quit)
; Before calling, set:  HL = destination of string data
;                        E = max number of characters
; Returns:   A  = number of characters in entered string (zero if aborted by ESC)


ext_user_input
				call z,mbase_hl
				
os_user_input
				xor a
				ld (ui_index),a
				ld (ui_string_addr),hl
				ld a,e
				ld (ui_maxchars),a
				
				ld a,(overwrite_mode)
				ld (ui_im_cache),a
				xor a
				ld (overwrite_mode),a				;user input routine always shows underscore cursor
				
ui_loop			call hwsc_draw_cursor			;draw underscore cursor
				call os_wait_key_press			;wait for a new scan code in buffer
				ld (current_scancode),a
				ld a,b
				ld (current_asciicode),a		;store ascii version	
				call hwsc_remove_cursor
	
				ld a,(current_scancode)
				cp 066h							;pressed back space?
				jr nz,os_nuibs
				ld a,(ui_index)
				or a
				jr z,ui_loop					;cant delete if at start
				ld hl,cursor_x					;shift cursor left and put a 	
				dec (hl)						;space at new position
os_uixok		ld b,(hl)		
				ld a,(cursor_y)
				ld c,a
				ld a,32
				call hwsc_plot_char
				ld hl,ui_index
				dec (hl)						;dec char count
				jr ui_loop

os_nuibs		cp 076h							; pressed escape
				jr z,ui_aborted
				cp 05ah							; pressed enter?
				jr z,ui_enter_pressed
	
				ld a,(ui_index)					; no action if at max character
				ld hl,ui_maxchars
				cp (hl)
				jr z,ui_loop	

				ld a,(current_asciicode)		; not a bkspace or enter... 
				cp 32							; if scancode is not an ascii char
				jr c,ui_loop					; skip plotting char.

ui_gtcha		ld d,a
				ld hl,(ui_string_addr)
				ld a,(ui_index)
				ld bc,0
				ld c,a
				add hl,bc
				ld (hl),d						; enter char in user input string
				inc a
				ld (ui_index),a					; next string position
				
				ld bc,(cursor_y)				; and print character on screen...
				ld a,d
				call hwsc_plot_char		
				ld hl,cursor_x					; ..and move cursor right
				inc (hl)
				ld a,(charmap_columns)			; if at screen right, wrap to 0
				cp (hl)
				jp nz,ui_loop
				ld (hl),0
				jp ui_loop

ui_enter_pressed
				
				ld a,(ui_im_cache)				; restore original insert mode 
				ld (overwrite_mode),a
				ld a,(ui_index)					; A = number of characters
				or a
				jr nz,ui_data
				ld a,081h						; number of chars = 0, return error 81h
				or a
				ret
ui_data			ld hl,(ui_string_addr)
				ld de,0
				ld e,a
				add hl,de
				ld (hl),0						; null terminate the string
				cp a							; zero flag set, all ok
				ret

ui_aborted		ld a,(ui_im_cache)				; restore original insert mode 
				ld (overwrite_mode),a
				ld a,080h						; on exit a = 80h if escape pressed / aborted
				or a							; zero flag not set = error indicator
				ret
		
;--------------------------------------------------------------------------------
	
os_count_lines

				push hl							; counts output lines, says 'More?' and waits for 'y' key every 'n' lines
				ld b,'y'						; b (ascii code) = 'y' by default	
				ld hl,os_linecount			
				inc (hl)							
				ld a,(charmap_rows)
				sub 4
				cp (hl)
				jr nz,os_nntpo
				ld (hl),0
				ld hl,os_more_txt
				call os_print_string
				call os_wait_key_press	
os_nntpo		pop hl
				ret

;---------------------------------------------------------------------------------

ext_compare_strings
	
				call z,mbase_hl
				call z,mbase_de
				
os_compare_strings

; both strings at HL/DE should be zero terminated.
; compare will fail if string lengths are different
; unless count (B) is reached first
; Case is ignored
; Zero flag set on return if same

				push hl							;set de = source string
				push de							;set hl = compare string
ocslp			ld a,(de)						;b = max chars to compare
				or a
				jr z,ocsbt
				call case_insensitive_compare	;compare a with (HL) ignoring case
				jr nz,ocs_diff
				inc de
				inc hl
				djnz ocslp
				jr ocs_same
ocsbt			ld a,(de)						;check both strings at termination point
				or (hl)
				jr nz,ocs_diff
ocs_same		pop de
				pop hl
				xor a							; zero flag set if same		
				ret
ocs_diff		pop de
				pop hl
				xor a							; no zero flag if different	
				inc a
				ret


;-----------------------------------------------------------------------------------

os_copy_ascii_run

;INPUT HL = source ($00 or $20 terminates)
;      DE = dest
;       b = max chars

;OUTPUT HL/DE = end of runs
;           c = char count
	
				ld c,0
cpyar_lp		ld a,(hl)
				or a
				ret z
				cp 32
				ret z
				ld (de),a
				inc hl
				inc de
				inc c
				djnz cpyar_lp
				ret

;-----------------------------------------------------------------------------------

uppercasify_string

; Set HL to string location ($00 quits)
; Set B to max number of chars

				ld a,(hl)
				or a
				ret z
				call os_uppercasify
				ld (hl),a
				inc hl
				djnz uppercasify_string	
				ret
	

os_uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

				cp 061h			
				ret c
				cp 07bh
				ret nc
				sub 020h				
				ret

;----------------------------------------------------------------------------------

case_insensitive_compare

; compares A with (HL) disregarding the case of both
; Zero flag set if the characters are the same
; all registers are preserved.

				push bc					
				ld c,a

				call os_uppercasify				
				ld b,a
				ld a,(hl)
				call os_uppercasify
				cp b

				ld a,c
				pop bc
				ret

;----------------------------------------------------------------------------------

os_decimal_add

;INPUT HL = source LSB, DE = dest LSB, b = number of digits

				push bc
				ld c,0
decdlp			ld a,(de)
				add a,(hl)
				add a,c
				cp 10
				jr c,daddnc
				sub 10
				ld c,1
decnclp			ld (de),a
				inc hl
				inc de
				djnz decdlp
				pop bc
				ret
daddnc			ld c,0
				jr decnclp
	
;----------------------------------------------------------------------------------

os_hex_to_decimal

; INPUT xDE hex longword
; OUTPUT xHL = decimal LSB address (8 digits) 

hex_to_convert		equ scratch_pad
decimal_digits		equ scratch_pad+3
decimal_add_digits	equ scratch_pad+3+8

				ld (hex_to_convert),de
		
				ld hl,decimal_add_digits
				push hl
				ld de,decimal_digits
				xor a
				ld b,8
setupdec		ld (de),a
				ld (hl),a
				inc hl
				inc de
				djnz setupdec
				pop hl
				ld (hl),1
	
				ld hl,hex_to_convert
				ld b,3
decconvlp		push bc
				ld a,(hl)
				call decadder
				call decaddx16
				ld a,(hl)
				rrca
				rrca
				rrca
				rrca
				call decadder
				call decaddx16
				pop bc
				inc hl
				djnz decconvlp
				ld hl,decimal_digits
				ret



decadder		and 15
				ret z
				ld b,a
				push hl
daddlp			push bc
				ld de,decimal_digits
				ld hl,decimal_add_digits
				ld b,8
				call os_decimal_add
				pop bc
				djnz daddlp	
				pop hl
				ret
			
				
decaddx16		push hl
				ld b,4								;add the add value to itself 4 times 
x16loop			push bc
				ld de,decimal_add_digits
				ld hl,decimal_add_digits
				ld b,8
				call os_decimal_add
				pop bc
				djnz x16loop	
				pop hl
				ret
	
	
;----------------------------------------------------------------------------------

os_show_decimal

				ld de,output_line						;skips leading zeros
				ld bc,9
				add hl,bc
				ld b,10
shdeclp			ld a,(hl)
				or a
				jr z,dnodigit
				add a,030h
				ld (de),a
				inc de
dnodigit		dec hl
				djnz shdeclp
				xor a
				ld (de),a
				call os_print_output_line
				ret
				
;-----------------------------------------------------------------------------------
		
os_copy_to_output_line
	
				push de
				push bc
				ld de,output_line						; hl = zero terminated string
				ld bc,max_buffer_chars+1				; note copies terminating zero
os_cloll		ldi
				ld a,(hl)
				or a
				jr z,os_clold
				ld a,b
				or c
				jr nz,os_cloll
os_clold		ld (de),a
				pop bc
				pop de
				ret


;----------------------------------------------------------------------------------

os_show_hex_address

				push hl							; put address to display in xDE
				ld hl,output_line
				ld (hex_address),de
				ld a,(hex_address+2)
				call hexbyte_to_ascii
				jr shw_nt
				

os_show_hex_byte

				push hl							; put byte to display in A
				ld hl,output_line
				call hexbyte_to_ascii
				jr shb_nt



os_show_hex_word

				push hl							; put word to display in DE
				ld hl,output_line
shw_nt			call hexword_to_ascii
shb_nt			ld (hl),0
				pop hl

	

os_print_output_line

				push hl
				ld hl,output_line
cproline		call os_print_string
				pop hl
				ret



os_print_output_line_skip_zeroes

				push hl
				ld hl,output_line
				call os_skip_leading_ascii_zeros
				jr cproline
				
		
;----------------------------------------------------------------------------------

os_store_CPU_regs

				di								; store_register_values - PC and ADL are stored elsewhere

				inc sp							; Add 3 to SPL because the routine's CALL offset the stack (ADL mode)
				inc sp
				inc sp
				ld (store_spl),sp
				dec sp							; restore SPL
				dec sp
				dec sp
				
				push af
				ld (store_a1),a					
				ex af,af'
				ld (store_a2),a
				ex af,af'
				ld (store_bc1),bc		
				ld (store_de1),de
				ld (store_hl1),hl
				exx
				ld (store_bc2),bc
				ld (store_de2),de
				ld (store_hl2),hl
				exx
				ld (store_ix),ix
				ld (store_iy),iy
				
			    ld a,MB
				ld (store_mbase),a
								
				push bc
				ld b,0
				jr nz,zfstzero					; test zero flag
				set 6,b

zfstzero		jr nc,cfstzero					; test carry flag
				set 0,b

cfstzero		jp p,sfstzero					; test sign flag 1=minus
				set 7,b

sfstzero		jp pe,pfstzero					; test parity flag 1=par odd
				set 2,b

pfstzero		ld a,i			
				jp pe,ifstzero					; test iff flag
				set 4,b

ifstzero		ld a,b
				ld (store_f),a
				
				ld a,os_location/65536			; temp switch MBASE to the 64KB page OS is residing in
				ld MB,a							; so SPS is written to correct location
				ld.sis (store_sps),sp
				ld a,(store_mbase)				; put MBASE back to whatever it was before
				ld MB,a
				
				pop bc
				pop af
				ei
				ret



os_dont_store_registers

				xor a
				ld (store_registers),a			;returns with zero flag set, no error
				ret
	
	
;-----------------------------------------------------------------------------------

os_new_line_cond

				call test_quiet_mode
				ret nz

	
os_new_line

				push hl
				ld hl,crlfx2_txt+1
				call os_print_string
				pop hl
				ret
				
;-----------------------------------------------------------------------------------

os_set_cursor_position
				
														; if either coordinate is out of range
				ld a,(charmap_rows)						; the routine returns with zero flag not set
				dec a									; and a = $88 
				cp c
				jr c,badpos
				ld a,c
				ld (cursor_y),a
				
				ld a,(charmap_columns)
				dec a
				cp b
				jr c,badpos
				ld a,b
				ld (cursor_x),a
				xor a
				ret				

badpos			ld a,88h								;out of range error
				or a
				ret


					
	
	
os_get_cursor_position

				ld bc,(cursor_pos)						; returns pos in bc (b = x, c = y)
				cp a									; zero flag set, no error
				ret


;---------------------------------------------------------------------------------------------

os_show_packed_text_cond

				call test_quiet_mode
				ret nz

	
os_show_packed_text

; Construct sentence from internal dictionary using word indexes from HL
	
				push bc
				push de
				push ix
				ld ix,output_line
readpind		ld a,(hl)
				or a
				jr nz,getword							; if word index = 0, its the end of the line
				dec ix									; remove previously added space from end of line
				ld (ix),a								; null terminate output line
			
				push hl
				call os_print_output_line
				pop hl
			
				pop ix
				pop de
				pop bc
				ret
				
getword			ld de,dictionary-1
				ld c,0
dictloop		inc de
				ld a,(de)
				or a									; is this a marker byte (not a char)
				jr z,faword
				bit 7,a									; ''                              ''
				jr z,dictloop	
			
faword			inc c									; reached desired word count?
				ld a,c
				cp (hl)
				jr nz,dictloop
copytol			inc de									; skip the marker char
				ld a,(de)
				or a
				jr z,eoword								; if find a marker char, its the end of the word
				bit 7,a
				jr nz,eoword
				ld (ix),a								; copy char to output line
				inc ix
				jr copytol
eoword			ld (ix),32								; enter a space		
				inc ix
				inc hl
				jr readpind


		
;--------- Mouse functions ------------------------------------------------------------------------

os_set_mouse_window

; Set: HL/DE = window size mouse pointer is to work within (for absolute coordinates)
	
				ld (mouse_window_size_x),hl	 
				ld (mouse_window_size_y),de
				ld hl,0
				ld (mouse_abs_x),hl
				ld (mouse_abs_y),hl
				ld a,1
				ld (mouse_new_window),a
				xor a
				ret
				
			
os_get_mouse_motion
			
; Returns: ZF = Set: Relative X coord in HL, Relative y coord in DE, buttons in A, Wheel in B
;          ZF = Not set: Mouse driver not initialized.
			
				ld a,(devices_connected)
				and 2
				xor 2
				ret nz
				
ms_reread		xor a
				ld (mouse_updated),a
				ld hl,(mouse_disp_x)					 
				ld de,(mouse_disp_y)
				ld a,(mouse_updated)					; has mouse interrupted whilst we were reading?
				or a
				jr nz,ms_reread
mouse_end		xor a
				ld a,(mouse_wheel)
				ld b,a
				ld a,(mouse_buttons)
				ret
			
			
os_get_mouse_position

; Returns: ZF = Set: Abolute X coord in HL, Absolute Y coord in DE, buttons in A, Wheel in B
;          ZF = Not set: Mouse driver not initialized.

				ld a,(devices_connected)
				and 2
				xor 2
				ret nz
				
ms_reread_abs	xor a
				ld (mouse_updated),a

				ld hl,(mouse_abs_x)
				ld de,(mouse_abs_y)
				ld a,(mouse_updated)					; has mouse interrupted whilst we were reading?
				or a
				jr nz,ms_reread_abs
				
				jr mouse_end
				
	
;====================================================================================================
;----- General Subroutines --------------------------------------------------------------------------
;====================================================================================================

; .--------------.
; ! CRC Checksum !
; '--------------'

; makes 16 bit checksum in HL, src addr = DE, length = C bytes

crc_checksum

				ld hl,0ffffh		
crcloop			ld a,(de)			
				xor h			
				ld h,a			
				ld b,8
crcbyte			add.sis hl,hl					;16 bit add
				jr nc,crcnext
				ld a,h
				xor 10h
				ld h,a
				ld a,l
				xor 21h
				ld l,a
crcnext			djnz crcbyte
				inc de
				dec c
				jr nz,crcloop
				ret


;----------------------------------------------------------------------------------------------

os_get_key_mod_flags

				ld a,(key_mod_flags)
				cp a							; ZF set, no error
				ret

;-----------------------------------------------------------------------------------------------

os_get_vmode
			
				ld a,(charmap_rows)
				ld c,a
				ld a,(charmap_columns)
				ld b,a
				ld a,(video_mode)
				cp a						; ZF set, no error
				ret

;-----------------------------------------------------------------------------------------------

ext_set_vmode	ld a,e

os_set_vmode	cp 4
				jr c,vm_range_ok
				ld a,88h					;out of range error return
				or a
				ret
				
vm_range_ok		ld (video_mode),a
				ld hl,3
				ld h,a
				mlt hl
				ld de,vmode_parameter_list
				add hl,de
				ld a,(hl)
				inc hl
				ld b,(hl)
				inc hl
				ld c,(hl)
				call set_charmap_parameters
				
				call hwsc_clear_screen

				xor a				
				ret


;------------------------------------------------------------------------------------------

os_bchl_memfill

; fill memory from xHL with A. Count in xBC.
		
mf_loop			ld (hl),a
				cpi								;use CPI to inc HL / dec BC and test for BC = 0
				jp pe,mf_loop
				ret
	
;---------------------------------------------------------------------------------------

ext_set_pen		ld a,e

os_set_pen		ld (current_pen),a
				cp a							;ZF set, no error
				ret

;---------------------------------------------------------------------------------------
	
os_get_pen		ld a,(current_pen)
				cp a							;ZF set, no error
				ret	

;----------------------------------------------------------------------------------------

ext_background_colours
				
				call z,mbase_hl
				jp hswc_set_ui_colours
				
				
;---------------------------------------------------------------------------------------

os_get_xde_msb	
			
				ld (xrr_temp),de				;Puts xDE[23:16] in A
				ld a,(xrr_temp+2)
				ret

;---------------------------------------------------------------------------------------

mbase_hl		push af
				ld (xrr_temp),hl				;replace [23:16] in HL with MBASE
				ld a,MB
				ld (xrr_temp+2),a
				ld hl,(xrr_temp)
				pop af
				ret
				
mbase_de		push af
				ld (xrr_temp),de				;replace [23:16] in de with MBASE
				ld a,MB
				ld (xrr_temp+2),a
				ld de,(xrr_temp)
				pop af
				ret


;---------------------------------------------------------------------------------------
; Unpacks Phil's Z80P_RLE packed files - V1.02 
;----------------------------------------------------------------------------------------

unpack_rle

;set xHL = source address of packed file
;set xDE = destination address for unpacked data
;set xBC = length of packed file

			push hl	
			pop ix
			dec bc									; length less one (for token byte)
			inc hl
unp_gtok	ld a,(ix)								; get token byte
unp_next	cp (hl)									; is byte at source location same as token?
			jr z,unp_brun							; if it is, there's a byte run to expand
			ldi										; if not, simply copy this byte to destination
			jp pe,unp_next							; last byte of source?
			ret
	
unp_brun	push bc									; stash B register
			inc hl		
			ld a,(hl)								; get byte value
			inc hl		
			ld b,(hl)								; get run length
			inc hl
	
unp_rllp	ld (de),a								; write byte value, byte run length
			inc de			
			djnz unp_rllp
	
			pop bc	
			dec bc									; last byte of source?
			dec bc
			dec bc
			push hl									; must be a better way to test xBC = 0...
			ld hl,0
			or a
			adc hl,bc
			pop hl
			jr nz,unp_gtok
			ret	
	
;---------------------------------------------------------------------------------------
; Commonly called error messages - gets message code
;---------------------------------------------------------------------------------------


os_no_fn_error		ld a,0dh
					or a
					ret
			
os_fn_too_long		ld a,15h
					or a
					ret
				
os_no_start_addr	ld a,16h
					or a
					ret
			
os_no_filesize		ld a,17h
					or a
					ret
			
os_abort_save		ld a,18h
					or a
					ret
			
os_no_e_addr_error	ld a,1ch
					or a
					ret
			
os_no_d_addr_error	ld a,1dh
					or a
					ret
				
os_range_error		ld a,1eh
					or a
					ret
			
os_no_args_error	ld a,1fh
					or a
					ret	

;--------------------------------------------------------------------------------------

; Set xHL to address of zero terminated filename.
; RETURNS:	C:xDE  = File length
;    		HL     = Start cluster of file

ext_find_file	call z,mbase_hl

os_find_file	call fs_hl_to_filename
				call fs_open_file_command				; Returns A = 0, file found OK..
				jr c,os_fferr							; If carry = 1: driver error.
				ret										; If ZF is not set: File Error.
					
os_fferr		ld b,a									; driver error: A = $01, B = error bits
				xor a			
				inc a									; Zero flag cleared
				ret	

;--------------------------------------------------------------------------------------------------------

os_set_load_length

				ld (fs_file_transfer_length),de			; set load length to xDE
				cp a									; set zero flag
				ret
				
;----------------------------------------------------------------------------------------------------------	

ext_set_file_pointer

				ld a,c
				
os_set_file_pointer

; Moves the 'start of file' pointer allowing random access to file contents.
; Note: File pointer is reset by opening a file, and automatically incremented
; by normal read function.

				ld (fs_file_pointer),de					; set 32 bit file pointer to A:xDE  
				ld (fs_file_pointer+3),a
				push af
				xor a
				ld (fs_filepointer_valid),a				; invalidate filepointer
				pop af
				cp a									; set zero flag
				ret
				
;-----------------------------------------------------------------------------------------------------------

; set xHL = load address 
; (Before calling this routine, call os_find_file)

ext_read_bytes_from_file

				call z,mbase_hl						; if called from z80 mode, adjust HL(23:16)
				
os_read_bytes_from_file

				ld (fs_ez80_address),hl					 
				call fs_read_data_command
				jr c,os_fferr
				ret

;-----------------------------------------------------------------------------------------------------------

; Before calling, set xHL = address of zero terminated filename.

ext_create_file	call z,mbase_hl

os_create_file	call fs_hl_to_filename
				call fs_create_file_command			; this routine returns A = 0/carry clear if file created OK..
				jp c,os_fferr						; translate errors to standard OS format (Zero Flag,A,B)
				ret

;--------------------------------------------------------------------------------------------------------

ext_write_bytes_to_file

				call z,mbase_hl
				call z,mbase_de

os_write_bytes_to_file

; Before calling, set..

; xDE   = address to save data from
; xBC   = number of bytes to save
; xHL   = address of null-terminated ascii name of file the databytes are to be appended to

; On return:

; If zero flag NOT set, there was an error.
; If   A = $00, b = hardware error code
; Else A = File system error code

; NOTE:
; Will return 'file not found' if the file has not been created previously.
				
				ld (fs_file_transfer_length),bc
				ld (fs_ez80_address),de	 	
				call fs_hl_to_filename
				call fs_write_bytes_to_file_command
				jp c,os_fferr
				ret
		
		
;--------------------------------------------------------------------------------------------------------
	

os_check_volume_format

				call fs_check_disk_format
os_rffsc		jp c,os_fferr
				ret

;--------------------------------------------------------------------------------------------------------


ext_format		ld a,e
				call z,mbase_hl						; if called from Z80 mode prog, adjust HL(23:16)

os_format		push hl								; set HL to label and A to DEV number
				call dev_to_driver_lookup
				pop hl
				jr c,sdevok
				ld a,0d0h							; error - $d0: invalid DEVICE selection
				or a
				ret

sdevok			push af				
				ld de,fs_sought_filename
				call fs_clear_filename
				ld b,11
				call os_copy_ascii_run
				pop af
				
				ld hl,current_driver
				ld b,(hl)
				ld (hl),a
				push bc
				push hl
				call fs_format_device_command
				pop hl
				pop bc
				ld (hl),b
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


ext_make_dir	call z,mbase_hl					;if called from Z80 mode prog, adjust HL(23:16)

os_make_dir		call fs_hl_to_filename
				call fs_make_dir_command
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


ext_change_dir	call z,mbase_hl					;if called from Z80 mode prog, adjust HL(23:16)

os_change_dir	call fs_hl_to_filename
				call fs_change_dir_command
				jr os_rffsc
				
	
;--------------------------------------------------------------------------------------------------------
	
	
os_parent_dir	call fs_parent_dir_command
				jr os_rffsc
				

;--------------------------------------------------------------------------------------------------------

	
os_root_dir		call fs_goto_root_dir_command
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


ext_erase_file	call z,mbase_hl							;if called from Z80 mode prog, adjust HL(23:16)

os_erase_file	call fs_hl_to_filename
				call fs_erase_file_command
				jr os_rffsc
	

;--------------------------------------------------------------------------------------------------------


os_goto_first_dir_entry	

				call fs_goto_first_dir_entry
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


os_get_dir_entry		

				call fs_get_dir_entry	
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


os_goto_next_dir_entry	
	
				call fs_goto_next_dir_entry	
				jr os_rffsc


;--------------------------------------------------------------------------------------------------------


os_get_current_dir_name

				call fs_get_current_dir_name
				jr os_rffsc
				

;--------------------------------------------------------------------------------------------------------


ext_rename_file	call z,mbase_hl
				call z,mbase_de

os_rename_file	push de
				call fs_hl_to_alt_filename				; set hl = file to rename, de = new filename
				pop hl				
				call fs_hl_to_filename	
				call fs_rename_command
				jr os_rffsc
				

;--------------------------------------------------------------------------------------------------------


ext_delete_dir	call z,mbase_hl							;if called from Z80 mode prog, adjust HL(23:16)

os_delete_dir	call fs_hl_to_filename
				call fs_delete_dir_command
				jp os_rffsc
	
	
;----- LOW LEVEL SECTOR ACCESS ETC FOR EXTERNAL PROGRAMS ---------------------------------------------------


ext_read_sector
				call ext_sector_access_preamble
				ret nz
				ld (current_driver),a
				call fs_read_sector
				jr nz,sect_done
				jr c,sect_done
				ld hl,sector_buffer
				ld de,(sector_rd_wr_addr)
				ld bc,512
				ldir			
sect_done		push af
				ld a,(sys_driver_backup)			;restore system driver number
				ld (current_driver),a
				pop af
				jp os_rffsc
				

ext_write_sector
			
				call ext_sector_access_preamble
				ret nz
				ld (current_driver),a
				ld hl,(sector_rd_wr_addr)
				ld de,sector_buffer
				ld bc,512
				ldir			
				call fs_write_sector
				jr sect_done


ext_sector_access_preamble

				call z,mbase_hl
				ld (sector_rd_wr_addr),hl
				
				ld a,b
				push af								;set B = device, set sector = C:xDE, xHL = address of/for data
				ld ix,sector_lba0
				ld (ix),de							;on return if ZF set: all OK, else sector out of range
				ld (ix+3),c
				call dev_to_driver_lookup			
				push hl
				pop ix
				ld hl,(sector_lba0)					
				ld a,(sector_lba3)					;A:xHL = desired sector
				ld bc,(ix+1)						
				or a								;clear carry
				sbc hl,bc
				sbc a,(ix+4)
				jr c,range_ok
				pop af
				ld a,0d5h							;error $d5 = 'sector out of range'
				or a								;clear zero flag
				ret
	
range_ok		ld a,(current_driver)
				ld (sys_driver_backup),a
				pop af								;get requested device back
				call dev_to_driver_lookup
				jr nc,bad_dev
os_null			cp a								;set zero flag, retaining contents of A (driver number)
				ret
					
bad_dev			ld a,0d0h							;error $d0 - 'invalid device' error
				or a								;clear zero flag
				ret	
			

;-------------------------------------------------------------------------------------------


os_get_device_info

				ld hl,host_device_hardware_info
				ld de,driver_table
				ld a,(device_count)
				ld b,a
				ld a,(current_driver)
				cp a
				ret




os_get_volume_info

				ld hl,volume_mount_list	
				ld a,(volume_count)
				ld b,a
				ld a,(current_volume)
				ret
				
		
;------------------------------------------------------------------------------------------------------------


ext_serial_get_header

				call z,mbase_hl
				ld a,e
				call serial_get_header
				push ix
				pop de
				ret
				
				
ext_serial_receive_file
				
				call z,mbase_hl
				call serial_receive_file
				ret
				
	
ext_serial_send_file

				call z,mbase_hl							;filename location
				call z,mbase_de							;de/ix = start address
				push de	
				pop ix									
				push bc									;bc/de = length
				pop de									
				call serial_send_file
				ret


ext_serial_tx
				ld a,e
				call send_serial_byte
				xor a									;ZF set, no error
				ret


ext_serial_rx
				ld a,e
				ld (serial_timeout),a
				call receive_serial_byte
				ret
				

;-----------------------------------------------------------------------------------------------

ext_mount_volumes

				ld a,e

os_mount_volumes
				
				ld (os_quiet_mode),a					; set A to 0 for verbose, 1 for quiet mode
				
				ld hl,storage_txt
				call os_print_string_cond
				call mount_go
				xor a
tvloop			ld (current_volume),a
				call os_change_volume					; after mount, current volume is set to 0
				ret z									; unless its not valid, then try next vol
				ld a,(current_volume)					; until good volume found
				inc a
				cp max_volumes
				jr nz,tvloop
				ld a,(device_count)
				or a
				jr nz,mfsdevs
				ld hl,none_found_msg
				call os_show_packed_text_cond
mfsdevs			xor a
				ret



mount_go		ld hl,volume_mount_list					; wipe current mount list
				ld bc,max_volumes*16
clrdl_lp		xor a
				call os_bchl_memfill
								
				ld hl,volume_dir_clusters				; wipe directory cluster list
				ld bc,max_volumes*3		
				xor a	
				call os_bchl_memfill	
			
				ld de,host_device_hardware_info
				ld (dhwn_temp_pointer),de
				
				ld iy,volume_mount_list
				xor a
				ld (volume_count),a
				ld (device_count),a
mnt_loop		ld (current_driver),a					; host driver number
				call locate_driver_base					; gets base address of driver A in xDE
				ld hl,0
				xor a
				adc hl,de
				ret z									; if 0, end driver scan
				ex de,hl								; hl = 'get_id' subroutine address for host device
				push iy
				call find_dev							; 'get_id' routines must return ZF=1 if present
				pop iy									; size in bc:de and h/w device name location at HL
				call z,got_dev		
nxt_drv			ld a,(current_driver)					; try next driver type 	
				inc a
				jr mnt_loop

				
find_dev		jp (hl)
			
			
got_dev			push hl									; Host device found, hl = h/w name from get_id
				push de									; bc:de = total device capacity in sectors
				push bc
				call os_new_line_cond						
				ld bc,015bh
				call os_print_multiple_chars_cond		; '['
				ld a,(current_driver)
				call locate_driver_base
				ld hl,0ch
				add hl,de
				call os_print_string_cond				; show driver name 'SD_CARD' etc
				ld bc,015dh
				call os_print_multiple_chars_cond		; ']'
				pop bc
				pop de
				xor a
				ld (vols_on_device_temp),a
				
				ld hl,device_count
				inc (hl)								; Increase the device count
				ld a,(current_driver)
				ld hl,(dhwn_temp_pointer)	
				ld (hl),a
				inc hl
				ld (hl),e								; Fill in total capacity of host device (in sectors) BC:DE
				ld (iy+4),e								; Also put total capacity in first volume entry for devices
				inc hl									; where there is no MBR
				ld (hl),d
				ld (iy+5),d
				inc hl
				ld (hl),c			
				ld (iy+6),c
				inc hl
				ld (hl),b								; capacity MSB
				inc hl
				pop de
				ex de,hl
				ld bc,22
				ldir									; Fill in hardware name of host device - limit to 22 chars
				xor a
				ld b,5		
clrrode			ld (de),a								; pad device entry with zeroes to 32 bytes
				inc de
				djnz clrrode
				ld (dhwn_temp_pointer),de				; update device info pointer ready for next device
					
				xor a									; Now scan this device for partitions
fnxtpart		push iy
				call fs_get_partition_info
				pop iy
				jr c,nxt_dev							; if hardware error skip device
				cp 0ceh									; if bad format, skip device
				jr z,nxt_dev
				push af
				ld (iy),1								; Found a partition - set volume present
				ld a,(current_driver)
				ld (iy+1),a								; Set volume's Host driver number
				ld a,(partition_temp)	
				ld (iy+7),a								; Set its partition-on-host device number	
				pop af
				or a
				jr z,dev_mbr
				xor a
				ld (iy+8),a								; No MBR on device - fill in partition offset as zero
				ld (iy+9),a								; and go immediately to next device
				ld (iy+10),a							; (capacity data has already been filled in)
				ld (iy+11),a
				call show_vol_info
				call test_max_vol
				ret z									; quit if reached max allowable number of volumes
			
nxt_dev			ld a,(vols_on_device_temp)				; were any volumes found on the previous device?
				or a
				ret nz		
				call test_quiet_mode
				jr nz,skp_cu
				ld a,10
				ld (cursor_x),a
skp_cu			ld hl,no_vols_msg						; if not say 'No volumes'
				call os_show_packed_text_cond
				call os_new_line_cond
				ret
				
			
dev_mbr			ld de,4
				add hl,de
				ld a,(hl)								;A = type of partition
				or a
				ret z									;end if partition type is zero
				add hl,de
				
				push iy
				ld b,4
sfmbrlp			ld a,(hl)								; fill in offset in sectors from MBR to partition
				ld (iy+8),a
				inc hl
				inc iy
				djnz sfmbrlp
				pop iy
				push iy
				ld b,3	
nsivlp			ld a,(hl)
				ld (iy+4),a								; fill in number of sectors in volume (partition)
				inc hl
				inc iy
				djnz nsivlp
				pop iy
				
				call show_vol_info
				call test_max_vol	
				ret z									; quit if reached max allowable number of volumes
				ld a,(partition_temp)
				inc a
				cp 4									; max number of partitions per device
				jp nz,fnxtpart
				jr nxt_dev
				

test_max_vol
			
				ld de,16
				add iy,de			
				ld hl,volume_count
				inc (hl)
				ld a,(hl)
				cp max_volumes
				ret
			
			
show_vol_info
				
				call test_quiet_mode
				jr nz,skp_cm2
				ld a,9			
				ld (cursor_x),a
skp_cm2			ld a,(volume_count)
				push af
				add a,30h		
				ld (vol_txt+4),a	
				ld hl,vol_txt
				call os_print_string_cond				; show 'VOLx:'
				ld hl,vols_on_device_temp
				set 0,(hl)								; note that some volumes were found on this device
			
				pop af
				push iy
				call os_change_volume					; sets up the data structures and variables for the desired volume
				jr z,vform_ok							; so format type / label can be read
svi_fe			ld hl,format_err_msg		
svi_pem			call os_show_packed_text_cond			; volume not formatted to fat16
				jr skpsvl
			
vform_ok		call fs_get_volume_label
				jr c,svi_hwe
				or a
				jr nz,svi_fe
				call os_print_string_cond				; show volume label
			
skpsvl			call os_new_line_cond
				pop iy
				ret
				
svi_hwe			ld hl,disk_err_msg
				jr svi_pem
			
			
test_quiet_mode
			
				ld a,(os_quiet_mode)
				or a
				ret

;-----------------------------------------------------------------------------------------------


show_dev_driver_name
	
	
				call locate_driver_base					; set driver number in A before calling	
				ex de,hl
				ld de,0ch
				add hl,de
				call os_print_string					; show driver name (IE: 'SD Card' etc).
				push bc
				ld bc,0120h
				call os_print_multiple_chars			; add a space
				pop bc
				ret


locate_driver_base

				push hl									; returns driver base address in DE
				ld de,3									; set driver number in A before calling
				ld d,a
				mlt de
				ld hl,driver_table
				add hl,de
				ld de,(hl)
				pop hl
				ret
				
		
;-------------------------------------------------------------------------------------------------------

os_print_multiple_chars_cond

				call test_quiet_mode
				ret nz
			
os_print_multiple_chars

;c = char
;b = count
				push bc
				push hl
				ld a,c
				ld hl,rep_char_txt
				ld (hl),a
pmch_lp			push hl
				call os_print_string
				pop hl
				djnz pmch_lp
				pop hl
				pop bc
				ret

;--------------------------------------------------------------------------------------------------


ext_plot_char	ld a,e
				jp hwsc_plot_char
				

;-----------------------------------------------------------------------------------------------
; Some file system related routines 
;-----------------------------------------------------------------------------------------------


fs_get_dir_cluster


				push af								;returns current volume's dir cluster in DE  
				push hl			
				call fs_get_dir_cluster_address
				ld de,(hl)
dclopdone		pop hl
				pop af
				cp a								;set ZF, all OK
				ret
				




fs_update_dir_cluster

				push af								;updates current volume's dir cluster from DE
				push hl			
				push de			
				call fs_get_dir_cluster_address	
				pop de
				ld (hl),de
				jr dclopdone
			




fs_get_dir_cluster_address

				ld hl,volume_dir_clusters			;HL returns location dir cluster pointer
				ld a,(current_volume)	
				ld de,3
				ld d,a
				mlt de
				add hl,de
				ret
				
	

	
	
fs_get_total_sectors


				push af
				push hl								;returns total sectors of current volume in xDE 
				call fs_calc_volume_offset	
				ld hl,volume_mount_list+4
				add hl,de
				ld de,(hl)
				pop hl
				pop af
				cp a								;set ZF, no error
				ret





fs_calc_volume_offset

				ld a,(current_volume)			;selected volume 
calc_vol		ld de,16
				ld d,a
				mlt de
				ret





dev_to_driver_lookup

				ld hl,device_count				; set A to DEVICE, on return if carry is set: A is driver number
				cp (hl)							; (and hl is device_info base) else: invalid device selected
				ret nc
				ld de,32						; each entry is 32 bytes long
				ld d,a
				mlt de
				ld hl,host_device_hardware_info
				add hl,de
				ld a,(hl)
				scf
				ret
				


ext_change_volume

				ld a,e

os_change_volume

				ld b,a									; set A to required volume before calling
				cp max_volumes		
				jr nc,fs_ccv2							; report error if above max number of allowable volumes
			
				ld a,(current_volume)					; note the original volume selection
				push af
				ld a,b
				ld (current_volume),a					; change to new volume
				call fs_set_driver_for_volume			; set driver appropriately
				
				call fs_check_disk_format				; check that its a valid volume
				jr c,fs_cant_chg_vols	
				jr nz,fs_cant_chg_vols
				pop af									; restore stack parity
				xor a									; Exit, All OK
				ret


fs_cant_chg_vols
			
				pop af
				ld (current_volume),a					;restore original volume selection
				call fs_set_driver_for_volume			;set driver appropriately
				
fs_ccv2			ld a,0cfh								;return 'invalid volume' error code if specified volume is no good	
				or a
				ret
					
	
fs_set_driver_for_volume

				call fs_calc_volume_offset				; update 'current_driver' based on volume info table
				ld hl,volume_mount_list+1
				add hl,de
				ld a,(hl)
				ld (current_driver),a
				ret


;--------------------------------------------------------------------------------------------

ext_file_sector_list

;Input HL = cluster, E = sector offset

;Output HL = new cluster, E = new sector number
;       IX = address of LBA0 LSB of sector (internally updates the LBA pointer)

				
				ld a,(fs_cluster_size)
				cp e
				jr nz,fsl_sc
				call get_fat_entry_for_cluster
				jp c,os_fferr
				ld e,0
fsl_sc			call cluster_and_offset_to_lba
				inc e
fsl_done		ld bc,sector_lba0
				cp a									; set zero flag, no error
				ret

;--------------------------------------------------------------------------------------------

os_get_disk_sector_ptr
 
				ld hl,sector_lba0
				ld de,sector_buffer
				cp a
				ret
				
;--------------------------------------------------------------------------------------------


os_count_chars	push hl									; count chars in HL string, result in BC
				ld bc,0
cch_lp			ld a,(hl)
				or a
				jr z,cch_end
				inc hl
				inc bc
				jr cch_lp
cch_end			pop hl
				ret
				
			
;--------------------------------------------------------------------------------------------
; Environment variable code V0.01
;--------------------------------------------------------------------------------------------

envar_buffer_size equ 256

;--------------------------------------------------------------------------------------------

ext_get_envar
				call z,mbase_hl

os_get_envar

;Set: 		HL = name of required variable
;Returns:	ZF Set: DE = address of variable's data string
;        	ZF Not Set: Couldn't find variable
				
				ld ix,envar_list-1
env_fname		call os_count_chars					; count characters at HL to 0, count in BC
				ld a,b
				or c
				jr z,env_bad
								
env_cname		lea de,ix+1
				ld a,(de)
				cp 0ffh
				jr z,env_bad
				push bc
				ld b,c
				call os_compare_strings
				pop bc
				jr nz,env_nomatch
				inc bc								; skip the "="
				ex de,hl
				add hl,bc
				ex de,hl							; DE = pointer to value string
				xor a
				ret			
				
env_nomatch		inc ix								; look for following zero byte
				call check_envar_bounds
				jr nz,env_bad
				ld a,(ix)
				or a
				jr z,env_cname
				jr env_nomatch

env_bad			ld a,82h							; ZF not set (and "bad data" error) = Didnt find envar
				or a
				ret	
				
;--------------------------------------------------------------------------------------------

ext_set_envar

;HL = addr of variable name (zero terminated)
;DE = addr of data for variable (zero terminated)

;Returns:
;ZF = Set: OK
;ZF = Not Set: No enough space for new variable
		
				call z,mbase_hl
				call z,mbase_de

os_set_envar	ld a,(hl)							;abort if either args point at zero
				or a
				jr z,env_bad
				ld a,(de)
				or a
				jr z,env_bad

				push hl
				push de
				call os_delete_envar				;doesn't matter if named envar didnt previously exist
				pop de
				pop hl
				
				ld ix,(envar_top_loc)				;is there space for new entry?	
env_enlp		call check_envar_bounds
				jr nz,env_bad
				ld a,(hl)							;enter name into list 
				ld (ix),a
				or a
				jr z,env_ndone
				inc hl
				inc ix
				jr env_enlp
				
env_ndone		call check_envar_bounds				;enter "=" into list
				jr nz,env_bad
				ld (ix),'='
				inc ix

env_evlp		call check_envar_bounds				;enter value into list
				jr nz,env_bad
				ld a,(de)
				ld (ix),a
				or a
				jr z,env_vdone
				inc de
				inc ix
				jr env_evlp

env_vdone		inc ix
				ld (ix),0ffh
				ld (envar_top_loc),ix					;note the end-of-list location
				xor a
				ret

	
;--------------------------------------------------------------------------------------------

ext_delete_envar

				call z,mbase_hl

os_delete_envar

;HL = name of required variable (null terminated string)
;ZF = Set: OK
;ZF = Not Set: Didnt find named variable


				call os_get_envar					;does it even exist?
				ret nz
				
				push de
				pop hl
				xor a
				sbc hl,bc							;hl = location of name in envar list
				
env_fnxt		inc de								;find next envar (look for next zero)
				push de
				pop ix
				call check_envar_bounds
				jr nz,env_bad
				ld a,(de)
				or a
				jr nz,env_fnxt

env_gnxt		inc de								;skip past zero
				ex de,hl
env_collp		ld a,(hl)
				ld (de),a							;put this character at previous envar name (collapse list)
				cp 0ffh
				jr z,env_clspd						;if this byte is FF, it's the end of the envar list
				push hl
				pop ix
				call check_envar_bounds
				jr nz,env_bad
				inc hl
				inc de
				jr env_collp

env_clspd		ld (envar_top_loc),de				;note the end of the envar list
				xor a
				ret
				
;--------------------------------------------------------------------------------------------

check_envar_bounds

				push bc
				push hl
				push ix
				pop hl
				ld bc,1+(envar_list+envar_buffer_size)
				xor a
				sbc hl,bc
				jr c,env_bok
				xor a
				inc a
				pop hl
				pop bc
				ret

env_bok			xor a
				pop hl
				pop bc
				ret
						
;--------------------------------------------------------------------------------------------

os_get_keymap_location

				ld hl,unshifted_keymap
				cp a									; set zero flag = no error
				ret


;--------------------------------------------------------------------------------------------


ext_play_audio	call z,mbase_hl
				
os_play_audio	call hwsc_play_audio
				ret
				
;--------------------------------------------------------------------------------------------

test_de			push hl
				ld hl,0
				adc hl,de
				pop hl
				ret

;==============================================================================================
; Internal OS command routines
;==============================================================================================

	include 'commands\c.asm'
	include 'commands\cd.asm'
	include 'commands\cls.asm'
	include 'commands\colon.asm'
	include 'commands\d.asm'
	include 'commands\del.asm'
	include 'commands\dir.asm'
	include 'commands\f.asm'
	include 'commands\format.asm'
	include 'commands\h.asm'
	include 'commands\help.asm'
	include 'commands\gtr.asm'
	include 'commands\lb.asm'
	include 'commands\m.asm'
	include 'commands\md.asm'
	include 'commands\r.asm'
	include 'commands\rd.asm'
	include 'commands\rn.asm'
	include 'commands\sb.asm'
	include 'commands\rx.asm'
	include 'commands\tx.asm'
	include 'commands\t.asm'
	include 'commands\mount.asm'
	include 'commands\vers.asm'
	include 'commands\exec.asm'
	include 'commands\ltn.asm'
	include 'commands\pen.asm'
	include 'commands\palette.asm'
	include 'commands\mouse.asm'
	include 'commands\vmode.asm'
	include 'commands\font.asm'
	include 'commands\set.asm'
	include 'commands\dz.asm'
	include 'commands\sound.asm'
	include 'commands\avail.asm'
	include 'commands\fi.asm'
	
os_cmd_unused	ret		; <- dummy command, should never be called

;-----------------------------------------------------------------------------------------------

os_get_mem_base

		ld hl,(free_sysram_base)
		ld de,(free_vram_a_base)
		ld bc,(free_vram_b_base)
		cp a
		ret


os_get_mem_top

		ld hl,(free_sysram_top)
		ld de,(free_vram_a_top)
		ld bc,(free_vram_b_top)
		cp a
		ret

;-----------------------------------------------------------------------------------------------

ext_set_pointer

; Set D = 1: use default pointer, otherwise:

;  Set HL to location of sprite data in memory (copied to sprite RAM by this routine)
;  followed by:
;   $00 - palette offset
;   $00 - colour count
;  then.. palette data (starting from colour 1)

;   Set C to pointer height (max 32)
;   Set B to palette 0-3
;   Set E to enable/disable pointer sprite

;   Returns with Zero Flag set if mouse driver is active.
				
				call z,mbase_hl

os_set_pointer

				ld a,e
				or a
				jr z,disable_pointer
				
				ld a,(devices_connected)			; If the mouse is not enabled, disable the pointer
				and 2
				jr nz,ok_md_enabled
				call disable_pointer
				xor a
				inc a
				ret
				
				
ok_md_enabled	ld a,d
				and 1
				jr z,user_def_pointer
					
				ld hl,default_pointer
				ld de,vram_b_addr+vram_b_size-512
				ld bc,default_pointer_colours-default_pointer
				call unpack_rle
					
				ld bc,0
				ld c,default_pointer_height
				ld (os_pointer_height),bc
				ld hl,default_pointer_colours
				ld a,3
				ld (os_pointer_palette),a		;default pointer uses palette 3
				jr copy_spr_pal
				
user_def_pointer
				ld a,b
				and 3
				ld (os_pointer_palette),a	
				ld a,c
				cp 020h
				jr c,pointhok
				ld a,020h
pointhok		ld (os_pointer_height),a
				ld bc,16
				ld b,a
				mlt bc								;height * 16 = number of bytes in def
				ld de,vram_b_addr+vram_b_size-512
				ldir								;copy image to sprite RAM
							
copy_spr_pal	push hl								;stash address of palette offset
				ld bc,0
				ld c,(hl)
				sla c
				rl b								;bc = palette offset * 2
				ld hl,hw_palette			
				add hl,bc
				ld a,(os_pointer_palette)			;add palette selection
				sla a
				ld b,a
				ld c,0
				add hl,bc				
				ex de,hl							;de = dest in palette
				pop hl								;retrieve palette offset
				inc hl								;move to number of colours
				ld b,0
				ld c,(hl)
				sla c
				rl b								;bc = palette colour count * 2
				inc hl
				ldir								;copy colours to palette 3
				
				ld hl,07fe0h
				ld (os_pointer_definition),hl		
				ld a,1
				ld (os_pointer_enable),a
				ld (sprite_control),a				;globally enable all sprites
				ld a,(os_pointer_palette)
				ld (sprite_palette_select),a						
				call hwsc_update_pointer_sprite				
				xor a
				ret


disable_pointer

				xor a
				ld (os_pointer_enable),a
				ld (sprite_control),a				;globally enable all sprites
				ret
				
;-----------------------------------------------------------------------------------------------

test_amoeba_vers

				call hwsc_get_version				;returns only if hardware version correct
				ld hl,amoeba_version_required-1		;otherwise shows error message
				xor a
				sbc hl,de
				ret c
				
				ld hl,hw_warn_txt2
				ld de,amoeba_version_required
				call hexword_to_ascii
				
				ld hl,vram_a_addr+16384				;clear screen (use video settings from ROM code
				ld (bitmap_parameters),hl			;except reposition the display location)
				ld (hl),0
				push hl
				pop de
				inc de
				ld bc,320*240
				ldir
					
				ld ix,vram_a_addr+16384+(320*116)+56		;display error message - use bitmap mode as charmap mode
				ld iy,hw_warn_txt1							;was a later addition to hardware
nextwchar		ld a,(iy)
				or a
				jr z,wmsg_done
				ld hl,64
				ld h,a
				mlt hl
				ld de,vram_a_addr
				add hl,de									;hl = char pattern address
				ld c,8
wpixlp2			ld a,(hl)
				ld b,8
wpixlp1			rl a
				jr nc,nowpix
				ld (ix),1
				jr wpixd
nowpix			ld (ix),0
wpixd			inc ix
				djnz wpixlp1
				ld de,320-8
				add ix,de
				ld de,8
				add hl,de
				dec c
				jr nz,wpixlp2
				
				ld de,8-(320*8)
				add ix,de
				inc iy
				jr nextwchar


wmsg_done		call purge_keyboard
				call set_irq_vectors
				call enable_os_irqs
				ei

wmsg_loop		call hwsc_wait_vrt			;	flash error message until ESC pressed (reset)
				
				ld de,ccch
				ld hl,cursorflashtimer
				inc (hl)
				ld a,(hl)
				and 64
				jr z,got_wcolour
				ld de,000h
got_wcolour		ld (hw_palette+2),de
								
				call os_get_key_press
				cp 76h
				jr nz,wmsg_loop
				jp 0

;-----------------------------------------------------------------------------------------------


relativize_hl	push de						

				pop de
				pop de						; PC of return address					
				add hl,de
				ld de,8
				or a
				sbc hl,de
				dec sp
				dec sp
				dec sp
				dec sp
				dec sp
				dec sp
				pop de						; original DE
				ret


relative_call	push de						

				pop de
				pop de						; PC of return address					
				add hl,de
				ld de,8
				or a
				sbc hl,de
				dec sp
				dec sp
				dec sp
				dec sp
				dec sp
				dec sp
				pop de						; original DE
				jp (hl)


;-----------------------------------------------------------------------------------------------

os_allocate_ram

; set BC = number of bytes to allocate
; set E = 0 sysram, E = 1 vram_a, E = 2 vram_b
; returns HL = address of allocated RAM
; ZF set if all OK

				ld a,e
				ld de,6
				ld d,a
				mlt de
				ld ix,free_sysram_base
				add ix,de
				
				ld hl,(ix+3)
				xor a
				sbc hl,bc
				jr c,alloc_err
				ld (ix+3),hl
				
				ld de,(ix)
				xor a
				push hl
				sbc hl,de
				pop hl
				inc hl
				jr nc,alloc_ok
alloc_err		ld a,8eh						; cannot allocate memory
				or a
				ret
				
alloc_ok		xor a
				ret
			


os_deallocate_ram

; set BC = number of bytes to de-allocate
; set E = 0 sysram, E = 1 vram_a, E = 2 vram_b
; returns HL = address of allocated RAM
; ZF set if all OK		

				push de
				
				ld a,e
				ld de,6
				ld d,a
				mlt de
				ld ix,free_sysram_base
				add ix,de
				
				ld hl,(ix+3)
				add hl,bc
				ld (ix+3),hl
				
				pop de								;if deallocating sysram, check against STACK
				ld a,e
				or a
				jr nz,dealloc_ok					
				
				ld de,sysram_addr+sysram_size-stack_size
				xor a
				sbc hl,de
				jr c,dealloc_ok
				dec de
				ld (ix+3),de
dealloc_ok		xor a
				ret
				
				
;-----------------------------------------------------------------------------------------------

os_protected_ram_test

; set bc = start of range
; set de = end of range

; Returns ZF set if no collision


				ld ix,free_sysram_base			;is range within PROSE?
				ld hl,(ix)
				xor a
				sbc hl,bc
				jr c,no_prose_hit
				ld a,26h						;error - OS area protected
				or a
				ret
				
no_prose_hit	ld hl,(ix+6)					;is range within the charmap/font data
				xor a
				sbc hl,bc
				jr c,no_vram_a_low_hit
				ld hl,800000h
				xor a
				sbc hl,de
				jr nc,no_vram_a_low_hit
				ld a,36h						;error - video ram protected
				or a
				ret

no_vram_a_low_hit
				
				call test_alloc
				ret nz
				lea ix,ix+6
				call test_alloc
				ret nz
				lea ix,ix+6
				call test_alloc
				ret 
				
test_alloc		ld hl,(ix+3)					;hl = syram freee top
				xor a
				sbc hl,de
				jr nc,no_colis
				ld hl,sysram_addr+sysram_size	;hl = sysram max
				xor a
				sbc hl,bc
				jr c,no_colis
				ld a,35h						;error - range within allocated memory 
				or a
				ret
				
no_colis		xor a
				ret
				
;-----------------------------------------------------------------------------------------------

os_protected_ram_query

				push af
				ld hl,pmq_txt
				call os_print_string
				call os_wait_key_press
				ld a,b
				cp 'y'
				jr z,ok_pmwrite
				cp 'Y'
				jr z,ok_pmwrite
				pop af
				ret
				
ok_pmwrite		pop af
				xor a
				ret

;-----------------------------------------------------------------------------------------------
					
os_output_to_envars

; Set IX to location of first 24bit value to output 
; B = number of envars to make 
; C = Start envar number
				
out_to_envlp	push bc
				ld a,c
				ld hl,envar_out_n_txt+3
				call hexbyte_to_ascii
						
				ld hl,scratch_pad
				lea de,ix+2
				ld b,3
				call n_hexbytes_to_ascii
				ld (hl),0
				
				ld hl,envar_out_n_txt
				ld de,scratch_pad
				push ix
				call os_set_envar
				pop ix
				pop bc
				ret nz
				
				lea ix,ix+3
				inc c
				djnz out_to_envlp
				xor a
				ret			


clear_output_envars

				ld c,0
del_out_envlp	push bc
				ld a,c
				ld hl,envar_out_n_txt+3
				call hexbyte_to_ascii
				ld hl,envar_out_n_txt
				call os_delete_envar
				pop bc
				ret nz
				inc c
				djnz del_out_envlp
				xor a
				ret			

;-----------------------------------------------------------------------------------------------
; Storage Device Drivers
;-----------------------------------------------------------------------------------------------

	include		'prose_sdcard_driver_v110.asm'		; SD Card driver 
	
; Additional storage device driver source can be added here..
; Also add the driver's PROSE header address label to the list below, end with 0.

driver_table		dw24 sd_card_driver	; Storage Device Driver #0
					dw24 0 				; Storage device driver #1 place holder
					dw24 0				; Storage device driver #2 place holder
					dw24 0				; Storage device driver #3 place holder
					
					dw24 0				; Essential zero terminator 
					
;----------------------------------------------------------------------------------------
; IO routines
;-----------------------------------------------------------------------------------------------

	include		'ez80p_interrupt_code.asm'			; ez80p-specific low level code	
	include		'ez80p_rs232_code.asm'
	include		'ez80p_video_code.asm'
	include		'ez80p_misc_code.asm'

	include		'prose_keyboard_routines.asm'		; general OS-level code
	include		'prose_serial_routines.asm'
	include		'prose_fat16_code_v08.asm'

;-----------------------------------------------------------------------------------------------
; OS Data 
;-----------------------------------------------------------------------------------------------


	include		'prose_data.asm'					; OS data
	include		'phil_font_packed.asm'				; Default font


default_pointer_height equ 20

	include		'default_pointer_packed.asm'		; Default mouse pointer image

default_pointer_colours	db 1,2						;offset from colour 0, number of colours 
						dw 000h,0fffh

;================================================================================================
	
os_max_addr		db 0								; address marker for start of safe user RAM
	

;================================================================================================

				end	
				
;================================================================================================
	