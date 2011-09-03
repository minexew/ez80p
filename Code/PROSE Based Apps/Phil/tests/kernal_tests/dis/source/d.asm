;---------------------------------------------------------------------------------------
;OS "D" Command: Z80 Disassembler v6.00
;---------------------------------------------------------------------------------------

os_cmd_d:

	ld de,$ffff
	ld (d_end_location),de	; default end address
		
	call ascii_to_hexword	; convert command line args to address in DE
	cp $c			; if A is $1f on return, use last address (no address)
	ret z			; if A is $c hex address given is bad	
	cp $1f
	jr nz,dvalidhex
	ld de,(memmonaddrl)		; last used address
	ld (d_start_location),de
	jr startdis

dvalidhex	ld (d_start_location),de
	call ascii_to_hexword
	cp $c
	ret z
	cp $1f
	jr z,startdis
	ld (d_end_location),de	; use specifed end location
	
startdis	xor a			; start disassembly listing
	ld (os_linecount),a

	ld ix,(d_start_location)
nxt_loc	ld (line_addr),ix
nxt_loc2	push ix
	pop bc
	ld hl,(d_end_location)
	xor a
	sbc hl,bc
	jr nc,not_end
disend:	ld (memmonaddrl),ix		;update "last at" address
	xor a
	ret


not_end	ld a,(ix)			;get op code
	cp $dd			;check for instruction prefixes
	jr z,do_dd		;no output for dd,ed,fd & cb
	cp $ed
	jr z,do_ed
	cp $fd
	jr z,do_fd
	cp $cb
	jr nz,no_prefix

do_cb	ld a,(cb_prefix)		;if CB already set, decode as a real opcode
	or a
	jr nz,no_prefix	
	ld a,1
	ld (cb_prefix),a
	ld a,(dd_prefix)
	or a
	jr nz,fdddcb
	ld a,(fd_prefix)
	or a
	jr z,pre_done
fdddcb:	inc ix			
	ld a,(ix)			;get disp part of op code
	ld (ixiy_disp),a
	ld a,1
	ld (fdddcb_prefix),a
	jr pre_done

do_dd	ld a,(cb_prefix)		;if CB prefix set, decode as a real opcode
	or a
	jr nz,no_prefix	
	ld a,1
	ld (dd_prefix),a
	jr pre_done

do_ed	ld a,(cb_prefix)		;if CB prefix set, decode as a real opcode
	or a
	jr nz,no_prefix	
	ld a,1
	ld (ed_prefix),a
	jr pre_done

do_fd	ld a,(cb_prefix)		;if CB prefix set, decode as a real opcode
	or a
	jr nz,no_prefix	
	ld a,1
	ld (fd_prefix),a

pre_done	inc ix
	jp nxt_loc2


no_prefix	ld a,(ix)	
	and %11000000		;decode op code into x,y,z,p & q vars
	rlca
	rlca
	ld (var_x),a
	ld a,(ix)
	and %00111000
	ld (var_yx8),a
	srl a
	srl a
	srl a	
	ld (var_y),a
	sub 4
	ld (var_y_4),a
	ld a,(ix)
	and %00000111
	ld (var_z),a
	ld a,(ix)
	and %00110000
	srl a
	srl a
	srl a
	srl a
	ld (var_p),a
	ld a,(ix)
	and %00001000
	srl a
	srl a
	srl a
	ld (var_q),a
	ld b,0
	ld a,(var_y)
	cp 6
	jr nz,ynot6
	ld b,1
ynot6	ld a,b
	ld (var_y6),a
	ld b,0
	ld a,(var_y)
	cp 1
	jr nz,ynot1
	ld b,1
ynot1	ld a,b
	ld (var_y1),a
	
	
	ld a,(var_x)		;get address of x / z opcode group
	sla a
	sla a
	sla a
	sla a			;x * 16
	ld c,a
	ld b,0
	push bc
	ld a,(var_z)		;z * 2
	sla a
	add a,c
	ld b,0
	ld c,a
	ld hl,x0_zlist		;start of op lists
	ld a,(cb_prefix)
	or a
	jr z,notcb1
	ld hl,cb_x0_zl
