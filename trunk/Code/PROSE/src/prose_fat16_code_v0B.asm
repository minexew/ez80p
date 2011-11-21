;----------------------------------------------------------------------------------------------
; eZ80 FAT16 File System code for PROSE by Phil @ Retroleum (ADL mode)
;----------------------------------------------------------------------------------------------
;
; Changes:
;
; 0.0B - Bugfix, typo in "fs_adjust_fp_tl_so" - filepointer[31:24] was being written to filepointer[7:0]
;      - Thanks to Mike ("X Y") for bringing that to my attention.
; 0.0A - ?
; 0.09 - Format command now formats based solely on "partition_base", "partition_size" 
;		 and "current driver"
;        If the paritition is an MBR type, the MBR partition ID byte is set to $0E (FAT16 LBA) if necessary
;      - "Get partition info" looks at each partitions ID not just the first one 
;
; 0.08 - Speeded up reading of files (pre-calc read loop)
;        All routines return with ZF not set if there was a filesystem error
; 0.07 - Made compatible with v1.10 drivers (ZF/CF return) 
; 0.06 - Fixed "fs_get_volume_label"
; 0.05 - Fixed format command
; 0.04 - File system error codes are now in the C0-F0 range
; 0.03 - ADL mode
; 0.02 - removed references to banks, added 24 bit address for load/save
; 0.01 - first version based on FLOS routines v1.12
;
; Known limitations:
; ------------------
; If a disk full error is returned during a file write: The file reported length is not truncated
; Allows a file to be created in root even if there's no space for the content
;        
;----------------------------------------------------------------------------------------------
;
; All routines return carry clear / zero flag set if OK.
;
; If carry set there was a driver error, A = Error code from driver.
; Check for "carry set" first!
; If carry clear, check zero flag. If not set: A= File system error code:
;
;					$c1  - Disk full
;					$c2  - file not found
;             	    $c3  - (root) dir table is full
;					$c4  - directory requested is actually a file
;             	    $c5  - cant delete dir, it is not empty
;					$c6  - not a file
;					$c7  - file length is zero
;              	    $c8  - out of memory
;					$c9  - filename already exists
;					$ca  - already at root directory
;                  	$cb  - directory not found
;					$cc  - requested bytes beyond EOF
;					$cd  - invalid filename
;					$ce  - unknown/incorrect disk format
;					$cf  - invalid volume
;                 	$d0  - device not present		
;					$d1  - directory not found		     
;                 	$d2  - end of directory list
;                 	$d3  - device does not use MBR
;                  	$d4  - cant find volume label
;                   $d5  - sector out of range

;-----------------------------------------------------------------------------------------------
; Main routines called by external programs
;-----------------------------------------------------------------------------------------------

fs_format_partition

; Formats a FAT16 partition based on:

; "partition_base" LBA (32bit, absolute: all format writes are offset from this location)
; "partition_size" in sectors (24bit - will be truncated to 0x3f0000 sectors) and "current driver"				
; Set HL to label location

				ld de,fs_sought_filename					;copy label to fs_sought_filename
				call fs_clear_filename
				ld b,11
				call os_copy_ascii_run

				call fs_clear_sector_buffer					;wipe partition sectors 0-767 (this range covers
				ld de,0										;(max fat length * 2) + root length + reserved sectors.)
form_ws			call set_lba_and_write_sector
				ret c
				inc de
				ld a,d
				cp 3
				jr nz,form_ws
	
				ld hl,bootsector_stub						;copy generic partition boot sector data to sector buffer
				ld de,sector_buffer							;sector buffer will still be clear from ops at start
				ld bc,03fh
				ldir
	
				ld hl,(partition_size)
				ld de,3f0000h
				xor a
				sbc hl,de				
				jr c,fs_fssok								;if more than $3f0000 sectors, fix at $3f0000
fs_truncs		ld (partition_size),de
				
fs_fssok		ld a,(partition_size+2)
				ld hl,080h									;find appropriate cluster size (in h)
fs_fcls			add hl,hl
				cp h
				jr nc,fs_fcls

				ld ix,sector_buffer
				ld (ix+0dh),h								;fill in sectors-per-cluster in boot sector data
				
				ld de,(partition_size)
				ld a,(partition_size+2)
				ld c,a										;C = [23:16] for following division
				or a										;if A = 0, write 16 bit sector size word
				jr nz,ts_dword								;else update the 32 bit sector size word
				ld (ix+13h),e								;set total sectors (word) when < 65536
				ld (ix+14h),d
				jr ts_done
ts_dword		ld (ix+20h),de								;set total sectors (dword) when >65535
				ld (ix+23h),0

ts_done			ld a,h										; A = sectors-per-cluster
				ld hl,0				
ffatslp1		srl a	
				jr z,fatsc1									;divide total sectors by sectors per cluster..
				srl c				
				rr d
				rr e
				rr h
				rr l
				jr ffatslp1
fatsc1			ld b,8
ffatslp2		srl c										; ..and 256 to find length of FAT tables
				rr d
				rr e
				rr h
				rr l
				djnz ffatslp2
				ld a,h
				or l
				jr z,gotfatsize								; if remainder, add 1 to number of sectors in FAT
				inc de
	
