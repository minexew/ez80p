;-----------------------------------------------------------------------------------------
; OS "D" Command: EZ80 Disassembler V0.01
; Totally and utterly unoptimized!
;------------------------------------------------------------------------------------------

os_cmd_d		ld iy,prefix_bits_loc
				set adl_dis,(iy+var_adl)

os_cmd_d_go		call hexword_or_bust			; the call only returns here if the hex in DE is valid
				jr z,d_no_hex					; or there's no hex - if no hex, use old address
				ld (dis_addr),de
				
d_no_hex		ld a,(window_rows)				; do this many lines - 2
				sub a,2
				ld b,a
dis_loop		push bc
				
				ld ix,(dis_addr)				; IX = address to disassemble from..
				call show_ix					; show disassembly address..
				ld a,' '
				call show_ascii_char

				ld iy,prefix_bits_loc
				ld (iy),0						; clear the prefix flags
				call dis_instr					; disassemble one line..
				inc ix							; ix = start of next opcode
				
				ld a,24							; move cursor to column 24				
				ld (cursor_pos+1),a				; show the hex bytes use by opcode
				ld bc,(dis_addr)
				ld (dis_addr),ix				; IX now = next opcode address			
				push ix
				pop hl
				xor a
				sbc hl,bc						; number of bytes in opcode
				ld a,l
				and 7
				ld l,a
shexoplp		ld a,(bc)						
				call show_hex_byte
				ld a,' '
				call show_ascii_char
				inc bc
				dec l
				jr nz,shexoplp
				
				call os_new_line
				pop bc
				djnz dis_loop

				call os_new_line
				xor a
				ret


;- Handle op code prefixes -----------------------------------------------------------------------
			
cb_prefix			equ 0					
ed_prefix			equ 1
sub_ix_prefix		equ 2
sub_iy_prefix		equ 3
ddcb_fdcb_prefix	equ 4					; priority over subst_ix / subst_iy
dot_l_prefix		equ 5
il_prefix			equ 6
show_adl_prefix		equ 7

adl_dis				equ 0					; bit in var_adl


dis_instr	ld a,(ix)						; check for instruction prefixes						
			
			bit adl_dis,(iy+var_adl)		; if ADL mode disassembly, use 24bit words by setting
			jr z,z80_list					; The "il" prefix ("il" is not shown unless the prefix is
			set il_prefix,(iy)				; actually included in the code).
z80_list			
			
;-----------------------------------------------------------------------------------------------

			cp 40h
			jr nz,not_sis
			res il_prefix,(iy)
			res dot_l_prefix,(iy)
			jr set_adl_pf
			
not_sis		cp 49h
			jr nz,not_lis
			res il_prefix,(iy)
			set dot_l_prefix,(iy)
			jr set_adl_pf
			
not_lis		cp 52h
			jr nz,not_sil
			set il_prefix,(iy)
			res dot_l_prefix,(iy)
			jr set_adl_pf
			
not_sil		cp 5bh
			jr nz,not_adl_prefix_byte
			set il_prefix,(iy)
			set dot_l_prefix,(iy)
			
set_adl_pf	set show_adl_prefix,(iy)
			inc ix
			ld a,(ix)	
			
;-----------------------------------------------------------------------------------------------

not_adl_prefix_byte			
			
			cp 0cbh								;check for traditional Z80 prefixes
			jr nz,not_cb
do_cb		set cb_prefix,(iy)
			inc ix
			jr not_traditional_prefix_byte

not_cb		cp 0edh
			jr nz,not_ed
do_ed		set ed_prefix,(iy)
			inc ix
			jr not_traditional_prefix_byte

not_ed		cp 0ddh
			jr nz,not_dd
do_dd		call check_nxt_byte_prefix			;if next byte is DD,ED, or FD ignore this byte
			jr z,dis_instr						;and move to next
			set sub_ix_prefix,(iy)
xdcb_query	cp 0cbh								;if next byte is CB, decode as a ddcb instruction 
			jr nz,not_traditional_prefix_byte	;otherwise just substitute HL for IX in normal instruction
			set ddcb_fdcb_prefix,(iy)
			inc ix								; skip the CB
			inc ix								; skip the following byte which is the displacement for the ix/iy+d
			jr not_traditional_prefix_byte

not_dd		cp 0fdh
			jr nz,not_traditional_prefix_byte
do_fd		call check_nxt_byte_prefix
			jr z,dis_instr	
			set sub_iy_prefix,(iy)
			jr xdcb_query

not_traditional_prefix_byte