notcb1	ld a,(ed_prefix)
	or a
	jr z,noted1
	ld hl,ed_x0_zl
noted1	add hl,bc
	ld e,(hl)			
	inc hl
	ld d,(hl)			;de = loc of op code ascii, to x / z resolution

	pop bc			;retrieve x * 16
	ld a,(var_z)		
	add a,c
	ld c,a			;add z
	ld hl,x0_vlist1
	ld a,(cb_prefix)
	or a
	jr z,notcb2
	ld hl,cb_x0_vl1
notcb2	ld a,(ed_prefix)
	or a
	jr z,noted2
	ld hl,ed_x0_vl1
noted2	add hl,bc			
	ld b,h
	ld c,l			;bc = loc of vlist1 entry 	


	ld a,(bc)
	or a
	jr z,got_opascii		;if contains 0 = no op list offsets
	
	ld hl,var_x		;get addr of selected opcode modifier in HL
	add a,l
	jr nc,noc_1
	inc h
noc_1	ld l,a			;hl = what var to use as step
	ld a,(hl)
	or a
	jr z,got_opascii		;ignore part 2 if 1st mod value is zero
	ld l,a			;l = number of steps part 1
	push hl
	
	ld a,c			;move BC to vlist2 entry
	add a,8
	jr nc,noc_2
	inc b
noc_2	ld c,a
	ld a,(bc)			;bc = address of 2nd modifier
	or a
	jr z,skpt2
	ld hl,var_x		;list of vars
	add a,l
	jr nc,noc_3
	inc h
noc_3	ld l,a
	ld a,(hl)			;a = value in selected var
skpt2	pop hl
	add a,l			;a = total number of op codes ascii entries to skip
	
	or a			;any op-code modifiers?
	jr z,got_opascii
	
	ld b,a			;step through op codes in group to arrive
fnd_nxt	inc de
	ld a,(de)			;at the correct one
	or a
	jr nz,fnd_nxt
got_nxt	djnz fnd_nxt
	inc de			;modified op code address
	


got_opascii

	
	ld hl,output_line		;create opcode line
	ex de,hl			;de = output line dest, hl = op ascii src
	ld a,"<"			;"<" means assembly output
	ld (de),a		
	inc de
	ld a," "
	ld (de),a
	inc de
	ld bc,(line_addr)
	ld a,b			;pc address high
	call hex_2_asc
	ld a,c			;pc address low
	call hex_2_asc
	ld a," "			;leave a space before op code
	ld (de),a
	inc de
		

copy_op	ld a,(hl)			;write out actual opcode
	or a			;ascii is zero terminated
	jp z,end_of_op

	cp "n"			;substitute 8 bit abs value for part of op code?
	jr nz,not8abs
	ld a,"$"
	ld (de),a
	inc de
	inc ix
	ld a,(ix)
	call hex_2_asc	
	jp nxt_chr2	
	
not8abs	cp "m"			;substitute 16 bit abs value for part of op code?
	jr nz,not16abs
	ld a,"$"
	ld (de),a
	inc de
	ld a,(ix+2)
	call hex_2_asc	
	ld a,(ix+1)
	call hex_2_asc
	inc ix
	inc ix
	jp nxt_chr2
	
not16abs	cp "b"			;show a single digit character from
	jr nz,notsingd		;following var, no "$" prefix
	inc hl
	ld a,(hl)
	sub $30
	ld bc,var_x
	add a,c
	jr nc,noc_9
	inc b
noc_9	ld c,a
	ld a,(bc)
	call hex_2_asc
	dec de
	ld a,(de)
	dec de
	ld (de),a
	inc de
	ld a," "
	ld (de),a
	jp nxt_chr2
	
notsingd	cp "d"			;substitute displacement for part of op code?
	jr nz,not8disp		;insert calculated 16 bit value
	ld a,"$"
	ld (de),a
	inc de
	ld a,(ix+1)
	inc ix
	push hl
	push ix
	pop hl
	inc hl
	ld c,a
	ld b,0
	bit 7,c
	jr z,disppos
	ld b,255
