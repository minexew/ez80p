;-----------------------------------------------------------------------------
;'R' - show CPU register values saved on return from command. V0.03 - ADL mode
;-----------------------------------------------------------------------------

os_cmd_r	
				ld ix,store_a1							; show CPU register values
				ld hl,register_txt
rcmdloop2		call os_print_string
rcmdloop		ld a,(hl)
				cp 1
				jr z,showbyte
				cp 2
				jr z,showword16
				cp 3
				jr z,showaddr
				inc hl
				jr rcmdloop
				
showbyte		ld a,(ix)
				inc ix
				push ix
				push hl
				call os_show_hex_byte
				jr showreg

showword16		ld a,(ix+1)
				push ix
				push hl
				call os_show_hex_byte
				pop hl
				pop ix
				ld a,(ix)
				inc ix
				inc ix
				push ix
				push hl
				call os_show_hex_byte
				jr showreg

showaddr		ld de,(ix)
				lea ix,ix+3
				push ix
				push hl
				call os_show_hex_address
showreg			pop hl
				pop ix
				inc hl
				ld a,(hl)
				or a
				jr nz,rcmdloop2
			
				call os_new_line							; show the CPU flags
				ld hl,flag_txt
				call os_copy_to_output_line
				ld hl,output_line+4
				ld bc,5
				ld a,(store_f)
				bit 6,a										;zero flag
				jr z,zfzero
				ld (hl),'1'
zfzero			add hl,bc
				bit 0,a										;carry flag
				jr z,cfzero
				ld (hl),'1'
cfzero			add hl,bc
				bit 7,a										;sign flag
				jr z,sfzero
				ld (hl),'M'
sfzero			add hl,bc
				bit 2,a										;parity flag
				jr z,pfzero
				ld (hl),'O'
pfzero			add hl,bc
				inc hl
				bit 4,a										;IFF flag
				jr z,iffzero
				ld (hl),'1'
iffzero			
				ld bc,6
				add hl,bc
				ld a,(store_adl)
				add a,30h
				ld (hl),a
				call os_print_output_line
				xor a
				ret

;---------------------------------------------------------------------------------
	

register_txt		db ' A=',0,1
					db '  BC=',0,3
					db '  DE=',0,3
					db '  HL=',0,3
					
					db 11

					db 027h,'A=',0,1
					db ' ',027h,'BC=',0,3
					db ' ',027h,'DE=',0,3
					db ' ',027h,'HL=',0,3
					
					db 11

					db ' IX=',0,3
					db ' IY=',0,3
					
					db 11
					
					db ' PC=',0,3
					db ' LSP=',0,3
					db ' SSP=',0,2
					
					db 11
					
					db ' MBASE=',0,1,0,0
					
					db 11

flag_txt			db ' ZF=0 CF=0 SF=P PV=E IFF=0 ADL=0',11,11,0
		
;---------------------------------------------------------------------------------
