;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,msg_txt
			ld a,kr_print_string
			call.lil prose_kernal			

			call my_prog
			
			jp.lil prose_return
			
;---------------------------------------------------------------------------------------------

chunk_size	equ 1							;load a byte at a time


my_prog
			ld hl,filename
			ld a,kr_find_file
			call.lil prose_kernal
			ret nz
			
			ld hl,20000h
			ld (load_addr),hl

load_loop	ld de,chunk_size				;number of bytes to load
			ld a,kr_set_load_length
			call.lil prose_kernal
			
			ld hl,(load_addr)
			push hl
			ld de,chunk_size
			add hl,de
			ld (load_addr),hl				;update load address for next pass
			pop hl
			ld a,kr_read_file
			call.lil prose_kernal
			jr z,load_loop					;if no error, continue loading
			
			cp 0cch							;if error is just the E.O.F, that's OK we're expecting that. 
			ret nz							;(otherwise report it)			
			
			ld hl,loaded_txt				;say "all bytes loaded" and quit without error
			ld a,kr_print_string
			call.lil prose_kernal

			xor a							
			ret

;-----------------------------------------------------------------------------------------

filename	db "test.bin",0

load_addr	dw24 0

msg_txt		db "Loading file a byte at a time...",11,0

loaded_txt	db "OK, all bytes loaded.",11,0

;-----------------------------------------------------------------------------------------
