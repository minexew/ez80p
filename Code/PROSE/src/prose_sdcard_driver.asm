;--------------------------------------------------------------------------------------------------
; Z80 MMC/SDC card access routines - Phil Ruston 2008-2010 V1.06 (ADL mode)
;--------------------------------------------------------------------------------------------------
;
; Limitations:
; ------------
; Currently does not support V2.0 SD cards (IE: SDHC large capacity cards > 2GB)
; Does not check for voltage compatibility or block size
; Somewhat arbitary timimg..
;
;--------------------------------------------------------------------------------------------------

; Key Routines:      Input Registers             Output Registers
; -------------      ---------------             ----------------
; sdc_get_id			no arguments required      	BC:DE = Capacity in sectors, HL = ID ASCII string, A = error code
; sdc_read_sector		sector_LBA0-3				Carry Flag / A = error code
; sdc_write_sector		sector_LBA0-3    			Carry Flag / A = error code
;
; (Assume all other registers are trashed.)
;
; Routines respond with Carry flag set if operation was OK, else A =

sdc_error_spi_mode_failed			equ 0
sdc_error_bad_init_mmc				equ 1
sdc_error_bad_init					equ 2
sdc_error_bad_id					equ 3
sdc_error_bad_command_response		equ 4
sdc_error_data_token_timeout		equ 5
sdc_error_write_timeout				equ 6
sdc_error_write_failed				equ 7

; Variables required:
; -------------------
;
; "sector_buffer" - 512 bytes
;
; "sector_lba0" - LBA of desired sector LSB
; "sector_lba1" 
; "sector_lba2"
; "sector_lba3" - LBA of desired sector MSB
;
; "sdc_sdc" - 1 byte (0 = card is MMC, 1 = card is SD)


;-------------------------------------------------------------------------------------------------
; PROSE STANDARD DRIVER HEADER
;-------------------------------------------------------------------------------------------------

sd_card_driver				; label of driver code

	jp sdc_get_id			; $00 : init / get hardware ID routine
	jp sdc_read_sector		; $04 : jump to read sector routine
	jp sdc_write_sector		; $08 : jump to write sector routine
	db "SD_CARD",0			; $0c : desired ASCII name of device type						

;--------------------------------------------------------------------------------------------------
; Hardware agnostic section..
;--------------------------------------------------------------------------------------------------

sdc_get_id


; Initializes card, reads CSD and CID into sector buffer and creates string
; containing ASCII device ID. Returns device capacity (number of 512 byte sectors) 

; Returns:
; --------
;   HL = Pointer to device ID string 
; C:DE = Capacity (number of sectors)


				ld a,1								; Assume card is SD type at start
				ld (sdc_sdc),a			

				call sdc_power_off					; Switch off power to the card
				call sdc_slow_clock					; Use slow clock rate
				call sdc_select_card				; 

				ld de,16384							; wait 0.5 seconds
				call hwsc_time_delay
				
				call sdc_power_on					; Switch card power on

				ld de,131							; wait approx 4ms
				call hwsc_time_delay

				call sdc_deselect_card				; Set Card's /CS line inactive (high)
	
				ld b,10								; send 80 clocks to ensure card has stabilized
sdc_ecilp		call sdc_send_eight_clocks
				djnz sdc_ecilp
	
				call sdc_select_card				; Set Card's /CS line active (low)
	
				ld a,040h							; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
				ld bc,09500h						; When /CS is low on receipt of CMD0, card enters SPI mode 
				ld de,00000h
				call sdc_send_command		 
				call sdc_get_byte					; skip nCR
				call sdc_wait_ncr					; wait for valid response..			
				xor 01h								; command response should be $01 ("In idle mode")
				jp nz,init_spi_mode_fail		


				ld bc,8000							; Send SD card init command ACMD41, if illegal try MMC card init
