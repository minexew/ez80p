//#ifndef PROSE_Header_H
//#define PROSE_Header_H

#define INLINEASM(Linea)		asm(Linea)

//Define eZ80 Internal CPU Ports
#define INT_CPU_PORTS			INLINEASM("PB_DR		equ 09Ah");			\
								INLINEASM("PB_DDR		equ 09Bh");			\
								INLINEASM("PB_ALT1		equ 09Ch");			\
								INLINEASM("PB_ALT2		equ 09Dh");			\
								INLINEASM("PC_DR		equ 09Eh");			\
								INLINEASM("PC_DDR		equ 09Fh");			\
								INLINEASM("PC_ALT1		equ 0A0h");			\
								INLINEASM("PC_ALT2		equ 0A1h");			\
								INLINEASM("PD_DR		equ 0A2h");			\
								INLINEASM("PD_DDR		equ 0A3h");			\
								INLINEASM("PD_ALT1		equ 0A4h");			\
								INLINEASM("PD_ALT2		equ 0A5h");			\
								INLINEASM("UART0_RBR	equ 0C0h");			\
								INLINEASM("UART0_THR	equ 0C0h");			\
								INLINEASM("UART0_BRG_L	equ 0C0h");			\
								INLINEASM("UART0_BRG_H	equ 0C1h");			\
								INLINEASM("UART0_IER	equ 0C1h");			\
								INLINEASM("UART0_FCTL	equ 0C2h");			\
								INLINEASM("UART0_LCTL	equ 0C3h");			\
								INLINEASM("UART0_MCTL	equ 0C4h");			\
								INLINEASM("UART0_LSR	equ 0C5h");			\
								INLINEASM("UART0_MSR	equ 0C6h");			\
								INLINEASM("CS0_LBR		equ 0A8h");			\
								INLINEASM("CS0_UBR		equ 0A9h");			\
								INLINEASM("CS0_CTL		equ 0AAh");			\
								INLINEASM("CS1_LBR		equ 0ABh");			\
								INLINEASM("CS1_UBR		equ 0ACh");			\
								INLINEASM("CS1_CTL		equ 0ADh");			\
								INLINEASM("CS2_LBR		equ 0AEh");			\
								INLINEASM("CS2_UBR		equ 0AFh");			\
								INLINEASM("CS2_CTL		equ 0B0h");			\
								INLINEASM("CS3_LBR		equ 0B1h");			\
								INLINEASM("CS3_UBR		equ 0B2h");			\
								INLINEASM("CS3_CTL		equ 0B3h");			\
								INLINEASM("TMR0_CTL		equ 080h");			\
								INLINEASM("TMR0_DR_L	equ 081h");			\
								INLINEASM("TMR0_RR_L	equ 081h");			\
								INLINEASM("TMR0_DR_H	equ 082h");			\
								INLINEASM("TMR0_RR_H	equ 082h");			\
								INLINEASM("TMR_ISS		equ 092h");			\
								INLINEASM("RTC_CTRL		equ 0EDh");			\
								INLINEASM("RTC_ACTRL	equ 0ECh");			\
								INLINEASM("RTC_SEC		equ 0E0h");			\
								INLINEASM("RTC_MIN		equ 0E1h");			\
								INLINEASM("RTC_HRS		equ 0E2h");			\
								INLINEASM("RTC_DOW		equ 0E3h");			\
								INLINEASM("RTC_DOM		equ 0E4h");			\
								INLINEASM("RTC_MON		equ 0E5h");			\
								INLINEASM("RTC_YR		equ 0E6h");			\
								INLINEASM("RTC_CEN		equ 0E7h");
								
