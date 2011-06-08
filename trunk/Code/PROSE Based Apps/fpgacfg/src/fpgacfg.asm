;***********************************************
; FPGACFG v0.03 COMMAND LINE APP for PROSE/EZ80P
;***********************************************

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

				ld (command_line_arg_ptr),hl
				
				in0 a,(port_pic_data)						; clear PIC receive buffer
				call short_pause

				call get_slot_count							; find size of EEPROM
				jr z,slc_ok
				ld hl,slot_count_error_txt
				jr quit_string
					
slc_ok			ld hl,(command_line_arg_ptr)
				ld a,(hl)									; if no args, show usage
				or a				
				jp z,show_usage

				ld a,(hl)
				cp 'W'
				jp z,write_slot_cmd
				cp 'w'
				jp z,write_slot_cmd
				cp 'B'
				jp z,set_boot_slot_cmd
				cp 'b'
				jp z,set_boot_slot_cmd
				cp 'E'
				jp z,erase_slot_cmd
				cp 'e'
				jp z,erase_slot_cmd
				cp 'L'
				jp z,list_slots_cmd
				cp 'l'
				jp z,list_slots_cmd
				cp 'P'
				jp z,show_pic_fw_cmd
				cp 'p'
				jp z,show_pic_fw_cmd
				cp 'C'
				jp z,configure_cmd
				cp 'c'
				jp z,configure_cmd
				
				ld hl,unknown_arg_txt
quit_string		call print_string
				xor a
				jp prose_return


;----------------------------------------------------------------------------------------------


show_usage		ld hl,usage_txt
				jp quit_string


;----------------------------------------------------------------------------------------------


list_slots_cmd	ld hl,slots_txt
				call print_string

				xor a
id_loop			ld (working_slot),a
				ld e,a
				ld hl,slot_hex+1
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,slot_hex
				call print_string
				ld hl,0
				ld a,(working_slot)						; read in EEPROM page that contains the ID string
				ld h,a
				add hl,hl
				ld de,01ffh
				add hl,de
				ex de,hl
				call read_eeprom_page
				jp c,pic_error
				ld hl,buffer+090h						; location of ID (filename ASCII) = start of slot+1ff90h
				ld a,(hl)
				or a
				jr z,unk_id
				bit 7,a
				jr z,id_ok
unk_id			ld hl,unknown_txt
				call print_string
				ld c,0
				jr nxtslot
id_ok			call print_string
				ld c,1
nxtslot			ld a,(working_slot)
				ld de,0
				ld e,a
				ld hl,slots_valid
				add hl,de
				ld (hl),c
				ld hl,slot_count
				inc a
				cp (hl)
				jr nz,id_loop
			
				ld hl,boot_slot_txt						; show power on boot slot
				call print_string
				call get_boot_slot
				jp c,timeout
				call show_hex_byte
				call new_line
				
				ld hl,last_cfg_txt						; show slot configured from
				call print_string
				call get_last_cfg_slot
				jp c,timeout
				call show_hex_byte
				
				ld hl,cr_txt
				jp quit_string	


;-----------------------------------------------------------------------------------------------
		

show_pic_fw_cmd	ld hl,firmware_txt						; show PIC firmware version
				call print_string
				call get_fw_version
				jp c,timeout
				call show_hex_byte
				ld hl,cr_txt
				jp quit_string	

			
;----------------------------------------------------------------------------------------------


write_slot_cmd	ld hl,buffer
				ld bc,256*1024
				ld a,0ffh
clbuflp			ld (hl),a
				cpi
				jp pe,clbuflp

				call find_next_argument					; look for slot number
				jp z,missing_arg
				
				ld a,kr_ascii_to_hex_word				; returns de = slot number
				call.lil prose_kernal
				jp nz,bad_hex
				ld a,e
				ld (target_slot),a
				ld hl,slot_count
				cp (hl)
				jp nc,invalid_slot
				
				call find_next_argument					; HL = filename location
				jp z,serial_cfg_load
				ld de,filename
				ld b,16