disppos:	add hl,bc
	ld a,h
	call hex_2_asc
	ld a,l
	call hex_2_asc
	pop hl
	jp nxt_chr2

not8disp	cp "t"			;substitute table data for part of op code?
	jr nz,notabtrans
	push de
	inc hl
	ld a,(hl)
	sub $30			
	sla a			;get table number * 2 in A
	inc hl			;skip "i" ascii
	inc hl
	ld e,(hl)			;get indexing var in e
	inc hl
	push hl
	
	ld bc,tables		;add table number * 2 to start of address list
	add a,c
	jr nc,noc_6
	inc b
noc_6	ld c,a
	ld a,(bc)
	ld l,a
	inc bc
	ld a,(bc)
	ld h,a			;hl = location of required table
	
	ld bc,var_x		
	ld a,e
	sub $30
	add a,c
	jr nc,noc_7
	inc b
noc_7	ld c,a
	ld a,(bc)			;get indexing variable in a
	or a
	jr z,nttst

	ld b,a			;step through table entries based on index			
fnd_nxt2	inc hl
	ld a,(hl)			
	or a
	jr nz,fnd_nxt2
got_nxt2	djnz fnd_nxt2
	inc hl

nttst	ld b,h
	ld c,l			;BC = address of opcode
	pop hl
	pop de
nttstlp	ld a,(bc)
	or a
	jp z,copy_op
	call hl_sub_check
	ld (de),a
	inc bc
	inc de
	jr nttstlp
	

notabtrans
	
	cp $30			;output the number in var specified
	jr c,nolitvarnum
	cp $3a
	jr nc,nolitvarnum
	sub $30
	ld bc,var_x
	add a,c
	jr nc,noc_5
	inc b
noc_5	ld c,a
	ld a,"$"
	ld (de),a
	inc de
	ld a,(bc)
	call hex_2_asc
	jr nxt_chr2
	
nolitvarnum

copyasc	call hl_sub_check
	ld (de),a
nxt_chr	inc de
nxt_chr2	inc hl
	jp copy_op
	

end_of_op	xor a
	ld (cb_prefix),a
	ld (dd_prefix),a
	ld (ed_prefix),a
	ld (fd_prefix),a
	ld (fdddcb_prefix),a

	ld a,11
	ld (de),a
	inc de
	xor a
	ld (de),a
	call os_print_output_line
	call os_count_lines
	ld a,"y"
	cp b
	jp nz,disend
	
	inc ix
	jp nxt_loc

;--------------------------------------------------------------------------------------------


hex_2_asc	push hl
	push de
	ex de,hl
	call hexbyte_to_ascii
	pop de
	pop hl
	inc de
	inc de
	ret
	

;---------------------------------------------------------------------------------------------


hl_sub_check

	cp "*"			;is character the token for "HL"?
	jr z,hlabs
	cp "!"
	jr z,hlind		;is character the token for "(HL)"?
	ret
	
hlabs	push hl
	ld hl,hl_abs		;by default (no prefix) use "HL"
	ld a,(dd_prefix)
	or a
	jr z,notaix
	ld hl,ix_abs		;if $dd prefix is set, show "IX" intead of "HL"
notaix	ld a,(fd_prefix)
	or a
	jr z,notaiy
	ld hl,iy_abs		;if $fd prefix is set, show "IX" intead of "HL"
notaiy	ld a,(hl)
	ld (de),a			;copy chars to output line
	inc hl
	inc de
	ld a,(hl)			;last character placed in on return
	pop hl
	ret


hlind	push bc			;handle indirect "(HL)" substitution
	push hl
	ld a,(dd_prefix)
	or a
	jr z,notddixi
	ld hl,ix_ind		;if $dd prefix is set, show "(IX+$xx)" intead of "HL"
	jr ixiyi	
	
notddixi	ld a,(fd_prefix)
	or a
	jr nz,fdiyi
	ld hl,hl_ind		;no subsitution: show "(HL)"
	ld bc,3
	ldir
	pop hl
	pop bc
	ld a,")"			;last character placed in on return
	ret
	
