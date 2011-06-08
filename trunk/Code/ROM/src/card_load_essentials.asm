;----------------------------------------------------------------------------------------------
; Simplified Z80 FAT16 File System code by Phil @ Retroleum
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
				call sdc_read_sector
				ccf								;switch carry flag so set = error
				pop hl
				pop de
				pop bc
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

;--------------------------------------------------------------------------------------------------
; SIMPLIFIED SD CARD ROUTINES for ROM
;--------------------------------------------------------------------------------------------------

sdc_init_card

; Initializes card. Returns: Carry = 1 if initialized OK


				ld a,1						; Assume card is SD type at start
				ld (card_type),a			

				call sdc_power_off			; Switch off power to the card
	
				ld b,128					; wait approx 0.5 seconds
sdc_powod		call pause_4ms
				djnz sdc_powod			
		
				call sdc_power_on			; Switch card power back on

				call sdc_slow_clock

				call pause_4ms				; Short delay

				call sdc_deselect_card		
	
				ld b,10						; send 80 clocks to ensure card has stabilized
sdc_ecilp		ld a,0ffh
				call sdc_send_byte
				djnz sdc_ecilp
	
				call sdc_select_card		; Set Card's /CS line active (low)
	
				ld a,040h					; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
				ld bc,9500h					; When /CS is low on receipt of CMD0, card enters SPI mode 
				ld de,0000h
				call sdc_send_command		 
				call sdc_get_byte			; skip nCR
				call sdc_wait_ncr			; wait for valid response..			
				cp 01h						; command response should be $01 ("In idle mode")
				jp nz,card_init_fail		


				ld bc,8000					; Send SD card init command ACMD41, if illegal try MMC card init
sdc_iwl			push bc						;
				ld a,77h					; CMD55 ($77 00 00 00 00 01) 
				ld bc,0100h
				ld de,0000h
				call sdc_send_command
				call sdc_get_byte			; NCR
				call sdc_get_byte			; Command response

				ld a,69h					; ACMD41 ($69 00 00 00 00 01)
				ld bc,0100h				
				ld de,0000h
				call sdc_send_command		
				call sdc_get_byte
				pop bc
				call sdc_wait_ncr			; wait for valid response..	
				bit 2,a						; check bit 2, if set = illegal command
				jr nz,mmc_init			
				or a
				jr z,sdc_init_done			; when response is $00, card is ready for use
				dec bc
				ld a,b
				or c
				jr nz,sdc_iwl
				jp card_init_fail

mmc_init		xor a
				ld (card_type),a

				ld bc,8000					; Send MMC card init and wait for card to initialize
mmc_iw1			push bc

				ld a,41h					; send CMD1 ($41 00 00 00 00 01) to test this
				ld bc,0100h				
				ld de,0000h
				call sdc_send_command		; send Initialize command
				pop bc
				call sdc_wait_ncr			; wait for valid response..	
				or a						; command response is $00 when card is ready for use
				jr z,sdc_init_done
				dec bc
				ld a,b
				or c
				jr nz,mmc_iw1
				jr card_init_fail


sdc_init_done

				call sdc_deselect_card

				call sdc_fast_clock			; Use Fast SPI clock		
	
				scf							; carry set = card initialized 
				ret

;---------------------------------------------------------------------------------------------

card_init_fail

				call sdc_deselect_card
				xor a						; a = 0, init failed
				ret

card_read_fail

				call sdc_deselect_card
				xor a
				inc a						; a =1. read failed
				ret
		
;------------------------------------------------------------------------------------------

sdc_read_sector

				call sdc_select_card

				ld hl,sector_lba0
				ld e,(hl)						; sector number LSB
				inc hl
				ld d,(hl)
				inc hl
				ld c,(hl)
				sla e							; convert sector to byte address
				rl d
				rl c
				ld a,51h						; Send CMD17 read sector command		
				ld b,01h						; A = $51 command byte, B = $01 dummy byte for CRC
				call sdc_send_command		
				call sdc_wait_ncr				; wait for valid response..	 
				or a							; command response should be $00
				jp nz,card_read_fail		
				call sdc_wait_data_token		; wait for the data token
				or a
				jp nz,card_read_fail
				
				ld hl,sector_buffer				; read 512 bytes into sector buffer - unoptimized
				ld b,0
