;--------------------------------------------------------------------------------------------------
; Low level Z80 MMC/SDC/SDHC card access routines - Phil Ruston '08-'11 ADL
;--------------------------------------------------------------------------------------------------
;
; V1.10 - SDHC support added
;
; Limitations:
; ------------
; Does not check for block size
;
; Somewhat arbitrary timimg due to quirks of my SD interface ("D_out" is not pulled up
; which means the data from the card following commands is undefined for one byte. This
; byte is skipped by the send_command routine.)


;--------------------------------------------------------------------------------------------------
;
; Key Routines:      Input Parameters           Output Registers
; -------------      ----------------           ----------------
; sd_initialize		no arguments required       Zero Flag / A = error code, BC:DE = Capacity in sectors, HL = ID ASCII string
; sd_read_sector	[sector_lba0-3]				Zero Flag / A = error code
; sd_write_sector	[sector_lba0-3]    			Zero Flag / A = error code
;
; (Assume all other registers are trashed.)
;
;--------------------------------------------------------------------------------------------------

; Routines respond with Zero Flag set if operation was OK, Otherwise A = Error code:

; $01 - SPI mode failed	 
; $10 - MMC init failed	
; $11 - SD init failed	
; $12 - SDHC init failed	
; $13 - voltage range bad	
; $14 - check pattern bad
; $20 - illegal command
; $21 - bad command response
; $22 - data token timeout
; $23 - write timeout
; $24 - write failed
;
;---------------------------------------------------------------------------------------------------

; Define "sector_buffer" in main code (512 bytes)

;---------------------------------------------------------------------------------------------------

CMD1	equ 40h + 1
CMD9	equ 40h + 9
CMD10	equ 40h + 10
CMD13	equ 40h + 13
CMD17	equ 40h + 17
CMD24	equ 40h + 24
ACMD41	equ 40h + 41
CMD55	equ 40h + 55
CMD58	equ 40h + 58

sd_error_spi_mode_failed		equ 01h

sd_error_mmc_init_failed		equ 10h
sd_error_sd_init_failed			equ 11h
sd_error_sdhc_init_failed		equ 12h
sd_error_vrange_bad				equ 13h
sd_error_check_pattern_bad		equ 14h

sd_error_illegal_command		equ 20h
sd_error_bad_command_response	equ 21h
sd_error_data_token_timeout		equ 22h
sd_error_write_timeout			equ 23h
sd_error_write_failed			equ 24h

;-------------------------------------------------------------------------------------------------
; PROSE STANDARD DRIVER HEADER
;-------------------------------------------------------------------------------------------------

sd_card_driver	jp sd_initialize			; $00 : init / get hardware ID routine
				jp sd_read_sector			; $04 : jump to read sector routine
				jp sd_write_sector			; $08 : jump to write sector routine
				db "SD_CARD",0				; $0c : desired ASCII name of device type						

;--------------------------------------------------------------------------------------------------
; SD Card INITIALIZE code begins...
;--------------------------------------------------------------------------------------------------

sd_initialize	call sd_init_main
				or a						; if non-zero returned in A, there was an error
				jr z,sd_inok
				call sd_power_off			; if init failed shut down the SPI port
				ret

sd_inok			call sd_spi_port_fast		; on initializtion success -  switch to fast clock 

				call sd_read_cid			; and read CID/CSD
				jr nz,sd_done
				push hl						; cache the location of the ID string
				call sd_read_csd
				pop hl

sd_done			call sd_deselect_card		; Routines always deselect card on return
				or a						; If A = 0 on SD routine exit, ZF set on return: No error
				ret				 

;--------------------------------------------------------------------------------------------------
		
sd_read_sector	call sd_read_sector_main
				jr sd_done

;--------------------------------------------------------------------------------------------------
	
sd_write_sector	call sd_write_sector_main
				jr sd_done
	
;--------------------------------------------------------------------------------------------------
	
sd_init_main	xor a							; Clear card info at start
				ld (sd_card_info),a			

				call sd_power_off				; Switch off power to the card (SPI clock slow, /CS is low but should be irrelevent)
				
				ld de,16384						; wait 0.5 seconds
				call hwsc_time_delay
							
				call sd_power_on				; Switch card power back on (/CS high - de-selected)

				ld de,131						; wait approx 4ms
				call hwsc_time_delay
				
				ld b,10							; send 80 clocks to ensure card has stabilized
sd_ecilp		call sd_send_eight_clocks
				djnz sd_ecilp
				
				ld hl,CMD0_string				; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
				call sd_send_command_string		; (When /CS is low on receipt of CMD0, card enters SPI mode) 
				cp 01h							; Command Response should be $01 ("In idle mode")
				jr z,sd_spi_mode_ok
				
				ld a,sd_error_spi_mode_failed
				ret		