fdiyi	ld hl,iy_ind		;if $dd prefix is set, show "(IX+$xx)" intead of "HL"
ixiyi	ld bc,5	
	ldir			;copy first 5 characters
	
	ld a,(fdddcb_prefix)	;is this a $fdcb or $ddcb prefixed instruction?
	or a
	jr z,dfromop
	ld a,(ixiy_disp)		;if so, show the displacement byte stored at start
	jr gotdisp		
dfromop	inc ix			;otherwise, get displacement from next byte in memory
	ld a,(ix)
gotdisp	call hex_2_asc
	ld a,")"			;last character placed in on return
	pop hl
	pop bc
	ret
	

;=================================================================================================
; DATA FOR COMMAND
;=================================================================================================

d_start_location	dw $8000
d_end_location	dw $8010

line_addr		dw 0

;---------------------------------------------------------------------------------------------

cb_prefix		db 0
dd_prefix 	db 0
ed_prefix 	db 0
fd_prefix 	db 0
fdddcb_prefix	db 0

ixiy_disp		db 0

;---------------------------------------------------------------------------------------------

var_x	db 0 	;0 
var_y	db 0	;1 
var_z	db 0 	;2 
var_p	db 0 	;3 
var_q	db 0 	;4 
var_y_4	db 0 	;5
var_yx8	db 0	;6
var_y6	db 0	;7
var_y1	db 0	;8
	
;-------------------------------------------------------------------------------------------

;* = "HL"
;! = "(HL)"

hl_abs	db "HL"
ix_abs	db "IX"
iy_abs	db "IY"

hl_ind	db "(HL)"
ix_ind	db "(IX+$"
iy_ind	db "(IY+$"


tables	dw tab_r,tab_rp,tab_rp2,tab_cc,tab_alu,tab_rot,tab_im


tab_r	db "B",0, "C",0, "D",0, "E",0, "H",0, "L",0, "!",0, "A",0		;0

tab_rp	db "BC",0,"DE",0,"*",0,"SP",0					;1
	
tab_rp2	db "BC",0,"DE",0,"*",0,"AF",0					;2
	
tab_cc	db "NZ",0, "Z",0, "NC",0, "C",0, "PO",0, "PE",0, "P",0, "M",0			;3
	
tab_alu	db "ADD A,",0, "ADC A,",0, "SUB ",0, "SBC A,",0, "AND ",0, "XOR ",0, "OR ",0, "CP ",0 ;4
	
tab_rot	db "RLC",0, "RRC",0, "RL",0, "RR",0, "SLA",0, "SRA",0, "SLL",0, "SRL",0	;5
	
tab_im	db "0",0, "0/1",0, "1",0, "2",0, "0",0, "0/1",0, "1",0, "2",0		;6
	

;-------------------------------------------------------------------------------------------


x0_zlist	dw x0_z0_y0, x0_z1_q0, x0_z2_y0, x0_z3_q0, x0_z4, x0_z5, x0_z6, x0_z7_y0
x1_zlist	dw x1,x1,x1,x1,x1,x1,x1_z6,x1
x2_zlist	dw x2,x2,x2,x2,x2,x2,x2,x2
x3_zlist	dw x3_z0, x3_z1_q0, x3_z2, x3_z3_y0, x3_z4, x3_z5_q0, x3_z6, x3_z7

cb_x0_zl	dw cb_x0, cb_x0, cb_x0, cb_x0, cb_x0, cb_x0, cb_x0, cb_x0
cb_x1_zl	dw cb_x1, cb_x1, cb_x1, cb_x1, cb_x1, cb_x1, cb_x1, cb_x1
cb_x2_zl	dw cb_x2, cb_x2, cb_x2, cb_x2, cb_x2, cb_x2, cb_x2, cb_x2
cb_x3_zl	dw cb_x3, cb_x3, cb_x3, cb_x3, cb_x3, cb_x3, cb_x3, cb_x3

