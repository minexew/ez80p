;**************
;* PROSE DATA *
;**************

;-------------------------------------------------------------------------------------------
; kernal routine locations
;-------------------------------------------------------------------------------------------

kernal_table

	dw24 ext_mount_volumes			;00		
	dw24 os_get_device_info			;01		
	dw24 os_check_volume_format		;02		
	dw24 ext_change_volume			;03		
	dw24 os_get_volume_info			;04		
	dw24 ext_format					;05		
	dw24 ext_make_dir				;06		
	dw24 ext_change_dir				;07		
	dw24 os_parent_dir				;08		
	dw24 os_root_dir				;09		
	dw24 ext_delete_dir				;0a		
	dw24 ext_find_file				;0b		
	dw24 ext_set_file_pointer		;0c		
	dw24 os_set_load_length			;0d		
	dw24 ext_read_bytes_from_file	;0e		
	dw24 ext_erase_file				;0f		
	dw24 ext_rename_file			;10		
	dw24 ext_create_file			;11		
	dw24 ext_write_bytes_to_file	;12		
	dw24 fs_get_total_sectors		;13		
	dw24 os_goto_first_dir_entry	;14		 
	dw24 os_get_dir_entry			;15		
	dw24 os_goto_next_dir_entry		;16		
	dw24 ext_read_sector			;17		
	dw24 ext_write_sector			;18		
	dw24 ext_file_sector_list		;19		
	dw24 fs_get_dir_cluster			;1a		
	dw24 fs_update_dir_cluster		;1b		
	dw24 os_get_current_dir_name	;1c		

	dw24 os_wait_key_press			;1d		
	dw24 os_get_key_press			;1e		
	dw24 os_get_key_mod_flags		;1f		

	dw24 ext_serial_get_header		;20		
	dw24 ext_serial_receive_file	;21		 
	dw24 ext_serial_send_file		;22		 
	dw24 ext_serial_tx				;23		
	dw24 ext_serial_rx				;24		

	dw24 ext_print_string			;25		
	dw24 hwsc_clear_screen			;26		
	dw24 hwsc_wait_vrt				;27		
	dw24 os_set_cursor_position		;28		
	dw24 ext_plot_char				;29		
	dw24 ext_set_pen				;2a		
	dw24 ext_background_colours		;2b		
	dw24 hwsc_draw_cursor			;2c		
	dw24 os_get_pen					;2d		
	dw24 hwsc_scroll_up				;2e		
	dw24 os_set_video_hw_regs		;2f		
	dw24 os_get_display_size		;30		
	dw24 hwsc_get_charmap_addr_xy	;31		
	dw24 os_get_cursor_position		;32		 

	dw24 ext_set_envar				;33		
	dw24 ext_get_envar				;34		
	dw24 ext_delete_envar			;35		

	dw24 os_set_mouse_window		;36		
	dw24 os_get_mouse_position		;37		
	dw24 os_get_mouse_motion		;38		

	dw24 hwsc_time_delay			;39		
	dw24 ext_compare_strings		;3a		
	dw24 ext_hexbyte_to_ascii		;3b		
	dw24 ext_ascii_to_hexword		;3c		
	dw24 ext_user_input				;3d		

	dw24 hwsc_get_version			;3e		
	dw24 os_dont_store_registers	;3f		
	dw24 os_get_font_info			;40 	
	dw24 hwsc_read_rtc				;41     
	dw24 hwsc_write_rtc				;42		 
	dw24 os_get_keymap_location		;43		 
	dw24 os_get_mem_high			;44
	
;-------------------------------------------------------------------------------------------
; Non-packed Text Strings
;-------------------------------------------------------------------------------------------

welcome_message			db "PROSE for EZ80P by Phil Ruston 2011",11,11
						db "SYSTEM RAM free above: $",0
storage_txt				db "Drives:",11,0
os_dos_cmds_txt			db "COMMANDS",0
startup_script_fn		db "STARTUP.SCR",0
os_hex_prefix_txt		db "$",0
os_version_txt			db "OS Version: $",0		
hw_version_txt			db "AMOEBA HW Version: $",0
fwd_slash_txt			db " / ",0
loading_txt				db "Loading..",11,0
saving_txt				db "Saving..",11,0
ezp_extension_txt		db ".ezp",32
os_more_txt				db 11,"More?",11,11,0
nmi_freeze_txt			db "Register Dump:"
crlfx2_txt				db 11,11,0
rep_char_txt			db "x",0
to_txt					db " to ",0

