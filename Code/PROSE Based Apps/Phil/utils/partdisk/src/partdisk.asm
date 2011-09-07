; ******************************************
; * DISK PARTITIONER V0.02 by P.Ruston 2011*
; ******************************************

; Essentially, a Z80-mode port of the FLOS app "Disktool" without
; the Format option (as PROSE is able to format partitions itself)

;---------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 3bh				; 0 = dont care about OS version
ADL_mode			equ 0				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

				ld hl,scan_txt
				call print_string
				
				ld e,1
				ld a,kr_mount_volumes
				call.lil prose_kernal
		
begin			ld a,kr_clear_screen
				call.lil prose_kernal
				
				ld hl,app_banner
				call print_string
							
				ld a,(device)
				add a,30h
				ld (dev_number_text),a
				ld hl,device_txt
				call print_string
				
				ld a,kr_get_device_info
				call.lil prose_kernal
				push.lil hl
				pop.lil ix
				push.lil de
				pop.lil hl
				ld a,(device)				;show the driver name
				ld.lil bc,32
				ld b,a
				mlt bc
				add.lil ix,bc				;start of this device's entry in device table (32 byte entry)
				push.lil ix
				pop.lil iy
				ld.lil bc,3
				ld.lil b,(ix)				;driver number
				mlt bc
				add.lil hl,bc
				ld.lil de,(hl)				;de=start of driver code
				push.lil de
				pop.lil hl
				ld.lil bc,0ch
				add.lil hl,bc				;name of driver
				ld de,temp_string
				ld a,'['
				ld (de),a
				inc de 
				ld b,30
cpydnlp			ld.lil a,(hl)
				ld (de),a
				or a
				jr z,dndone
				inc.l hl
				inc de
				djnz cpydnlp
dndone			ld hl,temp_string
				call print_string
				ld hl,close_space_txt
				call print_string
				
				lea.lil hl,iy+5
				ld de,temp_string			;cannot reference out of page pointers in kernal calls in Z80 mode so copy the
				ld b,32						;info here prior to print call
