;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
;test 1

			ld hl,msg1_txt
			ld a,kr_print_string
			call.lil prose_kernal			

			ld hl,filename
			ld a,kr_find_file
			call.lil prose_kernal
			jp nz,quit
			
			ld de,11231h
			ld a,kr_set_file_pointer
			call.lil prose_kernal
			
			ld hl,20000h
			ld a,kr_read_file
			call.lil prose_kernal
			jp quit			


;test 2----------------------------------------------------------------------------------------

chunk_size	equ 127							;load n bytes at a time
	
			ld hl,msg2_txt
			ld a,kr_print_string
			call.lil prose_kernal	
	
			ld hl,filename
			ld a,kr_find_file
			call.lil prose_kernal
			jr nz,quit
			
			ld hl,20000h
			ld (load_addr),hl

load_loop	ld de,chunk_size				;number of bytes to load on each read call
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


			push af
			ld (60000h),a
			ld a,b
			ld (60001h),a
			pop af


			cp 0cch							;if the error is just the E.O.F, that's OK we're expecting that. 
			jr nz,quit						;(otherwise report it)			
			
			ld hl,loaded_txt				;say "all bytes loaded" and quit without error
			ld a,kr_print_string
			call.lil prose_kernal


quit		jp.lil prose_return

;-----------------------------------------------------------------------------------------

filename	db "testdata.bin",0

load_addr	dw24 0

msg1_txt		db "File pointer test...",11,0

msg2_txt		db "Loading file sequentially...",11,0

loaded_txt	db "OK, all bytes loaded.",11,0

;-----------------------------------------------------------------------------------------
