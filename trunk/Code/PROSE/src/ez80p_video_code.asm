;---------------------------------
; ez80p-specific video code v0.10
; Character Mode Routines
;---------------------------------

charmap_addr	equ vram_a_addr+04000h				;IE immediately following 16KB font

set_charmap_parameters

;set
; a = line/pixel doubling (bit 0 = line double, bit 1 = pixel double)
; b = columns
; c = rows

				and 3
				ld (video_doubling),a
				ld a,c
				ld (charmap_rows),a
				ld a,b
				ld (charmap_columns),a
				ld hl,0
				ld l,c
				ld h,b
				mlt hl
				add hl,hl
				ld (charmap_size),hl
				ld de,charmap_addr
				add hl,de
				ld (free_vram_a_base),hl				;first free location in VRAM_A (for OS-friendly apps)
				
				call os_set_video_hw_regs
				xor a
				ret
				

os_set_video_hw_regs

				ld a,(video_doubling)
				sla a
				or 00011000b
				ld (video_control),a					;tile mode:on, charmode:on, no pixel doubling, no line doubling
				xor a
				ld (bgnd_palette_select),a
				ld a,99
				ld (right_border_position),a

				ld ix,tilemap_parameters			   ; set up char-map mode parameters 
				ld hl,charmap_addr
				ld (ix),hl			   			  	   ; location of charmap

				ld hl,2
				ld (ix+04h),hl						   ; map increment per charpos (char_def, attrib)
				
				ld hl,80000h
				ld de,0
				ld a,(charmap_columns)
				ld e,a
				xor a
				sbc hl,de
				xor a
				sbc hl,de
				ld (ix+08h),hl							; scan line modulo
				
				ld hl,0
				ld (ix+0ch),hl							; map line modulo
				
				ld a,(charmap_columns)
				dec a
				ld (ix+10h),a							; datafetch (chars across window - 1)
				
				ld a,0
				ld (ix+11h),a							; x pixel scroll position
				ld (ix+12h),a							; y pixel scroll position

				ld hl,pen_palette
				call hswc_set_ui_colours
				
				call hwsc_reset_sprites
				
				xor a
				ld (os_pointer_enable),a				; pointer not used in os
				
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

				ld hl,charmap_addr						; clear charmap to spaces, attributes to
				ld (hl),32								; background colour
				inc hl
				call get_fill_attr
				ld (hl),a
				inc hl
				ex de,hl
				ld hl,charmap_addr
				ld bc,(charmap_size)
				dec bc
				dec bc
				ldir
				
				ld bc,0
				ld (cursor_y),bc
				xor a										; ZF set, no error
				ret
				
				
get_fill_attr	push de
				ld a,(current_pen)
				and 0fh
				ld e,a
				ld a,(background_colour)
				rrca
				rrca
				rrca
				rrca
				and 0f0h
				or e
				pop de
				ret
				

;-------------------------------------------------------------------------------------------------

hwsc_scroll_up	
				
				push bc
				push de
				push hl

				ld hl,(charmap_size)
				ld de,(charmap_columns)
				xor a
				sbc hl,de
				sbc hl,de									;one less line than in charmap (bottom line = new data)
				push hl
				pop bc										;bytes to shift
				ld hl,charmap_addr
				push hl
				add hl,de
				add hl,de
				pop de
				ldir
				
				ex de,hl									;put spaces of fill_attr on last line
				push hl
				ld (hl),32
				inc hl
				call get_fill_attr
				ld (hl),a
				ld hl,(charmap_columns)
				dec hl
				add hl,hl
				push hl
				pop bc
				pop hl
				push hl
				pop de
				inc de
				inc de
				ldir
				
				pop hl
				pop de
				pop bc
				xor a										; ZF set, no error
				ret


;-------------------------------------------------------------------------------------------------

hwsc_plot_char

; Set:
; ----
; A = ascii char
; B = x character coordinate 
; C = y character coordinate

				push hl									; plots a character using the current pen colour
				push de
				push af

				ld a,(charmap_rows)						; if either coordinate is outside the display, nothing is
				dec a
				cp c									; plotted and the routine returns with the zero flag unset
				jr c,win_err
				ld a,(charmap_columns)
				dec a
				cp b
				jr nc,win_ok
win_err			pop af
				pop de
				pop hl
				ld a,88h								; zero flag not set (error=out of range) if outside of diplay
				or a
				ret
				
