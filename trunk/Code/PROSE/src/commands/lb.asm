;-----------------------------------------------------------------------
;"lb" - Load binary file command. V0.03 - ADL mode
;-----------------------------------------------------------------------

os_cmd_lb
	
				call os_check_volume_format	
				ret nz
				
				call filename_or_bust					;filename supplied?
				call os_find_file						;get header info
				ret nz
				ld (filesize_cache),de					;note the filesize (23:0)
				ld hl,(default_load_addr)
				ld (data_load_addr),hl					;default load location
				
				ld hl,(os_args_loc)
				call os_next_arg

				call hexword_or_bust					;the call only returns here if the hex in DE is valid
				jr z,os_lbnao							;load location override?
				ld (data_load_addr),de

os_lbnao		ld de,(data_load_addr)				
				ld hl,(sys_ram_high)					;ensure load doesn't overwrite OS
				dec hl
				xor a
				sbc hl,de
				jr c,os_lbprok
				ld a,026h								;ERROR $26 - OS AREA PROTECTED
				or a
				ret
				
os_lbprok		ld hl,(data_load_addr)					;load the file
				call os_read_bytes_from_file
				ret nz
			
report_bytes_loaded

				ld hl,os_hex_prefix_txt					;rx command also jumps here
				call os_print_string					;show "$"
				
				ld de,filesize_cache+2					;de must point at the msb
				ld hl,output_line
				ld b,3
				call n_hexbytes_to_ascii
				ld (hl),0	
				ld b,5									;skip leading zeros
				call os_print_output_line_skip_zeroes	;show hex figures 
				
				ld hl,bytes_loaded_msg					
				call os_show_packed_text
				
				ld hl,to_txt							;show " to "
				call os_print_string

				ld hl,os_hex_prefix_txt					;show "$"
				call os_print_string	

				ld de,(data_load_addr)					;show the load address
				call os_show_hex_address

				call os_new_line
				xor a
				ret
				
;-----------------------------------------------------------------------------------------------

data_load_addr	equ scratch_pad
filesize_cache	equ scratch_pad+3

;-----------------------------------------------------------------------------------------------
