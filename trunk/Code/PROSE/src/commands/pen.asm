;-----------------------------------------------------------------------------------------
;"Pen" - Change attribute v0.03 - ADL mode
;-----------------------------------------------------------------------------------------

os_cmd_pen
	
				ld b,18								;pen, plus optional background and palette
				ld ix,current_pen
				
chpenlp			call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,pendone						;any more data?
				inc hl
				ld (ix),e
				ld (ix+1),d
				inc ix
				inc ix
				djnz chpenlp	
				
pendone			ld hl,pen_palette					;refresh palette in case it was changed
				call hswc_set_ui_colours
				xor a
				ret

;------------------------------------------------------------------------------------------
