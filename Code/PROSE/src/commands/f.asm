;-----------------------------------------------------------------------
;"f" fill memory command. V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_f			

				call get_start_and_end				;this routine only returns here if start/end data is valid
			
				call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jp z,os_no_args_error				;or there's no hex supplied
				ld a,e
				ld (fillbyte),a
					
				call test_mem_range
				jp c,os_range_error					;abort if end addr <= start addr
					
				ld a,(fillbyte)
f_floop			ld (hl),a
				cpi									;use CPI to inc HL / dec BC and test for BC = 0
				jp pe,f_floop
					
				ld a,020h							;OK completion message
				or a
				ret

;-----------------------------------------------------------------------