;------------------------------------------------------------------------------------------------
; Packed text section
;------------------------------------------------------------------------------------------------

dictionary				db 0,"DEBUG"			;01	
						db 0,"-----"			;02
						db 0,"IO"				;03
						db 0,"--"				;04
						db 0,"MISC"				;05
						db 0,"----"				;06
						db 0,"addr"				;07
						db 0,"PROSE"			;08 
						db 0,"a b c"			;09
						db 0,"Address"			;0a
						db 0,"Bytes"			;0b
						db 0,"Executable"		;0c 
						db 0,"Hunt"				;0d
						db 0,"Fill"				;0e
						db 0,"Goto"				;0f
						
						db 0,"Show"				;10
						db 0,"CPU"				;11
						db 0,"Registers"		;12
						db 0,"As"				;13
						db 0,"ASCII"			;14
						db 0,"Clear"			;15
						db 0,"Screen"			;16
						db 0,"Disassemble"		;17
						db 0,"Switch"			;18
						db 0,"Copy"				;19
						db 0,"Device"			;1a
						db 0,"Change"			;1b
						db 0,"Drive"			;1c
						db 0,"Dir"				;1d
						db 0,"/"				;1e
						db 0,"fn"				;1f
						
						db 0,"Delete"			;20
						db 0,"File"				;21
						db 0,"Info"				;22
						db 0,"VOLx:"			;23
						db 0,"Make"				;24
						db 0,"Remount"			;25
						db 0,"Start"			;26
						db 0,"Warning!"			;27 
						db 0,"All"				;28
						db 0,"Remove"			;29
						db 0,"Rename"			;2a
						db 0,"Or"				;2b
						db 0,"Receive"			;2c
						db 0,"Save"				;2d
						db 0,"Transmit"			;2e
						db 0,"Load"				;2f
						
						db 0,"OS/HW"				;30
						db 0,"Version"				;31
						db 0,"[pen paper]"			;32				
						db 80h,":"					;33
						db 81h,">"					;34
						db 0,"*"					;35 (command $082h currently not used)
						db 0,"Volumes"				;36
						db 83h,"C"					;37
						db 84h,"CD"					;38
						db 85h,"CLS"				;39
						db 86h,"PEN"				;3a
						db 87h,"D"					;3b
						db 88h,"DEL"				;3c
						db 89h,"DIR"				;3d
						db 8ah,"H"					;3e
						db 8bh,"F"					;3f
						
						db 0,"On"				;40 
						db 8ch,"FORMAT"			;41
						db 0,"G"				;42
						db 8dh,"LB"				;43
						db 8eh,"M"				;44
						db 8fh,"MOUNT"			;45
						db 0,"Be"				;46
						db 90h,"R"				;47
						db 91h,"RD"				;48
						db 92h,"RN"				;49
						db 93h,"RX"				;4a
						db 94h,"SB"				;4b
						db 95h,"T"				;4c
						db 96h,"TX"				;4d
						db 97h,"VERS"			;4e	
						db 0,"Write"			;4f
						
						db 0,"Mem"				;50
						db 0,22h,"txt",22h		;51
						db 0,"Will"				;52
						db 0,"Rate"				;53
						db 0,"a"				;54
						db 0,"Prep"				;55
						db 98h,"MD"				;56
						db 0,"Drives"			;57
						db 0,"oldfn"			;58
						db 0,"newfn"			;59
						db 0,"len"				;5a
						db 0,"Colours"			;5b
						db 99h,"?"				;5c
						db 0,"Commands"			;5d
						db 0," "				;5e
						db 0,"-"				;5f
						
						db 0,"Volume"			;60
						db 0,"Full"				;61
						db 0,"Not"				;62
						db 0,"Found"			;63
						db 0,"Length"			;64
						db 0,"Zero"				;65
						db 0,"Out"				;66
						db 0,"Of"				;67
						db 0,"Range"			;68
						db 0,"Already"			;69
						db 0,"Exists"			;6a
						db 0,"At"				;6b
						db 0,"Root"				;6c
						db 0,"Mismatch"			;6d
						db 0,"Request"			;6e
						db 0,"Data"				;6f
				
						db 0,"EOF"				;70
						db 0,"After"			;71
						db 0,"Unknown"			;72
						db 0,"Command"			;73
						db 0,"Bad"				;74
						db 0,"Hex"				;75
						db 0,"No"				;76
						db 0,"Aborted"			;77
						db 0,"Present"			;78
						db 0,"Checksum"			;79
						db 0,"Loaded"			;7a
						db 0,"Comms"			;7b
						db 0,"Error"			;7c
						db 0,"Arguments"		;7d
						db 0,"Lost"				;7e
						
						db 0
