#ifndef PROSE_Header_H
#define PROSE_Header_H

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

static char *GenericPnt2, *TxtPnt;
static void *GenericPnt;
static unsigned char K_A, K_B, K_C, K_E;
static unsigned short K_HL, K_DE;
static unsigned int K_xHL, K_xDE;

#define MYVECT					asm ("RetError1");					\
								asm ("jr nz, checkError1");			\
								asm ("xor a");						\
								asm ("checkError1");				\
								asm ("ld (_K_B), a");				\
								asm ("ret");						\
								asm ("GetKeyInBuffer");				\
								asm ("jr nz, NoKeyInB");			\
								asm ("ld (_K_A), a");				\
								asm ("ld a, b");					\
								asm ("ld (_K_B), a");				\
								asm ("NoKeyInB:");					\
								asm ("ret");						\
								asm ("TestMouseEnable");			\
								asm ("xor a");						\
								asm ("jr nz, NoMouse");				\
								asm ("ld a, 1");					\
								asm ("NoMouse:");					\
								asm ("ld (_K_B), a");				\
								asm ("ret");						\
								


//Start Screen Section
#define Call_Print_String()			{									\
										asm ("push ix");				\
										asm ("ld hl, (_TxtPnt)");		\
										asm ("ld a, kr_print_string");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
#define Kjt_Print_String(Txt)			TxtPnt = Txt;				\
										Call_Print_String();
									
#define Kjt_Clear_Screen()			{									\
										asm ("push ix");				\
										asm ("ld a, kr_clear_screen");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
#define Kjt_Wait_Vrt()				{									\
										asm ("push ix");				\
										asm ("ld a, kr_wait_vrt");		\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
#define Kjt_Set_Cursor_Position(x,y){									\
										K_B = x;						\
										K_C = y;						\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_B");			\
										asm ("ld B, (hl)");				\
										asm ("ld hl, _K_C");			\
										asm ("ld C, (hl)");				\
										asm ("ld a, kr_set_cursor_position");\
										asm ("call.lil prose_kernal");	\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}
										
#define Kjt_Plot_Char(x,y,Ascii)	{									\
										K_B = x;						\
										K_C = y;						\
										K_E = Ascii;					\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_B");			\
										asm ("ld B, (hl)");				\
										asm ("ld hl, _K_C");			\
										asm ("ld C, (hl)");				\
										asm ("ld hl, _K_E");			\
										asm ("ld E, (hl)");				\
										asm ("ld a, kr_plot_char");		\
										asm ("call.lil prose_kernal");	\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}
									
#define Kjt_Set_Pen(Pen)			{									\
										K_E = Pen;						\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_E");			\
										asm ("ld E, (hl)");				\
										asm ("ld a, kr_set_pen");		\
										asm ("call.lil prose_kernal");	\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}
									
#define Kjt_Background_Colours(Pnt)	{									\
										GenericPnt = Pnt;				\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_background_colours");\
										asm ("call.lil prose_kernal");	\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}
									
#define Kjt_Draw_Cursor()			{									\
										asm ("push ix");				\
										asm ("ld a, kr_draw_cursor");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
//Result stored in global pseudoregister K_E									
#define Kjt_Get_Pen()				{									\
										asm ("push ix");				\
										asm ("ld a, kr_get_pen");		\
										asm ("call.lil prose_kernal");	\
										asm ("ld a, e");				\
										asm ("ld (_K_E), a");			\
										asm ("pop ix");					\
									}
									
#define Kjt_Scroll_Up()				{									\
										asm ("push ix");				\
										asm ("ld a, kr_scroll_up");		\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
#define Kjt_OS_Display()			{									\
										asm ("push ix");				\
										asm ("ld a, kr_os_display");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}
									
//Result stored in global pseudoregister K_B = Width and K_C = Height
#define Kjt_Get_Display_Size()		{									\
										asm ("push ix");				\
										asm ("ld a, kr_get_display_size");\
										asm ("call.lil prose_kernal");	\
										asm ("ld a, b");				\
										asm ("ld (_K_B), a");			\
										asm ("ld a, c");				\
										asm ("ld (_K_C), a");			\
										asm ("pop ix");					\
									}
									
//Result stored in global pseudoregister K_B = XPos and K_C = YPos
#define Kjt_Get_Cursor_Position()	{									\
										asm ("push ix");				\
										asm ("ld a, kr_get_cursor_position");\
										asm ("call.lil prose_kernal");	\
										asm ("ld a, b");				\
										asm ("ld (_K_B), a");			\
										asm ("ld a, c");				\
										asm ("ld (_K_C), a");			\
										asm ("pop ix");					\
									}
//End Screen Section

//Start File/SD Section
									
#define Kjt_Mount_Volumes(ValE)		{									\
										K_E = ValE;						\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_E");			\
										asm ("ld E, (hl)");				\
										asm ("ld a, kr_mount_volumes");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}
