;-----------------------------------------------------------------------------------------
;"Palette" - Change attribute v0.01 - ADL mode
;-----------------------------------------------------------------------------------------

os_cmd_palette

				ld b,16								;upto 16 RGB words 
				ld ix,pen_palette
				
				ld c,0
chcollp			push bc
				call hexword_or_bust				;the call only returns here if the hex in DE is valid
				pop bc
				jr z,colrdone						;any more data?
				inc c
				inc hl
				ld (ix),e
				ld (ix+1),d
				inc ix
				inc ix
				djnz chcollp
			
colrdone		ld a,c
				or a
				jr nz,pal_ok
				ld a,81h							; "no data" error
				or a
				ret
pal_ok			ld hl,pen_palette
				call hswc_set_ui_colours	
				xor a
				ret

;------------------------------------------------------------------------------------------