;-----------------------------------------------------------------------------------------------

			ld a,(ix)	
			and 11000000b			; seperate opcode into x,y,z,p & q variables
			rlca
			rlca
			ld (iy+var_x),a			;var x= value formed from bits 7:6
			
			ld a,(ix)
			and 00111000b
			srl a
			srl a
			srl a	
			ld (iy+var_y),a			;var x = vlue formed from bits 5:3

			ld a,(ix)
			and 00000111b
			ld (iy+var_z),a			;var z = value formed from bits 2:0
			
			ld a,(ix)
			and 00110000b
			srl a
			srl a
			srl a
			srl a
			ld (iy+var_p),a			; var p = value formed by bits 5:4
			
			ld a,(ix)
			and 00001000b
			srl a
			srl a
			srl a
			ld (iy+var_q),a				;var q = bit 3

			call find_instruction_ascii		; get ascii location of instruction group in HL, group index in B
	
;----------------------------------------------------------------------------------------------------------------

index_table	ld a,b							; at this point HL = instruction group string start, B = index  
			or a
			jr z,parse_instr				; move along B number of instructions to get to correct table entry
d_filp		bit 7,(hl)						; when ascii char has bit 7 set, this is the last char of an entry
			inc hl							; on loop exit hl = located entry (b no longer required)
			jr z,d_filp					
			djnz d_filp
										
			
parse_instr	ld iy,opcode_vars
			ld bc,0
			ld a,(hl)						;get a character of ascii opcode
			cp 80h
			ret z
			and 7fh
			
			cp '&'							;symbol for ADL prefix?
			jr nz,not_adlsym
			bit show_adl_prefix,(iy)		;do we show the prefix or not?
			jr z,next_opcode_ascii_char
			ld b,0
			bit dot_l_prefix,(iy)
			jr z,naplsb
			set 0,b
naplsb		bit il_prefix,(iy)
			jr z,napmsb
			set 1,b
napmsb		push hl
			ld hl,adl_prefix_list
			call index_table				; recursive call alert!
			pop hl
			jp next_opcode_ascii_char

not_adlsym	cp '^'							;symbol for immediate byte?
			jr nz,d_not_imm8
			inc ix							;the byte follows the opcode
			ld a,(ix)
			call show_hex_byte
			jp next_opcode_ascii_char
					
d_not_imm8	cp '!'							;symbol for immediate word?
			jr nz,d_not_imm16							
			ld de,2
			bit il_prefix,(iy)				;adl mode on for this instruction?
			jr z,imm16
			inc de
			ld a,(ix+3)
			call show_hex_byte
imm16		ld a,(ix+2)						;show high byte first
			call show_hex_byte			
			ld a,(ix+1)						;then low byte
			call show_hex_byte
			add ix,de						;adjust disassembly position
			jp next_opcode_ascii_char

d_not_imm16	cp '/'							;symbol for a signed byte displacement for (IX)/(IY)
			jr nz,d_not_sb
			bit ddcb_fdcb_prefix,(iy)
			jr z,norm_dbyte
			ld a,(ix-1)						;if a ddcb or fdcb preifx, the disp byte preceeds the opcode
			jr xdcb_dbyte
norm_dbyte	inc ix
			ld a,(ix)						;the displacement byte normally follows the opcode
xdcb_dbyte	bit 7,a
			jr nz,d_sbin					;show +/- depending on sign
			push af
			ld a,'+'
			call show_ascii_char
			pop af
			call show_hex_byte
			jp next_opcode_ascii_char
d_sbin		push af
			ld a,'-'
			call show_ascii_char
			pop af
			neg
			call show_hex_byte
			jp next_opcode_ascii_char
			
d_not_sb	cp 'd'							;symbol for PC (JR) displacement
			jr nz,d_not_pcdip
			inc ix
			ld bc,0
			ld a,(ix)
			bit 7,a
			jr z,d_spcd_pos
			dec bc
d_spcd_pos	ld c,a
			inc bc
			push ix
			add ix,bc
			call show_ix
			pop ix
			jp next_opcode_ascii_char

d_not_pcdip	cp '>'							;symbol for a single n digit (used in BIT n, SET n etc)
			jr nz,d_not_sdig
			inc hl							;the following byte specifies which variable holds the value
			ld bc,0
			ld c,(hl)
			ld iy,opcode_vars
			add iy,bc
			ld a,(iy)						;a = the value
			add a,30h						;convert to ASCII (will only be 0-7)
			jp d_output_char

d_not_sdig	cp '_'
			jr nz,d_nhlsubst				; symbol to substitute HL based on DD/FD prefix?
			push hl
			ld hl,hl_subs