sdc_iwl			push bc								;
				ld a,077h							; CMD55 ($77 00 00 00 00 01) 
				call sdc_send_command_null_args
				call sdc_get_byte					; NCR
				call sdc_get_byte					; Command response
				ld a,069h							; ACMD41 ($69 00 00 00 00 01)
				call sdc_send_command_null_args		
				call sdc_get_byte
				pop bc
				call sdc_wait_ncr					; wait for valid response..	
				bit 2,a								; check bit 2, if set = illegal command
				jr nz,mmc_init			
				or a
				jr z,sdc_init_done					; when response is $00, card is ready for use
				dec bc
				ld a,b
				or c
				jr nz,sdc_iwl
				jp sdc_init_fail


mmc_init		xor a								; try MMC card init command
				ld (sdc_sdc),a
				ld bc,8000							; Send MMC card init and wait for card to initialize
mmc_iwl			push bc
				ld a,041h							; send CMD1 ($41 00 00 00 00 01) to test this
				call sdc_send_command_null_args		; send Initialize command
				pop bc
				call sdc_wait_ncr					; wait for valid response..	
				or a								; command response is $00 when card is ready for use
				jr z,sdc_init_done
				dec bc
				ld a,b
				or c
				jr nz,mmc_iwl
				jp mmc_init_fail

sdc_init_done

				ld a,049h							; send "read CSD" command: 49 00 00 00 00 01 to read card info
				call sdc_send_command_null_args
				call sdc_wait_ncr					; wait for valid response..	 
				or a								; command response should be $00
				jp nz,sdc_id_fail
				call sdc_wait_data_token			; wait for the data token
				or a
				jp nz,sdc_id_fail
				ld hl,sector_buffer					; read the card info to sector buffer (16 bytes)
				call sdc_read_id_bytes	

				ld a,04ah							; send "read CID" $4a 00 00 00 00 00 command for more card data
				call sdc_send_command_null_args
				call sdc_wait_ncr					; wait for valid response..	 
				or a								; command response should be $00
				jp nz,sdc_id_fail
				call sdc_wait_data_token			; wait for the data token
				or a
				jp nz,sdc_id_fail
				ld hl,sector_buffer+16				; read in more card data (16 bytes) 
				call sdc_read_id_bytes
				call sdc_deselect_card


sdc_quit	

				ld hl,sector_buffer+013h			; Build name / version / serial number of card as ASCII string
				ld de,sector_buffer+020h
				ld bc,5
				ld a,(sdc_sdc)
				or a
				jr nz,sdc_cn5
				inc bc
sdc_cn5			ldir
				push hl
				push de
				ld hl,sdc_vnchars
				ld bc,26
				ldir
				pop de
				pop hl
				inc de
				inc de
				ld a,(hl)
				srl a
				srl a
				srl a
				srl a
				add a,030h									; put in version digit 1
				ld (de),a
				inc de
				inc de
				ld a,(hl)
				and 0fh
				add a,030h
				ld (de),a									; put in version digit 2
				inc de
				inc de
				inc de
				inc de
				inc de
				inc hl
				ld b,4
sdc_snulp		ld a,(hl)									; put in 32 bit serial number
				srl a
				srl a
				srl a
				srl a
				add a,030h
				cp 03ah
				jr c,sdc_hvl1
				add a,07h
sdc_hvl1		ld (de),a
				inc de
				ld a,(hl)
				and 0fh
				add a,030h
				cp 03ah
				jr c,sdc_hvl2
				add a,07h
sdc_hvl2		ld (de),a
				inc de
				inc hl
				djnz sdc_snulp
	
	

				ld ix,sector_buffer						; compute card's capacity
				ld a,(ix+6)
				and 00000011b
				ld d,a
				ld e,(ix+7)
				ld a,(ix+8)
				and 11000000b
				sla a
				rl e
				rl d
				sla a
				rl e
				rl d									; DE = 12 bit value: "C_SIZE"
	
				ld a,(ix+9)
				and 00000011b
				ld b,a
				ld a,(ix+10)
				and 10000000b
				sla a
				rl b									; B = 3 bit value: "C_MULT"
	
				inc b
				inc b
				ld hl,0
