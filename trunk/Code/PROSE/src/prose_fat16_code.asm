;----------------------------------------------------------------------------------------------
; eZ80 FAT16 File System code for PROSE by Phil @ Retroleum (ADL mode)
;----------------------------------------------------------------------------------------------
;
; Changes:
;
; 0.05 - Fixed format command
; 0.04 - File system error codes are now in the C0-F0 range
; 0.03 - ADL mode
; 0.02 - removed references to banks, added 24 bit address for load/save
; 0.01 - first version based on FLOS routines v1.12
;
; Known limitations:
; ------------------
; If a disk full error is returned during a file write: The file reported length is not truncated
; Allows a file to be created in root even if there's no space for it
;        
;----------------------------------------------------------------------------------------------
;
; All routines return carry clear / zero flag set if OK
;
; Carry set = hardware error, A = error byte from hardware (0 = timed out) 
;
; Carry clear, A = 	00 $00 - Command completed OK
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

fs_format_device_command

; Creates a single partition (truncated to 2GB) @ sector zero (no MBR)


				ld a,(device_count)							;get current driver's entry in the device info table
				ld b,a										;ix = location of 32 byte entry
				ld ix,host_device_hardware_info
fdevinfo		ld a,(current_driver)
				cp (ix)
				jr z,got_dev_info
				lea ix,ix+32
				djnz fdevinfo
				xor a
				ld a,0d0h									;device not present error
				ret	
	
