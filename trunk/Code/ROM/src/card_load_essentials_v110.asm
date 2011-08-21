;----------------------------------------------------------------------------------------------
; Simplified Z80-mode FAT16 File System code by Phil @ Retroleum
; Reduced to the essentials required to load file from root dir
;----------------------------------------------------------------------------------------------

find_file_fat16

; Set hl = filename location and "fs_z80_working_address" to load location before calling

; Output Carry set = Hardware error
;        Zero flag set = OK, else A = error code $1= Not FAT16, $2=File not found, $3= EOF encountered
				
				ld (filename_addr),hl
				
				xor a								; first, check disk format. 
				ld h,a
				ld l,a
				ld (sector_lba2),a
retry_fbs		ld (sector_lba0),hl
				call fs_read_sector					; read sector zero
				ret c								; quit on hardware error

				ld hl,(sector_buffer+1feh)			; check signature @ $1FE (applies to MBR and boot sector)
				ld de,0aa55h
				xor a
				sbc hl,de
				jr z,diskid_ok			
formbad			ld a,1								; error code $1 - not FAT16			
				or a
				ret

diskid_ok		ld a,(sector_buffer+3ah)			; for FAT16, char at $36 should be "6"
				cp 036h
				jr nz,test_mbr

				ld hl,(sector_buffer+0bh)			; get sector size
				ld de,512							; must be 512 bytes for this code
				xor a
				sbc hl,de
				jr nz,test_mbr
		
form_ok			ld a,(sector_buffer+0dh)			; get number of sectors in each cluster
				ld (fs_cluster_size),a
				ld hl,(sector_lba0)					; get start LBA of partition
				ld de,(sector_buffer+0eh)			; get 'sectors before FAT'
				add hl,de
				ld (fs_fat1_loc_lba),hl				; set FAT1 position
				ld de,(sector_buffer+16h)			; get sectors per FAT
				add hl,de							; HL = FAT2 position
				add hl,de							; HL = Root Dir loc
				ld (fs_root_dir_loc_lba),hl 		; set location of root dir
				ld hl,(sector_buffer+11h)			; get max root directory ENTRIES
				ld a,h
				or l
				jr z,test_mbr						; FAT32 puts $0000 here
				add hl,hl							; (IE: 32 bytes each, 16 per sector)
				add hl,hl
				add hl,hl
				add hl,hl
				xor a
				ld l,h
				ld h,a
				ld (fs_root_dir_sectors),hl			; set number of sectors used for root dir (max_root_entries / 32)				 
				jr read_file			
		
test_mbr		ld a,(sector_buffer+1c2h)			; get partition ID code (assuming this is MBR)
				and 4
				jp z,formbad						; bit 2 should be set for FAT16
				ld hl,(sector_lba0)					; have we already changed the LBA from 0?
				ld a,h
				or l
				jp nz,formbad			
				ld hl,(sector_buffer+1c6h)			; update LBA base location and retry
				jp retry_fbs
	
read_file		xor a								; find_os_file must be called first!!
				ld (fs_working_sector),a			; find_filename
ffnnxtsec		ld hl,(fs_root_dir_loc_lba)			; set up LBA for a root dir scan
				ld b,0
				ld a,(fs_working_sector)
				ld c,a
				add hl,bc
				ld (sector_lba0),hl					; sector low bytes
				xor a
				ld (sector_lba2),a					; sector MSB = 0
				call fs_read_sector
				ret c

				ld b,16								; sixteen 32 byte entries per sector
				ld ix,sector_buffer
ndirentr		ld de,(filename_addr)				; look for filename
				lea hl,ix+0
				ld c,11
comp_fn			ld a,(hl)
				call upper_casify
				ld (hl),a
				ld a,(de)
				or a
				jr z,fnsame							; end of filename?
				cp '.'
				jr nz,notdot						
				ld a,c								; if found a . and not already at last chars move
				cp 3								; to file extension
				jr c,notdot
				inc de
				lea hl,ix+8
				ld c,3
				ld a,(de)
notdot			call upper_casify				
				cp (hl)
				jr nz,fnnotsame
				inc hl
				inc de
				dec c
				jr nz,comp_fn
				jr fnsame
fnnotsame		lea ix,ix+32						; move to next filename entry in dir
				djnz ndirentr						; all entries in this sector scanned?
				
				ld hl,fs_working_sector				; move to next sector
				inc (hl)
				ld a,(fs_root_dir_sectors)			; reached last sector of root dir?
				cp (hl)								; LSB only: Assumes < 256 sectors used for root dir
				jr nz,ffnnxtsec
fnnotfnd		ld a,02h							; error code $02 - filename not found / zero file length
				or a
				ret

