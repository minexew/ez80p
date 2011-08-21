
;--- EZ80 Internal CPU Ports --------------------------------------------------------------------


include "ez80_cpu_equates.asm"


include "amoeba_hardware_equates.asm"


include "prose_kernal_labels.asm"


include "misc_system_equates.asm"


;---------------------------------------------------------------------------------------------------------------------------
; Standard PROSE executable header
;--------------------------------------------------------------------------------------------------------------------------


	IF ADL_mode = 0
		org load_location&0ffffh	; if Z80 mode program, CODE origin is a Z80 address (within 64KB page)
	ELSE
		org load_location			; otherwise origin is anywhere in system RAM
	ENDIF
	
		.assume ADL = 1				; All PROSE-launched programs START in ADL mode

		jr skip_header				; $0 - Jump over header
		db 'PRO'					; $2 - ASCII "PRO" = PROSE executable program ID
mb_loc	dw24 load_location			; $5 - Desired Load location (24 bit) 
		dw24 0						; $8 - If > 0, truncate load 
		dw prose_version_req		; $B - If > 0, minimum PROSE version requird
		dw amoeba_version_req		; $D - If > 0, minimum AMOEBA version required
		db ADL_mode					; $F - Z80 (0) or ADL mode (1) program.

skip_header
	
	IF ADL_mode = 0 
		
mbase_offset equ load_location & 0ff0000h

		ld a,load_location/65536	; Additional set up code for Z80 mode programs
		ld MB,a						; Set MBASE register (necessary for Z80-mode apps)
		jp.sis go_z80_mode			; switches off ADL mode for this app

go_z80_mode

		.assume ADL = 0

	ENDIF
	
;------------------------------------------------------------------------------------------------------------------------
	