//Define eZ80 Hardware equates
#define HARDWARE_EQUATES		INLINEASM("port_pic_data		equ 000h");		\
								INLINEASM("port_pic_ctrl		equ 001h");		\
								INLINEASM("port_hw_flags		equ 001h");		\
								INLINEASM("port_sdc_ctrl		equ 002h");		\
								INLINEASM("port_keyboard_data	equ 002h");		\
								INLINEASM("port_sdc_data		equ 003h");		\
								INLINEASM("port_memory_paging	equ 004h");		\
								INLINEASM("port_irq_ctrl		equ 005h");		\
								INLINEASM("port_nmi_ack			equ 006h");		\
								INLINEASM("port_ps2_ctrl		equ 007h");		\
								INLINEASM("port_selector		equ 008h");		\
								INLINEASM("port_mouse_data		equ 006h");		\
								INLINEASM("port_clear_flags		equ 009h");		\
								INLINEASM("sdc_power			equ 0h");		\
								INLINEASM("sdc_cs				equ 1h");		\
								INLINEASM("sdc_speed			equ 2h");		\
								INLINEASM("sdc_serializer_busy	equ 4h");		\
								INLINEASM("vrt					equ 5h");		
								
//Define eZ80 Memory Locations
#define MEMORY_LOCATIONS		INLINEASM("sysram_addr			equ 0000000h");		\
								INLINEASM("vram_a_addr			equ 0800000h");		\
								INLINEASM("vram_b_addr			equ 0C00000h");		
								
//Define eZ80 Hardware Register
#define HARDWARE_REGISTERS		INLINEASM("hw_palette			equ 0ff0000h");		\
								INLINEASM("hw_sprite_registers	equ 0ff0800h");		\
								INLINEASM("hw_video_parameters	equ 0ff1000h");		\
								INLINEASM("hw_audio_registers	equ 0ff1400h");		\
								INLINEASM("hw_video_settings	equ 0ff1800h");		\
								INLINEASM("tilemap_parameters	equ hw_video_parameters + 00h");\
								INLINEASM("bitmap_parameters	equ hw_video_parameters + 20h");\
								INLINEASM("video_control		equ hw_video_settings + 00h");  \
								INLINEASM("sprite_control		equ hw_video_settings + 01h");  \
								INLINEASM("bgnd_palette_select	equ hw_video_settings + 02h");  \
								INLINEASM("sprite_palette_select	equ hw_video_settings + 03h");\
								INLINEASM("right_border_position	equ hw_video_settings + 04h");
								
//Define OS Equates
#define OS_EQUATES				INLINEASM("os_start			equ 0A00h");				\
								INLINEASM("prose_return		equ os_start + 14h");		\
								INLINEASM("prose_kernal		equ os_start + 20h");		
								
//Define Kernal Jump Table Values
#define KJT_PROSE				INLINEASM("kr_mount_volumes			equ 00h");				\
								INLINEASM("kr_get_device_info		equ 01h");				\
								INLINEASM("kr_check_volume_format	equ 02h");				\
								INLINEASM("kr_change_volume			equ 03h");				\
								INLINEASM("kr_get_volume_info		equ 04h");				\
								INLINEASM("kr_format_device			equ 05h");				\
								INLINEASM("kr_make_dir				equ 06h");				\
								INLINEASM("kr_change_dir			equ 07h");				\
								INLINEASM("kr_parent_dir			equ 08h");				\
								INLINEASM("kr_root_dir				equ 09h");				\
								INLINEASM("kr_delete_dir			equ 0Ah");				\
								INLINEASM("kr_find_file				equ 0Bh");				\
								INLINEASM("kr_set_file_pointer		equ 0Ch");				\
								INLINEASM("kr_set_load_length		equ 0Dh");				\
								INLINEASM("kr_read_file				equ 0Eh");				\
								INLINEASM("kr_erase_file			equ 0Fh");				\
								INLINEASM("kr_rename_file			equ 10h");				\
								INLINEASM("kr_create_file			equ 11h");				\
								INLINEASM("kr_write_file			equ 12h");				\
								INLINEASM("kr_get_total_sectors		equ 13h");				\
								INLINEASM("kr_dir_list_first_entry	equ 14h");				\
								INLINEASM("kr_dir_list_get_entry	equ 15h");				\
								INLINEASM("kr_dir_list_next_entry	equ 16h");				\
								INLINEASM("kr_read_sector			equ 17h");				\
								INLINEASM("kr_write_sector			equ 18h");				\
								INLINEASM("kr_file_sector_list		equ 19h");				\
								INLINEASM("kr_get_dir_cluster		equ 1Ah");				\
								INLINEASM("kr_set_dir_cluster		equ 1Bh");				\
								INLINEASM("kr_get_dir_name			equ 1Ch");				\
								INLINEASM("kr_wait_key				equ 1Dh");				\
								INLINEASM("kr_get_key				equ 1Eh");				\
								INLINEASM("kr_get_key_mod_flags		equ 1Fh");				\
								INLINEASM("kr_serial_receive_header	equ 20h");				\
								INLINEASM("kr_serial_receive_file	equ 21h");				\
								INLINEASM("kr_serial_send_file		equ 22h");				\
								INLINEASM("kr_serial_tx_byte		equ 23h");				\
								INLINEASM("kr_serial_rx_byte		equ 24h");				\
								INLINEASM("kr_print_string			equ 25h");				\
								INLINEASM("kr_clear_screen			equ 26h");				\
								INLINEASM("kr_wait_vrt				equ 27h");								