ckdlp			ld.lil a,(hl)
				ld (de),a
				inc.l hl
				inc de
				djnz ckdlp
				ld hl,temp_string
				call print_string
				call new_line
				
				ld hl,total_cap_txt
				call print_string

				xor a
				ld (mbr_present),a

				ld.lil b,(ix+4)				;must use ADL addressing, table is out of this page
				ld.lil c,(ix+3)
				ld.lil d,(ix+2)
				ld.lil e,(ix+1)
				ld (total_sectors),de
				ld (total_sectors+2),bc
				
				ld e,d
				ld d,c
				ld c,b
				srl c
				rr d
				rr e
				srl c
				rr d
				rr e
				srl c
				rr d
				rr e
				ex de,hl
				call show_hexword_as_decimal
				ld hl,mb_txt
				call print_string
				call new_line
				call new_line

				ld hl,partitions_txt				; show current partitions
				call print_string

				call read_mbr						; get sector zero
				jp nz,disk_error
				
				ld hl,(my_sector_buffer+1feh)		; check FAT signature @ $1FE in sector buffer 
				ld de,0aa55h
				xor a
				sbc hl,de
				jp nz,no_mbr
				ld hl,my_sector_buffer				; carry set if 36-3a = FAT16 (if this is on sector 0 there's no MBR)
				ld de,36h
				add hl,de
				ld de,fat16_txt			
				ld b,5
				ld a,kr_compare_strings
				call.lil prose_kernal
				jp z,no_mbr
				ld hl,my_sector_buffer				; carry set if 36-3a = FAT32	(if this is on sector 0 there's no MBR)
				ld de,36h
				add hl,de
				ld de,fat32_txt			
				ld b,5
				ld a,kr_compare_strings
				call.lil prose_kernal
				jp z,no_mbr

				ld a,1								; assume then that this is an MBR at sector 0
				ld (mbr_present),a
				ld ix,my_sector_buffer+1beh
				xor a
fptnlp			ld (partition_count),a
				add a,30h
				ld (ptnum_txt),a
				ld a,(ix+4)							; what kind of partition is defined?
				or a								; 0 = no partition in this slot = assumed last partition
				jr z,last_ptn

				ld l,(ix+08h)					; this is a partition of *some* kind, add "sectors in partition" 
				ld h,(ix+09h)					; to "sectors from MBR" to make "first free sector"
				ld e,(ix+0ch)
				ld d,(ix+0dh)
				add hl,de
				ex de,hl
				ld l,(ix+0ah)
				ld h,(ix+0bh)
				ld c,(ix+0eh)
				ld b,(ix+0fh)
				adc hl,bc
				ld (first_free_sector),de
				ld (first_free_sector+2),hl

				ld hl,ptnum_txt		
				call print_string
				
				ld hl,fat32ptn_txt
				ld a,(ix+4)
				cp 0bh							; c and b are normal FAT32
				jr z,gotpart_type
				cp 0ch
				jr z,gotpart_type
				ld hl,fat16ptn_txt
				cp 4
				jr z,gotpart_type
				cp 6
				jr z,gotpart_type
				cp 0eh
				jr z,gotpart_type				
				ld hl,unknownptn_txt
gotpart_type	call print_string
				
				ld c,(ix+0fh)					; get size of partition
				ld h,(ix+0eh)
				ld l,(ix+0dh)
				srl c
				rr h
				rr l
				srl c
				rr h
				rr l
				srl c
				rr h
				rr l				
				call show_hexword_as_decimal		; show size of partition
				
				ld hl,mb_txt
				call print_string
				call new_line 

nxtptn			ld de,16
				add ix,de
				ld a,(partition_count)
				inc a
				cp 4
				jp nz,fptnlp
				ld (partition_count),a
				
last_ptn		ld a,(partition_count)
				or a
				jr nz,ptnsdone

noptns			ld hl,none_defined_txt
				call print_string
				ld hl,0
				ld (first_free_sector),hl
				ld (first_free_sector+2),hl
				
ptnsdone		ld hl,free_txt							;show remaining space
				call print_string
				ld hl,(total_sectors)
				ld de,(first_free_sector)
				xor a
				sbc hl,de
				ex de,hl
				ld hl,(total_sectors+2)
				ld bc,(first_free_sector+2)
				sbc hl,bc
				ld e,d
				ld d,l
				ld l,h
				srl l
				rr d
				rr e
				srl l
				rr d
				rr e
				srl l
				rr d
				rr e
				ex de,hl
				ld (unallocated_mb),hl
				call show_hexword_as_decimal
				ld hl,mb_txt
				call print_string
				call new_line
				call new_line
				jr menu

no_mbr			ld hl,nombr_txt
				call print_string

;---------------------------------------------------------------------------------------------

menu			ld hl,menu_txt
				call print_string
				
waitkey			ld a,kr_wait_key
				call.lil prose_kernal
				cp 076h
				jr z,quit

				ld a,b
				or a
				jr z,waitkey
				cp '0'
				jr z,init_mbr
				cp '1'
				jp z,make_part
				cp '2'
				jp z,delete_part
				cp '3'
				jp z,remount_devs
				cp '4'
				jp z,change_device
				
				jr waitkey
				
quit			call new_line
				call new_line
				ld e,0
				ld a,kr_mount_volumes
				call.lil prose_kernal
				
				jp.lil prose_return
				
				
;---------------------------------------------------------------------------------------------------

init_mbr		ld hl,mbr_warn_txt
				call print_string
				ld hl,response_txt
				ld e,2
				ld a,kr_get_string
				call.lil prose_kernal			; wait for confirmation
				ld hl,response_txt
				or a
				jp z,begin
				ld a,(hl)
				cp 'y'
				jr z,go_initmbr
				cp 'Y'
				jp nz,begin

go_initmbr		ld hl,working_txt
				call print_string

				ld hl,mbr_data					; copy "blank" MBR to sector buffer
				ld de,my_sector_buffer
				ld bc,512
				ldir

				call write_mbr					; write sector zero
				jp nz,disk_error
				
				call clear_sector_buffer
									
				ld bc,0							; fill sectors 1-255 with zeroes
				ld de,1
mbrilp			push bc
				push de
				call write_sector
				pop de
				pop bc
				jp nz,disk_error
				inc de
				bit 0,d
				jr z,mbrilp
				
done			ld hl,done_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin
				
;---------------------------------------------------------------------------------------------------

make_part		ld hl,makepart_txt
				call print_string
				
				ld a,(mbr_present)
				or a
				jr nz,mbrok
				ld hl,mpartnombr_txt
nombrerr		call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin
					
mbrok			ld a,(partition_count)
				cp 4
				jr nz,makeptn
				ld hl,ptntfull_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin
					
makeptn			ld hl,sizereq_txt
				call print_string
				ld e,5
				ld hl,response_txt
				ld a,kr_get_string
				call.lil prose_kernal
				ld hl,response_txt
				or a
				jp z,begin
				call ascii_decimal_to_hex
				jp nz,badfigs
				push hl							; check requested partition size is > 31MB and < 2049MB
				ld de,32						; and there is enough free space for it. 
				xor a
				sbc hl,de
				pop hl
				jp c,ptoosmall
				push hl
				ld de,801h
				xor a
				sbc hl,de
				pop hl
				jp nc,pmaxsize
				push hl
				dec hl
				ld de,(unallocated_mb)
				xor a
				sbc hl,de
				pop hl
				jp nc,ptoobig
				ld (new_ptn_size_mb),hl
				
				call read_mbr					; read in sector zero (MBR)
				jp nz,disk_error

				ld hl,first_partition_info
				ld a,(partition_count)			; get previous partition entry data (loc and len)
				or a							; special case when no partitions
				jr z,mfirstp
				dec a
				ld l,a
				ld h,0
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl	
				ld de,my_sector_buffer
				add hl,de
				ld de,01beh
				add hl,de
mfirstp			push hl
				pop ix
				ld l,(ix+08h)					; location lo
				ld h,(ix+09h)
				ld e,(ix+0ch)					; length lo
				ld d,(ix+0dh)
				add hl,de						; new loc lo
				ex de,hl	
				ld l,(ix+0ah)					; location hi
				ld h,(ix+0bh)
				ld c,(ix+0eh)					; length hi
				ld b,(ix+0fh)
				adc hl,bc
				push hl							; new loc hi
					
				ld a,(partition_count)			; put data in relevent partition entry (in sector buffer)
				ld l,a
				ld h,0
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl	
				ld bc,my_sector_buffer
				add hl,bc
				ld bc,01beh
				add hl,bc
				push hl
				pop ix
				ld (ix+08h),e					; start location (lo word)
				ld (ix+09h),d
				pop de
				ld (ix+0ah),e					; start location (hi word)
				ld (ix+0bh),d
				
				ld hl,(new_ptn_size_mb)			; convert mb to sectors
				ld e,0
				add hl,hl
				rl e
				add hl,hl
				rl e
				add hl,hl
				rl e
				ld (ix+0ch),0					; size of partition in sectors
				ld (ix+0dh),l
				ld (ix+0eh),h
				ld (ix+0fh),e
				
				ld (ix+04h),0eh					; partition type: FAT16 LBA

				ld (ix+0h),0					; non active sector
				
				ld (ix+01h),0					; C/H/S start tuple (unused)
				ld (ix+02h),0
				ld (ix+03h),0
				
				ld (ix+05h),0					; C/H/S end tuple (unused)
				ld (ix+06h),0
				ld (ix+07h),0

				ld e,(ix+08h)					; note where this partition's first sector is located
				ld d,(ix+09h)
				ld c,(ix+0ah)
				ld b,(ix+0bh)
				ld (partition_base),de
				ld (partition_base+2),bc

				call write_mbr					; rewrite MBR
				jp nz,disk_error

				call clear_sector_buffer		; also wipe partition's first sector
				ld hl,0			
				call get_bcde_lba
				call write_sector		
				jp nz,disk_error

				jp done
					

ptoosmall

				ld hl,ptoosmall_txt
mp_err			call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin
				
badfigs			ld hl,badfigs_txt
				jr mp_err
				
ptoobig			ld hl,ptoobig_txt
				jr mp_err
				
pmaxsize		ld hl,pmaxsize_txt
				jr mp_err
				
;---------------------------------------------------------------------------------------------------

delete_part		ld hl,delpart_txt
				call print_string
				
				ld hl,dp_nmbr_txt
				ld a,(mbr_present)
				or a
				jp z,nombrerr

				ld a,(partition_count)				; do any partitions exist?
				or a
				jr nz,ptdel
				ld hl,noparts_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin
				
ptdel			push af
				ld hl,delconfirm_txt
				call print_string
				pop af
				add a,02fh
				ld (delp_number_txt),a
				ld hl,delp_number_txt
				call print_string
				call new_line
				call new_line
				ld hl,yesno_txt
				call print_string
					
				ld a,kr_get_string
				ld hl,response_txt
				ld e,2
				call.lil prose_kernal				; wait for confirmation
				ld hl,response_txt
				or a
				jp z,begin
				ld a,(hl)
				cp 'y'
				jr z,go_delpart
				cp 'Y'
				jp nz,begin

go_delpart		call read_mbr						; get sector zero (MBR)
				jp nz,disk_error

				ld a,(partition_count)				; wipe relevant partition entry
				dec a	
				ld l,a
				ld h,0
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl	
				ld de,my_sector_buffer
				add hl,de
				ld de,01beh
				add hl,de
				push hl
				pop ix
				ld e,(ix+08h)						; note where this partition's first sector is located
				ld d,(ix+09h)
				ld c,(ix+0ah)
				ld b,(ix+0bh)
				ld (partition_base),de
				ld (partition_base+2),bc
				ld b,16
fill_loop1		ld (hl),0
				inc hl
				djnz fill_loop1
				
				call write_mbr						; rewrite MBR
				jp nz,disk_error

				call clear_sector_buffer			; also wipe partition's first sector
				ld hl,0			
				call get_bcde_lba
				call write_sector		
				jp nz,disk_error
				jp done
				
				
;---------------------------------------------------------------------------------------------------

remount_devs

				ld e,1
				ld a,kr_mount_volumes
				call.lil prose_kernal
				jp begin

;---------------------------------------------------------------------------------------------------

change_device
				ld hl,enter_dev_txt
				call print_string
					
				ld hl,response_txt
				ld e,2
				ld a,kr_get_string
				call.lil prose_kernal				; wait for confirmation
				or a
				jp z,begin
				ld a,(response_txt)
				sub 30h
				jp c,bad_dev
				cp 9
				jp nc,bad_dev
				push af
				ld a,kr_get_device_info
				call.lil prose_kernal
				pop af
				cp b
				jp nc,bad_dev
				ld (device),a
				jp begin

bad_dev			ld hl,bad_dev_txt
				jp mp_err
				
;---------------------------------------------------------------------------------------------------


disk_error

				ld hl,disk_error_txt
				call print_string	
				jp quit


;----------------------------------------------------------------------------------
				
get_bcde_lba

				ld de,(partition_base)		;input hl, output bc:de = partition_base + hl
				ld bc,(partition_base+2)
				add hl,de
				ex de,hl
				ret nc
				inc bc
				ret				
				
				
;----------------------------------------------------------------------------------

show_hexword_as_decimal



				ld de,decimal_output
				push de
				call hex2dec
				pop hl
				call showdec
				ret
				
				
hex2dec

; INPUT  : HL hex word to convert, DE = location for output string
				
				ld	bc,-10000
				call	Num1
				ld	bc,-1000
				call	Num1
				ld	bc,-100
				call	Num1
				ld	c,-10
				call	Num1
				ld	c,b

Num1			ld	a,'0'-1
Num2			inc	a
				add	hl,bc
				jr	c,Num2
				sbc	hl,bc

				ld	(de),a
				inc	de
				ret



showdec

; INPUT HL = location for most significant digit of decimal string

				ld b,4			;can only skip a max of 4 digits
shdeclp			ld a,(hl)
				cp '0'
				jr nz,dnzd
				inc hl
				djnz shdeclp
dnzd			call print_string
				ret
				

;------------------------------------------------------------------------------------------

ascii_decimal_to_hex

; INPUT:  HL = MSB ascii digit of decimal figure
; OUTPUT: HL = hex value (if ZF is not set: Error)

				ld b,0						;find lsb, check ascii digits
fdlsb			ld a,(hl)
				or a
				jr z,dnumend
				cp 30h
				jr c,dnumbad
				cp 3ah
				jr nc,dnumbad
				inc hl
				inc b						;b = number of digits
				ld a,b
				cp 6						;5 digits max
				jr nz,fdlsb
				xor a
				inc a
				ret
				
dnumend			ld a,b
				or a
				jr nz,dnumok
dnumbad			xor a						;zero flag not set = bad ascii figures / no text
				inc a
				ret

dnumok			dec hl
				push hl
				pop iy						;iy = location on LSB ascii digit
				ld hl,declist
				ld ix,0						;tally
d2hlp2			ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
				ld a,(iy)
				sub 030h
				jr z,nxtdd
d2hlp1			add ix,de
				jr c,dnumbad
				dec a
				jr nz,d2hlp1
nxtdd			dec iy
				djnz d2hlp2
				push ix
				pop hl
				xor a
				ret
				

				ret
				
declist	dw 1,10,100,1000,10000

;----------------------------------------------------------------------------------------


new_line		ld hl,newline_txt
				call print_string
				ret

;----------------------------------------------------------------------------------------
				
print_string	ld a,kr_print_string
				call.lil prose_kernal
				ret				

;----------------------------------------------------------------------------------------
	
read_mbr		ld a,(device)			
				ld b,a
				ld c,0							
				ld.lil de,0
				ld hl,my_sector_buffer
				ld a,kr_read_sector
				call.lil prose_kernal
				ret
				
write_mbr		ld a,(device)
				ld b,a
				ld c,0							
				ld.lil de,0
				ld hl,my_sector_buffer
				ld a,kr_write_sector
				call.lil prose_kernal
				ret

write_sector	ld l,c								; convert BC:DE to C:xDE
				push bc
				ld b,16
shhllp			add.lil hl,hl
				djnz shhllp
				ld h,d
				ld l,e
				push.lil hl
				pop.lil de
				pop bc
				ld c,b
				ld a,(device)
				ld b,a
				ld hl,my_sector_buffer
				ld a,kr_write_sector
				call.lil prose_kernal
				ret



clear_sector_buffer


				push hl
				push de
				push bc
				ld hl,my_sector_buffer				; zero the sector buffer
				ld bc,511	
				ld (hl),0
				push hl
				pop de
				inc de
				ldir
				pop bc
				pop de
				pop hl
				ret
				
;------------------------------------------------------------------------------------------

decimal_output	blkb 6,0

mbr_data		include "mbr_data.asm"

;-------------------------------------------------------------------------------------------

app_banner			db 11,"PARTDISK V0.02",11
					db    "==============",11,11,0
	
device				db 0



device_info_table	dw 0

total_sectors		dw 0,0
	
first_free_sector	dw 0,0
		
unallocated_mb		dw 0

partition_count		db 0

mbr_present			db 0
		
device_txt			db    "Device "
dev_number_text		db "x : ",0

total_cap_txt		db 11,"Capacity : ",0
	
mb_txt				db " MB",0
	
newline_txt			db 11,0

new_ptn_size_mb		dw 0
	
partition_base		dw 0,0
partition_size		dw 0,0


first_partition_info

				db 0,0,0,0, 0,0,0,0, 00h,00h,00h,00h, 3eh,00h,00h,00h

	
partitions_txt

				db 11,"Partition Table:",11
				db "----------------",11,11,0


fat16_txt		db "FAT16"

fat32_txt		db "FAT32"

nombr_txt		db "Device is not partitioned (No MBR)",11,11,0

ptnum_txt		db 'x: ',0

fat16ptn_txt	db "FAT16 partition ",0
fat32ptn_txt	db "FAT32 partition ",0
unknownptn_txt	db "Unknown partition ",0

disk_error_txt	db 11,11,"Disk Error!",11,11,0

none_defined_txt	db "No partitions are defined in the MBR.",11,0

free_txt			db 11,"Unallocated Space: ",0



menu_txt		db 11,"Options:",11
				db "--------",11,11
				db "0  : Initialize MBR",11
				db "1  : Make new partition",11
				db "2  : Delete last partition",11
				db "3  : Remount devices",11
				db "4  : Change target device",11
				db 11,"ESC: Quit",0
		



mbr_warn_txt	db 11,11,"INITIALIZE MBR",11
				db "--------------",11,11
				db "WARNING! This will erase any existing",11
				db "partitions. Are you sure you want to",11
				db "proceed?",11,11,"(y/n) ",0

delp_number_txt	db "x?",0




delpart_txt		db 11,11,"DELETE LAST PARTITION",11
				db "---------------------",11,11,0
		
delconfirm_txt	db "Sure you want to delete partition ",0
yesno_txt		db "(y/n) ",0

noparts_txt		db "There are no partitions to delete!",11,11
				db "Press any key..",0

dp_nmbr_txt		db "Error! No partitions defined (No MBR)",11,11
				db "Press any key..",0




makepart_txt	db 11,11,"MAKE NEW PARTITION",11
				db "------------------",11,11,0
		
ptntfull_txt	db "ERROR! The partition table is full.",11,11
				db "Press any key..",0

mpartnombr_txt	db "ERROR! Cannot make a partition on a",11
				db "device without a Master Boot Record.",11,11
				db "Please use Option 0 to initialize MBR.",11,11
				db "Press any key..",0

sizereq_txt		db "Enter size of desired partition (in MB)",11,11,":",0

working_txt		db 11,11,"Working..",0
done_txt		db 11,11,"Done! Press a key..",0

ptoosmall_txt	db 11,11,"ERROR! Minimum partition size is 32MB",11,11
				db "Press any key..",0

badfigs_txt		db 11,11, "ERROR! Invalid numeric data entered.",11,11
				db "Press any key..",0
		
ptoobig_txt		db 11,11, "ERROR! Not enough free space for the",11
				db "requested partition size.",11,11
				db "Press any key..",0

pmaxsize_txt	db 11,11, "ERROR! Maximum partition size is 2048MB",11,11
				db "Press any key..",0
		
byte_ascii_txt	db "$xx",0

word_ascii_txt	db "$xxxx",0
	
clustersize_txt	db "Cluster size: ",0

sectorsperfat_txt	db "Sectors per fat: ",0
		
		
nonfatptn_txt	db "ERROR! The partition type is not FAT",11,11
				db "Press any key..",0

enter_dev_txt	db 11,11,"Enter the target Device number..",11,11,0

response_txt	blkb 80,0

bad_dev_txt		db 11,11,"Invalid device selection!",11,11,0

temp_string		blkb 32,0

close_space_txt	db "] ",0

scan_txt		db 11,"Scanning devices. Please wait..",11,0

my_sector_buffer	blkb 512,0
				
;--------------------------------------------------------------------------------------------
	