hl_subst	call prefix_to_offset
			call index_table				; recursive call alert!
			pop hl
			jp next_opcode_ascii_char
			
d_nhlsubst	cp '|'
			jr nz,d_noinvhls
			push hl
			ld hl,inv_hl_subs
			jr hl_subst
			
d_noinvhls	cp 'h'							;symbol to substitute H based on DD,FD prefix?
			jr nz,d_nhsubst
			push hl
			ld hl,h_subs
			jr hl_subst
			
d_nhsubst	cp 'l'							;symbol to substitute L based on DD,FD prefix?
			jr nz,d_nlsubst
			push hl
			ld hl,l_subs
			jr hl_subst
			
d_nlsubst	cp '$'
			jr nz,d_nihlsubst				; symbol to substitute '(HL)' based on DD,FD prefix?
			push hl
			ld hl,ind_hl_subs
			jr hl_subst


d_nihlsubst	

			cp '~'							; symbol for r table?
			jr nz,ntable_r
			ld de,table_r
do_table 	inc hl
			ld bc,0							; the following byte specifies which var x/y/z etc is the index
			ld c,(hl)
			ld iy,opcode_vars
			add iy,bc
			ld b,(iy)						;index
			push hl
			ex de,hl
			call index_table				; recursive call alert!
			pop hl
			jp next_opcode_ascii_char
			
ntable_r	ld de,table_rp					; symbol for rp table?
			cp '@'
			jr z,do_table 
			
			ld de,table_rp2					; symbol for rp2 table?					
			cp '*'
			jr z,do_table
			
			ld de,table_rp3					; symbol for rp3 table?
			cp '<'
			jr z,do_table
			
			ld de,table_rp4					; symbol for rp3 table?
			cp '}'
			jr z,do_table
			
			ld de,table_cc					; symbol for cc table?
			cp '#'
			jr z,do_table 
			
			ld de,table_alu					; symbol for alu table?
			cp ':'
			jr z,do_table 
			
			ld de,table_rot					; symbol for rot table?
			cp '%'
			jr z,do_table 
			
			ld de,table_rst					; symbol for rst table?
			cp ';'
			jr z,do_table 

			
ntable_bli

;--------------------------------------------------------------------------------------------------------

d_output_char

			call show_ascii_char

next_opcode_ascii_char

			bit 7,(hl)						;if char was last of opcode, quit subroutine else loo for next char
			ret nz
			inc hl
			jp parse_instr
			
			
;--------------------------------------------------------------------------------------------------------


prefix_to_offset

			ld b,2							;sets b as follows: No prefix:0, dd prefix:1 fd prefix:2
			bit sub_iy_prefix,(iy)
			ret nz
			dec b
			bit sub_ix_prefix,(iy)
			ret nz
			dec b
			ret
			
			
check_nxt_byte_prefix			

			inc ix
			ld a,(ix)
			cp 0ddh
			ret z
			cp 0edh
			ret z
			cp 0fdh
			ret
			
			
;========================================================================================================
;- Find instruction ascii -------------------------------------------------------------------
;========================================================================================================

; Returns HL = ptr to ascii name
;          B = group index (number of instructions to skip from HL)

find_instruction_ascii

			ld b,0						; default index

			bit ddcb_fdcb_prefix,(iy)	; Was the ddcb or fdcb prefix set?
			jr z,not_ddcb_fdcb_inst
			ld hl,ddcb_fdcb_z6		
			ld b,(iy+var_x)				; x is the index in this group
			ld a,(iy+var_z)
			cp 6
			ret z
			ld hl,ddcb_fdcb_zn6					
			ret
			
;========================================================================================================

not_ddcb_fdcb_inst

			bit cb_prefix,(iy)			;is this a CB prefixed instruction?
			jr z,not_cb_inst
			ld hl,cb_group		
			ld b,(iy+var_x)				; x is the index in this group
			ret

;========================================================================================================

not_cb_inst

			bit ed_prefix,(iy)			;is this an ED prefixed instruction?
			jr z,not_ed_inst

			ld a,(iy+var_x)				;x = 0
			or a
			jr nz,notedx0
		
			
			ld a,(iy+var_z)				
			or a
			jr nz,notedx0z0
			ld hl,ed_x0_z0_yn6			;x0 / z0
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld b,1
			ret

notedx0z0	cp 1
			jr nz,notedx0z1
			ld hl,ed_x0_z1				;x0 / z1
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld b,1
			ret

notedx0z1	cp 2
			jr nz,notedx0z2
			ld hl,ed_x0_z2				;x0 / z2
			ret

