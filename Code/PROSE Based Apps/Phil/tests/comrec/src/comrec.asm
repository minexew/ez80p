
;test com port receiving bytes

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
			
wait_rx		ld a,kr_get_key
			call.lil prose_kernal
			cp 076h
			jr z,quit

			in0 a,(UART0_MSR)				;if /CTS has changed show it
			and 10h
			ld hl,cts_status
			cp (hl)
			jr z,no_cts_ch
			ld (hl),a
			ld hl,cts_pin_hi_txt			;bit in UART0_MSR is inverse of pin level
			or a
			jr z,show_cts
			ld hl,cts_pin_lo_txt
show_cts	ld a,kr_print_string
			call.lil prose_kernal
			
no_cts_ch	ld e,1
			ld a,kr_serial_rx_byte
			call.lil prose_kernal
			jr nz,wait_rx
			
			ld e,a
			ld hl,byte_rec
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			
			ld hl,rec_txt
			ld a,kr_print_string
			call.lil prose_kernal
			jr wait_rx
		
quit		xor a
			jp prose_return
			
;---------------------------------------------------------------------------------------------

thebyte		db "xx",11,0

cts_status	db 0	

cts_pin_lo_txt	db "CTS *pin* input is low (active)",11,0
cts_pin_hi_txt	db "CTS *pin* input is high (inactive)",11,0

app_txt		db "Displays bytes sent to serial port..",11,11,0

rec_txt	db "Received: $"
byte_rec	db "--",11,0

;---------------------------------------------------------------------------------------------
