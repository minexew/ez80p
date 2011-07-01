
;test com port sending keypresses

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

			ld hl,app_txt
			ld a,kr_print_string
			call.lil prose_kernal
			
sendloop	ld a,kr_wait_key
			call.lil prose_kernal
			cp 076h
			jr z,quit
			
			cp 05h									;f1 to toggle RTS line
			jr nz,not_f1
			ld a,(rts_status)
			xor 2
			ld (rts_status),a	
			out0 (UART0_MCTL),a						;RTS *pin* is inverse of bit written to UART0_MCTL [2]
			ld hl,rts_pin_hi_txt	
			or a
			jr z,show_rts
			ld hl,rts_pin_low_txt
show_rts	ld a,kr_print_string
			call.lil prose_kernal
			jr sendloop
			
not_f1		ld a,b
			ld (char),a
			ld hl,sent_txt
			ld a,kr_print_string
			call.lil prose_kernal
			
			ld a,(char)
			ld e,a
			ld a,kr_serial_tx_byte
			call.lil prose_kernal
			jr sendloop
			
quit		xor a
			jp prose_return
			
;---------------------------------------------------------------------------------------------

rts_status			db 0

rts_pin_low_txt		db "/RTS *pin* output set low (active)",11,0
rts_pin_hi_txt		db "/RTS *pin* output set high (inactive)",11,0

app_txt				db "Sends keypresses to serial port..",11
					db "(F1 to toggle /RTS)",11,0
			
sent_txt			db "Sent: "
char				db "-",11,0

;---------------------------------------------------------------------------------------------
