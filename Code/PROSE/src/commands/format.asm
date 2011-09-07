;-----------------------------------------------------------------------
;"format" - format volume / device command. V0.06
;-----------------------------------------------------------------------

os_cmd_format	ld a,(hl)									;check args exist
				or a
				jr nz,fgotargs								
				ld a,01fh									;no args message
				or a
				ret
			
fgotargs		push hl
				call os_next_arg							;use 2nd parameter as label if supplied
				jr nz,fgotlab
				ld hl,default_label
fgotlab			ld (format_label_loc),hl

				ld a,1										;quiet mode on
				call os_mount_volumes						;refresh mount list in case card has been swapped
				pop hl
				
;-------------------------------------------------------------------------
; Format an entire device?
;-------------------------------------------------------------------------

				ld a,(device_count)							;try to find a device with the name given after "FORMAT"
				or a
				jr z,fno_dev
				ld b,a
				ld c,0										;device number
				ld ix,host_device_hardware_info
fdev_lp			ld a,(ix)									;a = driver number for this dev
				call locate_driver_base						;DE = start addr of driver
				push de
				pop iy
				lea de,iy+0ch								;DE = location of ascii name of driver (EG: "SD_CARD")
				push bc
				ld b,7
				call os_compare_strings
				pop bc
				jr z,format_dev
				lea ix,ix+20h								;try next device name
				inc c
				djnz fdev_lp
				jr form_vol_req
				
format_dev		push bc										;show device format warning
				call os_new_line
				ld hl,form_dev_warn1
				call os_show_packed_text
				pop bc
				
				ld a,c										;a = device number requiring format
				add a,030h
				ld (dev_txt+3),a
				ld hl,dev_txt	
				call os_print_string						;show "DEVx" 
				
				ld a,c										;get device number in A
				call setup_dev_format						;set up partition size / location etc
				jr nc,fno_dev	
				ld a,(current_driver)
				call show_dev_driver_name					;show driver name ("SD card" etc)
								
				ld a,(ix+4)
				or a
				jr z,less16gb
				ld hl,dev16gbplus_txt
				jr form_capdone
less16gb		ld b,1
				call shr_de									;divide sectors by 2 for KB
				ld a,'('
				call os_print_char
				push ix
				ld de,(ix+1)								;capacity in sectors
				ld b,1
				call shr_de							
				call show_capacity							;divide by 2 for KB capacity
				pop ix
form_capdone	lea hl,ix+5		
				call os_print_string						;show hardware's name originally from get_id 
				ld a,')'
				call os_print_char

				call os_new_line
				call os_new_line
				ld hl,form_warn2
				call show_packed_text_and_cr
				
				jp confirm_format
			



fno_dev			ld a,0d0h									;return fs error code $D0 - device not present
				or a
				ret
				
	
	
setup_dev_format

; set A to device
					
				call dev_to_driver_lookup					;get driver number (also HL = start of 32byte device entry)
				ret nc										;if carry not set, bad device
				ld (current_driver),a						;set the driver required for the format
				push hl
				pop ix
				ld de,(ix+1)								
				ld (partition_size),de
				ld hl,0										;formatting a DEVICE removes any MBR
				ld (partition_base),hl						;and puts the partition boot sector at LBA 0
				xor a
				ld (partition_base+3),a
				scf											;ensure carry set on retrun if all ok
				ret
								

;------------------------------------------------------------------------
; Format a volume?
;------------------------------------------------------------------------

form_vol_req	ld (format_target_name),hl
				call test_volx								;was a target string of "volx:" entered?
				jr nz,bad_vol
				sub a,30h
				ld (format_target_volume),a					;a = volume to format
				ld de,16
				ld d,a
				mlt de
				ld ix,volume_mount_list	
				add ix,de
				ld a,(ix)
				or a
				jr z,bad_vol								;is volume present?
				
				ld de,(ix+4)
				ld (partition_size),de
				ld de,(ix+8)
				ld (partition_base),de
				ld a,(ix+0bh)
				ld (partition_base+3),a
				ld a,(ix+1)									;A = volume's driver number
				ld (current_driver),a
				
				call os_new_line
				ld hl,form_vol_warn1
				call show_packed_text_and_cr				; Show warning "all data on..."
				call os_new_line
				
				ld ix,(format_target_name)					
				ld (ix+5),0
				lea hl,ix+0
				call os_print_string						; show "volx:"
				
				ld a,(current_volume)
				push af
				ld a,(format_target_volume)
				call os_change_volume
				jr nz,no_vollab
				call fs_get_volume_label
				jr nz,no_vollab
				call os_print_string						; show volume label if applicable
no_vollab		pop af
				ld (current_volume),a
				
				call os_new_line
				call os_new_line
				ld hl,form_warn2
				call show_packed_text_and_cr				; show "will be lost"

				call confirm_format
				push af
				call fs_set_driver_for_volume
				pop af
				ret

bad_vol			ld a,0cfh									;invalid volume error
				or a
				ret
		
			
;------------------------------------------------------------------------


confirm_format

				call confirm_yes
				jr nz,abort_format
				
				ld hl,formatting_txt					;say "formatting..."
				call os_print_string
				
				ld hl,(format_label_loc)
				call fs_format_partition
				jr c,form_err
				jr nz,form_err
			
				ld hl,ok_txt							;say "OK"
				call os_print_string
				
f_end			call os_cmd_remount						;remount drives and show list
				ret


form_err		ld hl,ferr_txt
				call os_print_string
				jr f_end
				


abort_format	call os_new_line
				ld a,024h								;ERROR $24 - Format aborted	
				or a
				ret


confirm_yes		ld hl,scratch_pad
				ld e,3
				push hl
				call os_user_input
				pop hl
				ret nz
				ld b,3
				ld de,yes_txt+1
				call os_compare_strings
				ret
			
			
show_packed_text_and_cr
			
				call os_show_packed_text
				call os_new_line
				ret
			
;------------------------------------------------------------------------------------------------

form_dev_warn1

				db 027h,028h,036h,040h,097h,097h,0							;"Warning! all volumes on"

form_warn2

				db 052h,046h,07eh,098h,09eh,0a2h,0a3h,0a5h,097h,0			;"will be lost. Enter YES to Continue"

form_vol_warn1
	
				db 027h,028h,06fh,040h,0									;"Warning! All data on"


formatting_txt

				db 11,11,'Formatting.. ',0

ok_txt			db 'OK',11,11,0

ferr_txt		db 'ERROR!',11,11,0

default_label	db 'PROSE_DISK',0

dev16gbplus_txt	db '(16GB+ ',0

;------------------------------------------------------------------------------------------------

format_target_name		equ scratch_pad+30h		; keep these high in scratch pad (other routines
format_target_volume	equ scratch_pad+33h		; such as hex to decimal etc are using lower addresses)
format_label_loc		equ scratch_pad+34h

;------------------------------------------------------------------------------------------------

