
; test relative code

;------------------------------------------------------------------------------------------------------------------------

include "ez80_cpu_equates.asm"
include "amoeba_hardware_equates.asm"
include "prose_kernal_labels.asm"
include "misc_system_equates.asm"


		.assume ADL = 1					; All PROSE-launched programs START in ADL mode

;-------------------------------------------------------------------------------------------
; MACROS assisting with relative code:
;-------------------------------------------------------------------------------------------
;
; "LD_HL_RELATIVE" - Relative location pointer in HL
;
; "JP_HL_RELATIVE" - relative version of JP (HL)
;
; "CALL_HL_RELATIVE" - allows absolute relative CALLs 
;
;-------------------------------------------------------------------------------------------

LD_HL_RELATIVE : MACRO abs_hl_loc
	
$$addr	ld hl,abs_hl_loc-$$addr			;these two instructions MUST be as shown
		call prose_relativize_hl		;do not seperate - PROSE relies on it 

ENDMACRO


JP_HL_RELATIVE : MACRO abs_jp_loc

$$jaddr	ld hl,abs_jp_loc-$$jaddr		;these two instructions MUST be as shown
		call prose_relativize_hl		;do not seperate - PROSE relies on it 	
		jp (hl)

ENDMACRO


CALL_HL_RELATIVE : MACRO abs_call_loc
	
$$caddr	ld hl,abs_call_loc-$$caddr		;these two instructions MUST be as shown
		call prose_relative_call		;do not seperate - PROSE relies on it 
				
ENDMACRO

;----------------------------------------------------------------------------------------------
; Relative code - Remember:
; Cannot use JP for jumps unless "relativized" JP (HL) etc
; Absolute labels must be adjusted with "prose_relativize_hl" etc!
; CALLs must be indirect (set HL to address, call prose_relative_call)
;----------------------------------------------------------------------------------------------

native_location equ 020000h				; this is pretty much irrelevent

			org native_location
						
;----------------------------------------------------------------------------------------

			LD_HL_RELATIVE msg1
			ld a,kr_print_string
			call.lil prose_kernal	
			
			CALL_HL_RELATIVE some_routine
			
			JP_HL_RELATIVE cobblers
			
endloop		jp endloop
			

cobblers	LD_HL_RELATIVE msg2
			ld a,kr_print_string
			call.lil prose_kernal	
	
			xor a
			jp.lil prose_return

;---------------------------------------------------------------------------------------

some_routine

			ld a,0f8h
			ld (hw_palette),a
			ld bc,0
lp1			dec bc
			ld a,b
			or c
			jr nz,lp1
			ld a,0h
			ld (hw_palette),a
			ret
			

;----------------------------------------------------------------------------------------------

msg1		db "Relocatable code!",11,0

msg2		db "Relocatable code - the revenge!",11,0

;----------------------------------------------------------------------------------------------