//Result stored in global pseudoregisters K_HL, K_DE, K_B and K_A
//K_HL = location of device info table
//K_DE = location of driver table
//K_B = Device count
//K_A = Currently selected driver
#define Kjt_Get_Device_Info()		{									\
										asm ("push ix");				\
										asm ("ld a, kr_get_device_info");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_HL), hl");			\
										asm ("ld (_K_DE), de");			\
										asm ("ld (_K_A), a");			\
										asm ("ld a, b");				\
										asm ("ld (_K_B), a");			\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Check_Volume_Format()	{									\
										asm ("push ix");				\
										asm ("ld a, kr_check_volume_format");\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Change_Volume(VolNum)	{									\
										K_E = VolNum;					\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_E");			\
										asm ("ld E, (hl)");				\
										asm ("ld a, kr_change_volume");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Format_Device(DNum,Lab)	{									\
										K_E = DNum;						\
										GenericPnt = labs				\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, _K_E");			\
										asm ("ld E, (hl)");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_format_device"); \
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Make_Dir(DirName)		{									\
										GenericPnt = DirName;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_make_dir");		\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Change_Dir(DirName)		{									\
										GenericPnt = DirName;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_change_dir");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Parent_Dir()			{									\
										asm ("push ix");				\
										asm ("ld a, kr_parent_dir");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Root_Dir()				{									\
										asm ("push ix");				\
										asm ("ld a, kr_root_dir");		\
										asm ("call.lil prose_kernal");	\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Delete_Dir(DirName)		{									\
										GenericPnt = DirName;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_delete_dir");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
//If K_B = 0 then
//K_xHL = start cluster of file
//K_xDE = length of file
#define Kjt_Find_File(FileName)		{									\
										GenericPnt = FileName;			\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_find_file");		\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("ld (_K_xHL), hl");		\
										asm ("ld (_K_xDE), de");		\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Set_File_Pointer(FPos)	{									\
										K_xDE = FPos;					\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld de, (_K_xDE)");		\
										asm ("ld a, kr_set_file_pointer");\
										asm ("call.lil prose_kernal");	\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Set_Load_Length(LLen)	{									\
										K_xDE = LLen;					\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld de, (_K_xDE)");		\
										asm ("ld a, kr_set_load_length");\
										asm ("call.lil prose_kernal");	\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Read_File(Buffer)		{									\
										GenericPnt = Buffer;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_read_file");		\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Erase_File(FileName)	{									\
										GenericPnt = FileName;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_erase_file");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Rename_File(OldName, NewName)	{									\
												asm ("push ix");				\
												asm ("push hl");				\
												asm ("push de");				\
												GenericPnt = OldName;			\
												asm ("ld hl, (_GenericPnt)");	\
												GenericPnt = NewName;			\
												asm ("ld de, (_GenericPnt)");	\
												asm ("ld a, kr_rename_file");	\
												asm ("call.lil prose_kernal");	\
												asm ("call RetError1");			\
												asm ("pop de");					\
												asm ("pop hl");					\
												asm ("pop ix");					\
											}									\
											
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Create_File(FileName)	{									\
										GenericPnt = FileName;			\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, kr_create_file");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Write_File(FileName, Buffer, Len)							\
									{									\
										GenericPnt = FileName;			\
										GenericPnt2 = Buffer;			\
										K_xDE = Len;					\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("push de");				\
										asm ("push bc");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld de, (_GenericPnt2)");	\
										asm ("ld bc, (_K_xDE)");		\
										asm ("ld a, kr_write_file");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop bc");					\
										asm ("pop de");					\
										asm ("pop hl");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_xDE = sector count
#define Kjt_Get_Total_Sectors()		{									\
										asm ("push ix");				\
										asm ("ld a, kr_get_total_sectors");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_xDE), de");		\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Dir_List_First_Entry(Name, Len, Flag)						\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_dir_list_first_entry");\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("ld (_K_xHL), hl");		\
										asm ("ld (_K_xDE), de");		\
										asm ("ld (_K_A), b");			\
										asm ("pop de");					\
										asm ("pop ix");					\
										Name = (char *)K_xHL;			\
										Len = K_xDE;					\
										Flag = K_A;						\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Dir_List_Get_Entry(Name, Len, Flag)							\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_dir_list_get_entry");\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("ld (_K_xHL), hl");		\
										asm ("ld (_K_xDE), de");		\
										asm ("ld (_K_A), b");			\
										asm ("pop de");					\
										asm ("pop ix");					\
										Name = (char *)K_xHL;			\
										Len = K_xDE;					\
										Flag = K_A;						\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Dir_List_Next_Entry(Name, Len, Flag)						\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_dir_list_next_entry");\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("ld (_K_xHL), hl");		\
										asm ("ld (_K_xDE), de");		\
										asm ("ld (_K_A), b");			\
										asm ("pop de");					\
										asm ("pop ix");					\
										Name = (char *)K_xHL;			\
										Len = K_xDE;					\
										Flag = K_A;						\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Read_Sector(Dest, Sector, DevNumber)						\
									{									\
										GenericPnt = Dest;				\
										K_xDE = Sector;					\
										K_B = DevNumber;				\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld de, (_K_xDE)");		\
										asm ("ld b, (_K_B)");			\
										asm ("ld a, kr_read_sector");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Write_Sector(Buffer, Sector, DevNumber)						\
									{									\
										GenericPnt = Buffer;			\
										K_xDE = Sector;					\
										K_B = DevNumber;				\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld de, (_K_xDE)");		\
										asm ("ld b, (_K_B)");			\
										asm ("ld a, kr_write_sector");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//#define kr_file_sector_list - not implemented
									