notedx0z2	cp 3
			jr nz,notedx0z3
			ld hl,ed_x0_z3				;x0 / z3
			ret
			
notedx0z3	cp 4
			jr nz,notedx0z4
			ld hl,ed_x0_z4				;x0 / z4
			ret

notedx0z4	cp 6
			jr nz,notedx0z6				;x0 / z6
			ld hl,ed_x0_z6
			ret

notedx0z6	cp 7
			jr nz,bad_opcode			;x0 / z7
			ld hl,ed_x0_z7
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld b,1
			ret
			
;--------------------------------------------------------------------------------------------------------
			
notedx0		cp 1	
			jr nz,ed_xn1

			ld a,(iy+var_z)					;x = 1
			or a
			jr nz,ed_x1_zn0
			ld hl,ed_x1_z0_yn6				;z = 0
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld b,1
			ret
			
ed_x1_zn0	cp 1
			jr nz,ed_x1_zn1
			ld hl,ed_x1_z1_yn6				;z = 1
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld b,1
			ret
		
ed_x1_zn1	cp 2
			jr nz,ed_x1_zn2					;z = 2
			ld hl,ed_x1_z2	
			ld b,(iy+var_q)
			ret

ed_x1_zn2	cp 3
			jr nz,ed_x1_zn3					;z = 3
			ld hl,ed_x1_z3	
			ld b,(iy+var_q)
			ret
			
ed_x1_zn3	cp 4							;z = 4
			jr nz,ed_x1_zn4
			ld hl,ed_x1_z4
			ld b,(iy+var_y)
			ret
			
ed_x1_zn4	cp 5
			jr nz,ed_x1_zn5
			ld hl,ed_x1_z5					;z = 5
			ld b,(iy+var_y)
			ret
			
ed_x1_zn5	cp 6
			jr nz,ed_x1_zn6					;z=6
			ld hl,ed_x1_z6
			ld b,(iy+var_y)
			ret
			
ed_x1_zn6	ld hl,ed_x1_z7					;z=7
			ld b,(iy+var_y)
			ret

;---------------------------------------------------------------------------------------------------------
				
ed_xn1		cp 2
			jr nz,ed_xn2
			
			ld b,(iy+var_y)
			ld a,(iy+var_z)
			or a
			jr nz,edx2zn0
			ld hl,ed_x2_z0					;x=2, z=0
			ret

edx2zn0		cp 1
			jr nz,edx2zn1
			ld hl,ed_x2_z1					;x=2, z=1
			ret

edx2zn1		cp 2
			jr nz,edx2zn2
			ld hl,ed_x2_z2					;x=2, z=2
			ret

edx2zn2		cp 3
			jr nz,edx2zn3
			ld hl,ed_x2_z3					;x=2, z=3
			ret

edx2zn3		ld hl,ed_x2_z4					;x=2, z=4
			ret

;---------------------------------------------------------------------------------------------------------

ed_xn2		cp 3
			jr nz,ed_xn3
			
			ld b,(iy+var_y)
			ld a,(iy+var_z)
			cp 2
			jr nz,edx3zn2
			ld hl,ed_x3_z2					;x=3, z=2
			ret
edx3zn2		cp 3
			jr nz,edx3zn3
			ld hl,ed_x3_z3					;x=3, z=3
			ret

edx3zn3

ed_xn3

;---------------------------------------------------------------------------------------------------------

invalid_op
			ld hl,bad_opcode				; x=3
			ld b,0
			ret
			
			
;========= UNPREFIXED INSTRUCTION =======================================================================


not_ed_inst	ld a,(iy+var_x)				; is X = 0?
			or a
			jr nz,x_not_zero

;----------------------------------------------------------------------------------------


			ld a,(iy+var_z)				;x = 0
			or a
			jr nz,x0_z_not_zero
			ld hl,x0_z0
			ld a,(iy+var_y)				;y is the index
			ld b,a
			sub 4
			ld (iy+var_calc),a			;var_calc = y-4
			ld a,b
			cp 4
			ret c
			ld b,4						;if y > 4, y=4
			ret
			
x0_z_not_zero		
			
			cp 1
			jr nz,x0_z_not_one
			ld hl,x0_z1_yn6
			ld b,(iy+var_q)				;q is the index
			ld a,(iy+var_y)
			cp 6
			ret nz
			ld hl,x0_z1_y6
			ld b,0
			ret 
			
x0_z_not_one

			cp 2
			jr nz,x0_z_not_two
			ld hl,x0_z2
			ld b,(iy+var_y)				;y is the index
			ret
			
