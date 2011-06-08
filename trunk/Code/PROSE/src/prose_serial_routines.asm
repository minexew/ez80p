;**********************************************************************************************
; PROSE Serial File Transfer Routines V0.05 (ADL mode)
;**********************************************************************************************

;---------------------------------------------------------------------------------------------
; .---------------------.
; ! Receive file header !
; '---------------------'
;
; Before calling set:-
;
; HL = Filename ("*" if dont care)
;  A = Time out in seconds
;
; If zero flag set, all OK. IX returns location of serial file header
;    Else A=$84 = memory address out of range, $83 = time out error
;           $87 = Filename mismatch, $86 = checksum bad, $85 = comms error
;-----------------------------------------------------------------------------------------
	

serial_get_header

				ld (serial_timeout),a					; set timeout value
				ld (serial_fn_addr),hl
				call hwsc_flush_serial_buffer			; flush serial buffer at outset

				call s_getblock							; gets a block in buffer / test its checksum
				jr z,s_gbfhok							; if zero flag set, all OK
				push af									; else, there was an error (error code in A)
				ld a,(serial_transfer_started)
				or a									; if some bytes were actually received
				call nz,s_badack						; tell the sender that the header was rejected 
				pop af
				ret
	
s_gbfhok		ld hl,serial_header_id					; Check to make sure its tagged as a header block
				ld de,sector_buffer+20					; check ASCII chars 
				ld b,12
				call os_compare_strings
				jr nz,s_nfhdr
				ld b,256-32								; bytes 32-256 should be zero
				ld hl,sector_buffer+32
s_chdr			ld a,(hl)
				inc hl
				or a
				jr nz,s_nfhdr
				djnz s_chdr
				jr s_fhcsok
				
s_nfhdr			call s_badack							; not a header - tell sender to abort the file part
				ld a,085h								; "comms error"
				or a
				ret
		
s_fhcsok		ld hl,sector_buffer+16					; copy file details 
				ld de,serial_fileheader+16
				ld bc,4
				ldir
				
				ld hl,sector_buffer
				ld de,serial_fileheader					; Convert filename to uppercase	
				ld b,16									; if necessary (for string compare)
s_tuclp			ld a,(hl)								; and compare filenames
				or a
				jr z,s_ffhswz	
				call os_uppercasify
				ld (de),a
				inc hl
				inc de
				djnz s_tuclp
				jr s_tucdone
s_ffhswz		ld (de),a
				inc de
				djnz s_ffhswz		
	
s_tucdone		ld hl,(serial_fn_addr)					; is this the right filename?
				ld a,(hl)
				cp '*'
				jr z,s_rffns							; if requested filename = wildcard, skip compare
				ld de,serial_fileheader
				ld b,16
				call os_compare_strings
				jr z,s_rffns
s_rfnbad		call s_badack
				ld a,087h								; Error 87: Incorrect file
				or a
				ret
				
s_rffns			ld ix,serial_fileheader					; ix = start of serial file header
				xor a
				ret

s_fail			push af				
				call s_badack		 
				pop af
				ret
	
;-----------------------------------------------------------------------------------------
; .-------------------.
; ! Receive file data !
; '-------------------'
;
; Serial_get_header must be called first!
;
; Set:
;
; xHL = Address to load to [23:0]
;
; On return, if Zero flag is set, all OK (IX = start of serial_file_header data)
; Else A =  $84 = memory address out of range
;           $85 = comms error
;-----------------------------------------------------------------------------------------

serial_receive_file

				ld a,10										; Set in-file timeout to 1 second
				ld (serial_timeout),a
				push hl
				call s_goodack								; send "OK" to start the first block
				pop ix										; get load address in IX
				ld de,(serial_fileheader+16)				; file length (24 bit)

s_gbloop		call s_getblock
				jr nz,s_fail
				ld c,0										; copy buffer to actual location
				ld iy,sector_buffer
s_rfloop		ld a,(iy)
				ld (ix),a									; put byte at memory location
				dec de										; length of file countdown
				ld hl,0
				xor a
				adc hl,de									; ADC = zero flag affected
				jr z,s_rfabr								; if zero, last byte
				push bc
				ld bc,1
				add ix,bc									; next mem address
				pop bc
				jr nc,s_nbt
				ld a,84h									; mem addr out of range error				
				or a
				jr s_fail
s_nbt			inc iy
				dec c
				jr nz,s_rfloop
				call s_goodack								; send OK ("ready for next block")
				jr s_gbloop
			
s_rfabr			call s_goodack								; final block's "OK" ack
				ld ix,serial_fileheader						; ix = start of serial file header
				xor a										; ZF set, all ok
				ret
			
;-----------------------------------------------------------------------------------------

s_getblock

; carry set on return if timed out

				xor a
				ld (serial_transfer_started),a			; flag for header wait (dont send bad ack "XX" if a
				push hl									; transfer didnt even start)
				push de
				push bc
				ld hl,sector_buffer						; load a block of 256 bytes
				ld b,0
				exx
				ld hl,0ffffh							; CRC checksum
				exx
s_lgb			call receive_serial_byte
				jr nz,s_gberr							; timed out if carry = 1	
				push af
				ld a,1
				ld (serial_transfer_started),a
				pop af
				ld (hl),a
				exx
				xor h									; do CRC calculation		
				ld h,a			
				ld b,8