; ---- CARD IS IN IDLE MODE -----------------------------------------------------------------------------------

sd_spi_mode_ok	ld hl,CMD8_string					; send CMD8 ($48,$00,$00,$01,$aa,$87) to test for SDHC card
				call sd_send_command_string
				cp 01h
				jr nz,sd_sdc_init					; if R1 response is not $01: illegal command: not an SDHC card

				ld b,4
				call sd_read_bytes_to_sector_buffer	; get r7 response (4 bytes)
				ld a,1
				inc hl
				inc hl
				cp (hl)								; we need $01,$aa in response bytes 2 and 3  
				jr z,sd_vrok
				ld a,sd_error_vrange_bad
				ret				

sd_vrok			ld a,0aah
				inc hl
				cp (hl)
				jr z,sd_check_pattern_ok
				ld a,sd_error_check_pattern_bad
				ret
				
sd_check_pattern_ok

;------ SDHC CARD CAN WORK AT 2.7v - 3.6v ----------------------------------------------------------------------
	
				ld bc,8000							; Send SDHC card init

sdhc_iwl		ld a,CMD55							; First send CMD55 ($77 00 00 00 00 01) 
				call sd_send_command_null_args
				
				ld hl,ACMD41HCS_string				; Now send ACMD41 with HCS bit set ($69 $40 $00 $00 $00 $01)
				call sd_send_command_string
				jr z,sdhc_init_ok					; when response is $00, card is ready for use	
				bit 2,a
				jr nz,sdhc_if						; if Command Response = "Illegal command", quit
				
				dec bc
				ld a,b
				or c
				jr nz,sdhc_iwl
				
sdhc_if			ld a,sd_error_sdhc_init_failed		; if $00 isn't received, fail
				ret
				
sdhc_init_ok

;------ SDHC CARD IS INITIALIZED --------------------------------------------------------------------------------------

				ld a,CMD58							; send CMD58 - read OCR
				call sd_send_command_null_args
					
				ld b,4								; read in OCR
				call sd_read_bytes_to_sector_buffer
				ld a,(hl)
				and 040h							; test CCS bit
				rrca
				rrca 
				or 00000010b				
				ld (sd_card_info),a					; bit4: Block mode access, bit 0:3 card type (0:MMC,1:SD,2:SDHC)
				xor a								; A = 00, all OK
				ret

	
;-------- NOT AN SDHC CARD, TRY SD INIT ---------------------------------------------------------------------------------

sd_sdc_init		ld bc,8000							; Send SD card init

sd_iwl			ld a,CMD55							; First send CMD55 ($77 00 00 00 00 01) 
				call sd_send_command_null_args

				ld a,ACMD41							; Now send ACMD41 ($69 00 00 00 00 01)
				call sd_send_command_null_args
				jr z,sd_rdy							; when response is $00, card is ready for use
				
				bit 2,a				
				jr nz,sd_mmc_init					; check command response bit 2, if set = illegal command - try MMC init
							
				dec bc
				ld a,b
				or c
				jr nz,sd_iwl
				
				ld a,sd_error_sd_init_failed		; if $00 isn't received, fail
				ret
				
sd_rdy			ld a,1
				ld (sd_card_info),a					; set card type to 1:SD (byte access mode)
				xor a								; A = 0: all ok	
				ret	

;-------- NOT AN SDHC OR SD CARD, TRY MMC INIT ---------------------------------------------------------------------------

sd_mmc_init		ld bc,8000							; Send MMC card init and wait for card to initialize

sdmmc_iwl		ld a,CMD1
				call sd_send_command_null_args		; send CMD1 ($41 00 00 00 00 01) 
				ret z								; If ZF set, command response in A = 00: Ready,. Card type is default MMC (byte access mode)
				
sd_mnrdy		dec bc
				ld a,b
				or c
				jr nz,sdmmc_iwl
				
				ld a,sd_error_mmc_init_failed		; if $00 isn't received, fail	
				ret
	
;-----------------------------------------------------------------------------------------------------------------

; Returns BC:DE = Total capacity of card (in sectors)

sd_read_csd
				
				ld a,CMD9							; send "read CSD" command: 49 00 00 00 00 01 to read card info
				call sd_send_command_null_args	
				jp nz,sd_bcr_error					; ZF set if command response = 00

				call sd_wait_data_token				; wait for the data token
				jp nz,sd_dt_timeout	

sd_id_ok		ld b,18								; read the card info to sector buffer (16 bytes + 2 CRC)
				call sd_read_bytes_to_sector_buffer	

				ld ix,sector_buffer					; compute card's capacity
				bit 6,(ix)
				jr z,sd_csd_v1