fnsame			bit 4,(ix+0bh)						; make sure entry is actually a file - abort if a dir
				jr nz,fnnotfnd
				
				ld l,(ix+1ah)		
				ld h,(ix+1bh)
				ld (fs_file_working_cluster),hl		; set file's start cluster
				ld e,(ix+1ch)
				ld d,(ix+1dh)
				ld l,(ix+1eh)			
				ld h,(ix+1fh)
set_flen		ld (fs_file_length_working),de
				ld (fs_file_length_working+2),hl	; set filelength from hl:de
				ld a,h					
				or l
				or d
				or e
				jr z,fnnotfnd						; abort if file length is zero
				xor a
				ret
	

load_file_fat16


fs_flnc			ld a,(fs_cluster_size)				; find_os_file must be called first!!
				ld b,a
				ld c,0
fs_flns			ld a,c				
				ld hl,(fs_file_working_cluster) 
				call cluster_and_offset_to_lba
				call fs_read_sector					;read first sector of file
				ret c								;h/w error?

				push bc								;stash sector pos / countdown
				ld bc,512							;bv = number of bytes to read from sector
				ld hl,sector_buffer					;sector base
				ld de,(fs_z80_working_address)		;dest address for file bytes
fs_cblp			ldi									;(hl)->(de), inc hl, inc de, dec bc
	
				call file_length_countdown
				jr z,fs_bdld						;if zero flag set = last byte

				ld a,b								;last byte of sector?
				or c
				jr nz,fs_cblp
				ld (fs_z80_working_address),de		;update destination address
				pop bc								;retrive sector offset / sector countdown
				inc c								;next sector
				djnz fs_flns						;loop until all sectors in cluster read

				ld hl,(fs_file_working_cluster)		;get location of the next cluster in this file's chain
				ld b,0				
				ld c,l
				ld de,(fs_fat1_loc_lba)
				ld l,h
				ld h,0
				add hl,de
				ld (sector_lba0),hl
				xor a
				ld (sector_lba2),a
				call fs_read_sector
				ret c
				push ix
				ld ix,sector_buffer
				add ix,bc
				add ix,bc
				ld l,(ix)
				ld h,(ix+1)
				pop ix
				ld (fs_file_working_cluster),hl
				ld de,0fff8h			
				xor a				
				sbc hl,de
				jr nc,fs_fpbad			
fs_nfbok		jp fs_flnc		


fs_bdld			pop bc				
				xor a								; op completed ok: a = 0, carry = 0
				ret

fs_flerr		pop bc
fs_fpbad		ld a,3				
				or a
				ret			
						

;---------------------------------------------------------------------------------------------


cluster_and_offset_to_lba

; INPUT: HL = cluster, A = sector offset, OUTPUT: Internal LBA address updated

				push bc
				push de
				push hl
				push ix
				dec hl							; offset back by two clusters as there
				dec hl							; are no $0000 or $0001 clusters
				ex de,hl
				ld hl,(fs_root_dir_loc_lba)
				ld bc,(fs_root_dir_sectors)
				add hl,bc						; hl = start of data area
				ld c,a
				ld b,0
				add hl,bc						; add sector offset
				ld c,l
				ld b,h							; bc = sector offset + LBA of start of data area
				ex de,hl
				ld e,0							; e = LBA MSB
				ld ix,sector_lba0
				ld a,(fs_cluster_size)
caotllp			srl a
				jr nz,doubclus
				add hl,bc						; add sector offset to cluster LBA
				jr nc,caotlnc
				inc e
caotlnc			ld (ix),l						; update LBA variable
				ld (ix+1),h
				ld (ix+2),e
caodone			pop ix
				pop hl
				pop de
				pop bc
				ret
	
doubclus		sla l							; cluster * 2
				rl h
				rl e
				jr caotllp


;-----------------------------------------------------------------------------------------------


fs_read_sector

				push bc
				push de
				push hl
				call sd_read_sector			
				pop hl
				pop de
				pop bc
				ret z
				scf
				ret


;----------------------------------------------------------------------------------------------
	
file_length_countdown

				push hl							;count down number of bytes to transfer
				push bc
				ld b,4
				ld hl,fs_file_length_working
				ld a,0ffh
flcdlp			dec (hl)
				cp (hl)
				jr nz,fs_cdnu
				inc hl
				djnz flcdlp
fs_cdnu			ld hl,(fs_file_length_working)	;countdown = 0?
				ld a,h
				or l
				ld hl,(fs_file_length_working+2)
				or h
				or l
				pop bc
				pop hl
				ret

;---------------------------------------------------------------------------------------------------

upper_casify

; INPUT/OUTPUT A = ascii char to make uppercase

				cp 061h			
				ret c
				cp 07bh
				ret nc
				sub 020h				
				ret


;------------------------------------------------------------------------------------------------




;--------------------------------------------------------------------------------------------------
; Low level Z80-mode MMC/SDC/SDHC card access routines - Phil Ruston '08-'11
; Simplified for ROM use
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

