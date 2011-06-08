;-------------------------------------------
; ez80p-specific video code v0.05 (ADL mode)
; 16 colour mode routines
;-------------------------------------------

set_bitmap_parameters
				
				ld a,b
				ld (window_pixel_doubling),a
				ld (window_width_bytes),hl			;prepares internal variables, clears screen etc
				ld (window_height_lines),de
			
				ld hl,vram_a_addr					; calculate locations for data in VRAM
				ld (video_window_address),hl
				ld hl,0
				ld de,(window_width_bytes)
				ld bc,(window_height_lines)
cwsblp			add hl,de
				dec bc
				ld a,b
				or c
				jr nz,cwsblp
				ld (total_window_bytes),hl
				
				call os_set_video_hw_regs
				
				xor a
				ret



set_font_parameters

				ld a,b								;set b = char width (in bytes *displayed*), set c = char height
				ld (font_width_bytes),a
				ld a,c
				ld (font_height_lines),a				
				ld de,0
				ld e,c
				ld d,b
				mlt de
				ld hl,0
				ld b,224/4							;divide by 4 because 1 byte of bitmap src font = 4 bytes on display
cfslp			add hl,de
				djnz cfslp
				ld (font_length),hl
							
				ld b,c
				ld hl,0
				ld de,(window_width_bytes)
csualp			add hl,de
				djnz csualp
				ld (total_row_bytes),hl				;number of bytes in one character line of bitmap
				
				xor a
				ret
				
				

set_charmap_parameters

				ld a,c
				ld (window_rows),a
				ld a,b
				ld (window_columns),a
				
				ld hl,(video_window_address)
				ld de,(total_window_bytes)
				add hl,de
				ld (charmap_address),hl

				ld de,0
				ld a,(window_rows)
				ld e,a
				ld a,(window_columns)
				ld d,a
				mlt de
				ld (total_charmap_bytes),de
				add hl,de
				ld (attributes_address),hl
				add hl,de
				ld (cursor_image_address),hl
				ld de,0
				ld a,(font_height_lines)
				ld e,a
				ld a,(font_width_bytes)
				ld d,a
				push de
				mlt de
				add hl,de
				ld (font_addr),hl
				pop de
				ld d,224
				mlt de
				add hl,de				
				ld (vram_a_high),hl
				xor a
				ret
				

os_set_video_hw_regs

				ld ix,video_control						; set up bitmap mode for OS window
				ld a,(window_pixel_doubling)
				sla a
				or 1
				ld (ix),a								; 16 colour, bitmap mode 
				ld (ix+1),0								; disable sprites
				ld (ix+2),0								; palette 0
				ld (ix+4),99							; normal right border position

				ld ix,bitmap_parameters					
				ld de,(video_window_address)			; bitmap parameters:
				ld (ix),de								; display window address
				ld (ix+04h),1							; pixel_step
				ld (ix+08h),0							; unused, set at 0
				ld (ix+0ch),0							; modulo = 0
				ld bc,(window_width_bytes)				; bytes across display window
				srl b									; divide by 8 and sub 1 for hw register
				rr c
				srl b
				rr c
				srl b
				rr c
				dec c
				ld (ix+10h),c
				
				ld hl,pen_palette
				call hswc_set_ui_colours
				
				xor a									; ZF set, no error
				ret

;--------------------------------------------------------------------------------------------------
				
				
hswc_set_ui_colours

				ld de,hw_palette
				ld bc,16*2
				ldir
				xor a									; ZF set, no error
				ret


;--------------------------------------------------------------------------------------------------

hwsc_clear_screen

				ld hl,(video_window_address)			;clear video ram area
				ld a,(background_colour)
				and 0fh
				ld b,a
				rlca
				rlca
				rlca
				rlca
				or b
				ld (hl),a
				push hl
				pop de
				inc de
				ld bc,(total_window_bytes)
				dec bc
				ldir
				
				ld hl,(attributes_address)				;clear attributes area to transparent pen colour
				ld bc,(total_charmap_bytes)
				dec bc
				ld (hl),0
				push hl
				pop de
				inc de
				ldir				

				ld hl,(charmap_address)					;clear char map area (fill with spaces)
				ld bc,(total_charmap_bytes)
				dec bc
				ld (hl),' '
				push hl
				pop de
				inc de
				ldir				

				ld bc,0
				ld (cursor_y),bc
				xor a									;ZF set, no error
				ret
				
				