cpy_fn			ld a,(hl)
				or a
				jr z,fn_done
				cp ' '
				jr z,fn_done
				ld (de),a
				inc hl
				inc de
				djnz cpy_fn
fn_done			xor a
				ld (de),a
				
				ld hl,filename
				ld (fn_addr),hl
				ld a,kr_find_file
				call.lil prose_kernal
				jp nz,load_error
				
				ld hl,loading_txt
				call print_string
				
				ld hl,buffer
				ld a,kr_read_file
				call.lil prose_kernal
				jp nz,load_error
				jp dl_done
				

serial_cfg_load	ld hl,download
				call print_string

get_hdr_loop	ld e,1										; tenths of a second before timeout
				ld hl,dl_filename
				ld a,kr_serial_receive_header
				call.lil prose_kernal
				or a
				jr z,got_header
				
				cp 083h										;time out error?
				jr nz,comms_error
				ld a,kr_get_key
				call.lil prose_kernal
				cp 076h										;esc to abort
				jr nz,get_hdr_loop
				ld hl,aborted_txt
				jp quit_string
				
got_header		ld (fn_addr),ix
				ld hl,receiving								; receiving
				call print_string

				ld a,kr_serial_receive_file
				ld hl,buffer
				call.lil prose_kernal
				jp nz,comms_error

dl_done			ld hl,(fn_addr)
				ld de,buffer+01ff90h						; append filename to config (start of slot+1ff90h)
				ld b,16
cfnlp			ld a,(hl)
				ld (de),a
				or a
				jr z,cfnd
				inc hl
				inc de
				djnz cfnlp
				xor a
				ld (de),a
cfnd

				ld hl,write_txt
				call print_string
				ld a,(target_slot)
				call show_hex_byte
				call confirm
				jp nz,aborted

				call erase_slot
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				call check_erasure
				jp c,timeout
				jp nz,bad_erase
				


				call enable_pic_writes
				ret c
				cp 0
				ret nz

				ld hl,writing									; writing slot..	
				call print_string
				ld hl,buffer
				ld de,0
				ld a,(target_slot)
				sla a
				ld d,a											; page number
				ld bc,0200h										; pages to go 
lp1				push de
				push bc
				call write_eeprom_page
				pop bc
				pop de
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				inc de											;next page
				dec bc
				ld a,b
				or c
				jr nz,lp1

				call disable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
			




				ld a,088h									; send "set up databurst address" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low
				ld a,000h	
				call send_byte_to_pic						; send address mid
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld a,088h									;send "set up databurst length" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00h			
				call send_byte_to_pic						;send len low
				ld a,00h	
				call send_byte_to_pic						;send len mid
				ld a,02h
				call send_byte_to_pic						;send len high (20000h bytes)
	
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld hl,verifying								; read back data..	
				call print_string

				ld a,088h									;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld hl,buffer+020000h
				ld de,0
lp2				ld a,01h
				ld bc,port_pic_ctrl
				out (bc),a									; data out hi - pic responds by sending byte
				call get_byte_from_pic
				jp c,timeout
				ld (hl),a
				inc hl

				ld a,00h
				ld bc,port_pic_ctrl
				out (bc),a									; data out low - pic responds by sending next byte
				call get_byte_from_pic
				jp c,timeout
				ld (hl),a
				inc hl
				dec de
				ld a,d
				or e
				jr nz,lp2




				ld hl,buffer								;compare read back data to that which was written
				ld de,buffer+020000h
				ld b,0
lp4				push bc
				ld bc,0h
lp3				ld a,(de)
				cp (hl)
				jp nz,ver_bad
				inc hl
				inc de
				inc bc
				ld	a,b
				or c
				jr nz,lp3
				pop bc
				inc b
				ld a,b
				cp 2
				jr nz,lp4

				ld hl,ok_txt
				jp quit_string
								

