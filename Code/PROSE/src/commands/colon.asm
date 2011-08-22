;-----------------------------------------------------------------------
;":" for write hex bytes command. V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_colon
	
				call hexword_or_bust			;the call only returns here if the hex in DE is valid
				jp z,os_no_start_addr			;DE = address to write to
				push de
				pop ix							;ix is now dest
			
wmblp			call hexword_or_bust			;the call only returns here if the hex in DE is valid
				jr z,os_ccmdn
				ld (ix),e						;copy hex bytes from line to RAM
				inc ix
				jr wmblp

os_ccmdn		xor a
				ret
		

;-----------------------------------------------------------------------
