;-----------------------------------------------------------------------
;'TX' - Transmit binary file via serial port command. V0.03 - ADL mode
;-----------------------------------------------------------------------

os_cmd_tx		ld a,(hl)								;check args exist
				or a
				jp z,os_no_fn_error
			
				push hl									;clear serial filename area
				ld hl,serial_filename
				ld bc,16
				xor a
				call os_bchl_memfill
				pop hl
			
				ld b,16									;max chars to copy
				ld de,serial_filename
				call os_copy_ascii_run					;(hl)->(de) until space or zero, or count = 0
				ld a,c
				ld (serial_fn_length),a
				call os_scan_for_space
							
				call hexword_or_bust					;the call only returns here if the hex in DE is valid
				jp z,os_no_start_addr					;get save address in DE
				ld (serial_ez80_address),de
			
				call hexword_or_bust					;find file length		
				jp z,os_no_filesize
				ld (serial_file_length),de
				ld hl,0
				ld a,07h								;test for zero file length
				or a
				adc hl,de
				jr z,s_error
				
				ld hl,ser_send_msg
				call os_show_packed_text
			
				ld de,(serial_file_length)
				ld hl,serial_filename					;filename location in HL
				ld ix,(serial_ez80_address)
				call serial_send_file
				ret nz			
			
				ld a,020h								;ok message on return
s_error			or a
				ret
				
			
;----------------------------------------------------------------------------------------------