;-------------------------------------------------------------------------------------------------


erase_slot_cmd	call find_next_argument					; look for slot number
				jp z,missing_arg
				
				ld a,kr_ascii_to_hex_word				; returns de = slot number
				call.lil prose_kernal
				jp nz,bad_hex
				ld a,e
				ld (target_slot),a
				ld hl,slot_count
				cp (hl)
				jp nc,invalid_slot

				ld hl,erase_txt
				call print_string
				ld a,(target_slot)
				call show_hex_byte
				call confirm
				jp nz,aborted
				
				call erase_slot
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call check_erasure
				jp c,timeout
				ld hl,ok_txt
				jp z,quit_string
				
				ld hl,erase_failed_txt
				jp quit_string


;-------------------------------------------------------------------------------------------------


set_boot_slot_cmd

				call find_next_argument						; look for slot number
				jp z,missing_arg
				
				ld a,kr_ascii_to_hex_word					; returns de = slot number
				call.lil prose_kernal
				jp nz,bad_hex
				ld a,e
				ld (target_slot),a
				ld hl,slot_count
				cp (hl)
				jp nc,invalid_slot
	
				ld hl,new_boot_txt
				call print_string
				ld a,(target_slot)
				call show_hex_byte
				call confirm
				jp nz,aborted

				ld a,088h									; set the temp config address
				call send_byte_to_pic
				ld a,0b8h
				call send_byte_to_pic
				ld a,016h		
				call send_byte_to_pic
				ld a,(target_slot)	
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				call enable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				ld a,088h									; make the config address active
				call send_byte_to_pic
				ld a,037h
				call send_byte_to_pic
				ld a,0d8h		
				call send_byte_to_pic
				ld a,006h		
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call disable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call get_boot_slot							; verify boot slot changed
				jp c,timeout
				ld hl,target_slot
				cp (hl)
				jp nz,boot_slot_error
				
				ld hl,ok_txt
				jp quit_string


;-------------------------------------------------------------------------------------------------


configure_cmd	
				call find_next_argument						; look for slot number
				jp z,missing_arg
				ld a,kr_ascii_to_hex_word					; returns de = slot number
				call.lil prose_kernal
				jp nz,bad_hex
				ld a,e
				ld (target_slot),a
				ld hl,slot_count
				cp (hl)
				jp nc,invalid_slot

				ld hl,reconfigure_txt
				call print_string
				ld a,(target_slot)
				call show_hex_byte
				call confirm
				jp nz,aborted
				
				ld a,088h									; set the temp config address
				call send_byte_to_pic
				ld a,0b8h
				call send_byte_to_pic
				ld a,016h		
				call send_byte_to_pic
				ld a,(target_slot)	
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld a,088h									; reconfig now
				call send_byte_to_pic
				ld a,0a1h
				call send_byte_to_pic
				ld a,03fh		
				call send_byte_to_pic
				ld a,062h	
				call send_byte_to_pic
				call pause
				ld hl,ok_txt								; should never see this, as FPGA will have reconfigured
				jp quit_string


;-------------------------------------------------------------------------------------------------


find_next_argument

				ld hl,(command_line_arg_ptr)
findspc			inc hl
				ld a,(hl)
				or a
				jr z,endofargs
				cp ' '
				jr nz,findspc
								
find_args		inc hl										
				ld a,(hl)
				or a
				jr z,endofargs
				cp ' '
				jr z,find_args
				
endofargs		ld (command_line_arg_ptr),hl
				ret

;-----------------------------------------------------------------------------------------------


show_hex_byte	ld e,a
				ld a,kr_hex_byte_to_ascii
				ld hl,ascii_hex
				call.lil prose_kernal
				ld hl,ascii_hex
				call print_string
				ret


new_line		ld hl,cr_txt
				call print_string
				ret
				
				
;------------------------------------------------------------------------------------------	