fat16_txt				db "FAT16"				;7f

						db 0,"Serial"			;80
						db 0,"Time"				;81
						db 0,"Font"				;82
						db 0,"Too"				;83
						db 0,"Long"				;84
						db 0,"Destination"		;85
						db 0,"Selected"			;86
						db 0,"Invalid"			;87
						db 0,"Missing"			;88
						db 0,"OK"				;89
						db 0,"OS"				;8a
						db 0,"Protected"		;8b		
						db 0,"A"				;8c
						db 0,"Is"				;8d
						db 0,"Empty"			;8e
						db 0,"End"				;8f
						
						db 0,"$"
hex_byte_txt			db "xx"					;90 (for hex-to-ascii)
						
						db 0,"Append"			;91
						db 0,"?"				;92
						db 0,"$"				;93 
						db 0,"Awaiting"			;94
						db 0,"Receiving"		;95
						db 0,"Sending"			;96
						db 0,11					;97 (new line)
						db 0,".."				;98
						db 0,"Name"				;99
						db 0," Bytes"			;9a
						db 0,"Press"			;9b
						db 0,"Any"				;9c
						db 0,"Key"				;9d
						db 0,"Enter"			;9e
						db 9ah,"EXEC"			;9f
				
						db 0,"Run"				;a0
						db 0,"Script"			;a1
yes_txt					db 0,"YES" 				;a2
						db 0,"To"				;a3
						db 0,"Set"				;a4
						db 0,"Continue"			;a5
						db 0,"None"				;a6
						db 0,"Driver"			;a7
						db 9bh,"<"				;a8
						db 0,"Newer"			;a9
						db 0,"Required"			;aa
						db 0,"FPGA config"		;ab
						db 0,"Unchanged"		;ac
						db 0," (If fn = ! receive and run program)"	;ad
						db 9ch,"PALETTE"		;ae
						db 0,"palette"			;af
						
						db 9dh,"MOUSE"			;b0
						db 0,"Enable"			;b1
						db 0,"Keyboard"			;b2
						db 0,"Detected"			;b3
						db 0,"Mouse"			;b4
						db 0,"Sector"			;b5
						db 0,"Incorrect"		;b6
						db 9eh,"VMODE"			;b7
						db 0,"Video"			;b8
						db 0,"Mode"				;b9
						db 9fh,"FONT"			;ba
						db 0,"And"				;bb
						db 0,"Saving"			;bc
						db 0,"Unsupported"		;bd
						
						db 0,1					;END MARKER





save_append_msg			db 021h,099h,069h,06ah,05fh,091h,06fh,092h,097h,0		;"File Name Already Exists - Append data?"
os_loadaddress_msg 		db 02fh,00ah,093h,0										;"Load Addr: $",0
os_filesize_msg			db 021h,064h,093h,0										;"File Size: $",0
ser_rec_msg				db 094h,021h,097h,0										;"Awaiting file",11,0
ser_rec2_msg			db 095h,06fh,098h,097h,0								;"Receiving Data..",11,0
ser_send_msg			db 096h,06fh,098h,097h,0								;"Sending Data..",11,0
ser_recsave_msg			db 095h,021h,0bbh,0bch,098h,097h,0						;"Receiving file and saving.."
hw_err_msg				db 0a7h,07ch,090h,097h,0								;"Driver Error:$xx",11,0
disk_err_msg			db 060h,07ch,0											;"Disk Error",0
script_aborted_msg		db 0a1h,077h,097h,097h,0								;"Script Aborted",11.0
no_keyboard_msg			db 076h,0b2h,0b3h,097h,0								;"No keyboard detected",11,0