;-------------------------------------------------------------------------------------------------

hwsc_scroll_up	
				
				push bc
				push de
				push hl

				ld hl,(total_window_bytes)
				ld de,(total_row_bytes)
				xor a
				sbc hl,de
				push hl
				pop bc									;bc = bytes to shift
				ld hl,(video_window_address)
				ld de,(total_row_bytes)
				add hl,de								;hl = source (one charline down)
				ld de,(video_window_address)			;de = dest top of display
				ldir
				
				ex de,hl								;clear the bottom bitmap character line
				ld a,(background_colour)
				and 0fh
				ld c,a
				rlca
				rlca
				rlca
				rlca
				or c
				ld (hl),a
				ld bc,(total_row_bytes)
				dec bc
				push hl
				pop de
				inc de
				ldir

				ld hl,(charmap_address)				; scroll the charmap
				ld de,(window_columns)
				add hl,de
				ld de,(charmap_address)
				ld bc,(window_rows)
				dec c
				ld a,(window_columns)
				ld b,a
				mlt bc
				push bc
				ldir
				pop bc								

				ld hl,(charmap_address)				;fill bottom line with spaces
				add hl,bc
				ld (hl),' '
				ld bc,(window_columns)
				dec bc
				push hl
				pop de
				inc de
				ldir
					
				ld hl,(attributes_address)			; scroll the colour attributes
				ld de,(window_columns)
				add hl,de
				ld de,(attributes_address)
				ld bc,(window_rows)
				dec c
				ld a,(window_columns)
				ld b,a
				mlt bc
				push bc
				ldir
				pop bc			

				ld hl,(attributes_address)			;fill bottom line with 0
				add hl,bc
				ld (hl),0
				ld bc,(window_columns)
				dec bc
				push hl
				pop de
				inc de
				ldir

				pop hl
				pop de
				pop bc
				xor a								; ZF set, no error
				ret


;-------------------------------------------------------------------------------------------------

; Set:
; ----
; A = ascii char
; B = x character coordinate 
; C = y character coordinate

; Can only use 8_bits * n_line fonts at present (IE: 8 pixels wide)

hwsc_plot_char
				push hl									; plots a character using the current pen colour
				push af
				ld a,(current_pen)
				ld (plotchar_colour),a
				jr plotc_go
				
hwsc_plotchar_specific_attr	

				push hl
				push af									; plots a char without setting pen to the current colour
plotc_go		ld a,(window_rows)						; if either coordinate is outside the display, nothing is
				dec a
				cp c									; plotted and the routine returns with the zero flag unset
				jr c,win_err
				ld a,(window_columns)
				dec a
				cp b
				jr nc,win_ok
win_err			pop af
				pop hl
				ld a,82h								;zero flag not set (error=bad data) if outside of diplay
				or a
				ret
				
win_ok			pop af
				push de
				push bc
				push ix
				push iy
				ld hl,(font_height_lines)				;calc source address in font data
				sub a,32
				ld h,a
				add a,32
				mlt hl									;hl = char - 32 * lines_per_char (assumes each line = 1 byte)
				ld de,(font_addr)
				add hl,de
				push hl
				pop ix									;ix = source address
				
				ld de,0
				ld hl,(total_row_bytes)					;calc dest address in vram
				ld e,l
				ld d,c
				mlt de									;de = bytes per row [0:7] * y coord
				ld l,c									
				mlt hl									;hl = bytes per row [15:8] * y coord
				add hl,hl								;hl << 8
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,de								; hl=hl+de
				ld de,(font_width_bytes)
				ld d,b	
				mlt de									; de = width of DISPLAYED char in bytes * x coord	
				add hl,de								; add on cursor x position
				ld de,(video_window_address)
				add hl,de
				push hl
				pop iy									; iy = dest address
				
				ld hl,(window_columns)					; store the character code in character map
				ld h,c									
				mlt hl
				ld de,0
				ld e,b
				add hl,de
				ex de,hl
				ld hl,(charmap_address)
				add hl,de
				ld (hl),a

				ld a,(plotchar_colour)					;store colour in attribute map
				ld hl,(attributes_address)
				add hl,de
				ld (hl),a

				ld d,a				
				and 0f0h
				jr nz,notransbg
				ld a,(background_colour)
				and 0fh
				ld b,a
				rlca
				rlca
				rlca
				rlca
				ld c,a
				jr gotbg