sdc_cmsh		sla e
				rl d
				rl l
				rl h
				djnz sdc_cmsh							; HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2))
	
				ld a,(ix+5)
				and 00001111b							; A = "READ_BL_LEN"
				jr z,sdc_nbls
				ld b,a
sdc_blsh		sla e
				rl d
				rl l
				rl h
				djnz sdc_blsh							; Cap (bytes) HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2)) * (2^READ_BL_LEN)
	
				ld b,9									; convert number of bytes to numer of sectors
sdc_cbsec		srl h
				rr l
				rr d
				rr e
				djnz sdc_cbsec

sdc_nbls		push hl
				pop bc									; Return Capacity (number of sectors) in BC:DE
				ld hl,sector_buffer+020h				; Drive (hardware) name string at HL

				call sdc_fast_clock						; Use full speed SPI clock		
				xor a
				scf
				ret


;------------------------------------------------------------------------------------------

sdc_read_id_bytes

				ld b,16
sdc_csdlp		call sdc_get_byte
				ld (hl),a
				inc hl
				djnz sdc_csdlp
				call sdc_get_byte							; read CRC byte 1 
				call sdc_get_byte							; read CRC byte 2
				ret
	
;------------------------------------------------------------------------------------------
	
	
sdc_read_sector

;set c:de to sector number to read, 512 bytes returned in sector buffer

				call sdc_select_card

				ld hl,sector_lba0
				ld e,(hl)									; sector number LSB
				inc hl
				ld d,(hl)
				inc hl
				ld c,(hl)
				sla e										; convert sector to byte address
				rl d
				rl c
				ld a,051h									; Send CMD17 read sector command		
				ld b,001h									; A = $51 command byte, B = $01 dummy byte for CRC
				call sdc_send_command		
				call sdc_wait_ncr							; wait for valid response..	 
				or a										; command response should be $00
				jp nz,sdc_bcr_error			
				call sdc_wait_data_token					; wait for the data token
				or a
				jp nz,sdc_dt_timeout
	
				ld hl,sector_buffer							; read 512 bytes into sector buffer - unoptimized
				ld b,0
sdc_rslp		call sdc_get_byte
				ld (hl),a
				inc hl
				call sdc_get_byte
				ld (hl),a
				inc hl
				djnz sdc_rslp
				call sdc_get_byte							; read CRC byte 1
				call sdc_get_byte							; read CRC byte 2

				call sdc_deselect_card
				xor a
				scf
				ret
	
;---------------------------------------------------------------------------------------------

sdc_write_sector

;set c:de to sector number to write, 512 bytes written from sector buffer

				call sdc_select_card

				ld hl,sector_lba0
				ld e,(hl)								; sector number LSB
				inc hl
				ld d,(hl)
				inc hl
				ld c,(hl)
				sla e									; convert sector to byte address
				rl d
				rl c
				ld a,058h								; Send CMD24 write sector command
				ld b,001h								; A = $58 command byte, B = $01 dummy byte for CRC
				call sdc_send_command		
				call sdc_wait_ncr						; wait for valid response..	 
				or a									; command response should be $00
				jp nz,sdc_bcr_error			
	
				call sdc_send_eight_clocks				; wait 8 clocks before proceding	

				ld a,0feh
				call sdc_send_byte						; send $FE = packet header code

				ld hl,sector_buffer						; write out 512 bytes for sector -unoptimized
				ld b,0
sdc_wslp		ld a,(hl)
				call sdc_send_byte
				inc hl
				ld a,(hl)
				call sdc_send_byte
				inc hl
				djnz sdc_wslp

				call sdc_send_eight_clocks				; send dummy CRC byte 1 ($ff)
				call sdc_send_eight_clocks				; send dummy CRC byte 2 ($ff)
		
				call sdc_get_byte						; get packet response
				and 01fh
				srl a
				cp 002h
				jp nz,sdc_write_fail

				ld bc,50000								; read bytes until $ff is received