sd_csd_v2		ld l,(ix+9)							; for CSD v2.00
				ld h,(ix+8)
				inc hl
				ld a,10
				ld bc,0
sd_csd2lp		add.sis hl,hl
				rl c
				rl b
				dec a
				jr nz,sd_csd2lp
				ex de,hl							; Return Capacity (number of sectors) in BC:DE
				xor a
				ret
				
sd_csd_v1		ld a,(ix+6)							; For CSD v1.00
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
				rl d								; DE = 12 bit value: "C_SIZE"
				
				ld a,(ix+9)
				and 00000011b
				ld b,a
				ld a,(ix+10)
				and 10000000b
				sla a
				rl b								; B = 3 bit value: "C_MULT"
				
				inc b
				inc b
				ld hl,0
sd_cmsh			sla e
				rl d
				rl l
				rl h
				djnz sd_cmsh						; HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2))
				
				ld a,(ix+5)
				and 00001111b						; A = "READ_BL_LEN"
				jr z,sd_nbls
				ld b,a
sd_blsh			sla e
				rl d
				rl l
				rl h
				djnz sd_blsh						; Cap (bytes) HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2)) * (2^READ_BL_LEN)
				
				ld b,9								; convert number of bytes to numer of sectors
sd_cbsec		srl h
				rr l
				rr d
				rr e
				djnz sd_cbsec

sd_nbls			push hl
				pop bc								; Return Capacity (number of sectors) in BC:DE
				xor a
				ret

;----------------------------------------------------------------------------------------------------------------------

sd_read_cid
	
; Returns HL = Pointer to device ID string

				ld a,CMD10							; send "read CID" $4a 00 00 00 00 00 command for more card data
				call sd_send_command_null_args
				jp nz,sd_bcr_error					; ZF set if command response = 00	

				call sd_wait_data_token				; wait for the data token
				jp nz,sd_dt_timeout
					
				ld b,18
				call sd_read_bytes_to_sector_buffer	; read 16 bytes + 2 CRC
				
				ld hl,sector_buffer+03h				; Build name / version / serial number of card as ASCII string
				ld de,sector_buffer+20h
				ld bc,5
				ld a,(sd_card_info)
				and 0fh
				jr nz,sd_cn5
				inc bc
sd_cn5			ldir
				push hl
				push de
				ld hl,sd_vnchars
				ld bc,20
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
				add a,30h							; put in version digit 1
				ld (de),a
				inc de
				inc de
				ld a,(hl)
				and 0fh
				add a,30h
				ld (de),a							; put in version digit 2
				inc de
				inc de
				inc de
				inc de
				inc de
				inc hl
				ld b,4
sd_snulp		ld a,(hl)							; put in 32 bit serial number
				srl a
				srl a
				srl a
				srl a
				add a,30h
				cp 3ah
				jr c,sd_hvl1
				add a,07h
sd_hvl1			ld (de),a
				inc de
				ld a,(hl)
				and 0fh
				add a,30h
				cp 3ah
				jr c,sd_hvl2
				add a,07h
sd_hvl2			ld (de),a
				inc de
				inc hl
				djnz sd_snulp
				
				ld hl,sector_buffer+20h				; Drive (hardware) name string at HL
				xor a
				ret

;--------------------------------------------------------------------------------------------------
; SD Card READ SECTOR code begins...
;--------------------------------------------------------------------------------------------------
	
sd_read_sector_main

; 512 bytes are returned in sector buffer

				call sd_set_sector_addr

				ld a,CMD17							; Send CMD17 read sector command		
				call sd_send_command_current_args
				jr z,sd_rscr_ok						; if ZF set command response is $00	
sd_bcr_error	ld a,sd_error_bad_command_response
				ret

sd_rscr_ok		call sd_wait_data_token				; wait for the data token
				jr z,sd_dt_ok						; ZF set if data token reeceived
sd_dt_timeout	ld a,sd_error_data_token_timeout
				ret

sd_dt_ok		ld hl,sector_buffer
				call sd_read_513_bytes				; read 512 bytes to sector buffer, 2 CRCs are not saved
				call sd_get_byte
				
				xor a								; A = 0: all ok
				ret

;--------------------------------------------------------------------------------------------------
; SD Card WRITE SECTOR code begins...
;--------------------------------------------------------------------------------------------------

