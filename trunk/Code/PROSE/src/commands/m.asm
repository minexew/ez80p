;------------------------------------------------------------------------------------------------------
;'m' - Show memory as hex bytes command. V0.02 - ADL mode
;------------------------------------------------------------------------------------------------------

bytes_per_line	equ 16

os_cmd_m		call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,m_no_hex						;or there's no hex - if no hex, use old address
				ld (mem_mon_addr),de
				
m_no_hex		ld b,16								;shows 16 lines of bytes
smbllp			push bc								;starting from current cursor position
				
				ld hl,colon_cmd_prefix				
				call os_print_string
				ld de,(mem_mon_addr)
				call os_show_hex_address

				ld hl,output_line
				ld b,bytes_per_line					
mmbllp			ld (hl),' '
				inc hl
				ld a,(de)	
				call hexbyte_to_ascii
				inc de
				djnz mmbllp

				ld (mem_mon_addr),de
				ld (hl),11
				inc hl
				ld (hl),0
				ld hl,output_line
				call os_print_string
				pop bc
				djnz smbllp
				
				xor a
				ret

;---------------------------------------------------------------------------------------------------

colon_cmd_prefix	db ': ',0

;---------------------------------------------------------------------------------------------------