x0_z_not_two

			cp 3
			jr nz,x0_z_not_three
			ld hl,x0_z3
			ld b,(iy+var_q)				;q is the indedx
			ret
			
x0_z_not_three

			cp 4
			jr nz,x0_z_not_four
			ld hl,x0_z4					;no initial index
			ret			
			
x0_z_not_four

			cp 5
			jr nz,x0_z_not_five
			ld hl,x0_z5					;no initial index
			ret				
			
x0_z_not_five

			cp 6
			jr nz,x0_z_not_six
			ld hl,x0_z6					;normal group
			ld a,(iy+var_y)
			cp 7
			ret nz
			bit sub_ix_prefix,(iy)
			jr nz,altx0z6
			bit sub_iy_prefix,(iy)
			ret z	
altx0z6		ld hl,alt_x0_z6				;if dd/fd prefix set the y=7 instruction changes - unusual.
			ret


x0_z_not_six
			
			ld hl,x0_z7
			ld b,(iy+var_y)				;y is normally the index
			bit sub_ix_prefix,(iy)
			jr nz,altx0z7
			bit sub_iy_prefix,(iy)
			ret z
altx0z7		ld a,b
			and 1
			ld b,a						;if dd/fd prefix set - the (y6/y7) instructions change completely
			ld hl,alt_x0_z7				;this is unusual!
			ret

;----------------------------------------------------------------------------------------------------

x_not_zero	cp 1						; is x = 1?
			jr nz,x_not_one
			
			ld hl,x1_table				; x=1
			ld b,0
			ld a,(iy+var_y)				; no index
			cp 6
			ret nz
			ld a,(iy+var_z)
			cp 6
			ret nz
			inc b						; unless y=6 and z=6 
			ret
		
;----------------------------------------------------------------------------------------------------
			
x_not_one	cp 2						; is x = 2? 
			jr nz,x_not_two
			ld hl,x2_table				; no initial index 
			ret
			
;----------------------------------------------------------------------------------------------------

x_not_two	ld a,(iy+var_z)				; x must be 3. Is z = 0?
			or a
			jr nz,x3_z_not_zero
			ld hl,x3_z0					; no initial index
			ret
						
x3_z_not_zero

			cp 1
			jr nz,x3_z_not_one
			ld hl,x3_z1_q0
			ld a,(iy+var_q)
			or a
			ret z						; no initial index if q = 0
			ld hl,x3_z1_q1
			ld b,(iy+var_p)				; index is p if q =1 
			ret

x3_z_not_one

			cp 2
			jr nz,x3_z_not_two
			ld hl,x3_z2					;no initial index
			ret

x3_z_not_two

			cp 3
			jr nz,x3_z_not_three
			ld hl,x3_z3
			ld b,(iy+var_y)				;index is y
			ret

x3_z_not_three

			cp 4
			jr nz,x3_z_not_four
			ld hl,x3_z4				;no initial index
			ret						


x3_z_not_four

			cp 5
			jr nz,x3_z_not_five
			ld hl,x3_z5_q0
			ld a,(iy+var_q)
			or a
			ret z						;no index if q=0
			ld hl,x3_z5_q1
			ld b,(iy+var_p)				;else index is p
			ret

x3_z_not_five

			cp 6
			jr nz,x3_z_not_six
			ld hl,x3_z6					;no index
			ret

x3_z_not_six

			ld hl,x3_z7					;x=3, z=7 (rst table)
			ret


;========================================================================================================


show_hex_byte

			push hl
			ld hl,output_byte_txt
			push hl
			call hexbyte_to_ascii
			pop hl
			call os_print_string
			pop hl
			ret
			

show_ascii_char

			push hl
			ld hl,output_char_txt
			ld (hl),a
			call os_print_string
			pop hl
			ret
		
		
show_ix		ld (d_work_address),ix
			ld a,(d_work_address+2)
			call show_hex_byte
			ld a,(d_work_address+1)
			call show_hex_byte
			ld a,(d_work_address)
			call show_hex_byte
			ret
			
;--------------------------------------------------------------------------------------------------------

; SYMBOLS:

; # = CC_table
; ~ = r table (registers)
; @ = RP table (register pairs 1)
; * = RP2 table (registers pairs 2)
; : = ALU table
; % = ROT table
; _ = HL,IX/IY substitute selected by prefix
; £ = HL, IY/IX substitute based on prefix (IX/IY reversed version of above)
; $ = (HL),(IX+d),(IY+d) substitute selected by prefix
; h = H,IXH/IYH substitute selected by prefix
; l = L,IXL,IYL substitute selected by prefix
; & = ADL prefix 