;--------------------------------------------------------------------------------------------------
; SD Card INITIALIZE code begins...
;--------------------------------------------------------------------------------------------------

sd_initialize	call sd_init_main
				or a						; if non-zero returned in A, there was an error
				jr z,sd_inok
				call sd_power_off			; if init failed shut down the SPI port
				ret

sd_inok			call sd_spi_port_fast		; on initializtion success -  switch to fast clock 

sd_done			call sd_deselect_card		; Routines always deselect card on return
				or a						; If A = 0 on SD routine exit, ZF set on return: No error
				ret				 

;--------------------------------------------------------------------------------------------------
		
sd_read_sector	call sd_read_sector_main
				jr sd_done

;--------------------------------------------------------------------------------------------------
	
sd_init_main	xor a							; Clear card info at start
				ld (sd_card_info),a			

				call sd_power_off				; Switch off power to the card (SPI clock slow, /CS is low but should be irrelevent)
				
				ld b,128						; wait 0.5 seconds
				call pause_loop
							
				call sd_power_on				; Switch card power back on (/CS high - de-selected)

				call pause_4ms
				
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

sd_dt_ok		ld b,0								; read 512 bytes to sector buffer + 2 CRCs (not saved)
				call sd_read_bytes_to_sector_buffer
				inc h
				ld b,0
				call sd_read_bytes
				call sd_get_byte				
				call sd_get_byte
				
				xor a								; A = 0: all ok
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
				add hl,hl
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
				ld (cmd_generic_args+2),hl	
				
				
	
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
	

;===============================================================================================

;---------------------------------------------------------------------------------------------
; eZ80P Specific SD card low-level routines v1.10 (ADL mode)
;----------------------------------------------------------------------------------------------

sd_send_byte

;Put byte to send to card in A

					out0 (port_sdc_data),a
					push bc
					ld c,port_hw_flags
sd_wb_loop			tstio 1<<sdc_serializer_busy		; wait for serialization to end
					jr nz,sd_wb_loop					; ie: test bit in port (c)
					pop bc
					ret

;---------------------------------------------------------------------------------------------

sd_get_byte

; Returns byte read from card in A

					call sd_send_eight_clocks
					in0 a,(port_sdc_data)
					ret

;---------------------------------------------------------------------------------------------
; SD Card control
;---------------------------------------------------------------------------------------------

sd_select_card		push af
					ld a,00h+(1<<sdc_cs)					; set card /CS low
sd_wr_sdc_ctrl		out0 (port_sdc_ctrl),a
					pop af
					ret


sd_deselect_card	push af
					ld a,080h+(1<<sdc_cs)					; set card /CS high
					out0 (port_sdc_ctrl),a
					call sd_send_eight_clocks				; send 8 clocks to make card de-assert its D_out line
					pop af
					ret


sd_power_on			push af
					ld a,(1<<sdc_speed)						; bit 7 = set bits low / sdc speed bit selected
					out0 (port_sdc_ctrl),a					; SPEED = LOW
					ld a,80h+(1<<sdc_power)+(1<<sdc_cs)		; bit 7 = set bits high:  sdc power, cs
					jr sd_wr_sdc_ctrl						; CS: inactive, Power: ON


sd_power_off		push af
					ld a,00h+(1<<sdc_power)					; bit 7 = reset bits: sdc power (cs automatically
					jr sd_wr_sdc_ctrl						; pulled low by AMOEBA when card power is off)


sd_spi_port_fast	push af
					ld a,80h+(1<<sdc_speed)					; bit 7 = set bits: sdc speed
					jr sd_wr_sdc_ctrl


;----Low level sector access data/vars -------------------------------------------------------------------------

CMD0_string			db 40h,00h,00h,00h,00h,95h
CMD8_string			db 48h,00h,00h,01h,aah,87h
ACMD41HCS_string	db 69h,40h,00h,00h,00h,01h

cmd_generic			db 00h
cmd_generic_args	db 00h,00h,00h,00h
cmd_generic_crc		db 01h

sd_card_info		db 0	; Bit [4] = CCS (block mode access)  Bits [3:0] = Card type: 0=MMC, 1=SD, 2=SDHC

sector_lba0 		db 0
sector_lba1			db 0
sector_lba2			db 0
sector_lba3			db 0

;----FAT16 Data/vars -----------------------------------------------------------------------------------------

filename_addr			dw 0

fs_cluster_size			db 0			; FAT16 disk parameters
fs_fat1_loc_lba			dw 0
fs_root_dir_loc_lba		dw 0
fs_root_dir_sectors		dw 0

fs_file_length_working	dw 0,0
fs_file_working_cluster	dw 0
fs_z80_working_address	dw 0
fs_working_sector		dw 0


;----------------------------------------------------------------------------------------------