packed_help1				db 097h,0
							db 001h,0													;DEBUG
							db 002h,0													;-----
							db 033h,007h,009h,05fh,04fh,050h,00bh,0				; ": ad a b c - Write Mem Bytes"
							db 034h,007h,051h,05fh,04fh,014h,0					; "> ad "txt" - write ASCII"
							db 0a8h,007h,009h,05fh,04fh,00bh,01eh,017h,0		; "< ad a b c - write bytes / disassemble" 

							db 037h,007h,007h,007h,05fh,019h,050h,0				; "C ad ad ad - copy mem"
							db 03bh,007h,007h,05fh,017h,0						; "D ad ad - disassemble"
							db 03fh,007h,007h,054h,05fh,00eh,050h,0				; "F ad ad a" - fill mem"		
							db 042h,007h,05fh,00fh,00ah,0						; "G ad - goto address"
							db 03eh,007h,007h,009h,05fh,00dh,050h,0				; "H ad ad a b c - hunt mem"
							db 044h,007h,05fh,010h,050h,00bh,0					; "M ad - show mem bytes"
							db 047h,05fh,010h,011h,012h,0						; "R - show CPU registers"
							db 04ch,007h,05fh,010h,050h,013h,014h,0				; "T - show mem as ASCII"
	
							db 097h,0
							db 003h,0											; IO
							db 004h,0											; --
							db 038h,023h,01eh,01dh,05fh,01bh,060h,01eh,01dh,0	; "CD VOLx/dir - change volume / dir"
							db 03ch,01fh,05fh,020h,021h,0						; "DEL fn - delete file"
							db 03dh,05fh,010h,01dh,0							; "DIR - show dir"
							db 041h,01ah,099h,05fh,055h,01ch,0					; "FORMAT Device Name - prep drive"
							db 043h,01fh,007h,05fh,02fh,021h,0					; "LB fn ad - load file"
							db 056h,01dh,05fh,024h,01dh,0						; "MD fn make dir"
							db 045h,05fh,025h,057h,0							; "MOUNT remount drives"
							db 048h,01dh,05fh,029h,01dh,0						; "RD dir - remove dir"
							db 049h,058h,059h,05fh,02ah,021h,0					; "RN oldfn newfn - rename file"
							db 04ah,01fh,007h,05fh,02ch,021h,0adh,0				; "RX fn ad - receive file / receive+run"
							db 04bh,01fh,007h,05ah,05fh,02dh,021h,0				; "SB fn len - save file"
							db 04dh,01fh,007h,05ah,05fh,02eh,021h,0				; "TX fn len - transmit file"		
							db 023h,05fh,018h,060h,0							; "VOLx: - switch volume"

							db 097h,0
							db 005h,0											; MISC
							db 006h,0											; ----
							db 039h,05fh,015h,016h,0							; "CLS - clear screen"
							db 09fh,01fh,05fh,0a0h,0a1h,0						; "EXEC fn - run script"
							db 0bah,01fh,05fh,01bh,082h,0						; "FONT fn - change font"
							db 0b0h,05fh,0b1h,0b0h,0a7h,0h						; "MOUSE - enable mouse driver"
							db 0aeh,09h,05fh,01bh,0afh,0						; "PALETTE a b c - change palette"
							db 03ah,032h,05fh,01bh,05bh,0						; "PEN [pen paper] change cols"
							db 04eh,05fh,010h,030h,031h,0						; "VERS - show OS/HW version"
							db 0b7h,09h,5fh,01bh,0b8h,0b9h,0					; "VMODE a - change video mode"
							db 05ch,05fh,010h,05dh,0							; "? - Show commands"		
							db 097h,0
							db 0ffh




os_cmd_locs					dw24 os_cmd_colon							;command 0
							dw24 os_cmd_gtr								;1
							dw24 os_cmd_unused							;2
							dw24 os_cmd_c								;3
							dw24 os_cmd_cd								;4
							dw24 os_cmd_cls								;5	
							dw24 os_cmd_pen								;6
							dw24 os_cmd_d								;7
					
							dw24 os_cmd_del								;8
							dw24 os_cmd_dir								;9
							dw24 os_cmd_h								;a
							dw24 os_cmd_f								;b
							dw24 os_cmd_format							;c
							dw24 os_cmd_lb								;d
							dw24 os_cmd_m								;e
					
							dw24 os_cmd_remount							;f	
							dw24 os_cmd_r								;10
							dw24 os_cmd_rd								;11
							dw24 os_cmd_rn								;12
							dw24 os_cmd_rx								;13	
							dw24 os_cmd_sb								;14
							dw24 os_cmd_t								;15
							dw24 os_cmd_tx								;16	
					
							dw24 os_cmd_vers							;17											
							dw24 os_cmd_md								;18
							dw24 os_cmd_help							;19
							dw24 os_cmd_exec							;1a
							dw24 os_cmd_ltn								;1b
							dw24 os_cmd_palette							;1c
							dw24 os_cmd_mouse							;1d
							dw24 os_cmd_vmode							;1e
							dw24 os_cmd_font							;1f
							
								
