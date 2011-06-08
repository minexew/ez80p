;---------------------------------------------------------------------------------------
;PROSE KEYBOARD/MOUSE ROUTINES V0.04 (ADL mode)
;---------------------------------------------------------------------------------------

os_wait_key_press

; Busy waits for a keypress.
; Handles the following modifier keys (key_mod_flags):
; Returns scancode in A and ASCII code in B (B=$00 if no valid ascii char)
; (ASCII code is modifed by shift / alt key status)


				push de
				ld d,c
				push hl
wait_kbuf		call get_kb_buffer_indexes				; HL = buffer read index. A = buffer write index
				cp (hl)									; if read and write indexes are same, buffer is empty
				jr z,wait_kbuf		
			
new_key			ld bc,0									; HL = location in scancode buffer
				ld c,a
				ld hl,scancode_buffer	
				add hl,bc
																			
				ld c,(hl)								; c = scan code / b = 0 (no valid ascii equivalent by default)		
				ld de,16
				add hl,de								; move to qualifier part of buffer
				ld a,(hl)								; get qualifier status
				
				ld hl,alted_keymap						; ascii conversion table (with "ALT" pressed)	
				bit 3,a
				jr nz,got_kmap	
				ld hl,unshifted_keymap					; unshifted key
				and 011h			
				jr z,got_kmap
				ld hl,shifted_keymap					; shifted key
			
got_kmap		ld a,c									; retrieve scan code
				cp 062h
				jr nc,gotkdone
				add hl,bc								; use scancode as the index in ascii translation table	
				ld b,(hl)								; b = ascii version of keycode
			
gotkdone		ld a,(key_buf_rd_idx)					; advance the buffer read index one byte
				inc a									; and return with keypress info in A and B
				and 15
				ld (key_buf_rd_idx),a			
				ld a,c									; restore scancode into a
				pop hl
				ld c,d
				pop de
				cp a									; ZF set, all OK
				ret
			
		
;------------------------------------------------------------------------------------
			
os_get_key_press
				
; Gets a keycode on-the-fly - If one is available in the keyboard buffer	
; On return, ZF is set if there is a new scancode in A (and B = ascii translation, 0 if no valid ascii)
; (ASCII code is modifed by shift key status), else A (and B) = error code $81 (no data)
			
			
				push de
				ld d,c
				push hl
				call get_kb_buffer_indexes				; HL = buffer read index. A = buffer write index
				cp (hl)									; compare..
				jr nz,new_key							; if read and write indexes are not same, there's a keypress
				ld a,81h			
				ld b,a
				or a
				pop hl
				ld c,d
				pop de
				ret
			
;--------------------------------------------------------------------------------
			
get_kb_buffer_indexes
			
			
				ld hl,key_buf_wr_idx					; buffer write index			
				ld a,(key_buf_rd_idx)					; buffer read index
				ret
			
		
;-------------------------------------------------------------------------------------------
