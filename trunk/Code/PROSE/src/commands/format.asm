;-----------------------------------------------------------------------
;"format" - format disk command. V0.04 - ADL mode
;
; The internal format routine is limited to formatting entire disks
; No partition data is allowed.
;-----------------------------------------------------------------------


os_cmd_format

				ld a,(hl)									;check args exist
				or a
				jr nz,fgotargs								
				ld a,01fh									;no args message
				or a
				ret
			
fgotargs	
				ld de,fs_sought_filename
				call fs_clear_filename			
				push hl										;use 2nd parameter as label if supplied
				call os_next_arg
				jr nz,fgotlab
				ld hl,default_label
fgotlab			ld b,11
				call os_copy_ascii_run
				pop hl
				
				ld a,(device_count)							;try to find a device with the name given after "FORMAT"
				or a
				jr z,fno_dev
				ld b,a
				ld c,0										;dev number
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
			
fno_dev			ld a,0d0h									;return fs error code $D0 - device not present
				or a
				ret
				
			
				
;----- FORMAT A DEVICE (USE ENTIRE CAPACITY (TRUNCATE AT 2GB) NO MBR) -----
			
			
format_dev		push bc
				call os_new_line
				ld hl,form_dev_warn1
				call os_show_packed_text
				pop bc
				
				ld a,c									;a = device number requiring format
				add a,030h
				ld (dev_txt+3),a
				ld hl,dev_txt	
				call os_print_string					;show "DEVx" 
				
				ld a,c
				call dev_to_driver_lookup				;get driver number (also HL = start of 32byte device entry)
				push hl
				ld (current_driver),a
				call show_dev_driver_name				;show device driver name ("SD card" etc)
				pop ix
				ld de,(ix+1)
				ld iy,xrr_temp
				ld (iy),de								; de number of sectors, divide by 2 to get k.bytes
				srl (iy+2)
				rr (iy+1)
				rr (iy+0)								
				ld de,(iy)								;divide sectors by 2 for KB
				call show_hlde_decimal					;show capacity
				ld hl,kb_txt
				call os_print_string
				lea hl,ix+5		
				call os_print_string					;show hardware's name originally from get_id 
				ld a,')'
				call os_print_char
				
				call os_new_line
				call os_new_line
				ld hl,form_dev_warn2
				call show_packed_text_and_cr
				call confirm_yes
				jr nz,ab_form
				
				ld hl,formatting_txt					;say "formatting..."
				call os_print_string
				
				call fs_format_device_command
				jr c,form_err
				or a
				jr nz,form_err
			
				ld hl,ok_txt							;say "OK"
				call os_print_string
				
f_end			call os_cmd_remount						;remount drives and show list
				ret
			
form_err
				ld hl,ferr_txt
				call os_print_string
				jr f_end
				
				
;---------------------------------------------------------------------------------------------
				
				
ab_form			call os_new_line
				ld a,024h								;ERROR $24 - Format aborted	
				or a
				ret
				
confirm_yes
			
				ld hl,scratch_pad
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

form_dev_warn2

				db 052h,046h,07eh,098h,09eh,0a2h,0a3h,0a5h,097h,0			;"will be lost. Enter YES to Continue"

formatting_txt

				db 11,11,'Formatting.. ',0

ok_txt			db 'OK',11,11,0

ferr_txt		db 'ERROR!',11,11,0

default_label	

				db 'PROSE_DISK',0

kb_txt			db 'KB (',0

;------------------------------------------------------------------------------------------------

fs_drive_sel_cache		equ scratch_pad+4								

;------------------------------------------------------------------------------------------------