#define KJT_PROSE2				INLINEASM("kr_set_cursor_position	equ 28h");				\
								INLINEASM("kr_plot_char				equ 29h");				\
								INLINEASM("kr_set_pen				equ 2Ah");				\
								INLINEASM("kr_background_colours	equ 2Bh");				\
								INLINEASM("kr_draw_cursor			equ 2Ch");				\
								INLINEASM("kr_get_pen				equ 2Dh");				\
								INLINEASM("kr_scroll_up				equ 2Eh");				\
								INLINEASM("kr_os_display			equ 2Fh");				\
								INLINEASM("kr_get_display_size		equ 30h");				\
								INLINEASM("kr_get_charmap_addr_xy	equ 31h");				\
								INLINEASM("kr_get_cursor_position	equ 32h");				\
								INLINEASM("kr_set_envar				equ 33h");				\
								INLINEASM("kr_get_envar				equ 34h");				\
								INLINEASM("kr_delete_envar			equ 35h");				\
								INLINEASM("kr_set_mouse_window		equ 36h");				\
								INLINEASM("kr_get_mouse_position	equ 37h");				\
								INLINEASM("kr_get_mouse_motion		equ 38h");				\
								INLINEASM("kr_time_delay			equ 39h");				\
								INLINEASM("kr_compare_strings		equ 3Ah");				\
								INLINEASM("kr_hex_byte_to_ascii		equ 3Bh");				\
								INLINEASM("kr_ascii_to_hex_word		equ 3Ch");				\
								INLINEASM("kr_get_string			equ 3Dh");				\
								INLINEASM("kr_get_version			equ 3Eh");				\
								INLINEASM("kr_dont_store_registers	equ 3Fh");				\
								INLINEASM("kr_get_font_info			equ 40h");				\
								INLINEASM("kr_read_rtc				equ 41h");				\
								INLINEASM("kr_write_rtc				equ 42h");				\
								INLINEASM("kr_get_keymap_location	equ 43h");
								
#define INIT_HARDWARE			INT_CPU_PORTS;			\
								HARDWARE_EQUATES;		\
								MEMORY_LOCATIONS;		\
								HARDWARE_REGISTERS;		\
								OS_EQUATES;
								
#define INIT_KJT				KJT_PROSE;				\
								KJT_PROSE2;
								
#define CREATE_HEADER			asm ("jr skip_header");				\
								asm ("db 'PRO'");					\
								asm ("mb_loc dw24 10000h");			\
								asm ("dw24 0");						\
								asm ("dw 0");						\
								asm ("dw 0");						\
								asm ("db 1");						\
								asm ("skip_header");
								
#define QUIT_TO_PROSE		{										\
								asm ("xor a");						\
								asm ("jp.lil prose_return");		\
							}										\
							
#define RESTART_PROSE		{										\
								asm ("ld a, 0ffh");					\
								asm ("jp.lil prose_return");		\
							}										\							

								
/*-----------------------------------------------------------------------*/
									
//#endif