//Result stored in global pseudoregister K_DE, = current dir's cluster address
#define Kjt_Get_Dir_Cluster()		{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_get_dir_cluster");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_DE), de");			\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Set_Dir_Cluster(NewAddr)									\
									{									\
										K_DE = NewAddr;					\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld de, (_K_DE)");			\
										asm ("ld a, kr_set_dir_cluster");\
										asm ("call.lil prose_kernal");	\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else Error code
#define Kjt_Get_Dir_Name(GetName)	{									\
										asm ("push ix");				\
										asm ("push hl");				\
										asm ("ld a, kr_get_dir_name");	\
										asm ("call.lil prose_kernal");	\
										asm ("call RetError1");			\
										asm ("ld (_K_xHL), hl");		\
										asm ("pop hl");					\
										asm ("pop ix");					\
										GetName = (char *)K_xHL;		\
									}									\
									
//End File/SD Section
									
//Start Generic Section
									
#define Kjt_Wait_Key(Scancode, AsciiCode)								\
									{									\
										asm ("push ix");				\
										asm ("ld a, kr_wait_key");		\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_A), a");			\
										asm ("ld a, b");				\
										asm ("ld (_K_B), a");			\
										asm ("pop ix");					\
										Scancode = K_A;					\
										AsciiCode = K_B;				\
									}									\
									
#define Kjt_Get_Key(Scancode, AsciiCode)								\
									{									\
										K_A = 0;						\
										K_B = 0;						\
										asm ("push ix");				\
										asm ("ld a, kr_get_key");		\
										asm ("call.lil prose_kernal");	\
										asm ("call GetKeyInBuffer");	\
										asm ("pop ix");					\
										Scancode = K_A;					\
										AsciiCode = K_B;				\
									}									\

//Result stored in global pseudoregister K_A
#define Kjt_Get_Key_Mod_Flags(Flags)									\
									{									\
										K_A = 0;						\
										asm ("push ix");				\
										asm ("ld a, kr_get_key_mod_flags");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_A), a");			\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Set_Mouse_Window(Width, Height)								\
									{									\
										K_HL = Width;					\
										K_DE = Height;					\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld hl, (_K_HL)");			\
										asm ("ld de, (_K_DE)");			\
										asm ("ld a, kr_set_mouse_window");\
										asm ("call.lil prose_kernal");	\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else no Mouse
#define Kjt_Get_Mouse_Position(mX, mY, Btn)								\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_get_mouse_position");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_HL), hl");			\
										asm ("ld (_K_DE), de");			\
										asm ("ld (_K_A), a");			\
										asm ("call TestMouseEnable");	\
										asm ("pop de");					\
										asm ("pop ix");					\
										mX = K_HL;						\
										mY = K_DE;						\
										Btn = K_A;						\
									}									\
									
//Result stored in global pseudoregister K_B, 0 = OK else no Mouse
#define Kjt_Get_Mouse_Motion(dX, dY, Btn)								\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_get_mouse_motion");\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_HL), hl");			\
										asm ("ld (_K_DE), de");			\
										asm ("ld (_K_A), a");			\
										asm ("call TestMouseEnable");	\
										asm ("pop de");					\
										asm ("pop ix");					\
										dX = K_HL;						\
										dY = K_DE;						\
										Btn = K_A;						\
									}									\
									
#define Kjt_Time_Delay(Value)		{									\
										K_DE = Value;					\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld de, (_K_DE)");			\
										asm ("ld a, kr_time_delay");	\
										asm ("call.lil prose_kernal");	\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
//Result stored in global pseudoregisters K_B and K_A
//if K_B = 0; K_A number of characters entered
//if K_B <> 0; K_A = $80 if ESC was pressed, $81 if no characters were entered
#define Kjt_Get_String(String, NChars)									\
									{									\
										K_E = NChars;					\
										GenericPnt = String;			\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld hl, (_GenericPnt)");	\
										asm ("ld a, (_K_E)");			\
										asm ("ld e, a");				\
										asm ("ld a, kr_get_string");	\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_A), a");			\
										asm ("call RetError1");			\
										asm ("pop de");					\
										asm ("pop ix");					\
									}									\
									
#define Kjt_Get_Version(vPROSE, vAMOEBA)								\
									{									\
										asm ("push ix");				\
										asm ("push de");				\
										asm ("ld a, kr_get_version");	\
										asm ("call.lil prose_kernal");	\
										asm ("ld (_K_HL), hl");			\
										asm ("ld (_K_DE), de");			\
										asm ("pop de");					\
										asm ("pop ix");					\
										vPROSE = K_HL;					\
										vAMOEBA = K_DE;					\
									}									\
									
#endif