notransbg		ld c,a									;background for left
				rrca
				rrca
				rrca
				rrca
				ld b,a									;background for right
gotbg			ld a,d
				and 0fh
				jr nz,notransfg
				ld a,(background_colour)
				and 0fh
				ld d,a
				rlca
				rlca
				rlca
				rlca
				ld e,a
				jr gotfg
notransfg		ld d,a									;foreground for right
				rlca
				rlca
				rlca
				rlca
				ld e,a									;foreground for left
				
gotfg			exx
				ld a,(font_height_lines)
				ld b,a
				ld hl,(window_width_bytes)
				ld de,(font_width_bytes)
				xor a
				sbc hl,de
				ex de,hl
						
charloop		exx
				ld l,(ix)								;draw the character
				sla l
				ld a,c
				jr nc,nbgmsb7
				ld a,e
nbgmsb7			sla l
				jr nc,nfgmsb6
				or d
				jr gotpixcol76
nfgmsb6			or b
gotpixcol76		ld (iy),a
				inc iy

				sla l
				ld a,c
				jr nc,nbgmsb5
				ld a,e
nbgmsb5			sla l
				jr nc,nfgmsb4
				or d
				jr gotpixcol54
nfgmsb4			or b
gotpixcol54		ld (iy),a
				inc iy
				
				sla l
				ld a,c
				jr nc,nbgmsb3
				ld a,e
nbgmsb3			sla l
				jr nc,nfgmsb2
				or d
				jr gotpixcol32
nfgmsb2			or b
gotpixcol32		ld (iy),a
				inc iy
				
				sla l
				ld a,c
				jr nc,nbgmsb1
				ld a,e
nbgmsb1			sla l
				jr nc,nfgmsb0
				or d
				jr gotpixcol10
nfgmsb0			or b
gotpixcol10		ld (iy),a
				inc iy
				
				inc ix
				exx
				add iy,de
				djnz charloop
				exx 
				
				pop iy
				pop ix
				pop bc
				pop de
				pop hl
				xor a
				ret

;--------------------------------------------------------------------------------------------------

hwsc_remove_cursor

				ld bc,(cursor_y)
				call hwsc_get_charmap_addr_xy
				ld a,(de)
				ld (plotchar_colour),a
				ld a,(hl)				
				jp hwsc_plotchar_specific_attr
				

hwsc_draw_cursor

				ld hl,active_cursor_image
				ld a,(req_cursor_image)
				cp (hl)
				call nz,hwsc_set_cursor_image

				ld bc,(cursor_y)
				ld hl,(total_row_bytes)					;calc dest address in vram
				ld e,l
				ld d,c
				mlt de
				ld l,c
				mlt hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,de
				ld de,(font_width_bytes)
				ld d,b
				mlt de		
				add hl,de								; add on cursor x position
				ld de,(video_window_address)
				add hl,de								
				push hl
				pop iy
				
				ld bc,(font_height_lines)
				ld ix,(cursor_image_address)	
				ld de,(window_width_bytes)

curlp2			lea hl,iy+0
				ld b,4									; fixed at 4 byte width at present
curlp1			ld a,(hl)
				xor (ix)
				ld (hl),a
				inc ix
				inc hl
				djnz curlp1
											
				add iy,de
				dec c
				jr nz,curlp2

				xor a									;ZF set, no error
				ret
				
	
;--------------------------------------------------------------------------------------------------

hwsc_set_cursor_image

				ld (active_cursor_image),a
				sub a,32								; set A to ascii char for cursor
				ld hl,(font_height_lines)
				ld h,a
				mlt hl
				ld de,(font_addr)
				add hl,de
				ld de,(cursor_image_address)						
				ld a,(font_height_lines)
				ld b,a
fclp2			push bc

				ld c,(hl)
				ld b,4									; fixed to 4 byte width at present
fclp1			ld a,0
				sla c
				jr nc,nopixl
				or a,0f0h							
nopixl			sla c
				jr nc,nopixr
				or a,0fh
nopixr			ld (de),a
				inc de
				djnz fclp1
			
				inc hl
				pop bc
				djnz fclp2
				ret	


;--------------------------------------------------------------------------------------------------

hwsc_get_charmap_addr_xy