print_string	ld a,kr_print_string
				call.lil prose_kernal
				ret


;--------------------------------------------------------------------------------------------------


pause			ld de,32768									;wait 1 sec
				ld a,kr_time_delay
				call.lil prose_kernal
				ret


;--------------------------------------------------------------------------------------------------


short_pause		ld de,8192									;wait 0.25 sec
				ld a,kr_time_delay
				call.lil prose_kernal
				ret	
				
;------------------------------------------------------------------------------------------------


confirm			ld hl,sure_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				cp 035h										;scancode for y key
				ret


;------------------------------------------------------------------------------------------------

invalid_slot	ld hl,invalid_slot_txt
				jp quit_string


timeout			ld hl,timeout_msg
				jp quit_string


comms_error		ld hl,com_error_txt
				jp quit_string


load_error		ld hl,load_error_txt
				jp quit_string


pic_error		ld hl,pic_error_txt
				jp quit_string


missing_arg		ld hl,missing_arg_txt
				jp quit_string


bad_hex			ld hl,bad_hex_txt
				jp quit_string


bad_erase		ld hl,erase_failed_txt
				jp quit_string


ver_bad			ld hl,verify_failed_txt
				jp quit_string


boot_slot_error	ld hl,boot_slot_error_txt
				jp quit_string
				

aborted			ld hl,aborted_txt
				jp quit_string
				
				
bad_pic_response
				
				ld hl,ascii_hex
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,report_byte
				jp quit_string
				
;---------------------------------------------------------------------------------------
;--------- EEPROM SUBROUTINES ----------------------------------------------------------
;---------------------------------------------------------------------------------------

write_eeprom_page

				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp1			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp1
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,040h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
 
				ld b,64								;send 64 byte data packet to burn
wdplp2			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp2
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic	
				ld a,080h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp3			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp3
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,0c0h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp4			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp4
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret
				
;-------------------------------------------------------------------------------------------------------

new_write_eeprom_page

				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				ld a,128
				call send_byte_to_pic				;send number of bytes in packet

				ld b,128							;send 128 byte data packet to burn
nwdplp1			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz nwdplp1
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic
				ld a,080h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				ld a,128
				call send_byte_to_pic				;send number of bytes in packet

				ld b,128							;send 128 byte data packet to burn
nwdplp2			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz nwdplp2
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret 


;-------------------------------------------------------------------------------------------------------

read_eeprom_page

				push hl								;put page number to read to buffer in DE
				push de
				push bc
	
				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a
		
				ld a,88h							;send "set databurst location" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,0			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr
		
				ld a,88h							;send "set databurst location" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00			
				call send_byte_to_pic				;send length low
				ld a,01		
				call send_byte_to_pic				;send length mid
				ld a,00
				call send_byte_to_pic				;send length high
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr

			
				ld a,88h							;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr

			
				ld hl,buffer
				ld b,128
rplp2			ld a,01h
				out0 (port_pic_ctrl),a			; data out hi - pic responds by sending byte
				call get_byte_from_pic
				jr c,t_o
				ld (hl),a
				inc hl
				ld a,00h
				out0 (port_pic_ctrl),a			; data out low - pic responds by sending next byte
				call get_byte_from_pic
				jr c,t_o
				ld (hl),a
				inc hl
				djnz rplp2

				xor a
				pop bc
				pop de
				pop hl
				ret

bpr				scf
				pop bc
				pop de
				pop hl
				ret

t_o				xor a
				scf
				pop bc
				pop de
				pop hl
				ret	
				
				
;-------------------------------------------------------------------------------------------------------

enable_pic_writes

				ld a,088h									; 88,25,fa,99 = enable programming (red led on)
				call send_byte_to_pic
				ld a,025h
				call send_byte_to_pic
				ld a,0fah
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret

;-------------------------------------------------------------------------------------------------------

