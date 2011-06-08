;-----------------------------------------------------------------------
;">" for write ascii bytes to memory command. V0.02 - ADL
;-----------------------------------------------------------------------

os_cmd_gtr

				call hexword_or_bust					;the call only returns here if the hex in xDE is valid
				jp z,os_no_start_addr
fndquot1		inc hl
				ld a,(hl)
				or a
				jp z,os_no_args_error
				cp 022h									;find first quote
				jr nz,fndquot1
				inc hl
				push hl
fndquot2		ld a,(hl)
				inc hl
				or a
				jr z,noquot2
				cp 022h									;find second quote
				jr nz,fndquot2
				pop hl
					
wmbalp			ld a,(hl)								;copy chars from line to RAM
				cp 022h
				jr z,os_gtrdn							;ends when encounters another quote
				cp 07dh
				jr z,skpnasc
				ld (de),a
skpnasc			inc de
				inc hl
				jr wmbalp
os_gtrdn		xor a
				ret	
				
noquot2			pop hl									;no second quote - bad args
				ld a,012h
				or a
				ret

;-----------------------------------------------------------------------