; ^ = n (8 bit immediate)
; ! = nn (16 or 24 bit immediate)
; d = 8 bit signed jump displacement from PC
; / = 8 bit signed byte used for IX+d, IY+d instructions
; > = single digit used by BIT,SET,RES instructions
; < = RP3 table (register pairs 3)
; } = RP4 table (register pairs 4)
; ; = RST table

opcode_vars

prefix_bits_loc	db 0	
var_x_loc		db 0	
var_y_loc		db 0	
var_z_loc		db 0	
var_p_loc		db 0	
var_q_loc		db 0
var_calc_loc	db 0
var_adl_loc		db 1

prefix_bits		equ opcode_vars-prefix_bits_loc			;offsets
var_x			equ var_x_loc-opcode_vars
var_y			equ var_y_loc-opcode_vars
var_z			equ var_z_loc-opcode_vars
var_p			equ var_p_loc-opcode_vars
var_q			equ var_q_loc-opcode_vars
var_calc		equ var_calc_loc-opcode_vars
var_adl			equ var_adl_loc-opcode_vars

;---- Unprefixed opcodes --------------------------------------------------------------------------------


x0_z0		db 'NO','P'+80h				; y0
			db 'EX AF,AF',27h+80h		; y1 
			db 'DJNZ ','d',80h			; y2
			db 'JR ','d',80h			; y3
			db 'JR #',var_calc,',d',80h	; y4-y7
			
x0_z1_yn6	db 'LD& @',var_p,',!',80h	; q=0
			db 'ADD& _,@',var_p,80h		; q=1
x0_z1_y6	db 'LD& |,$',80h			; y=6
			
x0_z2		db 'LD& (BC)','A'+80h		;y=0
			db 'LD& A,(BC',')'+80h		;y=1
			db 'LD& (DE),','A'+80h		;y=2
			db 'LD& A,(DE',')'+80h		;y=3
			db 'LD& (!),','_'+80h		;y=4
			db 'LD& _,(!',')'+80h		;y=5
			db 'LD& (!),','A'+80h		;y=6
			db 'LD& A,(!',')'+80h		;y=7

x0_z3		db 'INC& @',var_p,80h		;q=0
			db 'DEC& @',var_p,80h		;q=1
			
x0_z4		db 'INC& ~',var_y,80h		

x0_z5		db 'DEC& ~',var_y,80h		
			
x0_z6		db 'LD& ~',var_y,',^',80h	
alt_x0_z6	db 'LD& $,|',80h			; when y=7 and dd/fd prefix set			
		
x0_z7		db 'RLC','A'+80h		;y=0
			db 'RRC','A'+80h		;y=1
			db 'RL','A'+80h			;y=2
			db 'RR','A'+80h			;y=3
			db 'DA','A'+80h			;y=4
			db 'CP','L'+80h			;y=5
			db 'SC','F'+80h			;y=6 (and no DD/FD prefix)
			db 'CC','F'+80h			;y=7 (and no DD/FD prefix)
			
alt_x0_z7	db 'LD& _,$',80h		;y=6 (DD/FD prefix - unusual instruction: DD/FD completely changes function)
			db 'LD& $,_',80h		;y=7 ("" "")


x1_table	db 'LD& ~',var_y,',~',var_z,80h		;for all except..
x1_y6_z6	db 'HAL','T'+80h					;when y=6 and z=6



x2_table	db ':',var_y,'~',var_z,80h			;ALU_table(y), r(z)
			
		
		
x3_z0		db 'RET #',var_y,80h

x3_z1_q0	db 'POP& *',var_p,80h			
x3_z1_q1	db 'RE','T'+80h			;p=0
			db 'EX','X'+80h			;p=1
			db 'JP& _',80h			;p=2
			db 'LD& SP,_',80h		;p=3

x3_z2		db 'JP& #',var_y,',!',80h		

x3_z3		db 'JP& !',80h			;y = 0
			db 'CB pfx',80h			;y = 1
			db 'OUT (^),','A'+80h	;y = 2
			db 'IN A,(^',')'+80h	;y = 3
			db 'EX& (SP),','_',80h	;y = 4
			db 'EX DE,H','L'+80h	;y = 5
			db 'D','I'+80h			;y = 6
			db 'E','I'+80h			;y = 7

x3_z4		db 'CALL& #',var_y,',!',80h

x3_z5_q0	db 'PUSH& *',var_p,80h			
x3_z5_q1	db 'CALL& !',80h			;p=0
			db 'DD pfx',80h			;p=1
			db 'ED pfx',80h			;p=2
			db' FD pfx',80h			;p=3

x3_z6		db ':',var_y,'^',80h	;ALU_table(y),n

