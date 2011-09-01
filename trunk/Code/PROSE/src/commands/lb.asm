;-----------------------------------------------------------------------
;"lb" - Load binary file command. V0.05
;-----------------------------------------------------------------------

os_cmd_lb		call os_check_volume_format	
				ret nz
				
				call os_cache_original_vol_dir
				call do_lb
				call os_restore_original_vol_dir
				ret
				
do_lb			call os_scan_for_non_space				;filename supplied?
				jr nz,lb_got_fn
missing_args	ld a,8dh
				or a
				ret
				
lb_got_fn		xor a
				call os_parse_path_string
				ret nz
				call os_find_file						;get header info
				ret nz
				ld (filesize_cache),de					;note the filesize (23:0)
				ld hl,(free_sysram_base)
				ld (data_load_addr),hl					;default load location
				
				ld hl,(os_args_loc)
				call os_next_arg
				call ascii_to_hexword					;load address
				jr z,lb_argsok
				cp 81h
				jr z,missing_args
				ret
				
lb_argsok		ld (data_load_addr),de
				ld bc,(data_load_addr)					;ensure load doesn't overwrite OS/Low VRAM/Allocated RAM
				push bc
				pop hl
				ld de,(filesize_cache)
				add hl,de
				ex de,hl
				call os_protected_ram_test
				call nz,os_protected_ram_query
				ret nz

				ld hl,(data_load_addr)					;load the file
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
