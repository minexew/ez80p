;----------------------------------------------------------------------------------------------------------
;"c" - Copy memory command. V0.02 - ADL mode
;----------------------------------------------------------------------------------------------------------

os_cmd_c

				call get_start_and_end				;this routine only returns here if start/end data is valid
				
				call hexword_or_bust				;only returns here if the hex in DE (destination address) is valid
				jp z,os_no_d_addr_error
				ld (copy_dest_address),de
						
				call test_mem_range				
				jp c,os_range_error					;abort if end addr < start addr
				ld de,(copy_dest_address)
				ldir

copy_done		ld a,020h							;completion message
				or a
				ret
			
			
;----------------------------------------------------------------------------------------------------------
			
test_mem_range
			
; on return:
;
; carry flag: Set = bad range
; xBC = run length on return
; xHL = start address
			
				ld hl,(cmdop_end_address)	
				ld bc,(cmdop_start_address)
				push bc
				xor a
				sbc hl,bc
				push hl
				pop bc
				inc bc
				pop hl
				ret
				
;------------------------------------------------------------------------
			
get_start_and_end
			
				call ascii_to_hexword						;get start address
				ld (cmdop_start_address),de
				inc hl
				jr z,st_addrok
				pop hl										;this pop is remove originating call addr from the stack
				cp 82h										;bad hex error code
				jr z,c_badhex
				ld a,016h									;no start address error code
c_badhex		or a
				ret
				
st_addrok		call ascii_to_hexword						;get end address
				ld (cmdop_end_address),de
				inc hl
				or a
				ret z
				pop hl										;this pop is remove originating call addr from the stack
				cp 82h										;bad hex error code
				jr z,c_badhex
				ld a,01ch									;no end address error code
				ret
				
;-------------------------------------------------------------------------------------------------------------

hexword_or_bust

; Set HL to string address:
; Returns to parent routine ONLY if the string is valid hex (or no hex found) in which case:
; DE = hex word. If no hex found, the zero flag is set (A = error code $81)
; If chars are invalid hex, returns to grandparent (IE: main OS) with error code $82: bad data

				call ascii_to_hexword		
				cp 82h
				jr nz,hex_good
				pop hl						; remove parent return address from stack
				or a	
				ret			 
hex_good		cp 081h						; no args?
				ret
	
;-------------------------------------------------------------------------------------------------------------