packed_msg_list				db 0										;First message marker
		
							db 060h,061h,0								;$01 Volume Full
							db 021h,062h,063h,0							;$02 File Not Found
							db 01dh,061h,0								;$03 Dir Full
							db 062h,08ch,01dh,0							;$04 Not A Dir 
							db 01dh,08dh,062h,08eh,0					;$05 Dir Is Not Empty
							db 062h,08ch,021h,0							;$06 Not A File
							db 021h,064h,08dh,065h,0					;$07 File Length Is Zero
							db 00ah,066h,067h,068h,0					;$08 Address out of range
							db 021h,099h,069h,06ah,0					;$09 File Name Already Exists
							db 069h,06bh,06ch,0							;$0a Already at root
					
							db 072h,073h,0								;$0b Unknown command
							db 087h,075h,0								;$0c Invalid Hex
							db 076h,021h,099h,0							;$0d No file name
					
							db 087h,0b5h,0								;$0e Invalid Sector 
							db 079h,074h,0								;$0f Checksum bad
bytes_loaded_msg			db 09ah,07ah,0								;$10 [Space] Bytes Loaded
							db 07bh,07ch,0								;$11 Comms error
							db 074h,07dh,0								;$12 Bad arguments

format_err_msg				db 062h,07fh,0								;$13 not FAT16

							db 081h,066h,0								;$14 time out
							db 021h,099h,083h,084h,0					;$15 file name too long
							db 076h,026h,00ah,0							;$16 no start address
							db 076h,021h,064h,0							;$17 no file length
							db 02dh,077h,0								;$18 save aborted
							db 02dh,07ch,06bh,085h,0					;$19 save error at destination
							db 062h,08ch,08h,0ch,0						;$1a Not a PROSE executable
							db 0a9h,031h,067h,08h,0aah,0				;$1b Newer version of PROSE required
							db 076h,08fh,00ah,0							;$1c no end address
							db 076h,085h,00ah,0							;$1d no destination address
					
							db 074h,068h,0								;$1e bad range
							db 088h,07dh,0								;$1f missing arguments
ok_msg						db 089h,0									;$20 ok
					
							db 087h,060h,0								;$21 Invalid Volume
							db 01ah,062h,078h,0							;$22 Device not present
					
							db 01dh,062h,063h,0							;$23 Dir not found
							db 077h,0									;$24 aborted 
					
							db 021h,099h,06dh,0							;$25 File name mismatch
							db 08ah,050h,08bh,0							;$26 OS RAM protected
							db 06fh,071h,070h,06eh,0					;$27 Data after EOF request
no_vols_msg					db 076h,036h,0								;$28 No Volumes
none_found_msg				db 097h,0a6h,063h,0							;$29 None Found
							
							db 0b6h,021h,0								;$2a Incorrect File
							db 0a9h,031h,067h,08h,0aah,0				;$2b "Newer version of FPGA config required"
							db 021h,0ach,0								;$2c File Unchanged
							
							db 076h,06fh,0								;$2d No data
							db 074h,06fh,0								;$2e Bad data
							db 066h,067h,068h,0							;$2f Out of range
							db 0bdh,01ah,0								;$30 Unsupported device
							db 01ah,062h,0b3h,0							;$31 Device not detected
							
							db 0ffh										;END MARKER

;-------------------------------------------------------------------------------------------

kernal_error_code_translation

					db 24h,2dh,2eh,14h, 08h,11h,0fh,2ah, 02fh,030h,031h		; begins at $80
					
fs_error_code_translation

					db 00h,01h,02h,03h,04h,05h,06h,07h, 08h,09h,0ah,0bh,0ch,0dh,13h,21h	  ;begins at $c0
					db 22h,23h,24h,25h,26h,0eh,00h,00h


