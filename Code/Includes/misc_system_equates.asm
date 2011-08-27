
;-- System Equates ---------------------------------------------------------------------

os_location		equ 0a00h

prose_return 	equ os_location + 14h
prose_relativize_hl	equ os_location + 18h
prose_relative_call	equ os_location + 1ch

prose_kernal 	equ os_location + 20h

;--------------------------------------------------------------------------------------

; Add to sprite locations to position a 0,0 sprite at the top/left pixel of the display

x_display_offset	equ 09ah
y_display_offset	equ 025h

;--------------------------------------------------------------------------------------