x3_z7		db 'RST ;',var_y,80h		; rst_table(y)


;--- CB - Prefixed op-codes-------------------------------------------------------------------------------------


cb_group		db '%',var_y,',~',var_z,80h			; x = 0
				db 'BIT& >',var_y,',~',var_z,80h		; x = 1   (">" = show variable: single digit)
				db 'RES& >',var_y,',~',var_z,80h		; x = 2
				db 'SET& >',var_y,',~',var_z,80h		; x = 3 


;---- ED - Prefixed op-codes-------------------------------------------------------------------------------------

ed_x0_z0_yn6	db 'IN0 ~',var_y,',(^',')'+80h
ed_x0_z0_y6		db 'IN0 (^',')'+80h	

ed_x0_z1		db 'OUT0 ~',var_y,',(^',')'+80h		;y not 6
				db 'LD& IY,(_',')'+80h				;y is 6

ed_x0_z2		db 'LEA& <',var_p,',IX/',80h		
ed_x0_z3		db 'LEA& }',var_p,',IY/',80h
ed_x0_z4		db 'TST& A,~',var_y,80h

ed_x0_z6		db 'LD& (_),}',var_p,80h

ed_x0_z7		db 'LD& (_),<',var_p,80h			;y not 6	
				db 'LD& IX,(_',')'+80h				;y is 6


ed_x1_z0_yn6	db 'IN ~',var_y,',(BC',')'+80h
ed_x1_z0_y6		db 'IN (C',')'+80h

ed_x1_z1_yn6	db 'OUT (C),~',var_y,80h
ed_x1_z1_y6		db 'OUT (C),','0'+80h

ed_x1_z2		db 'SBC& HL,@',var_p,80h		;q=0
				db 'ADC& HL,@',var_p,80h		;q=1

ed_x1_z3		db 'LD& (!),@',var_p,80h		;q=0
				db 'LD& @',var_p,'(!',')'+80h	;q=1

ed_x1_z4		db 'NE','G'+80h				;y=0
				db 'MLT B','C'+80h			;y=1
				db 'LEA& IX,IY/',80h			;y=2
				db 'MLT D','E'+80h			;y=3
				db 'TST& A,^',80h			;y=4
				db 'MLT H','L'+80h			;y=5
				db 'TSTIO ^',80h			;y=6
				db 'MLT S','P'+80h 			;y=7

ed_x1_z5		db 'RETN&',80h				;y=0
				db 'RETI&',80h				;y=1
				db 'LEA& IY,IX/',80h		;y=2
				db '?'+80h					;y=3
				db 'PEA& IX/',80h			;y=4
				db 'LD MB,','A'+80h			;y=5
				db '?'+80h					;y=6
				db 'STMI','X'+80h			;y=7
				
	
ed_x1_z6		db 'IM ','0'+80h			;y=0
				db '?'+80h					;y=1
				db 'IM ','1'+80h			;y=2
				db 'IM ','2'+80h			;y=3
				db 'PEA& IY/',80h			;y=4
				db 'LD A,','M','B'+80h		;y=5
				db 'SL','P'+80h				;y=6
				db 'RSMI','X'+80h			;y=7

ed_x1_z7		db 'LD I,','A'+80h			;y=0
				db 'LD R,','A'+80h			;y=1
				db 'LD A,','I'+80h			;y=2
				db 'LD A,','R'+80h			;y=3
				db 'RR','D'+80h				;y=4
				db 'RL','D'+80h				;y=5
				db 'NO','P'+80h				;y=6
				db 'NO','P'+80h				;y=7


ed_x2_z0		db '?'+80h,'?'+80h,'?'+80h,'?'+80h		; y0-3
				db 'LDI&',80h							; y4
				db 'LDD&',80h							; y5
				db 'LDIR&',80h							; y6
				db 'LDDR&',80h							; y7

ed_x2_z1		db '?'+80h,'?'+80h,'?'+80h,'?'+80h		; y0-3
				db 'CPI&',80h							; y4
				db 'CPD&',80h							; y5
				db 'CPIR&',80h							; y6
				db 'CPDR&',80h							; y7

ed_x2_z2		db 'INIM&',80h		; y0	
				db 'INDM&',80h		; y1
				db 'INIMR&',80h		; y2
				db 'INDMR&',80h		; y3
				db 'INI&',80h		; y4
				db 'IND&',80h		; y5
				db 'INIR&',80h		; y6
				db 'INDR&',80h		; y7