; returns address of charmap in xHL for character at (x,y) b=x, c=y
; and attrmap in xDE
				
				ld de,0
				ld a,(window_columns)				
				ld e,a									;e = window char columns
				ld d,c									;d = y coord 
				mlt de
				ld a,e
				add a,b
				ld e,a
				jr nc,choffh_ok
				inc d
choffh_ok		ld hl,(charmap_address)
				add hl,de
				push hl
				ld hl,(attributes_address)
				add hl,de
				ex de,hl
				pop hl
				xor a									; zero flag set, no error
				ret
								
;--------------------------------------------------------------------------------------------------

hwsc_chars_left

; moves characters (in character map) on the current line one char left, from x position in b

				push bc
				push de
				push hl

				ld a,(cursor_y)
				ld hl,(window_columns)
				ld h,a
				mlt hl
				ld de,0
				ld e,b
				add hl,de
				ex de,hl
				push de
				ld hl,(charmap_address)
				add hl,de							; hl = first source char

				push hl
				pop de
				dec de								; de = dest
				ld a,(window_columns)
				sub b
				ld bc,0
				ld c,a								; c = number of chars to do
				push bc
				ldir
				pop bc
				ld a,32
				ld (de),a							; put a space at right side
				
				ld hl,(attributes_address)			; shift attributes also
				pop de
				add hl,de
				push hl
				pop de
				dec de								; de = dest
				ldir								; c = number of chars to do
				ld a,(background_colour)
				ld (de),a							; put paper colour at right side

				call hwsc_redraw_line				

				pop hl
				pop de
				pop bc
				ret



hwsc_chars_right

; moves characters on current line right from cursor pos (unless at rightmost column)

				push bc
				push de
				push hl
	
				ld hl,cursor_x				
				ld a,(window_columns)
				dec a
				cp (hl)			
				jr z,chright_end

				ld b,(hl)
				ld de,0
				ld d,a
				inc d
				ld a,(cursor_y)
				ld e,a
				mlt de
				push de 
				
				push bc
				ld hl,(charmap_address)
				ld bc,(window_columns)
				dec bc
				dec bc
				add hl,bc
				pop bc
				
				add hl,de												; hl = first source char
				push hl
				pop de
				inc de													; de = dest
				ld a,(window_columns)
				dec a
				sub b
				ld b,a
				push bc													; bytes to copy	
mchrlp			ld a,(hl)
				ld (de),a
				dec hl
				dec de
				djnz mchrlp

				ld hl,(attributes_address)								;shift attributes also
				ld bc,(window_columns)
				dec bc
				dec bc
				add hl,bc

				pop bc
				pop de
				add hl,de												
				push hl
				pop de
				inc de													
mattrlp			ld a,(hl)
				ld (de),a
				dec hl
				dec de
				djnz mattrlp

				call hwsc_redraw_line				

chright_end		pop hl	
				pop de
				pop bc
				ret

;--------------------------------------------------------------------------------------------

hwsc_redraw_line
				
				ld a,(cursor_y)
				ld c,a
		
hwsc_redraw_ui_line

				ld de,(window_columns)							; set C = line to redraw
				ld d,c
				mlt de
				ld b,0											; b = x coordinate							
rs_xloop		ld hl,(attributes_address)				 
				add hl,de
				ld a,(hl)										;fetch attribute colour
				ld (plotchar_colour),a
				ld hl,(charmap_address)
				add hl,de
				ld a,(hl)				
				call hwsc_plotchar_specific_attr				;plot character with specified attribute
				inc de
				inc b
				ld a,(window_columns)
				cp b
				jr nz,rs_xloop
				ret	

;--------------------------------------------------------------------------------------------

hwsc_charline_to_command_string	
								
				ld de,(window_columns)
				ld a,(cursor_y)								; copy the cursor's line to the command string buffer
				ld d,a
				mlt de
				ld hl,(charmap_address)
				add hl,de
				ld de,commandstring				
				ld bc,(window_columns)
				ldir
				ret

;--------------------------------------------------------------------------------------------------

hwsc_wait_vrt	push bc

				ld c,1
				out0 (port_clear_flags),c

				ld c,port_hw_flags
ewaitvrtlp1		tstio 1<<vrt
				jr z,ewaitvrtlp1
				
				pop bc
				cp a									; ZF set, no error
				ret


;--------------------------------------------------------------------------------------------------