disable_pic_writes

				ld a,088h									; 88,1f = disable programming (green led on)
				call send_byte_to_pic
				ld a,01fh
				call send_byte_to_pic

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret
				
;-------------------------------------------------------------------------------------------------------
	
get_byte_from_pic

; Returns byte in A. If carry set, wait timed out.

				push de
				push bc
				ld b,32
				ld de,0
pcwbib			in0 a,(port_hw_flags)
				and 1										;check bit 0 (buffer status) if set, a byte has been received
				jr nz,pcbib
				dec de
				ld a,d
				or e
				jr nz,pcwbib
				djnz pcwbib
				pop bc
				pop de
				scf											; carry flag set = timed out
				ret

pcbib			in0 a,(port_pic_data)						; get the byte - this clears the buffer flag
				or a										; clear carry
				pop bc
				pop de
				ret

;------------------------------------------------------------------------------------------	

send_byte_to_pic

; put byte to send in A
						
														
				push af
				xor a
				out0 (port_pic_ctrl),a						; ensure data_out is not being forced high 

wpbusy			in0 a,(port_hw_flags)						; check bit 2 to ensure output serializer is not busy
				and 4
				jr nz,wpbusy

				pop af
				out0 (port_pic_data),a
				ret


;--------------------------------------------------------------------------------------------------

get_slot_count
	
				ld a,088h									; 88,5c = return capacity in slots
				call send_byte_to_pic
				ld a,5ch
				call send_byte_to_pic
				call get_byte_from_pic						
				ld (slot_count),a
				bit 7,a
				ret


;--------------------------------------------------------------------------------------------------

get_boot_slot				
				ld a,088h									; 88,76 = return power on boot slot selection
				call send_byte_to_pic
				ld a,76h
				call send_byte_to_pic
				call get_byte_from_pic						;pic should respond with slot byte
				ret

;--------------------------------------------------------------------------------------------------

get_last_cfg_slot				
	
				ld a,088h									; 88,71 = return last booted slot
				call send_byte_to_pic
				ld a,71h
				call send_byte_to_pic
				call get_byte_from_pic						;pic should respond with slot byte
				ret

;--------------------------------------------------------------------------------------------------				

get_sr				
				ld a,088h									; 88,76 = return SR
				call send_byte_to_pic
				ld a,06h
				call send_byte_to_pic
				call get_byte_from_pic						
				ret				

;--------------------------------------------------------------------------------------------------				

erase_slot		ld hl,erase									; erase slot..	
				call print_string
				
				call enable_pic_writes
				ret c
				cp 0
				ret nz
				
				ld a,088h									; send "erase 64KB EEPROM block" command
				call send_byte_to_pic
				ld a,0f5h
				call send_byte_to_pic
				ld a,000h		
				call send_byte_to_pic						; send address low - note: 64KB granularity
				ld a,000h		
				call send_byte_to_pic						; send address mid - note: 64KB granularity
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high - note: 64KB granularity
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld a,088h									; send "erase 64KB EEPROM block" command
				call send_byte_to_pic
				ld a,0f5h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low - note: 64KB granularity
				ld a,000h		
				call send_byte_to_pic						; send address mid - note: 64KB granularity
				ld a,(target_slot)
				sla a
				or 1
				call send_byte_to_pic						; send address high - note: 64KB granularity
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c 
				cp 0
				ret nz

				call disable_pic_writes
				ret
				
;--------------------------------------------------------------------------------------------------				

check_erasure

				ld hl,chkerase								; verify erase - read back data..	
				call print_string

				ld a,088h									; send "set up databurst address" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low
				ld a,000h	
				call send_byte_to_pic						; send address mid
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld a,088h									; send "set up databurst length" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00h			
				call send_byte_to_pic						; send len low
				ld a,00h	
				call send_byte_to_pic						; send len mid
				ld a,02h
				call send_byte_to_pic						; send address high
	
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz


				ld a,088h									;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld de,0