ed_x2_z3		db 'OTIM&',80h		; y0
				db 'OTDM&',80h		; y1
				db 'OTIMR&',80h		; y2
				db 'OTDMR&',80h		; y3
				db 'OUTI&',80h		; y4
				db 'OUTD&',80h		; y5
				db 'OTIR&',80h		; y6
				db 'OTDR&',80h		; y7

ed_x2_z4		db 'INI2&',80h		; y0
				db 'IND2&',80h		; y1
				db 'INI2R&',80h		; y2
				db 'IND2R&',80h		; y3
				db 'OUTI2&',80h		; y4
				db 'OUTD2&',80h		; y5
				db 'OTI2R&',80h		; y6
				db 'OTD2R&',80h		; y7


ed_x3_z2		db 'INIRX&',80h 	; y0
				db 'INDRX&',80h		; y1

ed_x3_z3		db 'OTIRX&',80h		; y0
				db 'OTDRX&',80h		; y1
			

;--- DDCB or FDCB - Prefixed op-codes-------------------------------------------------------------------------------------


ddcb_fdcb_zn6	db 'LD& ~',var_z, ',%',var_y,' $',80h		;x = 0		(">" = show variable: single digit)
				db 'BIT& >',var_y,',$',80h					;x = 1
				db 'LD& ~',var_z,',RES& >',var_y,',$',80h	;x = 2     
				db 'LD& ~',var_z,',SET& >',var_y,',$',80h	;x = 3

ddcb_fdcb_z6	db '%',var_y,' $',80h					;x = 0
				db 'BIT& >',var_y,',$',80h				;x = 1
				db 'RES& >',var_y,',$',80h				;x = 2
				db 'SET& >',var_y,',$',80h				;x = 3

;------------------------------------------------------------------------------------------------------------------

bad_opcode	db '??','?'+80h

;------------------------------------------------------------------------------------------------------------------


table_r		db 'B'+80h, 'C'+80h, 'D'+80h, 'E'+80h, 'h',80h, 'l',80h, '$',80h, 'A'+80h

table_rp	db 'B','C'+80h, 'D','E'+80h, '_'+80h, 'S','P'+80h

table_rp2	db 'B','C'+80h, 'D','E'+80h, '_',+80h, 'A','F'+80h
	
table_cc	db 'N','Z'+80h, 'Z'+80h, 'N','C'+80h, 'C'+80h, 'P','O'+80h, 'P','E'+80h, 'P'+80h, 'M'+80h
	
table_alu	db 'ADD& A',','+80h, 'ADC& A',','+80h, 'SUB&',' '+80h, 'SBC A&',','+80h
			db 'AND&',' '+80h, 'XOR&',' '+80h, 'OR&',' '+80h, 'CP&',' '+80h
			
table_rot	db 'RLC&',80h, 'RRC&',80h, 'RL&',80h, 'RR&',80h
			db 'SLA&',80h, 'SRA&',80h, 'SLL&',80h, 'SRL&',80h
	
table_rp3	db 'B','C'+80h, 'D','E'+80h, 'H','L'+80h, 'I','X'+80h

table_rp4	db 'B','C'+80h, 'D','E'+80h, 'H','L'+80h, 'I','Y'+80h
			
table_rst	db '0','0'+80h
			db '0','8'+80h
			db '1','0'+80h
			db '1','8'+80h
			db '2','0'+80h
			db '2','8'+80h	
			db '3','0'+80h
			db '3','8'+80h			

;----------------------------------------------------------------------------------------------------

; "_" = HL, IX, IY depending on prefix 
; "|" = as above with IX/IY switched

; "h" = H, IXH, IYL depending on prefix
; "l" = L, IXL, IYL depending on prefix
; "$" = (HL), (IX+d), (IY+d) depending on prefix

hl_subs		db 'H','L'+80h, 'I','X'+80h, 'I','Y'+80h		
inv_hl_subs	db 'H','L'+80h, 'I','Y'+80h, 'I','X'+80h
h_subs		db 'H'+80h, 'IX','H'+80h, 'IY','H'+80h
l_subs		db 'L'+80h, 'IX','L'+80h, 'IY','L'+80h
ind_hl_subs	db '(HL',')'+80h, '(IX/',')'+80h, '(IY/',')'+80h	; / = signed byte following opcode

;----------------------------------------------------------------------------------------------------

adl_prefix_list

			db '.SI','S'+80h, '.LI','S'+80h, '.SI','L'+80h, '.LI','L'+80h

;-----------------------------------------------------------------------------------------------------

d_work_address	dw24 0

output_byte_txt	db "--",0
output_char_txt	db "-",0

dis_addr		dw24 10000h

;-----------------------------------------------------------------------------------------------------

