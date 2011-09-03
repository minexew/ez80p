; Test path parse call
;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 39h				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'


;--------------------------------------------------------------------------------------
				
				ld hl,my_text
				ld a,kr_print_string
				call.lil prose_kernal

;				call test1
				
				call test2
				
				ld a,kr_print_string
				ld hl,new_line
				call.lil prose_kernal
				
				ld a,kr_get_dir_name
				call.lil prose_kernal
				ld a,kr_print_string
				call.lil prose_kernal
					
				xor a
				jp.lil prose_return				; back to OS


;--------------------------------------------------------------------------------------


test1			ld hl,my_path1					; hl = path to parse
				ld e,1							; e = 1, interpret as all directory names
				ld a,kr_parse_path
				call.lil prose_kernal
				ret
				
				
test2			ld hl,my_path2					; hl = path to parse
				ld e,0							; e = 0, last element is a filename
				ld a,kr_parse_path
				call.lil prose_kernal
				
				ld a,kr_print_string			; HL = filename part on return, just show it
				call.lil prose_kernal
				ret
				
				
;--------------------------------------------------------------------------------------

my_path1			db "vol0:games/chfight",0

my_path2			db "vol0:games/chfight/chfight.ezp",0

;-----------------------------------------------------------------------------------

my_text				db "path test..",0

new_line			db 11,0