;--------------------------------------------------------------------------------------------
; Scancode to ASCII keymaps
;--------------------------------------------------------------------------------------------

include	'UK_keymap.asm'

unshifted_keymap equ keymap+00h
shifted_keymap   equ keymap+62h
alted_keymap	 equ keymap+c4h
	
;---------------------------------------------------------------------------------------------

ui_index				db 0				; user input routine
ui_maxchars				db 0				; ""      ""
ui_string_addr			dw24 0				; ""      ""

;---------------------------------------------------------------------------------------------
; OS Display parameters
;---------------------------------------------------------------------------------------------

video_mode				db 0
current_pen				dw 07h				; current pen selection. NOTE: 16bit padded for COLOUR cmd etc.
background_colour		dw 00h				; for areas where characters have not been plotted. 16bit padded ""

pen_palette				dw 0000h,000fh,0f00h,0f0fh,00f0h,00ffh,0ff0h,0fffh
						dw 0555h,0999h,0ccch,0f71h,007fh,0df8h,0840h,038ch

plotchar_colour			db 0				; colour that the plotchat routine will use.

req_cursor_image		db 0
active_cursor_image		db 0

display_parameters							; Don't change list order!!
;-----------------

window_rows				dw24 0				; in characters		 
window_columns			dw24 0				; in characters
window_width_bytes		dw24 0				; in pixels (half the datafetch in 16 colour mode)
window_height_lines		dw24 0				; in scanlines

font_parameters			dw24 4,8,0,0
font_width_bytes		equ font_parameters+0		; this is the number of bytes plotted at destination, not in source font
font_height_lines		equ font_parameters+3
font_addr				equ font_parameters+6
font_length				equ font_parameters+9

video_window_address	dw24 0
charmap_address			dw24 0
attributes_address		dw24 0
cursor_image_address	dw24 0
total_window_bytes		dw24 0
total_charmap_bytes		dw24 0
total_row_bytes			dw24 0				; ie: font lines * window_width
window_pixel_doubling	db 0

;==================================================================================
;  Serial Routine Data
;==================================================================================

serial_ez80_address		dw24 0
serial_file_length		dw24 0
serial_fn_addr			dw24 0
serial_filename			blkb 18,0		
serial_fn_length		db 0
serial_timeout			db 0

serial_fileheader		blkb 20,0
serial_header_id		db "Z80P.FHEADER"		;12 chars
serial_transfer_started	db 0

anim_wait_count			db 0

;----------------------------------------------------------------------------------
; FILE SYSTEM RELATED VARIABLES
;----------------------------------------------------------------------------------

boot_drive			db 0

current_volume		db 0
	
current_driver		db 0			;normally updated by the "change volume" routine

device_count		db 0			;IE: the number of devices that initialized

volume_count		db 0
				
vol_txt				db " VOL0:",0	;space prefix intentional
dev_txt				db "DEV0:",0

sector_rd_wr_addr	dw24 0

;===================================================================================

; Add storage device drivers here, end with 0

driver_table		dw24 sd_card_driver	;Device driver #0
					dw24 0				;last driver

; Each driver's code should have a header in the form:
; ----------------------------------------------------
; $0    = JP to get ID routin
; $4    = JP to read sector routine
; $8    = JP to write sector routinee
; $c    = ASCII name of device type (null terminated)
;=====================================================================================

volume_dir_clusters

					blkb max_volumes*3,0
	
volume_mount_list

					blkb max_volumes*16,0

; Each entry is 16 bytes in the form:

; OFFSETS
; -------
; $00 - Volume is present (0/1)
; $01 - Volume's host driver number (1 byte)	
; $02 - [reserved]
; $03 - [reserved]
; $04 - Volume's capacity in sectors (3 bytes)
; $07 - Partition number on host drive (0/1/2/3)
; $08 - Offset in sectors from MBR to partition (2 words)
; $0c - [reserved]
; $0d - [reserved]	
; $0e - [reserved]
; $0f - [reserved]

;=====================================================================================

host_device_hardware_info

					blkb 32*4,0

; Each entry is 32 bytes..
;
; OFFSETS
; -------
; $00 - Device driver number
; $01 - Device's TOTAL capacity in sectors (4 bytes)
; $05 - Zero terminated hardware name (22 ASCII bytes max followed by $00)
; (remaining bytes to $1F currently unused)

