;-----------------------------------------------------------------------
;'SB' - Save binary file command. V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_sb
	
				call os_check_volume_format				;disk ok?
				ret nz
					
				call filename_or_bust					;filename supplied?
				ld (sb_save_name_addr),hl
				
				ld hl,(os_args_loc)
				call os_next_arg
				call hexword_or_bust					;the call only returns here if the hex in DE is valid
				jp z,os_no_start_addr					;get the save location from command string
				ld (sb_save_addr),de
				
				call hexword_or_bust					;find file length		
				jp z,os_no_filesize
				ld (sb_save_length),de
				
				ld hl,(sb_save_name_addr)				;try to make file
				call os_create_file
				jr z,os_sfapp
				cp 0c9h									;if error $c9, file exists already. Else quit.
				ret nz			
				ld hl,save_append_msg					;ask if want to append data to exisiting file
				call os_show_packed_text
				call os_wait_key_press
				ld a,'y'
				cp b
				jr z,os_sfapp
				ld a,2ch								;file unchanged message
				or a
				ret
			
os_sfapp		ld hl,(sb_save_name_addr)				;filename address
				ld ix,(sb_save_addr)					;address of source data
				ld de,(sb_save_length)					;xDE = length of save
				call os_write_bytes_to_file
				ret nz	
				
				ld a,020h								;ok msg
				or a
				ret
			
				
;-------------------------------------------------------------------------------------------------

sb_save_addr		equ scratch_pad
sb_save_length		equ scratch_pad+3
sb_save_name_addr	equ scratch_pad+6

;--------------------------------------------------------------------------------------------------
