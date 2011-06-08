;-----------------------------------------------------------------------
;"RX" - Receive binary file via serial port command. V0.05 - ADL mode
;-----------------------------------------------------------------------

buffer_blocks			 equ 128				;number of 256 byte blocks to buffer
buffer_addr				 equ os_max_addr		;location of data buffer
rx_buffer_ptr			 equ scratch_pad
serial_file_length_cache equ scratch_pad+3


os_cmd_rx		ld a,(hl)								; check args exist
				or a
				jp z,os_no_fn_error
				
				ld a,'>'								; if filename is ">" receive first file and save to disk
				cp (hl)
				jp nz,rx_nrs
				inc hl
				ld a,' '
				cp (hl)
				dec hl
				jp nz,rx_nrs
				
				call os_check_volume_format				;disk ok?
				ret nz		
				
				ld de,02ah								; set filename to wildcard. 
				ld (serial_filename),de					
				call rx_get_header
				ret nz
				call s_holdack							; tell sender to wait
				
				ld hl,serial_fileheader					; try to make file
				call os_create_file
				jp nz,rxwtd_fail						; quit if file creation error
				
				ld hl,ser_recsave_msg
				call os_show_packed_text
				
rx_rnblk		ld hl,(serial_fileheader+16)			; (remaining) length of file
				ld (serial_file_length_cache),hl
				ld hl,buffer_addr
				ld (rx_buffer_ptr),hl
				ld b,buffer_blocks						;max number of 256-byte blocks to buffer
				
rx_lnb			call s_goodack
				call s_getblock
				jr z,rxtd_blok

				push af									
				call s_badack							
				ld hl,serial_fileheader					;bad/no block received - erase the truncated file
				call os_erase_file
				pop af
				ret

rxtd_blok		call s_holdack
				
				ld hl,sector_buffer
				ld de,(rx_buffer_ptr)
				ld bc,256
				ldir
				ld (rx_buffer_ptr),de
				
				ld hl,(serial_fileheader+16)
				ld de,256
				xor a
				sbc hl,de
				ld (serial_fileheader+16),hl
				jr z,rx_lbr
				jr c,rx_lbr
				djnz rx_lnb

				ld de,buffer_blocks*256
				ld ix,buffer_addr
				ld hl,serial_fileheader
				call os_write_bytes_to_file
				jr z,rx_rnblk
rxwtd_fail		push af
				call s_badack
				pop af
				ret
				
rx_lbr			call s_goodack
				ld de,(serial_file_length_cache)
				ld ix,buffer_addr
				ld hl,serial_fileheader
				call os_write_bytes_to_file
				ret nz	
				
rxtd_done		ld a,020h								;ok msg
				or a
				ret

				

				
rx_nrs			ld a,'!'								; if filename is "!" then this is a load-and-run command
				cp (hl)									
				jr nz,notrxe
				inc hl
				ld a,' '
				cp (hl)
				dec hl
				jr nz,notrxe
				ld de,02ah								; set filename to wildcard. 
				ld (serial_filename),de					
				call rx_get_header
				ret nz
				ld hl,ser_rec2_msg
				call os_show_packed_text
				call s_goodack
				ld a,1									; Set in-file timeout to 1 second
				ld (serial_timeout),a
				call s_getblock							; Read first block (256 bytes) of file into sector buffer
				jr z,rxe_fblok
rxe_badblock	push af									; if ZF not set there was an error (code in A)
				call s_badack							; tell the sender that the header was rejected
				pop af
				ret
	
rxe_fblok		ld hl,(sector_buffer+2)
				ld de,04f5250h							; check "PRO" ID tag
				xor a
				jr z,rxe_ok
				ld a,1ah								; not a prose executable message
				or a
				ret
rxe_ok			ld hl,(sector_buffer+5)					; Get executable's start address
				ld (serial_ez80_address),hl
				ld bc,256								; copy first 256 (max) bytes to desired location
				ld ix,serial_fileheader
				xor a
				or (ix+18)								;length 23:16
				jr nz,mtones
				or a,(ix+17)							;length 15:8
				jr nz,mtones
				ld b,0
				ld c,(ix+16)							;length 7:0
mtones			ld hl,sector_buffer							 
				ld de,(serial_ez80_address)					
				ldir
				
				push de
				call s_goodack		
				pop ix									; ix = load address (continuation)
				ld hl,(serial_fileheader+16)			; length				
				ld de,256
				xor a
				sbc hl,de								; HL = (file length - first page)  
				jr z,rxe_done
				jr c,rxe_done
				ex de,hl
				ld (serial_fileheader+16),de			; length-256
				ld ix,(serial_ez80_address)
				ld bc,256
				add ix,bc
				call s_gbloop							; load the rest of the file
				ret nz
rxe_done		pop hl									; this pops the RX CMD's return address off the stack as it wont be used.
				call enable_nmi							; as we're launching an external program, enable freezer by default
				ld hl,(serial_ez80_address)
				jp (hl)									; run loaded program
				
				

notrxe			call clear_serial_filename
				
				ld b,16									;max chars to copy
				ld de,serial_filename
				call os_copy_ascii_run					;(hl)->(de) until space or zero, or count = 0
				ld a,c
				ld (serial_fn_length),a
				call os_scan_for_space
				
				call hexword_or_bust					;the call only returns here if the hex in DE is valid
				jp z,os_no_start_addr					;gets load location in DE
				ld (data_load_addr),de					;stash the load address									
				ld hl,(sys_ram_high)					;make sure it isnt going to overwrite the OS
				dec hl
				xor a
				sbc hl,de
				jr c,os_prok
				ld a,026h								;ERROR $26 - A load here would overwrite OS code/data
				or a
				ret

os_prok			call rx_get_header
				ret nz

				ld hl,ser_rec2_msg
				call os_show_packed_text
	
				ld hl,(data_load_addr)					;get load adress
				call serial_receive_file
				ret nz									

				ld de,(serial_fileheader+16)			;report number of bytes loaded
				ld (filesize_cache),de
				jp report_bytes_loaded					;use end part of LB command's code
				
;----------------------------------------------------------------------------------------------

rx_get_header
				ld hl,ser_rec_msg
				call os_show_packed_text
				
				ld a,0
				ld (anim_wait_count),a					;animate chars whilst waiting..
get_hdr_loop	ld a,(anim_wait_count)
				inc a
				ld b,a
				cp 6
				jr nz,notsix
				ld c,' '
				ld b,5
				xor a
				jr mcharset
notsix			ld c,'.'
mcharset		ld (anim_wait_count),a
				call os_print_multiple_chars
				call home_cursor
				
				ld hl,serial_filename					;filename location in HL
				ld a,1									;time out = .1 seconds
				call serial_get_header
				ret z
				cp 083h									;time out error?
				ret nz
				call os_get_key_press
				cp 076h
				jr nz,get_hdr_loop
				ld a,080h								;aborted with ESC error
notsto			or a
				ret										
							

;----------------------------------------------------------------------------------------------

clear_serial_filename

				push hl									;clear serial filename area
				ld hl,serial_filename
				ld bc,16
				xor a
				call os_bchl_memfill
				pop hl
				ret

;----------------------------------------------------------------------------------------------