rxcrcbyte		add.sis hl,hl							; 16 bit addition
				jr nc,rxcrcnext
				ld a,h
				xor 10h
				ld h,a
				ld a,l
				xor 21h
				ld l,a
rxcrcnext		djnz rxcrcbyte
				exx
				inc hl
				djnz s_lgb
				exx										; hl = calculated CRC
			
				call receive_serial_byte				; get 2 more bytes - block checksum in bc
				jr nz,s_gberr
				ld c,a
				call receive_serial_byte
				jr nz,s_gberr		
				ld b,a
				
				xor a									; compare checksum
				sbc.s hl,bc								; 16 bit subtract
				jr z,s_gberr
			
				ld a,86h								;A=$86 : bad checksum
				or a									;Zero flag not set
s_gberr			pop bc
				pop de
				pop hl
				ret
				
;----------------------------------------------------------------------------------

s_goodack		push bc
				ld bc,04b4fh							;chars for "OK"
ackbytes		ld a,c
				call send_serial_byte
				ld a,b
				call send_serial_byte
				pop bc
				ret

s_badack		push bc
				ld bc,05858h							;chars for "XX"
				jr ackbytes

s_holdack		push bc
				ld bc,05757h							;chars for "WW"
				jr ackbytes
				
;=================================================================================

; .-----------.
; ! Send file !
; '-----------'

; Before calling set:-

;  xHL   = filename
;  xDE   = length of file
;  xIX   = Start address [23:0]

; On return, if zero flag is set, all OK. Else:
; $81 = Save length is zero
; $84 = memory address out of range
; $85 = comms error


serial_send_file
			
				ld a,1									; Set timeout at about 1 second
				ld (serial_timeout),a
			
				ld (serial_ez80_address),ix
				ld (serial_fileheader+10h),de			; length of file (24 bit)
				push hl
				ld hl,0
				xor a
				adc hl,de
				jr nz,s_flok
				pop hl
				ld a,081h								; Error! Save request = 0 bytes
				or a									; ZF not set
				ret
			
s_flok			ld hl,serial_fileheader					; clear the filename part of header	
				ld bc,16
				xor a
				call os_bchl_memfill
				pop hl									; fill in filename
				ld de,serial_fileheader
				ld b,16
				call os_copy_ascii_run
				
				ld hl,serial_header_id					; add the ID string "Z80P.FHEADER" to header
				ld de,serial_fileheader+014h
				ld bc,12		
				ldir
			
				ld ix,serial_fileheader					; send file header
				ld de,32
				call s_makeblock			
				ret nz
				call s_sendblock
				ret nz
				call s_waitack							; wait to receive "OK" acknowledge
				ret nz									; anything else gives a comms error
				
				ld ix,(serial_ez80_address)
				ld de,(serial_fileheader+16)			; length of file (24 bit)
s_sbloop		call s_makeblock						; make a file block
				jr c,s_rerr
				call s_sendblock						; send the file block
				jr c,s_rerr	
				call s_waitack							; wait to receive "OK" acknowledge
				jr c,s_rerr
				ld hl,0
				xor a
				adc hl,de
				jr nz,s_sbloop							; was last byte of file in this block?
				xor a									; ZF set, all OK
s_rerr			ret

;-------------------------------------------------------------------------------------------

s_makeblock

; set xIX = src addr
; xDE = byte count
; a=0 on return if all ok	

				ld hl,sector_buffer							
				ld bc,256									
				xor a										
				call os_bchl_memfill					; first, clear the serial block 	
				
				ld b,0									; count bytes in sector
				ld iy,sector_buffer	
s_sloop			ld a,(ix)
				ld (iy),a
				dec de									; dec byte count
				ld hl,0
				xor a
				adc hl,de
				jr z,s_mbend	
				inc iy											
				push bc
				ld bc,1
				add ix,bc								; next address
				pop bc									
				jr nz,s_sbok
				ld a,84h								; Error! Memory address out of range
				or a
				ret
s_sbok			djnz s_sloop
s_mbend			xor a
				ret



s_sendblock

				push hl
				push de									;sends a 256 byte block and its 2 byte checksum
				push bc				
				ld hl,sector_buffer			
				ld e,0
s_sblklp		ld a,(hl)
				call send_serial_byte
				inc hl
				dec e
				jr nz,s_sblklp
				ld de,sector_buffer
				ld bc,0
				call crc_checksum
				ld a,l
				call send_serial_byte
				ld a,h
				call send_serial_byte
				xor a
s_popall		pop bc
				pop de
				pop hl
				ret
	

s_waitack
				push hl
				push de
				push bc
				call receive_serial_byte						; wait to receive "OK" acknowledge
				jr nz,s_popall
				ld b,a
				call receive_serial_byte
				jr nz,s_popall
				ld c,a
				ld h,'O'
				ld l,'K'
				xor a
				sbc.s hl,bc										; 16 bit subtract
				jr z,s_popall									; zero flag set on return if OK received
			
				ld a,085h										; bad ack received  ($85:"comms error")
				or a
				jr s_popall

	
;----------------------------------------------------------------------------------------------------------------