win_ok			ld hl,(charmap_columns)					; must be a 24 bit value
				ld h,c
				mlt hl
				ld de,0
				ld e,b
				add hl,de
				add hl,hl
				ld de,charmap_addr
				add hl,de
				pop af
				ld (hl),a
				inc hl
				ld a,(current_pen)
				ld (hl),a
				pop de
				pop hl
				xor a
				ret
				
				
;--------------------------------------------------------------------------------------------------

hwsc_remove_cursor

				ld a,(cursor_present)					;dont do anything if no cursor present
				or a
				ret z
				ld bc,(cursor_y)
				call hwsc_get_charmap_addr_xy
				ld a,(char_under_cursor)
				ld (hl),a
				xor a
				ld (cursor_present),a
				ret


hwsc_draw_cursor
								
				ld a,(cursor_present)				;dont do anything if a cursor already present
				or a
				ret nz
				inc a
				ld (cursor_present),a
				
				ld bc,(cursor_y)
				call hwsc_get_charmap_addr_xy
				ld a,(hl)							
				ld (char_under_cursor),a			;store the char that was under the cursor
				ld (hl),ffh							;replace char with char $ff - the cursor character
				
				ld de,64							;find location of original char to make a unique cursor character
				ld d,a
				mlt de
				ld iy,vram_a_addr					;start of font in VRAM
				add iy,de							;iy = location of character image in font
				
				ld hl,64
				ld a,(cursor_image_char)
				ld h,a
				mlt hl
				ld de,vram_a_addr
				add hl,de
				
				ld ix,vram_a_addr+03fc0h
				ld de,8
				ld b,8
cur_loop		ld a,(iy)							;original char
				xor (hl)							;cursor image
				ld (ix),a							;char ff
				add iy,de
				add ix,de
				add hl,de
				djnz cur_loop
				
				xor a
				ret
				

;--------------------------------------------------------------------------------------------------

hwsc_get_charmap_addr_xy

; returns address of charmap in xHL for character at (x,y) b=x, c=y
; and attrmap in xDE
				
				ld hl,(charmap_columns)					; must be a 24 bit value
				ld h,c
				mlt hl
				ld de,0
				ld e,b
				add hl,de
				add hl,hl
				ld de,charmap_addr
				add hl,de
				push hl
				pop de
				inc de
				xor a
				ret
								
;--------------------------------------------------------------------------------------------------

hwsc_chars_left

; moves characters (in character map) on the current line one char left, from x position in b

				push hl
				push de
				push bc
				
				ld hl,(charmap_columns)
				ld a,(cursor_y)
				ld h,a
				mlt hl
				ld de,0
				ld e,b
				add hl,de
				add hl,hl
				ld de,charmap_addr
				add hl,de
				
				ld a,(charmap_columns)
				sub b
				sla a
				ld bc,0
				ld c,a
				push hl
				pop de
				dec de
				dec de
				ldir
				
				ld a,32						;put a space with colour: background at right side
				ld (de),a
				inc de
				call get_fill_attr
				ld (de),a
				
				pop bc
				pop de
				pop hl
				ret


;--------------------------------------------------------------------------------------------------


hwsc_chars_right

; moves characters on current line right from cursor pos (unless at rightmost column)

				push bc
				push de
				push hl
	
				ld hl,cursor_x				
				ld a,(charmap_columns)
				dec a
				cp (hl)			
				jr z,chright_end
				ld b,(hl)
				
				ld hl,(charmap_columns)
				ld a,(cursor_y)
				inc a									;move down an extra row, the back up to get right side
				ld h,a
				mlt hl
				add hl,hl
				ld de,charmap_addr
				add hl,de					
				dec hl									
				push hl
				pop de									;de = location of last byte of line (attr)
				dec hl
				dec hl									;hl = location of previous attr
				ld a,(charmap_columns)
				sub b
				dec a
				sla a
				ld bc,0
				ld c,a									;bc = bytes to move
				lddr
				inc hl									;put space with fill_attr in the created "void"
				ld (hl),32
				inc hl
				call get_fill_attr
				ld (hl),a
							
chright_end		pop hl	
				pop de
				pop bc
				ret

;--------------------------------------------------------------------------------------------


hwsc_charline_to_command_string	
				
				
				ld hl,(charmap_columns)					; copy the cursor's line to the command string buffer
				ld a,(cursor_y)
				ld h,a
				mlt hl
				add hl,hl
				ld de,charmap_addr
				add hl,de
				ld de,commandstring
				ld b,max_buffer_chars					;copy just the ascii, skipping the attributes
copy_to_cmdline	ld a,(hl)
				ld (de),a
				inc de
				inc hl
				inc hl
				djnz copy_to_cmdline
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