sd_write_sector_main
	
				call sd_set_sector_addr

				ld a,CMD24							; Send CMD24 write sector command
				call sd_send_command_current_args		
				jr nz,sd_bcr_error					; if ZF set, command response is $00	
				
				call sd_send_eight_clocks			; wait 8 clocks before proceding	

				ld a,0feh
				call sd_send_byte					; send $FE = packet header code

				ld hl,sector_buffer
				call sd_write_512_bytes				; send contents of sector buffer
				call sd_send_eight_clocks			; send dummy CRC byte 1 ($ff)
				call sd_send_eight_clocks			; send dummy CRC byte 2 ($ff)
		
				call sd_get_byte					; get packet response
				and 1fh
				srl a
				cp 02h
				jr z,sd_wr_ok

sd_write_fail	ld a,sd_error_write_failed
				ret

sd_wr_ok		ld bc,65535							; read bytes until $ff is received
sd_wcbsy		call sd_get_byte					; until that time, card is busy
				cp 0ffh
				jr nz,sd_busy
				xor a								; A = 0, all OK
				ret
				
sd_busy			dec bc
				ld a,b
				or c
				jr nz,sd_wcbsy

sd_card_busy_timeout

				ld a,sd_error_write_timeout
				ret	

;---------------------------------------------------------------------------------------------

sd_set_sector_addr
				
				ld hl,sector_lba0
				ld c,(hl)
				inc hl
				ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
				ld b,(hl)					; sector LBA: B,D,E,C

				ld a,(sd_card_info)
				and 10h
				jr nz,lbatoargs				; if SDHC card, we use direct sector access
				ld l,c
				ld h,e
				ld a,d						; otherwise need to multiply by 512
				add.sis hl,hl
				adc a,a	
				ex de,hl
				ld b,a
				ld c,0
lbatoargs		ld hl,cmd_generic_args
				ld (hl),b
				inc hl
				ld (hl),d
				inc hl
				ld (hl),e
				inc hl
				ld (hl),c
				ret
	
	
;---------------------------------------------------------------------------------------------

sd_wait_data_token

				push bc
				ld bc,8000				
sd_wdt			call sd_get_byte			; read until data token ($FE) arrives, ZF set if received
				cp 0feh
				jr z,sd_gdt
				dec bc
				ld a,b
				or c
				jr nz,sd_wdt
				inc c						; didn't get a data token, ZF not set
sd_gdt			pop bc
				ret

;--------------------------------------------------------------------------------------------

sd_send_eight_clocks

				ld a,0ffh
				call sd_send_byte
				ret

;---------------------------------------------------------------------------------------------


sd_send_command_null_args

				ld hl,0
				ld (cmd_generic_args),hl	; clear the 4 bytes of the argument string
				ld (cmd_generic_args+1),hl	
				
				
	
sd_send_command_current_args
	
				ld hl,cmd_generic
				ld (hl),a



sd_send_command_string

; set HL = location of 6 byte command string
; returns command response in A (ZF set if $00)


				call sd_select_card				; send command always enables card select
						
				call sd_send_eight_clocks		; send 8 clocks first - seems necessary for SD cards..
				
				push bc
				ld b,6
sd_sclp			ld a,(hl)
				call sd_send_byte				; command byte
				inc hl
				djnz sd_sclp
				pop bc
				
				call sd_get_byte				; skip first byte of nCR, a quirk of my SD card interface?
					

sd_wait_valid_response
				
				push bc
				ld b,0
sd_wncrl		call sd_get_byte				; read until Command Response from card 
				bit 7,a							; If bit 7 = 0, it's a valid response
				jr z,sd_gcr
				djnz sd_wncrl
								
sd_gcr			or a							; zero flag set if Command response = 00
				pop bc
				ret
				
	
;-----------------------------------------------------------------------------------------------

sd_read_bytes_to_sector_buffer

				ld hl,sector_buffer
	
sd_read_bytes

; set HL to dest address for data
; set B to number of bytes required  

				push hl
sd_rblp			call sd_get_byte
				ld (hl),a
				inc hl
				djnz sd_rblp
				pop hl
				ret
	
;-----------------------------------------------------------------------------------------------

; This data can be placed in ROM:

CMD0_string			db 40h,00h,00h,00h,00h,95h
CMD8_string			db 48h,00h,00h,01h,aah,87h
ACMD41HCS_string	db 69h,40h,00h,00h,00h,01h
sd_vnchars			db " vx.x SN:00000000 ",0,0


; The following variables need to be placed in RAM:

cmd_generic			db 00h
cmd_generic_args	db 00h,00h,00h,00h
cmd_generic_crc		db 01h

sd_card_info		db 0	; Bit [4] = CCS (block mode access)  Bits [3:0] = Card type: 0=MMC, 1=SD, 2=SDHC


;===============================================================================================

;------------------------------------------------------------------------------------------------

include "ez80p_sdcard_code.asm"				;EZ80P hardware specific code

;------------------------------------------------------------------------------------------------