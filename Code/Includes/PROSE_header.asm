;--- EZ80 Internal CPU Ports --------------------------------------------------------------------

PB_DR			equ 09ah
PB_DDR			equ 09bh
PB_ALT1			equ 09ch
PB_ALT2			equ 09dh

PC_DR			equ 09eh
PC_DDR			equ 09fh
PC_ALT1			equ 0a0h
PC_ALT2			equ 0a1h

PD_DR			equ 0a2h
PD_DDR			equ 0a3h
PD_ALT1			equ 0a4h
PD_ALT2			equ 0a5h

UART0_RBR		equ 0c0h
UART0_THR		equ 0c0h
UART0_BRG_L		equ 0c0h
UART0_BRG_H		equ 0c1h
UART0_IER		equ 0c1h
UART0_FCTL		equ 0c2h
UART0_LCTL		equ 0c3h
UART0_MCTL		equ 0c4h
UART0_LSR		equ 0c5h
UART0_MSR		equ 0c6h

CS0_LBR			equ 0a8h			;eZ80 wait state CS0 control ports
CS0_UBR			equ 0a9h
CS0_CTL			equ 0aah			
CS1_LBR			equ 0abh			;eZ80 wait state CS1 control ports
CS1_UBR			equ 0ach
CS1_CTL			equ 0adh
CS2_LBR			equ 0aeh			;eZ80 wait state CS2 control ports
CS2_UBR			equ 0afh
CS2_CTL			equ 0b0h
CS3_LBR			equ 0b1h			;eZ80 wait state CS3 control ports
CS3_UBR			equ 0b2h
CS3_CTL			equ 0b3h

TMR0_CTL		equ 080h			;timer 0 equates
TMR0_DR_L		equ 081h
TMR0_RR_L		equ 081h
TMR0_DR_H		equ 082h
TMR0_RR_H		equ 082h
TMR_ISS			equ 092h

RTC_CTRL		equ 0edh			;RTC equates
RTC_ACTRL		equ 0ech
RTC_SEC			equ 0e0h
RTC_MIN			equ 0e1h
RTC_HRS			equ 0e2h
RTC_DOW			equ 0e3h
RTC_DOM			equ 0e4h
RTC_MON			equ 0e5h
RTC_YR			equ 0e6h
RTC_CEN			equ 0e7h

;-- EZ80P Hardware equates ------------------------------------------------------------------------

port_pic_data  			equ 000h
port_pic_ctrl			equ 001h
port_hw_flags			equ 001h
port_sdc_ctrl			equ 002h	; this is a set/reset type register (bit 7 controls whether selected bits are set or reset)
port_keyboard_data		equ 002h
port_sdc_data		 	equ 003h	
port_memory_paging		equ 004h
port_irq_ctrl			equ 005h
port_nmi_ack			equ 006h
port_ps2_ctrl			equ 007h
port_selector			equ 008h
port_mouse_data			equ 006h
port_clear_flags		equ 009h

sdc_power				equ 0		;(port_sd_ctrl, bit 0 - active high)
sdc_cs					equ 1		;(port_sd_ctrl, bit 1 - active low)
sdc_speed				equ 2 		;(port_sd_ctrl, bit 2 - set = full speed)

sdc_serializer_busy		equ 4 		;(port_hw_flags, bit 4 - set = busy - ie: byte being transmitted)
vrt						equ 5		;(port_hw_flags, bit 5 - set = last scan line of display)


;-- Memory locations -----------------------------------------------------------------------------

sysram_addr				equ 0000000h
vram_a_addr				equ 0800000h
vram_b_addr				equ 0c00000h

;-- Hardware registers ----------------------------------------------------------------------------

hw_palette				equ 0ff0000h
hw_sprite_registers		equ 0ff0800h
hw_video_parameters		equ 0ff1000h
hw_audio_registers		equ 0ff1400h
hw_video_settings		equ 0ff1800h

tilemap_parameters		equ hw_video_parameters+00h
bitmap_parameters		equ hw_video_parameters+20h

video_control			equ hw_video_settings+00h
sprite_control			equ hw_video_settings+01h
bgnd_palette_select		equ hw_video_settings+02h
sprite_palette_select	equ hw_video_settings+03h
right_border_position	equ hw_video_settings+04h

;-------------------------------------------------------------------------------------------------

os_start 	equ 0a00h

prose_return equ os_start+14h
prose_kernal equ os_start+20h