ed_x0_zl	dw ed_x0, ed_x0, ed_x0, ed_x0, ed_x0, ed_x0, ed_x0, ed_x0
ed_x1_zl	dw ed_x1_z0_yn6, ed_x1_z1_yn6, ed_x1_z2_q0, ed_x1_z3_q0, ed_x1_z4, ed_x1_z5_yn1, ed_x1_z6, ed_x1_z7_y0
ed_x2_zl	dw ed_x2_z0_y4, ed_x2_z1_y4, ed_x2_z2_y4, ed_x2_z3_y4, badop, badop, badop, badop
ed_x3_zl	dw ed_x3, ed_x3, ed_x3, ed_x3, ed_x3, ed_x3, ed_x3, ed_x3


x0_vlist1	db 1, 4, 1, 4, 0, 0, 0, 1	;opcode list modifier selection: 1="y", 2="z", 3="p" 
x0_vlist2	db 0, 0, 0, 0, 0, 0, 0, 0	;4="q", 5="y-4", 6="y*8", 7="y=6", 8="y=1"

x1_vlist1	db 0, 0, 0, 0, 0, 0, 7, 0
x1_vlist2	db 0, 0, 0, 0, 0, 0, 0, 0

x2_vlist1	db 0, 0, 0, 0, 0, 0, 0, 0
x2_vlist2	db 0, 0, 0, 0, 0, 0, 0, 0

x3_vlist1	db 0, 4, 0, 1, 0, 4, 0, 0
x3_vlist2	db 0, 3, 0, 0, 0, 3, 0, 0


cb_x0_vl1	db 0,0,0,0,0,0,0,0
cb_x0_vl2	db 0,0,0,0,0,0,0,0

cb_x1_vl1	db 0,0,0,0,0,0,0,0
cb_x1_vl2	db 0,0,0,0,0,0,0,0

cb_x2_vl1	db 0,0,0,0,0,0,0,0
cb_x2_vl2	db 0,0,0,0,0,0,0,0

cb_x3_vl1	db 0,0,0,0,0,0,0,0
cb_x3_vl2	db 0,0,0,0,0,0,0,0


ed_x0_vl1	db 0, 0, 0, 0, 0, 0, 0, 0
ed_x0_vl2	db 0, 0, 0, 0, 0, 0, 0, 0

ed_x1_vl1	db 7, 7, 4, 4, 0, 8, 0, 1
ed_x1_vl2	db 0, 0, 0, 0, 0, 0, 0, 0

ed_x2_vl1	db 5, 5, 5, 5, 0, 0, 0, 0
ed_x2_vl2	db 0, 0, 0, 0 ,0, 0, 0, 0

ed_x3_vl1	db 0, 0, 0, 0, 0, 0, 0, 0
ed_x3_vl2	db 0, 0, 0, 0, 0, 0, 0 ,0

;-------------------------------------------------------------------------------------------

	
x0_z0_y0	db "NOP",0
x0_z0_y1	db "EX AF,AF",$27,0
x0_z0_y2	db "DJNZ d",0
x0_z0_y3	db "JR d",0		;d = 8 bit displacement
x0_z0_y4	db "JR t3i5,d",0		;"t"able n, "i"ndexed by reg m
x0_z0_y5	db "JR t3i5,d",0		;
x0_z0_y6	db "JR t3i5,d",0		;
x0_z0_y7	db "JR t3i5,d",0		;

x0_z1_q0	db "LD t1i3,m",0		;"m" = 16 bit absolute
x0_z1_q1	db "ADD *,t1i3",0

x0_z2_y0	db "LD (BC),A",0
x0_z2_y1	db "LD A,(BC)",0
x0_z2_y2	db "LD (DE),A",0
x0_z2_y3	db "LD A,(DE)",0
x0_z2_y4	db "LD (m),*",0
x0_z2_y5	db "LD *,(m)",0
x0_z2_y6	db "LD (m),A",0
x0_z2_y7	db "LD A,(m)",0

x0_z3_q0	db "INC t1i3",0
x0_z3_q1	db "DEC t1i3",0

x0_z4	db "INC t0i1",0

