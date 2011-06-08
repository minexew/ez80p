;-----------------------------------------------------------------------------------------
;"Pen" - Change attribute v0.02 - ADL mode
;-----------------------------------------------------------------------------------------

os_cmd_pen
	
				ld b,2								;pen, plus optional background
				ld ix,current_pen
				
chpenlp			call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,pendone						;any more data?
				inc hl
				ld (ix),e
				ld (ix+1),d
				inc ix
				inc ix
				djnz chpenlp	
				
pendone			call os_refresh_screen
				xor a
				ret

;------------------------------------------------------------------------------------------