got_dev_info	call fs_clear_sector_buffer					;wipe sectors 0-767 sectors (this range covers
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
	
				ld a,(ix+4)									;if MSB of 32 bit total sectors <> 0, cap is > 2GB
				or a
				jr nz,above_2gb
				ld hl,3fff00h								;if total sectors [23:0] > 3fff00, cap is > 2GB
				ld de,(ix+1)								
				xor a			
				sbc hl,de									
				jr nc,lessthan2gb							
above_2gb		ld a,40h									;if cap is > 2GB, fix cluster size = 32KB
				ld de,3fff00h								;and truncate total sectors to = 2GB
				jr spcvalok

lessthan2gb		ld c,(ix+3)									;calc appropriate cluster size for capacity
				inc c										;c = (total sectors / 65536) + 1
spc_loop		ld a,1										;working cluster size
spc_comp		cp c										;sectors per cluster can only be 1,2,4,8,16,32 or 64
				jr z,spcvalok
				rlca
				cp 080h										;if not one of these values, inc until it is
				jr nz,spc_comp
				inc c			
				jr spc_loop									;loop until appropriate cluster size found
							
spcvalok		ld ix,sector_buffer
				ld (ix+0dh),a								;fill in sectors-per-cluster in boot sector data
				
				call os_get_xde_msb							;get xDE [23:16] in A
				ld c,a										;store xDE [23:16] in C for following division
				or a										;if A = 0, write 16 bit sector size word
				jr nz,ts_dword								;else update the 32 bit sector size word
				ld (ix+13h),e								;set total sectors (word) when < 65536
				ld (ix+14h),d
				jr ts_done
ts_dword		ld (ix+20h),de								;set total sectors (dword) when >65535
				ld (ix+23h),0

ts_done			ex de,hl									;xHL = total clusters
				ld de,0						
				ld d,(ix+0dh)								;xDE = cluster size * 256
				ld bc,0										;BC = xHL/xDE
div_tscls		xor a										;at end, xBC = size of fat table in sectors
				sbc hl,de
				jr z,gotfats
				jr c,gotfats	
				inc bc
				jr div_tscls
gotfats			inc bc
				ld (ix+16h),c								;fill in sectors per FAT in boot sector data
				ld (ix+17h),b
				ld (fs_sectors_per_fat),bc
				
				ld bc,0aa5500h
				ld (sector_buffer+1fdh),bc					;fill in $55,$AA format ID
				ld de,0
				call set_lba_and_write_sector				;write boot sector (LBA zero)
				ret c
				
				ld hl,0
				ld l,(ix+0eh)								;xHL = reserved sectors before fat from boot sector
				ld h,(ix+0fh)
				add hl,de
				ex de,hl									;xDE = loaction for FAT1
				
				call fs_clear_sector_buffer					;initial FAT entry is FF,F8,FF,FF
				ld (ix+0),0ffh
				ld (ix+1),0f8h
				ld (ix+2),0ffh
				ld (ix+3),0ffh
				call set_lba_and_write_sector				;write fat 1 (at MBR + 'reserved_sectors') 
				ret c

				ld hl,(fs_sectors_per_fat)	
				add hl,de
				ex de,hl
				call set_lba_and_write_sector 				;write fat 2 (at reserved_sectors + sectors_per_fat)
				ret c	
				
				push de										;make root dir sector
				call fs_clear_sector_buffer
				ld hl,fs_sought_filename
				ld de,sector_buffer
				ld bc,11
				ldir										;copy volume label
				pop de										
				ld (ix+0bh),8									
				ld (ix+018h),021h							;set date to 1 JAN 1980
				ld hl,(fs_sectors_per_fat)					
				add hl,de
				ex de,hl
				call set_lba_and_write_sector				;write 1st root dir entry (at reserved_sectors + (sectors_per_fat*2)
				ret c	
			
				xor a										;no error on return 
				ret
	


set_lba_and_write_sector

				push ix
				ld ix,sector_lba0							
				ld (ix),de									;set sector required = xDE 
				ld (ix+3),0
				pop ix
				call fs_write_sector
				ret
				
				
;---------------------------------------------------------------------------------------------

fs_get_partition_info

; Set A to partition: $00 to $03
; On return: If A = $00, xHL = Address of requested partition table entry
;            If A = $25, A partition table is not present at sector 0
;            If A = $13, Disk format is bad 
;            If carry flag set, there was a hardware error


				ld (partition_temp),a
				
				ld hl,0									; read sector zero
				ld (sector_lba0),hl
				ld a,l
				ld (sector_lba3),a
				call fs_read_sector
				ret c
			
				call fs_check_fat_sig					; sector 0 must always have the FAT marker
				jr nz,formbad
			
				call check_fat16_id						; if 36-3a = 'FAT16' this is disk has no MBR
				jr z,at_pbs								; assume there's a single parition at sector 0
				
				ld a,(sector_buffer+01c2h)				; assuming this is then an MBR, get the partition ID code 
				and 4									; bit 2 should be set for FAT16
				jr z,formbad	
				ld de,0
				ld a,(partition_temp)
				ld e,a
				ld d,16
				mlt de
				ld hl,sector_buffer+01beh
				add hl,de								; xhl = address of partition table entry
				xor a
				ret
					
at_pbs			xor a
				ld a,0d3h								; return code $d3 - No partition info (MBR) on this device
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
			
			
			
formbad			xor a
				ld a,0ceh								; error code $ce - incompatible format			
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
				
go_checkf		call fs_calc_volume_offset	
				ld hl,volume_mount_list
				add hl,de
				ld a,(hl)
				or a									; is volume present according to mount list?
				jr nz,fs_volpre
				xor a
				ld a,cfh								; error $cf = 'invalid volume'
				ret
			
fs_volpre		ld de,8									; get first sector of partition
				add hl,de
				ld de,sector_lba0
				ld bc,4
				ldir
				call fs_read_sector
				ret c	
				
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
				xor a									
				ld a,0d1h								; error $d1 - dir not found
				ret
founddir		xor a									; clear carry
				ld a,04h								; prep error code $04 - not a directory
				bit 4,(ix+0bh)
				ret z
				ld de,0
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

; INPUT: xHL = directory name ascii (zero/space terminate)
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
		
fs_load			ld hl,(fs_file_transfer_length)		; check that load length req > 0
				ld de,0
				xor a
				adc hl,de
				jr nz,fs_btrok
fs_fliz			xor a								; clear carry flag
				ld a,0c7h							; error $c7 - requested file length is zero
				ret
			 
fs_btrok		ld hl,(fs_ez80_address)				; set load address 
				ld (fs_ez80_working_address),hl		; routine affects working register copy only
			
				ld hl,(fs_file_length)				; check file pointer position is valid
				ld bc,(fs_file_pointer)				; compare against TOTAL file length (ie: not
				ld a,(fs_file_pointer+3)			; the temp working copy, which may be truncated)
				ld e,a
				ld a,(fs_file_length+3)
				or a								; clear carry flag
				sbc hl,bc
				sbc a,e
				jr c,fs_fpbad
				ld bc,0
				xor a
				adc hl,bc
				jr nz,fs_fpok
fs_fpbad		xor a
				ld a,0cch							; error $cc - requested bytes beyond end of file
				ret
			
	
fs_fpok			ld a,(fs_filepointer_valid)			; if the file pointer has been changed, we need
				or a								; to seek again from start of file
				jr z,seek_strt
			
				ld de,(fs_ez80_working_address)		; otherwise restore CPU registers and jump back into
				ld bc,(fs_sector_pos_cnt)			; main load loop
				push bc
				ld bc,(fs_in_sector_offset)
				ld hl,sector_buffer+0200h			; Set HL to sector buffer address
				xor a
				sbc hl,bc		
				jr fs_dadok
				
			
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
fs_fpgnb		push hl				
				ld hl,(fs_file_working_cluster)		; get value of next cluster in chain
				call get_fat_entry_for_cluster
				jr nc,fs_ghok						; hardware error?
				pop hl
				ret
fs_ghok			ld (fs_file_working_cluster),hl		; update cluster where desired bytes are located
				pop hl
				jr fs_fpblp
			
fs_fpgbo		add hl,bc							; HL = cluster's *byte* offset
				ld c,h
				srl c								; c = sectors into cluster	
				ld a,(fs_cluster_size)
				sub c
				ld b,a								; b = number of sectors to read
				ld a,h
				and 01h
				ld h,a
				ld (fs_in_sector_offset),hl			; bytes into sector where data is to be read from
				
fs_flns			ld a,c				
				ld hl,(fs_file_working_cluster) 
				call cluster_and_offset_to_lba
				call fs_read_sector					; read first sector of file
				ret c								; h/w error?
			
				push bc								; stash sector pos / countdown
				ld de,0
				ld hl,(fs_in_sector_offset)			; ensure xDE = $00:xxyy
				ld e,l
				ld d,h
				ld hl,512
				xor a
				sbc hl,de							
				ld b,h
				ld c,l								; bc = number of bytes to read from sector
				ld hl,sector_buffer					; sector base
				add hl,de							; add in-sector filepointer offset to sector base
				ld de,(fs_ez80_working_address)		; dest address for file bytes
fs_cblp			ldi 								; (hl)->(de), inc hl, inc de, dec bc

				ld a,d								; dest address passed a 64KB page?
				or e
				jr nz,fs_edaok
				ld (fs_ez80_working_address),de		; yes, check [23:16] - if zero, address error
				ld a,(fs_ez80_working_address+2)
				or a
				jr z,fs_mem_error

fs_edaok		call transfer_length_countdown		; zero flag set on return = last byte
				jr z,fs_bdld
fs_dadok		ld a,b								; last byte of sector?
				or c
				jr nz,fs_cblp
			
				ld (fs_in_sector_offset),bc			; byte offset for all following sectors is zero
				ld (fs_ez80_working_address),de		; update destination address
				pop bc								; retrive sector offset / sector countdown
				inc c								; next sector
				djnz fs_flns						; loop until all sectors in cluster read
			
				ld hl,(fs_file_working_cluster)	
				call get_fat_entry_for_cluster		; get location of the next cluster in this file's chain
				ret c								; h/w error?
				ld (fs_file_working_cluster),hl
				call fs_compare_hl_fff8				; if the continuation cluster >= $fff8, its the EOF
				jp nc,fs_fpbad			
fs_nfbok		ld c,0								; following clusters have zero sector offset		
				ld a,(fs_cluster_size)	
				ld b,a								; read full cluster of sectors
				jr fs_flns		
			
fs_bdld			ld (fs_in_sector_offset),bc			; all requested bytes transferred
				pop bc								; back up regs for any following sequential read
				ld (fs_sector_pos_cnt),bc
				xor a								; op completed ok: a = 0, carry = 0
				ret
				
fs_mem_error	ld a,0c8h							; error $c8 - memory overflow error
fs_flerr		pop bc
				or a								; clears carry flag
				ret			
			
;----------------------------------------------------------------------------------------------

fs_make_dir_command		
				
				call fs_find_filename					;does this file/dir name already exist?
				ret c
				cp 0c2h									;error $c2 - fnf?
				jr z,mdirfnde
				xor a									;clear carry flag
				ld a,0c9h								;error $c9: 'filename already exists'
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
				xor a
				ld a,0c4h								;error $c4 - not a dir
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
				xor a									;clear carry flag
				ld a,0c5h								;error $c5, cant delete directory - its not empty.
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
				xor a								; clear carry flag
				ld a,0c9h							; error $c9: 'filename already exists'
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
				ret z									;if error $c2 ('file not found') then quit
				bit 4,(ix+0bh)							;test dir/file attribute bit
				jr z,fs_oknad							;if zero, its a file: OK to proceed
				xor a									;clear carry flag
				ld a,0c6h								;else error $c6 - not a file
				ret

fs_oknad		call backup_sector_lba
				ld (fs_fname_in_sector_addr),ix

				ld iy,(ix+01ch)							;get existing 32bit file length in A:xIY
				ld a,(ix+01fh)
				ld (fs_existing_file_length),iy			;make a note of existing file length for seek-to-end
				ld (fs_existing_file_length),a
				ld de,(fs_file_transfer_length)			;transfer length is a 24 bit value
				add iy,de								;add length of new data to length of existing file
				adc a,0
				ld (ix+01ch),iy											
				ld (ix+01fh),a							;update filelength in sector data
				jr nc,nfsizeok
				xor a
				ld a,0c7h								;error code $07 - filesize > $ffffffff
				ret

nfsizeok		ld de,0
				ld e,(ix+01ah)							
				ld d,(ix+01bh)							;get first cluster of file in DE (will be 0 if existing filesize = 0)
				ld (fs_file_working_cluster),de		
				call fs_write_sector					;rewrite the current sector containing directory entry 
				ret c
				ld a,d
				or e
				jr nz,apenclch	
				
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

;---------------------------------------------------------------------------------------------

fs_erase_file_command


				call fs_find_filename						;does filename exist in current dir?
				ret c
				ret nz
				
				bit 4,(ix+0bh)								;is it a file (and not a directory)?
				jr z,okdelf
				xor a
				ld a,0c6h									;error $c6 - not a file
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
				xor a								;clear carry flag
				ld a,0c9h							;error $c9: 'filename already exists'
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
				xor a
				call set_abs_lba_and_read_sector
				ret c
				ld c,16										; sixteen 32 byte entries per sector
				ld ix,sector_buffer
find_vl			ld a,(ix+0bh)
				cp 08h
				jr nz,not_label
				ld (ix+0bh),0								; null terminate volume label
				push ix
				pop hl
				push hl
				ld b,11
				call uppercasify_string
				pop hl
				xor a
				ret
				
not_label		ld de,32									; assume volume label is in first sector
				add ix,de									; of root dir
				djnz find_vl
				xor a
				ld a,0d4h									; error $d4 - cant find volume label
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
fenotfnd		xor a									; clear carry
				ld a,0c3h								; error code $0c3 - (root) dir table is full
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
				push bc
				ld hl,sector_buffer			
				ld bc,512				
				xor a				
				call os_bchl_memfill	
				pop bc
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
secaccend		pop iy
				pop ix
				pop hl
				pop de
				pop bc
				ccf										;flip carry flag so that 1 = IDE error
				ret										;a = will be ide error reg bits in that case (00 = timeout)


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

;----------------------------------------------------------------------------------------------

