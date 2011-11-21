; Simple memory test - tests entire VRAM A and VRAM B, but only tests
; the free system RAM (approx 11000h-7FC00h)

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 21h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,app_msg
			prose_call kr_print_string

mt_loop		ld hl,sysram_txt
			prose_call kr_print_string	
			
			prose_call kr_get_ram_top		;Get top of sysram in HL
			ld bc,free_mem					;IE: last address used by this program.
			xor a
			sbc hl,bc
			push hl
			pop bc
			ld hl,free_mem
			call test_mem
			jp nz,fail
			
			ld hl,vrama_txt
			prose_call kr_print_string	
			call save_vram
			ld hl,vram_a_addr
			ld bc,80000h
			call test_mem
			push af
			call restore_vram
			pop af
			jp nz,fail
			
			ld hl,vramb_txt
			prose_call kr_print_string
			ld hl,vram_b_addr
			ld bc,80000h
			call test_mem
			jp nz,fail
			
			ld a,(passes)
			inc a
			ld (passes),a
			ld hl,pass_count_txt
			ld e,a
			prose_call kr_hex_byte_to_ascii
			ld hl,passes_txt
			prose_call kr_print_string
			
			jp mt_loop

;---------------------------------------------------------------------------------------------

fail		ld hl,fail_txt
			prose_call kr_print_string
stop_here	jp stop_here
			
;---------------------------------------------------------------------------------------------

save_vram	ld hl,vram_a_addr				;crudely, save first 64KB of VRAM to SysRAM
			ld bc,10000h					;(font and charmap)
			ld de,free_mem
			ldir
			ret
			
restore_vram
	
			ld hl,free_mem					;restore VRAM from sysRAM
			ld bc,10000h
			ld de,vram_a_addr
			ldir
			ret

;---------------------------------------------------------------------------------------------

test_mem
			ld e,0									; fill ram tests
			call fill_test
			ret nz
			ld e,255
			call fill_test
			ret nz
			ld e,1h
			call fill_test
			ret nz
			ld e,2h
			call fill_test
			ret nz
			ld e,4h
			call fill_test
			ret nz
			ld e,8h
			call fill_test
			ret nz
			ld e,10h
			call fill_test
			ret nz
			ld e,20h
			call fill_test
			ret nz
			ld e,40h
			call fill_test
			ret nz
			ld e,80h
			call fill_test
			ret nz
			

			ld de,(my_seed)
			ld (seed),de
			push hl
			push bc
rt1			call rand16								;random byte test
			ld a,(seed+1)
			ld (hl),a
			cpi
			jp pe,rt1
			pop bc
			pop hl

			ld de,(my_seed)
			ld (seed),de
rt2			call rand16
			ld a,(seed+1)
			cpi
			ret nz
			jp pe,rt2
			
			ld de,(seed)
			ld (my_seed),de
			xor a
			ret
			
;---------------------------------------------------------------------------------------------
			
			
fill_test	push hl
			push bc
mt1			ld (hl),e
			cpi								;use CPI to inc HL / dec BC and test for BC = 0
			jp pe,mt1
			pop bc
			pop hl
			
			push hl
			push bc
			ld a,e
mt2			cpi
			jr nz,bad
			jp pe,mt2
			xor a
bad			pop bc
			pop hl
			ret
			

;---------------------------------------------------------------------------------------------


rand16		push hl
			ld	de,(seed)		
			ld	a,d
			ld	h,e
			ld	l,253
			or	a
			sbc	hl,de
			sbc	a,0
			sbc	hl,de
			ld	d,0
			sbc	a,d
			ld	e,a
			sbc	hl,de
			jr	nc,rand
			inc	hl
rand		ld	(seed),hl		
			pop hl
			ret
	
;---------------------------------------------------------------------------------------------

app_msg			db 11,"Memory test v0.02",11
				db "-----------------",11,11
				db "Notes:",11,11
				db "* Garbage will appear on screen whilst VRAM A is tested.",11
				db "* A system reset is required to quit this program.",11,11,0
				
sysram_txt		db "Testing (free) System RAM..",11,0
vrama_txt		db "OK, Testing VRAM A..",11,0
vramb_txt		db "OK, Testing VRAM B..",11,0

passes_txt		db 11,"OK, Pass count: $"
pass_count_txt	db "xx",11,11,11,0

fail_txt		db "Failed!",11,0

my_seed			dw24 123456h
seed			dw24 0

passes			db 0

free_mem		db 0		; dont put anything beyond this address

;---------------------------------------------------------------------------------------------