x0_z5	db "DEC t0i1",0

x0_z6	db "LD t0i1,n",0		;"n" = 8 bit absolute

x0_z7_y0	db "RLCA",0
x0_z7_y1	db "RRCA",0
x0_z7_y2	db "RLA",0
x0_z7_y3	db "RRA",0
x0_z7_y4	db "DAA",0
x0_z7_y5	db "CPL",0
x0_z7_y6	db "SCF",0
x0_z7_y7	db "CCF",0

;-------------------------------------------------------------------------------------------

x1	db "LD t0i1,t0i2",0
x1_z6	db "LD t0i1,t0i2",0,"HALT",0

;-------------------------------------------------------------------------------------------

x2	db "t4i1t0i2",0

;-------------------------------------------------------------------------------------------

x3_z0		db "RET t3i1",0

x3_z1_q0		db "POP t2i3",0

x3_z1_q1_p0 	db "RET",0
x3_z1_q1_p1	db "EXX",0
x3_z1_q1_p2 	db "JP *",0
x3_z1_q1_p3 	db "LD SP,*",0		

x3_z2		db "JP t3i1,m",0

x3_z3_y0		db "JP m",0
x3_z3_y1		db "CB prefix",0
x3_z3_y2		db "OUT (n),A",0
x3_z3_y3		db "IN A,(n)",0
x3_z3_y4		db "EX (SP),*",0
x3_z3_y5		db "EX DE,HL",0
x3_z3_y6		db "DI",0
x3_z3_y7		db "EI",0

x3_z4		db "CALL t3i1,m",0

x3_z5_q0		db "PUSH t2i3",0		;Q=0
		
x3_z5_q1_p0	db "CALL m",0
x3_z5_q1_p1	db "DD prefix",0
x3_z5_q1_p2	db "ED prefix",0
x3_z5_q1_p3	db" FD prefix",0	

x3_z6		db "t4i1n",0

x3_z7		db "RST 6",0

;-------------------------------------------------------------------------------------------
;CB - Prefixed op-codes

cb_x0		db "t5i1 t0i2",0

cb_x1		db "BIT b1,t0i2",0		;b = single digit from following var

cb_x2		db "RES b1,t0i2",0

cb_x3		db "SET b1,t0i2",0

;---------------------------------------------------------------------------------------------
;ED - Prefixed op-codes

ed_x0		db "???",0

ed_x1_z0_yn6	db "IN t0i1,(C)",0
ed_x1_z0_y6	db "IN (C)",0

ed_x1_z1_yn6	db "OUT (C),t0i1",0
ed_x1_z1_y6	db "OUT (C)",0

ed_x1_z2_q0	db "SBC HL,t1i3",0
ed_x1_z2_q1	db "ADC HL,t1i3",0

ed_x1_z3_q0	db "LD (m),t1i3",0
ed_x1_z3_q1	db "LD t1i3,(m)",0

ed_x1_z4		db "NEG",0

ed_x1_z5_yn1	db "RETN",0
ed_x1_z5_y1	db "RETI",0
	
ed_x1_z6		db "IM t6i1",0

ed_x1_z7_y0	db "LD I,A",0
ed_x1_z7_y1	db "LD R,A",0
ed_x1_z7_y2	db "LD A,I",0
ed_x1_z7_y3	db "LD I,A",0
ed_x1_z7_y4	db "RRD",0
ed_x1_z7_y5	db "RLD",0
ed_x1_z7_y6	db "NOP",0
ed_x1_z7_y7	db "NOP",0

ed_x2_z0_y4	db "LDI",0, "LDD",0, "LDIR",0, "LDDR",0	
ed_x2_z1_y4	db "CPI",0, "CPD",0, "CPIR",0, "CPDR",0	
ed_x2_z2_y4	db "INI",0, "IND",0, "INIR",0, "INDR",0	
ed_x2_z3_y4	db "OUTI",0, "OUTD",0, "OTIR",0, "OTDR",0

ed_x3		db "???",0

badop		db "???",0

;-------------------------------------------------------------------------------------------