sdc_rslp		call sdc_get_byte
				ld (hl),a
				inc hl
				call sdc_get_byte
				ld (hl),a
				inc hl
				djnz sdc_rslp
				call sdc_get_byte				; read CRC byte 1
				call sdc_get_byte				; read CRC byte 2
				
				call sdc_deselect_card
				xor a
				scf								; carry set = card operation OK 
				ret
	
;---------------------------------------------------------------------------------------------

sdc_send_command

; set A = command, C:DE for sector number, B for CRC

				push af							; send 8 clocks first - seems necessary for SD cards..
				ld a,0ffh
				call sdc_send_byte
				pop af

				call sdc_send_byte				; command byte
				ld a,c							; then 4 bytes of address [31:0]
				call sdc_send_byte
				ld a,d
				call sdc_send_byte
				ld a,e
				call sdc_send_byte
				ld a,0
				call sdc_send_byte
				ld a,b							; finally CRC byte
				call sdc_send_byte
				ret

;---------------------------------------------------------------------------------------------

sdc_wait_ncr
	
				push bc
				ld b,0
sdc_wncrl		call sdc_get_byte			; read until valid response from card (skip NCR)
				bit 7,a						; If bit 7 = 0, its a valid response
				jr z,sdc_gcr
				djnz sdc_wncrl
sdc_gcr			pop bc
				ret
	
;---------------------------------------------------------------------------------------------

sdc_wait_data_token

				ld b,0
sdc_wdt			call sdc_get_byte			; read until data token arrives
				cp 0feh
				jr z,sdc_gdt
				djnz sdc_wdt
				ld a,1						; didn't get a data token
				ret

sdc_gdt			xor a						; all OK
				ret


;---------------------------------------------------------------------------------------------
; eZ80P Specific SD card low-level routines (Z80 mode)
;----------------------------------------------------------------------------------------------

sdc_send_byte

;Put byte to send to card in A

					push bc
					ld bc,port_sdc_data
					out (bc),a							; send byte to serializer
	
					ld c,port_hw_flags					; wait for serialization to end
sdc_wb_loop			tstio 1<<sdc_serializer_busy		; ie: test bit in port (c)
					jr nz,sdc_wb_loop

					pop bc
					ret

;---------------------------------------------------------------------------------------------

sdc_get_byte

; Returns byte read from card in A

					ld a,0ffh
					call sdc_send_byte
					push bc
					ld bc,port_sdc_data
					in a,(bc)							; read the contents of the shift register
					pop bc
					ret
	
;---------------------------------------------------------------------------------------------

sdc_select_card
	
					push bc
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_cs						;set card /CS low
					out (bc),a
					pop bc
					ret


sdc_deselect_card

					push bc
					ld bc,port_sdc_ctrl
					ld a,080h+(1<<sdc_cs)			;set card /CS high
					out (bc),a
					pop bc
				
					ld a,0ffh							; send 8 clocks to make card de-assert its D_out line
					call sdc_send_byte
					ret
	
;---------------------------------------------------------------------------------------------

sdc_power_on

					push bc
					ld bc,port_sdc_ctrl
					ld a,80h+(1<<sdc_power)			;bit 7 = set bits high / sdc power bit selected
					out (bc),a
					pop bc
					ret
	

sdc_power_off
	
					push bc							
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_power					;bit 7 = set bits low / sdc power bit selected
					out (bc),a							;switch power to card off (set line low) - the fpga
					pop bc								;logic automatically pulls /CS and Din low so as not to
					ret									;supply any other current to the card (clock will be low too).
	

;----------------------------------------------------------------------------------------------

sdc_slow_clock

					push bc
					ld bc,port_sdc_ctrl
					ld a,1<<sdc_speed					;bit 7 = set bits low / sdc speed bit selected
					out (bc),a
					pop bc
					ret


sdc_fast_clock
	
					push bc
					ld bc,port_sdc_ctrl
					ld a,080h+(1<<sdc_speed)			;bit 7 = set bits high / sdc speed bit selected
					out (bc),a
					pop bc
					ret

;------------------------------------------------------------------------------------------------

filename_addr			dw 0

fs_cluster_size			db 0			; FAT16 disk parameters
fs_fat1_loc_lba			dw 0
fs_root_dir_loc_lba		dw 0
fs_root_dir_sectors		dw 0

fs_file_length_working	dw 0,0
fs_file_working_cluster	dw 0
fs_z80_working_address	dw 0
fs_working_sector		dw 0

card_type				db 0

sector_lba0 			db 0
sector_lba1				db 0
sector_lba2				db 0
sector_lba3				db 0

;----------------------------------------------------------------------------------------------