sdc_wcbsy		call sdc_get_byte						; until that time, card is busy
				cp 0ffh
				jr z,sdc_nbusy
				dec bc
				ld a,b
				or c
				jr nz,sdc_wcbsy
				jp sdc_card_busy_timeout	

sdc_nbusy		ld a,04dh								; Send CMD13: Check the status registers following the write
				ld bc,0100h			
				ld de,0000h
				call sdc_send_command
				call sdc_wait_ncr						; wait for valid response..	
				or a									; "R1" command response should be $00
				jp nz,sdc_write_fail
				call sdc_get_byte						; now get "R2" status code
				or a									; "R2" should also be $00
				jp nz,sdc_write_fail		
				call sdc_deselect_card					; sector write all OK
				xor a
				scf
				ret
	
;---------------------------------------------------------------------------------------------

sdc_send_command_null_args

				ld bc,0100h				
				ld de,0000h


sdc_send_command

; set A = command, C:DE for sector number, B for CRC

				push af				
				call sdc_send_eight_clocks			; send 8 clocks first - seems necessary for SD cards..
				pop af

				call sdc_send_byte					; command byte
				ld a,c								; then 4 bytes of address [31:0]
				call sdc_send_byte
				ld a,d
				call sdc_send_byte
				ld a,e
				call sdc_send_byte
				ld a,0
				call sdc_send_byte
				ld a,b								; finally CRC byte
				call sdc_send_byte
				ret

;---------------------------------------------------------------------------------------------

sdc_wait_ncr
	
				push bc
				ld bc,0
sdc_wncrl		call sdc_get_byte					; read until valid response from card (skip NCR)
				bit 7,a								; If bit 7 = 0, its a valid response
				jr z,sdc_gcr
				dec bc
			 	ld a,b
				or c
				jr nz,sdc_wncrl
sdc_gcr			pop bc
				ret
	
;---------------------------------------------------------------------------------------------

sdc_wait_data_token

				push bc
				ld bc,0
sdc_wdt			call sdc_get_byte						; read until data token arrives
				cp 0feh
				jr z,sdc_gdt
				dec bc
			 	ld a,b
				or c
				jr nz,sdc_wdt
				pop bc
				ld a,1									; didn't get a data token
				ret

sdc_gdt			pop bc
				xor a									; all OK
				ret

;---------------------------------------------------------------------------------------------

sdc_send_eight_clocks

				ld a,0ffh
				call sdc_send_byte
				ret

;---------------------------------------------------------------------------------------------
	
init_spi_mode_fail	

				ld a,sdc_error_spi_mode_failed
fail_ret		push af
				call sdc_deselect_card
				pop af
				or a
				ret
				
;---------------------------------------------------------------------------------------------

mmc_init_fail

				ld a,sdc_error_bad_init_mmc
				jr fail_ret

;---------------------------------------------------------------------------------------------

sdc_init_fail

				ld a,sdc_error_bad_init
				jr fail_ret
	
	
;---------------------------------------------------------------------------------------------

sdc_id_fail

				ld a,sdc_error_bad_id
				jr fail_ret

;----------------------------------------------------------------------------------------------

sdc_bcr_error

				ld a,sdc_error_bad_command_response
				jr fail_ret
	
;---------------------------------------------------------------------------------------------

sdc_dt_timeout

				ld a,sdc_error_data_token_timeout
				jr fail_ret

;----------------------------------------------------------------------------------------------

sdc_write_fail
	
				ld a,sdc_error_write_failed
				jr fail_ret

;----------------------------------------------------------------------------------------------

sdc_card_busy_timeout

				ld a,sdc_error_write_timeout
				jr fail_ret

;----------------------------------------------------------------------------------------------

sdc_vnchars	db " vx.x SN:00000000      ",0,0,0,0

sdc_sdc		db 0	; 0 = Card is MMC type, 1 = Card is SD type

;===============================================================================================


;------------------------------------------------------------------------------------------------

include "ez80p_sdcard_code.asm"				;hardware specific code

;------------------------------------------------------------------------------------------------