;-----------------------------------------------------------------------
; Kernal Jump Table values for mode PROSE
;-----------------------------------------------------------------------
		
kr_mount_volumes				equ 00h	
kr_get_device_info				equ 01h	
kr_check_volume_format			equ 02h	
kr_change_volume				equ 03h	
kr_get_volume_info				equ 04h	
kr_format_device				equ 05h	
kr_make_dir						equ 06h

kr_change_dir					equ 07h	
kr_parent_dir					equ 08h	
kr_root_dir						equ 09h
kr_delete_dir					equ 0ah
kr_find_file					equ 0bh
kr_set_file_pointer				equ 0ch
kr_set_load_length				equ 0dh
kr_read_file					equ 0eh

kr_erase_file					equ 0fh
kr_rename_file					equ 10h
kr_create_file					equ 11h
kr_write_file					equ 12h
kr_get_total_sectors			equ 13h
kr_dir_list_first_entry			equ 14h
kr_dir_list_get_entry			equ 15h
kr_dir_list_next_entry			equ 16h

kr_read_sector					equ 17h
kr_write_sector					equ 18h
kr_file_sector_list				equ 19h
kr_get_dir_cluster				equ 1ah
kr_set_dir_cluster				equ 1bh
kr_get_dir_name					equ 1ch
kr_wait_key						equ 1dh
kr_get_key						equ 1eh

kr_get_key_mod_flags			equ 1fh
kr_serial_receive_header		equ 20h
kr_serial_receive_file			equ 21h
kr_serial_send_file				equ 22h
kr_serial_tx_byte				equ 23h
kr_serial_rx_byte				equ 24h

kr_print_string					equ 25h
kr_clear_screen					equ 26h
kr_wait_vrt						equ 27h
kr_set_cursor_position			equ 28h
kr_plot_char					equ 29h
kr_set_pen						equ 2ah
kr_background_colours			equ 2bh
kr_draw_cursor					equ 2ch
kr_get_pen						equ 2dh
kr_scroll_up					equ 2eh
kr_os_display					equ 2fh
kr_get_display_size				equ 30h
kr_get_charmap_addr_xy			equ 31h
kr_get_cursor_position			equ 32h

kr_set_envar					equ 33h
kr_get_envar					equ 34h
kr_delete_envar					equ 35h

kr_set_mouse_window				equ 36h
kr_get_mouse_position			equ 37h
kr_get_mouse_motion				equ 38h

kr_time_delay					equ 39h
kr_compare_strings				equ 3ah
kr_hex_byte_to_ascii			equ 3bh
kr_ascii_to_hex_word			equ 3ch
kr_get_string					equ 3dh

kr_get_version					equ 3eh
kr_dont_store_registers			equ 3fh
kr_get_font_info				equ 40h
kr_read_rtc						equ 41h
kr_write_rtc					equ 42h

kr_get_keymap_location			equ 43h
kr_get_os_high_mem				equ 44h

;---------------------------------------------------------------------------------------------------------------------------
; Standard PROSE executable header
;--------------------------------------------------------------------------------------------------------------------------


	IF ADL_mode = 0
		org load_location&0ffffh	; if Z80 mode program, CODE origin is a Z80 address (within 64KB page)
	ELSE
		org load_location			; otherwise origin is anywhere in system RAM
	ENDIF
	
		.assume ADL = 1				; All PROSE-launched programs START in ADL mode

		jr skip_header				; $0 - Jump over header
		db 'PRO'					; $2 - ASCII "PRO" = PROSE executable program ID
mb_loc	dw24 load_location			; $5 - Desired Load location (24 bit) 
		dw24 0						; $8 - If > 0, truncate load 
		dw prose_version_req		; $B - If > 0, minimum PROSE version requird
		dw amoeba_version_req		; $D - If > 0, minimum AMOEBA version required
		db ADL_mode					; $F - Z80 (0) or ADL mode (1) program.

skip_header
	
	IF ADL_mode = 0 
		
mbase_offset equ load_location & 0ff0000h

		ld a,load_location/65536	; Additional set up code for Z80 mode programs
		ld MB,a						; Set MBASE register (necessary for Z80-mode apps)
		jp.sis go_z80_mode			; switches off ADL mode for this app

go_z80_mode

		.assume ADL = 0

	ENDIF
	
;------------------------------------------------------------------------------------------------------------------------
	