lpve			ld a,01h
				ld bc,port_pic_ctrl
				out (bc),a									; data out hi - pic responds by sending byte
				call get_byte_from_pic
				ret c
				cp 0ffh
				ret nz

				ld a,00h
				ld bc,port_pic_ctrl
				out (bc),a									; data out low - pic responds by sending next byte
				call get_byte_from_pic
				ret c
				cp 0ffh
				ret nz

				dec de
				ld a,d
				or e
				jr nz,lpve
				xor a
				ret

;--------------------------------------------------------------------------------------------------------------


get_fw_version	ld a,088h									; 88,4e = return PIC firmware version
				call send_byte_to_pic
				ld a,04eh
				call send_byte_to_pic
				call get_byte_from_pic						; pic should respond with FIRMWARE version byte
				ret


;===============================================================================================================

command_line_arg_ptr	dw24 0

dl_filename				db '*',0

filename				blkb 18,0

fn_addr					dw24 0

page_hi					db 0
page_med				db 0
page_lo					db 0

target_slot				db 0
slot_count				db 1
working_slot			db 0
boot_slot				db 0

ok_txt					db "OK.",11,0

usage_txt				db 11,"Usage: FPGACFG [W/E/B/L/C/P] [SLOT] [FILENAME]",11,11
						db "W - Write new config to slot",11
						db "E - Erase slot",11
						db "B - Set boot slot",11
						db "L - List slot contents",11
						db "C - Configure from slot",11
						db "P - Show PIC firware version",11,11
						db "(FPGACFG.EZP Version 0.03)",11,11,0

unknown_arg_txt			db "ERROR - Unexpected argument.",11,0

missing_arg_txt			db "ERROR - Missing argument.",11,0

bad_hex_txt				db "ERROR - Bad argument - hexadecimal expected.",11,0

erase_failed_txt		db "ERROR - Erase failed.",11,0

boot_slot_error_txt		db "ERROR - Boot slot did not update.",11,0

invalid_slot_txt		db "ERROR - Invalid slot.",11,0

pic_error_txt			db "ERROR - Unexpected PIC response.",11,0

verify_failed_txt		db "ERROR - Verify failed.",11,0

slot_count_error_txt	db "ERROR - Failed reading EEPROM size",11,0

com_error_txt			db "ERROR - Serial comms problem",11,0

load_error_txt			db "ERROR - File not found?",11,0

timeout_msg 			db "ERROR - Timed out.",11,0

erase_ok_txt			db "Confirmed: Erased OK.",11,0

aborted_txt				db "Aborted.",11,0

erase_txt				db "Erase EEPROM slot $",0

write_txt				db "Write to EEPROM slot $",0

new_boot_txt			db "Set FPGA boot slot to $",0

sure_txt				db " - Sure? (y/n)",11,0

boot_slot_txt			db 11,11,'Power-on boot slot  : $',0

last_cfg_txt			db 'Configured from slot: $',0

firmware_txt			db "PIC Firmware : $",0

reconfigure_txt			db "Reconfigure from slot $",0

loading_txt				db "Loading.. ",11,0

download				db "Waiting for config file via serial link [Esc to quit]",11,0
receiving				db "Receiving file..",11,0
received				db "File received.",11,0
erase					db "Erasing Slot..",11,0
chkerase				db "Checking Erasure..",11,0
writing   	  			db "Writing data to EEPROM..",11,0
verifying				db "Verifying data..",11,0
report_byte				db 11,"Error - Received byte $"
ascii_hex				db "xx",0

slots_txt				db 11,'Slot contents:',11
						db '--------------',11,0
slot_hex				db 11,'xx - ',0
unknown_txt				db 'Unknown / Blank',0

cr_txt					db 11,0

slots_valid				blkb 32,0

;--------------------------------------------------------------------------------------------------
buffer					db 0										; dont put anything after this
;--------------------------------------------------------------------------------------------------

