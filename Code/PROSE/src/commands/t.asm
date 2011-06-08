;-----------------------------------------------------------------------
;'T' - Show memory as ascii text command. V0.02 - ADL mode
;-----------------------------------------------------------------------

os_cmd_t		call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr z,t_no_hex						;or there's no hex - if no hex, use old address
				ld (mem_mon_addr),de
							
t_no_hex		ld b,16
smaalp			push bc
				
				ld hl,gtr_cmd_prefix				
				call os_print_string
				ld de,(mem_mon_addr)
				call os_show_hex_address

				ld hl,output_line
				ld (hl),' '
				inc hl
				ld (hl),022h
				ld b,16
mabllp			inc hl
				ld a,(de)	
				cp 020h
				jr c,chchar
				cp 07fh
				jr c,nchchar
chchar			ld a,07ch
nchchar			ld (hl),a
				inc de
				djnz mabllp

				ld (mem_mon_addr),de
				inc hl
				ld (hl),022h
				inc hl
				ld (hl),11
				inc hl
				ld (hl),0
				call os_print_output_line
				pop bc
				djnz smaalp
				xor a
				ret
	
;-----------------------------------------------------------------------

gtr_cmd_prefix	db '> ',0

;-----------------------------------------------------------------------