gotfatsize		ld (ix+16h),e								;fill in sectors per FAT in boot sector data
				ld (ix+17h),d
				ld hl,0
				ld l,e
				ld h,d
				ld (fs_sectors_per_fat),hl
				
				ld bc,0aa5500h
				ld (sector_buffer+1fdh),bc					;fill in $55,$AA format ID
				ld de,0
				call set_lba_and_write_sector				;write boot sector
				ret c
				
				ld de,0
				ld e,(ix+0eh)								
				ld d,(ix+0fh)								;xDE = location for FAT1 (P.B.S + reserved sectors)
				
				call fs_clear_sector_buffer					;initial FAT entry is FF,F8,FF,FF
				ld (ix+0),0ffh
				ld (ix+1),0f8h
				ld (ix+2),0ffh
				ld (ix+3),0ffh
				call set_lba_and_write_sector				;write FAT1 
				ret c

				ex de,hl
				ld de,(fs_sectors_per_fat)	
				add hl,de
				ex de,hl
				call set_lba_and_write_sector 				;write fat 2 (at reserved_sectors + sectors_per_fat)
				ret c	

				call fs_clear_sector_buffer					;make root dir sector
				push de	
				ld hl,fs_sought_filename
				ld de,sector_buffer
				ld bc,11
				ldir										;copy volume label
				pop de										
				ld (ix+0bh),8									
				ld (ix+018h),021h							;set date to 1 JAN 1980
				
				ex de,hl
				ld de,(fs_sectors_per_fat)					
				add hl,de
				ex de,hl
				call set_lba_and_write_sector				;write 1st root dir entry (at reserved_sectors + (sectors_per_fat*2)
				ret c	
						

				ld hl,partition_base						;change the partition ID in the MBR if necessary..	
				ld a,(hl)
				inc hl
				or (hl)
				inc hl
				or (hl)
				inc hl
				or (hl)
				jr z,format_done							;if the partition is located at 0, there in no MBR to check/update

				call fs_read_mbr							;which partition is being formatted?
				ret c
				ld ix,sector_buffer+1beh
				ld c,0
fs_lanp			ld b,4
				lea de,ix+8
				ld hl,partition_base
fs_fpart		ld a,(de)
				cp (hl)
				jr z,fs_chkpaddrlp
				lea ix,ix+16								;try next partition entry
				inc c
				ld a,c
				cp 4
				jr nz,fs_lanp				
				ld a,0ceh									;if cannot locate partition, error $ce
				or a
				ret
fs_chkpaddrlp	inc de
				inc hl
				djnz fs_fpart								;loop to compare all 4 bytes
				
				ld a,(ix+4)									;found the partition, what's the partition ID byte?
				cp 0eh
				jr z,format_done							;if set for FAT16 LBA, nothing else to do..
				ld (ix+4),0eh
				ld hl,0										;if not, set it to 0E and rewrite MBR
				xor a
				ld (sector_lba0),hl					 
				ld (sector_lba0+3),a				
				call fs_write_sector
				ret c

format_done		xor a										;no error on return 
				ret				
				

				


set_lba_and_write_sector

				push hl
				push de
				push bc
				ld hl,(partition_base)
				ld a,(partition_base+3)
				ld b,0
				add hl,de
				adc a,b
				ld (sector_lba0),hl					 
				ld (sector_lba0+3),a				
				call fs_write_sector
				pop bc
				pop de
				pop hl
				ret



fs_read_mbr		ld hl,0
				xor a
				ld (sector_lba0),hl					 
				ld (sector_lba0+3),a				
				call fs_read_sector
				ret
				


;---------------------------------------------------------------------------------------------

fs_get_partition_info

; Set A to partition: $00 to $03
; On return: If A = $00, IX = Address of requested partition table entry
;            If A = $d3, no partition table is present at sector 0
;            If A = $ce, Disk format is bad 
;            If A = $cf, No (or unknown,non-FATxx) partition is defined
;            If carry flag set, there was a hardware error

				
				call fs_read_mbr						; read sector zero
				ret c
			
				call fs_check_fat_sig					; sector 0 must always have the FAT marker
				jr nz,formbad
			
				call check_fat16_id						; if 36-3a = 'FAT16' sector 0 is not an MBR
				jr nz,mbr_at_zero						
				ld a,0d3h								; return code $d3 - No MBR on this device
				or a
				ret

mbr_at_zero		ld de,16
				ld a,(partition_temp)
				ld d,a
				mlt de
				ld ix,sector_buffer+01beh
				add ix,de
				bit 2,(ix+4)							; partition ID code = FATxx?
				jr nz,formok							
				ld a,0cfh								; if no partition/non-FATxx partition error code $CF - invalid volume
				or a
				ret
				
formok			xor a									; ix = address of partition table entry
				ret
					



check_fat16_id
		
				ld hl,sector_buffer+036h				; carry set if 36-3a = FAT16
				ld de,fat16_txt			
				ld b,5
				call os_compare_strings
				ret
				
;----------------------------------------------------------------------------------------------


fs_check_fat_sig

				ld hl,(sector_buffer+01feh)				; check FAT signature @ $1FE in sector buffer 
				ld de,0aa55h
				xor a
				sbc.s hl,de								; 16 bit subtract
				ret
			
			
			
formbad			ld a,0ceh								; error code $ce - incompatible format			
				or a
				ret

;---------------------------------------------------------------------------------------------


fs_check_disk_format

; ensures disk is FAT16, sets up constants..
	
				push bc
				push de
				push hl
				call go_checkf
				pop hl
				pop de
				pop bc
				ret
				
go_checkf		call fs_read_partition_bootsector
				ret c
				or a
				ret nz
				
				call fs_check_fat_sig					; must have a FAT signature at $1FE
				jr nz,formbad		
			
				call check_fat16_id						; must be FAT16
				jr nz,formbad
			
				ld ix,sector_buffer
				ld hl,(ix+0bh)							; get sector size
				ld de,512								; must be 512 bytes for these routines
				xor a
				sbc.s hl,de								; 16 bit subtract
				jr nz,formbad
			
				ld a,(ix+0dh)							; get number of sectors in each cluster
				ld (fs_cluster_size),a
				sla a
				ld (fs_bytes_per_cluster+1),a
							
				ld hl,0
				ld l,(ix+0eh)							; get 'sectors before FAT'
				ld h,(ix+0fh)
				ld (fs_fat1_position),hl				; note FAT1 position
				ld de,0
				ld e,(ix+16h)							; get sectors per FAT
				ld d,(ix+17h)
				ld (fs_sectors_per_fat),de
				add hl,de
				ld (fs_fat2_position),hl				; note FAT2 position
				add hl,de
				ld (fs_root_dir_position),hl 			; note location of root dir
				ex de,hl
				ld l,(ix+11h)							; get max root directory ENTRIES
				ld h,(ix+12h)							; FAT32 puts $0000 here, so quit if 0
				ld a,h
				or l
				jr z,formbad							
				add hl,hl								; Each entry is 32 bytes each, so 16 entries per sector
				add hl,hl								; (entries * 16) / 256 = number of SECTORS
				add hl,hl
				add hl,hl
				ex de,hl
				ld a,d
				ld (fs_root_dir_sectors),a				; note number of SECTORS used for root dir (max 255)			 
				ld bc,0
				ld c,d
				add hl,bc				
				ld (fs_data_area),hl					; hl = beginning of file data area
												
				ld hl,0
				ld bc,0
				ld c,(ix+022h)							; this the MSW of the 32bit sectors in partition count (0 if sectors < 65536)		
				ld b,(ix+023h)
				ld l,(ix+013h)							; this is the 16 bit version
				ld h,(ix+014h)
				ld a,h									; is 16 bit version 0?
				or l
				jr nz,got_tsfbs
				ld l,(ix+020h)							; if so get the LSW of the 32 bit version in HL
				ld h,(ix+021h)
got_tsfbs 		ld de,(fs_data_area)
				xor a									; calculate max clusters available for file data
				sbc.s hl,de								; subtract the amount of sectors up to the file data area
				jr nc,nomxcb
				dec.s bc
nomxcb			ld a,(fs_cluster_size)
fmaxcl			srl a
				jr z,got_cmaxc							; divide remaining sectors by sectors-per-cluster
				srl c				
				rr h
				rr l
				jr fmaxcl
got_cmaxc		push hl									; if max clusters > $ffef, truncate to $fff0
				ld de,0fff0h
				xor a
				sbc.s hl,de								; 16 bit subtract
				jr c,cmaxok
				pop hl
				push de
cmaxok			pop hl
				ld (fs_max_data_clusters),hl
				xor a
				ret				

;-----------------------------------------------------------------------------------------------

fs_read_partition_bootsector

				call fs_calc_volume_offset				; read in partition bootsector of currently selected volume
				ld hl,volume_mount_list
				add hl,de
				ld a,(hl)
				or a									; is volume present according to mount list?
				jr nz,fs_volpre
				ld a,0cfh								; error $cf = 'invalid volume'
				or a
				ret
			
fs_volpre		ld de,8									; get first sector of partition
				add hl,de
				ld de,sector_lba0
				ld bc,4
				ldir
				call fs_read_sector
				ret	

;---------------------------------------------------------------------------------------------

fs_calc_free_space

;returns free space in KB in HL:DE

				ld de,(fs_max_data_clusters)
				inc de
				inc de									; compensate for first two FAT entries always being ffff fff8
				push de
				pop ix
			
				xor a
cfs_lp2			ld (fs_working_sector),a
				ld hl,(fs_fat1_position)
				call set_abs_lba_and_read_sector
				ret c
				
				ld hl,sector_buffer
				ld b,0
cfs_lp1			xor a
				or a,(hl)								; most of the time if the cluster is in use the
				inc hl									; first byte will be zero, so its quickest to test
				jr nz,cfs_ciu							; that first
				or a,(hl)
				jr z,cfs_ddcc
cfs_ciu			dec ix									; reduce free cluster count if fat entry in use
cfs_ddcc		inc hl
				dec de
				ld a,d
				or e
				jr z,cfs_ok								; max cluster count depleted?
				djnz cfs_lp1
				ld a,(fs_working_sector)
				inc a
				jr cfs_lp2
				
cfs_ok			ld a,(fs_cluster_size)					; convert free clusters to KB
cltoslp			srl a
				jr z,powdone
				add ix,ix
				jr cltoslp	
powdone			ld iy,xrr_temp
				ld (iy),ix								; de number of sectors, divide by 2 to get k.bytes
				srl (iy+2)
				rr (iy+1)
				rr (iy+0)								
				ld de,(iy)								; de = Kilobytes
				xor a
				ret

;---------------------------------------------------------------------------------------------

fs_change_dir_command

; INPUT: HL = directory name ascii (zero/space terminate)
			
			
				call fs_find_filename					; returns with start of 32 byte entry in IX
				ret c									; quit on hardware error
				cp 0c2h									; file not found error?
				jr nz,founddir
				ld a,0d1h								; error $d1 - dir not found
				or a
				ret

founddir		bit 4,(ix+0bh)
				jr nz,fs_isadir
				ld a,0c4h
				or a
				ret
				
fs_isadir		ld de,0
				ld e,(ix+01ah)
				ld d,(ix+01bh)							; de = starting cluster of dir
				call fs_update_dir_cluster
				xor a
				ret


;----------------------------------------------------------------------------------------------
	
	
fs_goto_root_dir_command

				push de
				ld de,0
				call fs_update_dir_cluster
				pop de
				xor a
				ret

;----------------------------------------------------------------------------------------------
	
	
fs_parent_dir_command

				call fs_get_dir_cluster
				ld a,d
				or e
				jr nz,pdnaroot
				ld a,0cah								; error $ca = already at root block
				or a
				ret
pdnaroot		ld hl,0202e2eh							; make filename = '..         '
				ld (fs_sought_filename),hl				; (cant use normal filename copier due to dots)
				ld hl,fs_sought_filename+3		
				ld a,32
				ld bc,8
				call os_bchl_memfill
				jr fs_change_dir_command
				
		
;------------------------------------------------------------------------------------------------
		
fs_open_file_command

; INPUT: xHL = filename ascii (zero/space terminate)
; OUTPUT: C:xDE  = File length
;            HL  = Start cluster of file
;            Internal vars (file pointer reset to zero etc)

			
				call fs_find_filename				; set fs_filename ascii string before calling!
				ret c								; h/w error?
				ret nz								; file not found
								
				ld a,0c6h							; prep for error $c6 - not a file
				bit 4,(ix+0bh)
				ret nz

				xor a
				ld (fs_filepointer_valid),a			; invalidate filepointer
				ld hl,0
				ld (fs_file_pointer),hl				; default 32bit file pointer offset = 0
				ld (fs_file_pointer+3),a			
				ld (fs_sector_last_read_lba0),hl	; force fs_read_data routine to always refresh 
				ld (fs_sector_last_read_lba0+3),a	; sector buffer at the first pass

				ld de,(ix+01ch)
				push de
				pop hl
				ld c,(ix+01fh)						; get filelength in C:xDE
				ld (fs_file_length),de				; [23:0]
				ld a,c
				ld (fs_file_length+3),a				; [32:24]
				or a								; default 24 bit transfer length = file length
				jr z,fs_dflsm						; if file length > 16MB, transfer length = $ffffff
				ld hl,0ffffffh
fs_dflsm		ld (fs_file_transfer_length),hl		
				
				ld hl,0
				ld l,(ix+01ah)		
				ld h,(ix+01bh)
				ld (fs_file_start_cluster),hl		; set file's start cluster (in HL on return)				
				
				xor a
				ret


;------------------------------------------------------------------------------------------------

fs_read_data_command		

;*******************************************
;*** 'fs_open_file' must be called first ***
;*******************************************
		
fs_load			call fs_test_transfer_length		; check that load length req > 0
				jr nz,fs_btrok

fs_fliz			ld a,0c7h							; error $c7 - requested file length is zero
				or a
				ret
			 
fs_btrok		ld hl,(fs_ez80_address)				; set load address 
				ld (fs_ez80_working_address),hl		; routine affects working register copy only
			
				ld hl,(fs_file_pointer)				; check file pointer position is valid
				ld a,(fs_file_pointer+3)			; compare against TOTAL file length (ie: not
				ld de,1								; the temp working copy, which may be truncated)
				add hl,de
				adc a,0
				ld c,a
				ex de,hl							; C:DE = filepointer + 1
				ld hl,(fs_file_length)				
				ld a,(fs_file_length+3)				; A:HL = File length
				or a								
				sbc hl,de							
				sbc a,c
				jp c,fs_rd_eof
					
fs_fpok			ld a,(fs_filepointer_valid)			; if the file pointer has been changed, we need
				or a								; to seek again from start of file
				jr nz,fs_get_sector_if_necessary	; otherwise just continue reading from last position
			
seek_strt		ld a,1
				ld (fs_filepointer_valid),a
				ld hl,(fs_file_start_cluster)		; get original record for working cluster
				ld (fs_file_working_cluster),hl		; routine affects working register copy only
			
				ld a,(fs_file_pointer+3)			; move into file - sub bytes_per_cluster and advance
				ld hl,(fs_file_pointer)				; a block if no carry 	
fs_fpblp		ld bc,(fs_bytes_per_cluster)
				xor a
				sbc hl,bc							
				sbc a,0
				jr c,fs_fpgbo
				push hl				
				ld hl,(fs_file_working_cluster)		; get value of next cluster in chain
				call get_fat_entry_for_cluster
				jr nc,fs_ghok						; hardware error?
				pop hl
				ret
fs_ghok			ld (fs_file_working_cluster),hl		; update cluster where desired bytes are located
				pop hl
				jr fs_fpblp
			
fs_fpgbo		add hl,bc							; HL = cluster's *byte* offset
				ld a,h
				srl a								; c = sectors into cluster	
				ld (fs_sector_pos_cnt),a
				ld a,h
				and 01h
				ld h,a
				ld (fs_in_sector_offset),hl			; bytes into sector where data is to be read from

				

fs_get_sector_if_necessary
				
				call fs_test_transfer_length		
				jr z,fs_read_done	
				
				ld hl,(fs_file_working_cluster)
				call fs_compare_hl_fff8				; if the continuation cluster >= $fff8, its the EOF
				jr c,fs_rd_noteof		
fs_rd_eof		ld a,0cch							; error $cc - requested bytes beyond end of file
				or a
				ret
				
fs_rd_noteof	ld hl,(fs_file_working_cluster) 	; refresh sector_buffer if the required sector
				ld a,(fs_sector_pos_cnt)			; is different to that already loaded
				call cluster_and_offset_to_lba
				call fs_is_same_sector_in_buffer
				jr z,fs_same_sector
				call fs_read_sector									
				ret c								; driver error?
			
fs_same_sector	ld hl,512
				ld de,(fs_in_sector_offset)
				xor a
				sbc hl,de							
				push hl
				pop bc								; by default bytes to transfer = remaining bytes in sector 
				
				ld de,(fs_file_transfer_length)
				xor a
				sbc hl,de
				jr c,fs_got_bc						; if bytes to transfer < than bytes left to read
				push de								; from sector, then transfer count = bytes_to_transfer
				pop bc

fs_got_bc		ld hl,sector_buffer
				ld de,(fs_in_sector_offset)			; hl = source address
				add hl,de
				ld de,(fs_ez80_working_address)		; de = dest address
				push bc
				ldir								; transfer the bytes
				ld (fs_ez80_working_address),de		; update destination address
				pop bc
				call fs_adjust_fp_tl_so
				ld hl,(fs_in_sector_offset)
				ld a,h
				cp 02h								; does transfer move into a new sector?
				jr z,fs_new_sec
fs_read_done	xor a
				ret

fs_new_sec		ld hl,0
				ld (fs_in_sector_offset),hl			; new sector now so offset-within-sector is zero
				ld hl,fs_sector_pos_cnt				; loop until all sectors in cluster read
				inc (hl)
				ld a,(fs_cluster_size)
				cp (hl)
				jr nz,fs_get_sector_if_necessary
				
				ld (hl),0							; first sector in (next) cluster
				ld hl,(fs_file_working_cluster)		; move to next cluster of file
				call get_fat_entry_for_cluster		; get location of the next cluster in this file's chain
				ret c								; h/w error?
				ld (fs_file_working_cluster),hl		; update the working cluster for next read
				jr fs_get_sector_if_necessary

;----------------------------------------------------------------------------------------------

fs_adjust_fp_tl_so

; advance / reduce by BC

				push bc
				push hl
				ld hl,(fs_file_pointer)				; advance file pointer by 1-512 bytes
				add hl,bc
				ld (fs_file_pointer),hl				
				ld a,(fs_file_pointer+3)			; file pointer is 32 bit so do [31:24]
				adc a,0
				ld (fs_file_pointer+3),a		
				
				ld hl,(fs_file_transfer_length)
				xor a
				sbc hl,bc
				ld (fs_file_transfer_length),hl		; reduce remaining transfer byte count
				
				ld hl,(fs_in_sector_offset)
				add hl,bc
				ld (fs_in_sector_offset),hl
				
				pop hl
				pop bc
				ret
				
				
fs_test_transfer_length
				
				push bc
				push hl
				ld hl,0
				ld bc,(fs_file_transfer_length)
				xor a
				adc hl,bc
				pop hl
				pop bc
				ret
				
;----------------------------------------------------------------------------------------------

fs_make_dir_command		
				
				call fs_find_filename					;does this file/dir name already exist?
				ret c
				cp 0c2h									;error $c2 - fnf?
				jr z,mdirfnde
				ld a,0c9h								;error $c9: 'filename already exists'
				or a
				ret
			
mdirfnde		call fs_find_free_cluster				;check for free space of disk
				ret c									;hardware error?
				ret nz									;disk full?
							
				ld hl,(fs_free_cluster)
				ld (fs_new_file_cluster),hl
			
				call fs_find_free_dir_entry				;look for a free entry in current dir table
				ret c									;hardware error?
				ret nz									;error $03 = (root) dir table is full / $01 = disk is full
			
				push ix									;copy filename to dir entry (first 11 bytes) 
				pop de
				ld hl,fs_sought_filename
				ld bc,11
				ldir
				xor a									;clear rest of dir entry (remaining 21 bytes)
				ld b,21
clrdiren		ld (de),a
				inc de
				djnz clrdiren
				ld (ix+0bh),010h						;set attribute byte, $10 = subdirectory
				ld (ix+018h),021h						;set date: Jan 1 1980
				ld de,(fs_new_file_cluster)
				ld (ix+01ah),e							;set cluster of new dir
				ld (ix+01bh),d
				call fs_write_sector					;rewrite the current sector
				ret c									;hardware error?
				
				call fs_clear_sector_buffer
				ld ix,sector_buffer						;make the standard '.' and '..' sub-directories
				ld (ix+00h),02eh						;in first sector of new directory
				ld (ix+01h),020h
				ld (ix+020h),02eh
				ld (ix+021h),02eh
				ld (ix+0bh),010h
				ld (ix+02bh),010h
				ld de,(fs_new_file_cluster)				; '.' entry's cluster
				ld (ix+01ah),e
				ld (ix+01bh),d
				call fs_get_dir_cluster					; '..' entry's cluster
				ld (ix+03ah),e
				ld (ix+03bh),d
				ld (ix+018h),021h						;set date: Jan 1 1980
				ld (ix+038h),021h						;set date: Jan 1 1980
				ld b,9
mndelp			ld (ix+002h),32
				ld (ix+022h),32
				inc ix
				djnz mndelp
				ld hl,(fs_new_file_cluster)				;write to first sector of the new dir cluster
				xor a
				call cluster_and_offset_to_lba
				call fs_write_sector
				ret c									;hardware error?
			
				call fs_clear_sector_buffer				;now fill rest of cluster with zeroes	
				xor a
wroslp			inc a
				ld (fs_working_sector),a
				ld hl,fs_cluster_size
				cp (hl)
				jr z,allsclr
				ld hl,(fs_new_file_cluster)
				call cluster_and_offset_to_lba
				call fs_write_sector
				ret c
				ld a,(fs_working_sector)
				jr wroslp
			
allsclr			ld hl,(fs_new_file_cluster)				;mark cluster 'in use / no continuation'
				ld de,0ffffh
				call update_fat_entry_for_cluster
				xor a
				ret



;------------------------------------------------------------------------------------------------

fs_delete_dir_command

				call fs_find_filename					;does filename exist in current dir?
				ret c
				jr z,ddc_gotd
				ld a,0d1h								;change file not found error to $d1 - dir not found
				or a
				ret
				
ddc_gotd		bit 4,(ix+0bh)							;is it really a directory?
				jr nz,okdeldir
				ld a,0c4h								;error $c4 - not a dir
				or a
				ret
				
okdeldir		ld (fs_fname_in_sector_addr),ix			;store position in sector where filename was found
				call backup_sector_lba
				ld l,(ix+01ah)							;hl = starting cluster of dir
				ld h,(ix+01bh)
				
fs_ddecl		ld a,(fs_cluster_size)
				ld b,a									;check that this dir is empty
				ld c,0			
fs_cne2 		ld a,c
				call cluster_and_offset_to_lba
				call fs_read_sector
				ret c									;hardware error?
				
				push bc
				ld b,16									;entries per sector count
				ld ix,sector_buffer
				ld de,020h
fs_cne1			ld a,(ix)
				or a
				jr z,fs_chnde
				cp 0e5h
				jr z,fs_chnde
				cp '.'
				jr z,fs_chnde
				pop bc
				ld a,0c5h								;error $c5, cant delete directory - its not empty.
				or a
				ret
			
fs_chnde		add ix,de
				djnz fs_cne1
				pop bc
				inc c
				djnz fs_cne2
			
				call get_fat_entry_for_cluster			;cluster is empty, any more clusters in dir chain?
				ret c
				call fs_compare_hl_fff8
				jr c,fs_ddecl
			
dir_empty		call restore_sector_lba					; sector where filename was found
				call fs_read_sector
				ret c									; hardware error?
				ld hl,(fs_fname_in_sector_addr)			; position in sector where filename was found
fs_delco		ld (hl),0e5h							; mark entry deleted and re-write current sector
				call fs_write_sector
				ret c
			
				push hl
				pop ix
				ld l,(ix+01ah)
				ld h,(ix+01bh)
				ld (fs_working_cluster),hl
				ld a,h									; if the start cluster is $0000, then the file
				or l									; was created only and has no associated clusters
				ret z									; to free up in the FAT.
				
clrfatlp		ld hl,(fs_working_cluster)
				call get_fat_entry_for_cluster
				ret c
				ex de,hl
				
				ld hl,(fs_working_cluster)
				ld (fs_working_cluster),de
				ld de,0
				call update_fat_entry_for_cluster		;clear cluster allocation
				ret c
				
				call fs_compare_hl_fff8					;last cluster in chain?
				jr c,clrfatlp
				xor a
				ret


;------------------------------------------------------------------------------------------------

fs_create_file_command

; Note: As per FAT standard, creating a file (0 bytes) does not use a FAT entry
; only a directory entry (FAT is only updated when data is added)

				call fs_find_filename				; does this file/dir name already exist?
				ret c
				cp 0c2h								; we want a $c2 - fnf error - here
				jr z,mfilefnde
				
				ld a,0c9h							; error $c9: 'filename already exists'
				or a
				ret
			
mfilefnde		call fs_find_free_dir_entry			; look for a free entry in current dir table
				ret c								; hardware error?
				ret nz								; error $c3 = (root) dir table is full / $c1 = disk is full
			
				push ix								; copy filename to dir entry (first 11 bytes) 
				pop de
				ld hl,fs_sought_filename
				ld bc,11
				ldir
				xor a								; clear rest of dir entry (remaining 21 bytes)
				ld b,21
clrfnen			ld (de),a
				inc de
				djnz clrfnen
				ld (ix+018h),021h					; set date: Jan 1 1980
				call fs_write_sector				; rewrite the current sector
				ret c								; hardware error?
				xor a
				ret									; return A=0, carry clear = All OK.


;---------------------------------------------------------------------------------------------

fs_write_bytes_to_file_command
	
; ***************************************************************************
; * set up: fs_file_transfer_length (new data), fs_filename, fs_ez80_address*
; * before calling                                           		 		*
; ***************************************************************************

				
				ld de,(fs_file_transfer_length)			;24 bit length of new data
				ld hl,0
				xor a
				adc hl,de
				jp z,fs_fliz							;if append data length is zero, return with error	
				 
				call fs_find_filename					;look for this file within current directory
				ret c									;quit on h/w error
				cp 0c2h				
				jr nz,fs_fetwt							;if error $c2 ('file not found') then quit
				or a
				ret
fs_fetwt		bit 4,(ix+0bh)							;test dir/file attribute bit
				jr z,fs_oknad							;if zero, its a file: OK to proceed
				ld a,0c6h								;else error $c6 - not a file
				or a
				ret

fs_oknad		call backup_sector_lba
				ld (fs_fname_in_sector_addr),ix

				ld iy,(ix+01ch)							;get existing 32bit file length in A:xIY
				ld a,(ix+01fh)
				ld (fs_existing_file_length),iy			;make a note of existing file length for seek-to-end
				ld (fs_existing_file_length+3),a
				ld de,(fs_file_transfer_length)			;transfer length is a 24 bit value
				add iy,de								;add length of new data to length of existing file
				adc a,0
				ld (ix+01ch),iy											
				ld (ix+01fh),a							;update filelength in sector data
				jr nc,nfsizeok
				ld a,0c7h								;error code $07 - filesize > $ffffffff
				or a
				ret

nfsizeok		ld de,0
				ld e,(ix+01ah)							
				ld d,(ix+01bh)							;get first cluster of file in DE (will be 0 if existing filesize = 0)
				ld (fs_file_working_cluster),de		
				call fs_write_sector					;rewrite the current sector that contains the directory entry 
				ret c
				ld a,d
				or e
				jr nz,apenclch							;if current sector is not 0, this is an append operation
				
				call fs_find_free_cluster				;look for a fresh cluster for file data as original file length was zero
				ret c
				ret nz
				ld hl,(fs_free_cluster)
				ld (fs_file_working_cluster),hl
				ld de,0ffffh
				call update_fat_entry_for_cluster		;mark new cluster as used 
				ret c
			
				call restore_sector_lba					;re-read the sector with the filename in it
				call fs_read_sector
				ret c
				ld ix,(fs_fname_in_sector_addr)			;update the start cluster entry
				ld de,(fs_file_working_cluster)	
				ld (ix+01ah),e
				ld (ix+01bh),d
				call fs_write_sector					;rewrite sector 
				ret c
				
					
apenclch		ld hl,(fs_file_working_cluster)			;move along cluster chain, looking for final cluster
				call get_fat_entry_for_cluster
				ret c
				call fs_compare_hl_fff8
				jr nc,atlclif
				ld (fs_file_working_cluster),hl
				ld bc,0
				ld a,(fs_cluster_size)
				sla a
				ld b,a
				ld hl,(fs_existing_file_length)			;subtract a cluster's byte-length from original file length
				xor a									;note: it's not necessary to adjust the MSB of the 32 bit
				sbc hl,bc								;length as only the lower bytes are used from the result
				ld (fs_existing_file_length),hl
				jr apenclch
				
atlclif			ld bc,(fs_existing_file_length)
				srl b				
				ld c,b										;c = sectors into this cluster
				ld a,(fs_cluster_size)
				sub c
				ld b,a										;b = remaining sectors in cluster
				jr z,fs_sfncl								;if b = 0, continuation is at end of cluster, new cluster req'd
				
				ld hl,(fs_file_working_cluster)
				ld a,c
				call cluster_and_offset_to_lba
				call fs_read_sector
				ret c
				push bc										;store sector and count
				
				ld de,0
				ld a,(fs_existing_file_length)
				ld e,a
				ld a,(fs_existing_file_length+1)
				and 1
				ld d,a										;DE = $0 to $1FF, file continuation offset in sector
				ld hl,512	
				xor a
				sbc hl,de									
				push hl
				pop bc										;BC = remaining bytes in sector
				ld hl,sector_buffer
				add hl,de
				ex de,hl									;DE = destination addr in sector buffer
				ld a,h			
				or l
				jr nz,fs_dcsb								;If at byte 0 of sector buffer: clear buffer
fs_dbfil		call fs_clear_sector_buffer
fs_dcsb			ld hl,(fs_ez80_address)						;xHL = source of data to appended
fs_cbsb			ldi											;(hl)->(de), hl=hl+1, de=de+1, bc=bc-1
				ld a,h										; src address wrapped?
				or l
				jr nz,fs_srcadok
				ld (fs_ez80_address),hl
				ld a,(fs_ez80_address+2)
				or a
				jp z,fs_mem_error
fs_srcadok		call transfer_length_countdown
				jr z,fs_lbof								;all bytes written?
fs_sadok		ld a,b										
				or c
				jr nz,fs_cbsb								;last byte of sector?

				ld (fs_ez80_address),hl						;update the source address count register
				pop bc										;retrieve the sector postition and count
				ld a,c
				ld hl,(fs_file_working_cluster)	
				call cluster_and_offset_to_lba
				call fs_write_sector						;write out this sector
				ret c										;quit on h/w error
				inc c										;inc sector count
				dec b
				jr z,fs_sfncl								;any more sectors in this cluster?	
fs_sfns			push bc				
				ld bc,512									;byte count max = full sector
				ld de,sector_buffer							;no offset from start of sector buffer
				jr fs_dbfil									;loop back and do next sector of cluster
				
fs_sfncl		call fs_find_free_cluster					;new block required
				ret c										;h/w error?
				ret nz										;quit if disk is full
				ld hl,(fs_file_working_cluster)
				ld de,(fs_free_cluster)
				call update_fat_entry_for_cluster			;current cluster points to new cluster
				ret c
				ld hl,(fs_free_cluster)
				ld (fs_file_working_cluster),hl				;current file cluster becomes the new cluster	
				ld de,0ffffh
				call update_fat_entry_for_cluster			;mark new cluster as used / no continue (yet)
				ret c
				ld a,(fs_cluster_size)
				ld b,a										;sectors remaining in cluster (full quota)
				ld c,0										;sector position (at start)
				jr fs_sfns									;loop to block data fill
				
fs_lbof			pop bc
				ld a,c										;last sector updated, so write it out
				ld hl,(fs_file_working_cluster)		
				call cluster_and_offset_to_lba
				call fs_write_sector	
				ret c
				xor a										;A=0, carry clear = all done OK
				ret


fs_mem_error	ld a,0c8h									; error $c8 - memory overflow error
fs_flerr		pop bc
				or a										; clears carry flag
				ret			

;---------------------------------------------------------------------------------------------

fs_erase_file_command


				call fs_find_filename						;does filename exist in current dir?
				ret c
				ret nz
				
				bit 4,(ix+0bh)								;is it a file (and not a directory)?
				jr z,okdelf
				ld a,0c6h									;error $c6 - not a file
				or a
				ret
				
okdelf			push ix
				pop hl
				jp fs_delco									;use same code as dir delete to clear FAT etc
					

;---------------------------------------------------------------------------------------------


fs_rename_command

				call fs_find_filename				;does a file/dir already exist with that name?
				ret c								;h/w error?
				cp 0c2h												
				jr z,fs_nfnok						;if error = $c2 (file not found), its OK to proceed
				ld a,0c9h							;error $c9: 'filename already exists'
				or a
				ret
			
fs_nfnok		ld hl,fs_sought_filename			;stash replacement filename for now
				ld de,fs_filename_buffer
				ld bc,11
				ldir
				ld hl,fs_alt_filename				;get existing filename
				ld de,fs_sought_filename
				ld bc,11
				ldir
				call fs_find_filename				;does it exist?
				ret c
				cp 0c2h
				ret z								;file/dir not found - return with error
				
				push ix
				pop de
				ld hl,fs_filename_buffer	 	
				ld bc,11
				ldir								;overwrite original filename
				call fs_write_sector				;re-write relevent dir sector
				
fs_rndone		xor a
				ret
				

;-----------------------------------------------------------------------------------------------------------------


fs_goto_first_dir_entry

				call fs_get_dir_cluster
				ld (fs_dir_entry_cluster),de
				xor a
				ld (fs_dir_entry_sector),a						; 0 to cluster size
				ld de,0
				ld (fs_dir_entry_line_offset),de				; 0 to 480 incl, step 32. (continues into get_entry...)
				


fs_get_dir_entry

; No input parameters.
;
; Returns HL    = Location of null terminated filename string
;         IX:IY = Length of file (if applicable)
;         B     = File flag (1 = directory, 0 = file)
;         A     = Error code
;         Carry = Set if hardware error encountered (priority over A)


				ld a,(fs_dir_entry_sector)		
				ld c,a
				ld hl,(fs_dir_entry_cluster)					; HL = cluster, A = Sector offset. 
				call cluster_and_offset_to_lba
			
				ld a,h											; check special case for FAT16 root directory...
				or l											; if working cluster = 0, we're in the root 
				jr nz,nr_read									; dir so set up LBA directly
				ld hl,(fs_root_dir_position)		
				ld a,c
				call set_absolute_lba
				
nr_read			call fs_read_sector								;read the sector
				ret c											;exit upon hardware error
				
				ld de,(fs_dir_entry_line_offset)
dscan_int_loop	ld ix,sector_buffer
				add ix,de
ds_int_loop		ld a,(ix)
				or a											;dir line empty?
				jr z,fs_dir_entry_free		
				cp 0e5h											;dir entry deleted?
				jr z,fs_dir_entry_free	
				cp 05h											;special code = same as $e5
				jr z,fs_dir_entry_free	
				bit 3,(ix+0bh)									;if this entry is a volume lable (or LF entry) ignore it
				jr z,fs_dir_entry_in_use		

fs_dir_entry_free

				ex de,hl
				ld de,32
				add hl,de
				ex de,hl
				bit 1,d
				jr z,dscan_int_loop
				jr dscan_new_sect

fs_dir_entry_in_use
				
				ld (fs_dir_entry_line_offset),de
				push ix
				pop hl
				call os_clear_output_line
				ld b,8											;8 chars in FAT16 filename
				ld de,output_line
dcopyn			ld a,(hl)
				cp ' '											;skip if a space
				jr z,digchar
				ld (de),a
				inc de
digchar			inc hl
				djnz dcopyn
				ld a,(hl)										;if the extension starts with a space dont
				cp ' '											;bother with it
				jr z,dirnoex
				ld a,'.'										;put a dot
				ld (de),a
				inc de	
				ld bc,3											;copy 3 char extension			
				ldir
dirnoex			xor a 
				ld (de),a										;null terminate the filename
				
				ld b,a
				bit 4,(ix+0bh)									;is this entry a file?
				jr z,fs_fniaf		
				inc b											;on return, B = 1 if dir, 0 if file	
fs_fniaf		ld de,(ix+01ch)									;on return C:xDE = filesize
				ld c,(ix+01fh)
				ld hl,output_line								;on return, HL = location of filename string
				xor a
				ret




fs_goto_next_dir_entry

				ld de,32
				ld hl,(fs_dir_entry_line_offset)
				add hl,de
				ld (fs_dir_entry_line_offset),hl
				bit 1,h
				jp z,fs_get_dir_entry

dscan_new_sect	ld hl,0				
				ld (fs_dir_entry_line_offset),hl				;line offset reset to 0
			
				ld hl,fs_dir_entry_sector
				inc (hl)										;next sector
			
				ld de,(fs_dir_entry_cluster)
				ld a,d
				or e											;are we in the root dir?
				jr nz,nonroot2
				ld a,(fs_root_dir_sectors)
				cp (hl)
				jr z,endofdir			
				jp fs_get_dir_entry
																		
nonroot2		ld a,(fs_cluster_size)		
				cp (hl)											;last sector in cluster?
				jp nz,fs_get_dir_entry
				ld (hl),0										;sector offset reset to 0
				ld hl,(fs_dir_entry_cluster)
				call get_fat_entry_for_cluster
				ld (fs_dir_entry_cluster),hl
				call fs_compare_hl_fff8							;any more clusters in this chain?
				jp c,fs_get_dir_entry
	
endofdir		ld a,0d2h
				or a											; a = $d2, end of dir
				ret	
				
;-----------------------------------------------------------------------------------------------

fs_get_volume_label


; On return HL = volume label


				ld hl,(fs_root_dir_position)
				ld c,0
gvl_nrsec		xor a
				call set_abs_lba_and_read_sector
				ret c
				ld b,16										; sixteen 32 byte entries per sector
				ld ix,sector_buffer
find_vl			ld a,(ix+0bh)
				cp 08h
				jr z,got_label
				lea ix,ix+32								
				djnz find_vl								
				inc hl
				inc c
				ld a,(fs_root_dir_sectors)					; reached last sector of root dir?
				cp c										
				jr nz,gvl_nrsec
			
				call fs_read_partition_bootsector			; if not in root, get label from partition record
				ret c
				or a
				ret nz
				ld ix,sector_buffer+02bh
				
got_label		ld (ix+0bh),0								; null terminate volume label
				push ix
				pop hl
				xor a
				ret
				
				
;---------------------------------------------------------------------------------------------
; Internal subroutines
;---------------------------------------------------------------------------------------------

fs_compare_hl_fff8

;INPUT HL = value to compare with fff8
;OUTPUT CARRY set if < $fff8, ZERO FLAG set if = $fff8
	
	
				push hl
				push de
				ld de,0fff8h			
				or a											;clear carry flag
				sbc.s hl,de										;only want 16 bit subtract
				pop de
				pop hl
				ret

;---------------------------------------------------------------------------------------------


fs_find_free_cluster
	
				ld ix,0											;cluster entry counter
				ld de,(fs_fat1_position)						;fat sector start	
				xor a				
fs_ffcl2		ld (fs_working_sector),a	
				push de
				pop hl
				ld a,(fs_working_sector)
				call set_abs_lba_and_read_sector
				ret c
				ld hl,sector_buffer
				ld b,0
fs_ffcl1		ld a,(hl)										; scan the fat entry table for $0000 entry
				inc hl
				or (hl)
				inc hl
				jr z,fs_gotfc
				inc ix
				djnz fs_ffcl1
				
				ld hl,(fs_sectors_per_fat)
				ld a,(fs_working_sector)						;next sector of fat
				inc a				
				cp l		
				jr nz,fs_ffcl2									;stop if end of fat (assumes FAT < 256 sectors)
fs_dfull		ld a,c1h										
				or a											;error $c1: disk is full (and zero flag not set)
				ret
			
fs_gotfc		push ix											;cluster numbers > $ffef cannot be used 
				pop hl											;so if free cluster > $ffef disk is full
				dec hl											;
				dec hl											;hl=hl-2 as first two FAT entries are non-zero
				ld de,(fs_max_data_clusters)
				xor a
				sbc.s hl,de										;16bit subtract
				jr nc,fs_dfull
			
				ld (fs_free_cluster),ix
				xor a
				ret
	
	
;-----------------------------------------------------------------------------------------------
	
	
fs_find_free_dir_entry


; OUTPUT IX start of 32 byte dir entry in sector buffer

			
				call fs_get_dir_cluster					; get current directory in DE
				ex de,hl
ffenxtclu		ld (fs_file_working_cluster),hl
				xor a
				ld (fs_working_sector),a
			
ffenxtsec		ld hl,(fs_root_dir_position)			; initially set up LBA for a root dir scan
				ld a,(fs_working_sector)
				call set_absolute_lba
				
				call fs_get_dir_cluster					; if not actually in root...
				ld a,d
				or e
				jr z,at_rootd
				ld hl,(fs_file_working_cluster)			; ...set up LBA for current cluster
				ld a,(fs_working_sector)
				call cluster_and_offset_to_lba
				
at_rootd		call fs_read_sector
				ret c
				ld b,16									; sixteen 32 byte entries per sector
				ld de,32
				ld ix,sector_buffer
scdirfe			ld a,(ix)								; first byte must be $00 or $e5 to be usable
				or a
				jr z,got_fde
				cp 0e5h
				jr z,got_fde
				add ix,de								; move to next filename entry in dir
				djnz scdirfe							; all entries in this sector scanned?
				
				ld hl,fs_working_sector					; move to next sector of cluster
				inc (hl)
				
				call fs_get_dir_cluster					; are we scanning the root dir?
				ld a,d
				or e
				jr nz,ffenotroo
				ld a,(fs_root_dir_sectors)				; reached last sector of root dir?
				cp (hl)									; LSB only: Assumes < 256 sectors used for root dir
				jr nz,ffenxtsec
fenotfnd		ld a,0c3h								; error code $0c3 - (root) dir table is full
				or a
				ret
			
ffenotroo		ld a,(fs_cluster_size)					; reached last sector of dir cluster?
				cp (hl)
				jr nz,ffenxtsec
				ld hl,(fs_file_working_cluster)			; yes, so..		
				call get_fat_entry_for_cluster			; does this cluster have a continuation entry in the FAT?		
				ret c
				call fs_compare_hl_fff8					; if < $FFF8 set the base cluster to the continuation word 
				jr c,ffenxtclu
			
				call fs_find_free_cluster				; need to add a fresh cluster to this chain
				ret c									; h/w error?
				ret nz									; disk full?
				ld de,(fs_free_cluster)
				ld hl,(fs_file_working_cluster)	 	
				call update_fat_entry_for_cluster		; update cluster entry in FAT table
				ret c
				ex de,hl								; new cluster -> HL
				ld de,0ffffh
				call update_fat_entry_for_cluster		; set new cluster in use / continuation marker = STOP
				ret c
			
				ld hl,(fs_free_cluster)					; when adding a new cluster to a non-root directory
				call fs_clear_cluster					; list chain, it is necessary to clear it of any previous data	
				ret c
				ld hl,(fs_free_cluster)					; Note: This is referring to the (parent) dir list cluster,
				jp ffenxtclu							; not the new directory cluster itself
			
got_fde			xor a
				ret
					

;-----------------------------------------------------------------------------------------------

fs_clear_cluster

;INPUT HL = cluster to clear

				ld (fs_working_cluster),hl
			
				call fs_clear_sector_buffer
					
				xor a				
				ld (fs_working_sector),a			
wipeclulp		ld a,(fs_working_sector)		
				ld hl,(fs_working_cluster)		
				call cluster_and_offset_to_lba		
				call fs_write_sector
				ret c
				ld hl,fs_working_sector
				inc (hl)
				ld a,(fs_cluster_size)
				cp (hl)
				jr nz,wipeclulp
				xor a
				ret
			
			
fs_clear_sector_buffer
			
				push hl
				push de
				push bc
				ld hl,sector_buffer			
				ld bc,512				
				xor a				
				call os_bchl_memfill	
				pop bc
				pop de
				pop hl
				ret
				

	
;-----------------------------------------------------------------------------------------------
	
fs_find_filename

				xor a

fs_search	
				
				ld (fs_search_type),a
			
; OUTPUT IX start of 32 byte dir entry
			
				call fs_get_dir_cluster
ffnnxtclu		ld (fs_file_working_cluster),de
				xor a
				ld (fs_working_sector),a
			
ffnnxtsec		ld hl,(fs_root_dir_position)				; initially set up LBA for a root dir scan
				ld a,(fs_working_sector)
				call set_absolute_lba
				
				call fs_get_dir_cluster						; if not actually in root....
				ld a,d
				or e
				jr z,at_rootd2
				ld hl,(fs_file_working_cluster)				; ....set up LBA for current cluster	
				ld a,(fs_working_sector)
				call cluster_and_offset_to_lba	
				
at_rootd2		call fs_read_sector
				ret c
				ld c,16										; sixteen 32 byte entries per sector
				ld ix,sector_buffer
ndirentr		push ix
				pop de
				ld a,(fs_search_type)
				or a
				jr z,fs_ststr
			
				ld a,(ix)									; ensure dir entry is valid (IE: 1st filename
				cp 080h										; char is betweeen $20 and $80)
				jr nc,fnnotsame
				cp 020h
				jr c,fnnotsame
				ld de,(fs_stash_dir_block)					; search type 1 = find cluster reference
				ld a,(ix+01ah)
				cp e
				jr nz,fnnotsame
				ld a,(ix+01bh)
				cp d
				jr z,fs_found
				jr fnnotsame
				
fs_ststr		ld iy,fs_sought_filename					; search type = 0 find filename string
				ld b,11										; 8+3 chars to compare, filename and extension
cmpfnlp			ld a,(de)									; will have been padded with spaces so a single
				call os_uppercasify							; run on all 11 characters is fine
				ld l,a
				ld a,(iy)
				call os_uppercasify
				cp l				
				jr nz,fnnotsame
				inc iy
				inc de
				djnz cmpfnlp
fs_found		xor a										; found filename: return with zero flag set
				ret
			
fnnotsame		ld de,32									; move to next filename entry in dir
				add ix,de
				dec c
				jr nz,ndirentr								; all entries in this sector scanned?
				
				ld hl,fs_working_sector						; move to next sector
				inc (hl)
				
				call fs_get_dir_cluster						; are we scanning the root dir?
				ld a,d
				or e
				jr nz,notrootdir
				ld a,(fs_root_dir_sectors)					; reached last sector of root dir?
				cp (hl)										; LSB only: Assumes < 256 sectors used for root dir
				jp nz,ffnnxtsec
fnnotfnd		ld a,0c2h									; error code $c2 - filename not found
				or a
				ret
			
notrootdir
				
				ld a,(fs_cluster_size)						; reached last sector of dir cluster?
				cp (hl)
				jp nz,ffnnxtsec
				
				ld hl,(fs_file_working_cluster)		
				call get_fat_entry_for_cluster
				ret c
				call fs_compare_hl_fff8						; does this cluster have a continuation entry in the FAT?
				jr nc,fnnotfnd								; if hl > $FFF7 there's no continuation - stop scanning 
				ex de,hl									; put hl in DE for instruction at loop point
				jp ffnnxtclu								; set base cluster = the continuation word just found
				

;----------------------------------------------------------------------------------------------

fs_hl_to_alt_filename

				ld de,fs_alt_filename
				jr hltofngo


fs_hl_to_filename

;INPUT: HL = address of filename (null / space termimated)
;OUTPUT HL = address of first character after filename
;        C = number of characters in filename

				ld de,fs_sought_filename
hltofngo		call fs_clear_filename						; this preserves DE
				push de			
				pop ix										; stash filename address for extension
				
				ld c,0
				ld b,8
csfnlp2			ld a,(hl)									; now copy filename, upto 8 characters
				or a
				ret z										; is char a zero?
				cp 32
				ret z										; is char a space?
				cp 02fh
				ret z										; is char a fwd slash?
				cp '.'
				jr z,dofn_ext								; is char a dot?
				ld (de),a
				inc de
				inc hl
				inc c										; inc source character count
				djnz csfnlp2								; allow 8 filename chars
find_ext		ld a,(hl)
				cp '.'										; ninth char should be a dot
				jr z,dofn_ext	
				cp ' '										; if space, zero or forward slash, no extension
				ret z
				cp 02fh
				ret z
				or a
				ret z
				inc hl
				jr find_ext
				
dofn_ext		inc hl										; skip '.' in source filename
				ld b,3				
fnextlp			ld a,(hl)									; copy 3 filename extension chars
				or a
				ret z										; end if space or zero
				cp 32
				ret z
				ld (ix+8),a
				inc ix
				inc hl
				inc c
				djnz fnextlp
				ret
				
;----------------------------------------------------------------------------------------------


get_fat_entry_for_cluster

; INPUT: HL = cluster in question, OUTPUT: HL = cluster's FAT table entry

				push bc
				push de
				ld bc,0
				ld c,l
				ld a,h
				ld hl,(fs_fat1_position)
				call set_abs_lba_and_read_sector
				jr c,hwerr
				push ix
				ld ix,sector_buffer
				add ix,bc
				add ix,bc
				ld hl,0
				ld l,(ix)
				ld h,(ix+1)
				pop ix
hwerr			pop de
				pop bc
				ret


;----------------------------------------------------------------------------------------------


update_fat_entry_for_cluster

; INPUT: HL = cluster in question
;        DE = new value to put in FAT tables
			
				push bc
				push hl
				ld bc,0
				ld c,l
				ld a,h
				ld hl,(fs_fat1_position)					;update FAT 1
				call fat_upd
				jr c,fup_end
			
				pop hl
				push hl
				ld a,h
				ld hl,(fs_fat2_position)					;update FAT 2
				call fat_upd
fup_end			pop hl
				pop bc
				ret
			
			
fat_upd			call set_abs_lba_and_read_sector
				jr c,ufehwerr
				ld hl,sector_buffer
				add hl,bc
				add hl,bc
				ld (hl),e
				inc hl
				ld (hl),d
				call fs_write_sector
ufehwerr		ret
				
	
;-----------------------------------------------------------------------------------------------

transfer_length_countdown

				push hl										;count down number of bytes to transfer
				push bc
			
				ld b,4
				ld hl,fs_file_pointer						;advance the file pointer
fpinclp			inc (hl)
				jr nz,fs_fpino
				inc hl
				djnz fpinclp
				
fs_fpino		ld hl,(fs_file_transfer_length)
				dec hl
				ld (fs_file_transfer_length),hl
				ld bc,0
				or a
				adc hl,bc									;countdown = 0?
				
				pop bc
				pop hl
				ret

;-----------------------------------------------------------------------------------------------

fs_get_current_dir_name

;returns current dir name - location at HL

				call fs_get_dir_cluster						; get the current dir block
				ld a,d
				or e
				jr nz,fs_dnnr
				ld hl,vol_txt+1								; if at root ($0000), return 'volx:'
				ld a,(current_volume)
				add a,030h
				ld (vol_txt+4),a
				xor a
				ret
					
fs_dnnr			ld (fs_stash_dir_block),de
				call fs_parent_dir_command					; go up a directory
				ret c
				or a
				ret nz
				ld a,1
				call fs_search								; and look for the forward reference to the original cluster
				ret c
				ret nz
					
fs_gdbn			push ix
				pop hl
				ld b,11										;null terminate dir name string (in sector buffer)
ntdirn			ld a,(hl)
				cp ' '
				jr z,rdirfsp
				inc hl
rdirnsp			djnz ntdirn
				
rdirfsp			ld (hl),0
				push ix
				ld de,(fs_stash_dir_block)
				call fs_update_dir_cluster					; go back to original directory
				pop hl	
				xor a										; HL = current dir name
				ret

			
;----------------------------------------------------------------------------------------------

fs_clear_filename

				push de										;fills string at DE with 12 spaces
				push bc
				ld b,12
				ld a,' '
clrfnlp			ld (de),a
				inc de
				djnz clrfnlp
				pop bc
				pop de
				ret
				
;----------------------------------------------------------------------------------------------


cluster_and_offset_to_lba

; INPUT: HL = cluster, A = sector offset, OUTPUT: Internal LBA address updated

				push bc
				push de
				push hl
				push ix

				dec hl								; offset back by two clusters as there
				dec hl								; are no $0000 or $0001 clusters
				ld de,0								
				ld bc,0
				ld e,a
				ld a,(fs_cluster_size)				; multiply cluster by cluster_size and put in xHL
caotllp			srl a
				jr z,clusdone
				add hl,hl							; xHL * 2
				jr caotllp
			
clusdone		ld bc,(fs_data_area)			
				add hl,bc							; add start of data area
				add hl,de							; add sector offset
				
add_ptn_offset	push hl								; add volume's partition offset
				call fs_calc_volume_offset
				ld ix,volume_mount_list
				add ix,de
				pop hl
				ld bc,(ix+08h)						; A:xBC = partition start LBA
				ld a,(ix+0bh)
				add hl,bc
				adc a,0
				ld (sector_lba0),hl					; set LBA [23:0]
				ld (sector_lba3),a					; set LBA [31:24]
				
				pop ix
				pop hl
				pop de
				pop bc
				ret
				

;-----------------------------------------------------------------------------------------------

set_absolute_lba

; set A to sector offset, HL to sectors from start of partition

				push bc									; this takes a 16 bit 'offset from first sector of partition'
				push de									; address in HL, adds on an 8 bit offset from A
				push hl									; then adds on the 32bit partition offset
				push ix									; relevant to the volume, then sets the LBA registers
				ld bc,0
				ld de,0
				ld e,a
				add hl,de
				jr add_ptn_offset		
				

set_abs_lba_and_read_sector

				call set_absolute_lba
				jp fs_read_sector
				
;-----------------------------------------------------------------------------------------------


backup_sector_lba

				push bc
				push de
				push hl
				ld hl,sector_lba0
				ld de,fs_backed_up_sector_lba0
lbabur			ld bc,4
				ldir
				pop hl
				pop de
				pop bc
				ret


restore_sector_lba

				push bc
				push de
				push hl
				ld hl,fs_backed_up_sector_lba0
				ld de,sector_lba0
				jr lbabur	
					
;-----------------------------------------------------------------------------------------------

fs_read_sector
			
				push bc
				push de
				push hl
				push ix
				push iy
				ld bc,04h								;offset to 'read_sector' routine in driver
				call sector_access_redirect
secaccend		ld hl,(sector_lba0)
				ld (fs_sector_last_read_lba0),hl
				ld a,(sector_lba0+3)
				ld (fs_sector_last_read_lba0+3),a
				pop iy
				pop ix
				pop hl
				pop de
				pop bc
				ret z									;If ZF is set by low-level driver, all OK
				scf										
				ret										;Otherwise set CF. (A = driver error code)


fs_write_sector	
				
				push bc
				push de
				push hl
				push ix
				push iy
				ld bc,08h								;offset of 'write_sector' routine in driver
				call sector_access_redirect
				jr secaccend



sector_access_redirect

	
				ld a,(current_driver)					;selects sector h/w code to run based on the currently selected device type
				call locate_driver_base					;current device is updated by change_volume routine (or forced)
				ex de,hl
				add hl,bc								;HL = address of required routine
				jp (hl)

;-----------------------------------------------------------------------------------------------

fs_is_same_sector_in_buffer
				
				push hl
				push de
				ld hl,(sector_lba0)
				ld de,(fs_sector_last_read_lba0)
				xor a
				sbc hl,de
				jr nz,fs_notsamsec
				ld a,(sector_lba0+3)
				ld l,a
				ld a,(fs_sector_last_read_lba0+3)
				cp l
fs_notsamsec	pop de
				pop hl
				ret

;-----------------------------------------------------------------------------------------------
	
bootsector_stub

				db  0EBh,03Ch,090h,04Dh,053h,044h,04Fh,053h,035h,02Eh,030h,000h,002h,000h,040h,000h 
				db  002h,000h,002h,000h,000h,0F8h,0F2h,000h,03Fh,000h,0FFh,000h,000h,000h,000h,000h 
				db  000h,000h,000h,000h,000h,000h,029h,0C4h,0E6h,036h,098h,04Eh,04Fh,020h,04Eh,041h 
				db  04Dh,045h,020h,020h,020h,020h,046h,041h,054h,031h,036h,020h,020h,020h,0C3h    

;-----------------------------------------------------------------------------------------------

fs_cluster_size				db 0
fs_bytes_per_cluster		dw24 0
fs_fat1_position			dw24 0		; offset from partition base
fs_fat2_position			dw24 0		; offset from partition base
fs_root_dir_position		dw24 0		; offset from partition base
fs_data_area				dw24 0		; offset from partition base
fs_root_dir_sectors			db 0

fs_sectors_per_fat			dw24 0
fs_max_data_clusters		dw24 0

fs_sought_filename			blkb 12,0
fs_alt_filename				blkb 12,0
fs_filename_buffer			blkb 12,0

fs_file_pointer				dw 0,0		; 32 bit value
fs_file_length				dw 0,0		; 32 bit value
fs_existing_file_length 	dw 0,0		; 32 bit value	

fs_file_transfer_length		dw24 0		; 24 bit

fs_file_start_cluster		dw24 0
fs_file_working_cluster		dw24 0

fs_ez80_address				dw24 0
fs_ez80_working_address		dw24 0

fs_in_sector_offset			dw24 0
fs_working_sector			db 0

fs_working_cluster			dw24 0
fs_free_cluster				dw24 0
fs_new_file_cluster			dw24 0

fs_fname_in_sector_addr		dw24 0

fs_dir_entry_cluster		dw24 0
fs_dir_entry_line_offset	dw24 0
fs_dir_entry_sector			db 0

fs_filepointer_valid		db 0
fs_sector_pos_cnt			dw24 0

fs_stash_dir_block	 		dw24 0

fs_search_type				db 0

fs_backed_up_sector_lba0	db 0,0,0,0

fs_sector_last_read_lba0	db 0,0,0,0

partition_size				dw24 0			;24 bit
partition_base				db 0,0,0,0		;32 bit

;----------------------------------------------------------------------------------------------