;----------------------------------------------------------------------------------

dhwn_temp_pointer		dw24 0

partition_temp			db 0
vols_on_device_temp		db 0
sys_driver_backup		db 0
os_quiet_mode			db 0

default_load_addr		dw24 os_max_addr

;--------------------------------------------------------------------------------------

time_data				blkb	7,0

frozen					db 0
first_run				db 1
devices_connected		db 1					; bit 0 = keyboard, bit 1 = mouse

;--------------------------------------------------------------------------------------

sys_ram_high			dw24 os_max_addr
vram_a_high				dw24 vram_a_addr
vram_b_high				dw24 vram_b_addr

;----------------------------------------------------------------------------------

store_a1				db 0		
store_bc1				dw24 0
store_de1				dw24 0
store_hl1				dw24 0
store_a2				db 0
store_bc2				dw24 0
store_de2				dw24 0
store_hl2				dw24 0
store_ix				dw24 0
store_iy				dw24 0
store_pc				dw24 0		;only relevant for when program frozen by NMI
store_spl				dw24 0
store_sps				dw 0
store_mbase				db 0
store_f	 				db 0
store_adl				db 0

;----------------------------------------------------------------------------------
os_variables
;----------------------------------------------------------------------------------

store_registers			db 0
com_start_addr			dw24 0

temp_string				blkb max_buffer_chars+2,0		
script_fn				blkb 13,0

sector_lba0				db 0			; keep this byte order
sector_lba1				db 0
sector_lba2				db 0
sector_lba3				db 0

;--------------------------------------------------------------------------------------------

cursor_pos				dw24 0			; 3rd byte of triplet not used, but padding is required for 24bit writes

cursor_y 				equ cursor_pos
cursor_x 				equ cursor_pos+1
						
cursorflashtimer		db 0
cursor_status			db 0
os_linecount			db 0
		
mem_mon_addr			dw24 0
cmdop_start_address		dw24 0
cmdop_end_address		dw24 0
copy_dest_address		dw24 0
hex_address				dw24 0

find_hexstringascii 	dw24 0
xrr_temp				dw24 0
temphex					db 0
fillbyte				db 0 
ui_im_cache				db 0

commandstring			blkb max_buffer_chars+2,0
output_line				blkb max_buffer_chars+2,0
				
os_args_loc				dw24 0
os_args_pos_cache		dw24 0

os_dir_block_cache  	dw24 0
os_extcmd_jmp_addr		dw24 0

in_script_flag			db 0
script_dir				dw24 0
script_buffer			blkb max_buffer_chars+2,0
script_file_offset		dw24 0
script_buffer_offset	dw24 0
script_orig_dir			dw24 0

char_to_print			db 0,0	; zero terminated

;---------------------------------------------------------------------------------------
; Keyboard buffer and registers
;---------------------------------------------------------------------------------------

scancode_buffer			blkb 32,0

key_buf_wr_idx			db 0
key_buf_rd_idx			db 0
key_release_mode		db 0		
not_currently_used		db 0
key_mod_flags			db 0
insert_mode				db 0
current_scancode		db 0
current_asciicode		db 0

;--------------------------------------------------------------------------------------
; Mouse related registers
;--------------------------------------------------------------------------------------

mouse_id				db 0
mouse_packet_size		db 0

mouse_packet			blkb 4,0			; these registers are updated by the mouse IRQ
mouse_packet_index		db 0				;
mouse_buttons			db 0				;
mouse_disp_x			dw24 0				; cumulative mouse x displacement (not absolute position)
mouse_disp_y			dw24 0				; cumulative mouse y displacement (not absolute position)
mouse_wheel				db 0				; mouse wheel data (if available)
mouse_updated			db 0

mouse_window_size_x		dw24 0				; these registers provide higher level absolute location functions
mouse_window_size_y		dw24 0
mouse_abs_x				dw24 0
mouse_abs_y				dw24 0
mouse_disp_x_old		dw24 0
mouse_disp_y_old		dw24 0
mouse_disp_x_buffer		dw24 0
mouse_disp_y_buffer		dw24 0
mouse_new_window		db 0

mouse_sample_rate		db 0
mouse_resolution		db 0
mouse_scaling			db 0

;======================================================================================
last_os_var				db 0 
;=======================================================================================

first_os_var			equ cursor_y

;=======================================================================================


