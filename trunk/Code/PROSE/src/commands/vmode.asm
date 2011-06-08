;-----------------------------------------------------------------------------------------
;"vmode" - Change video mode - ADL mode 0.1
;-----------------------------------------------------------------------------------------

os_cmd_vmode
	
				call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,vm_no_data						;any data?
				ld a,e

set_vmode		cp 4
				jr nc,vm_bad_range
				
				ld hl,(font_addr)					;copy the font to the display window for now
				ld de,(video_window_address)
				ld bc,(font_length)
				ldir
								
				ld (video_mode),a
				ld hl,7
				ld h,a
				mlt hl
				push hl
				pop ix
				ld de,mode_param_list
				add ix,de
				ld hl,0
				ld de,0
				ld l,(ix)
				ld h,(ix+1)
				ld e,(ix+2)
				ld d,(ix+3)
				ld b,(ix+4)
				push ix
				call set_bitmap_parameters
				pop ix
				ld b,(ix+5)
				ld c,(ix+6)
				call set_charmap_parameters
				
				ld hl,(video_window_address)		;copy the font to its new location - this assumes 
				ld de,(font_addr)					;the video window source address hasnt changed
				ld bc,(font_length)					;(normally fixed to top of vram_a)
				ldir
				
				call hwsc_clear_screen
				
				ld bc,0408h
				call set_font_parameters				
				
				xor a
				ld (active_cursor_image),a			;invalidate cursor image, causing a refresh when next drawn
				
				ret

vm_bad_range	ld a,88h
				or a
				ret

vm_no_data		ld a,81h
				or a
				ret

;------------------------------------------------------------------------------------------

mode_param_list

				dw 640/2,480
				db 00b
				db 80,60
				
				dw 640/2,240
				db 01b
				db 80,30
				
				dw 320/2,480
				db 10b
				db 40,60
				
				dw 320/2,240
				db 11b
				db 40,30
				
;------------------------------------------------------------------------------------------