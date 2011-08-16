#ifndef _LIBEZ80P_H_
#define _LIBEZ80P_H_

#include <defines.h>

extern UINT8 PROSE_Result;

typedef enum
{
	TEXT_80x60 = 0,
	TEXT_80x30,
	TEXT_40x60,
	TEXT_40x30
} char PROSE_VIDEO_MODE;

typedef enum
{
	TYPE_FILE	= 0,
	TYPE_DIR	= 1
} char PROSE_FILE_TYPE;

typedef struct 
{
	void 	*DeviceTable;
	void 	*DriverTable;
	UINT8 	DeviceCount;
	UINT8 	DriverIndex;
} PROSE_DEVICE_INFO;

typedef struct
{
	void 	*MountList;
	UINT8 	VolumeCount;
	UINT8 	VolumeIndex;
} PROSE_VOLUME_INFO;

typedef struct
{
	UINT24 	location;
	UINT24 	length;
	UINT24  loop_location;
	UINT24	loop_length;
	UINT16	period;
	UINT8	volume;
} PROSE_SAMPLE_INFO;

typedef struct 
{
	char 				*FileName;
	UINT32				FileLength;
	PROSE_FILE_TYPE		FileType;
} PROSE_FILE_INFO;

typedef struct
{
	// NOTE: All of these values should be in
	// BCD format (i.e. 0x43 = 43, 0x12 = 12 etc)
	UINT8 	sec;
	UINT8 	min;
	UINT8	hr;
	UINT8	dow;
	UINT8	day;
	UINT8	mon;
	UINT8	yr;
	UINT8	cen;
} PROSE_RTC;

typedef struct
{
	UINT16	colours[16];
} PROSE_PAL16;

/* Function 00h - Rescans hardware for any storage devices
 *
 * INPUT: 	If suppressText is true, no text will be shown.
 * OUTPUT:  Zero if OK, otherwise error code
 */
extern void KR_Mount_Volumes(BOOL suppressText);

/* Function 01h - Get info about the storage devices
 *
 * INPUT: 	Ptr to PROSE_DEVICE_INFO structure
 * OUTPUT:  Zero if OK, otherwise error code
 */
extern void KR_Get_Device_Info(PROSE_DEVICE_INFO *info);

/* Function 02h - Check current volume is formatted to FAT16
 *
 * INPUT: 	None
 * OUTPUT:  None, but see PROSE_Result
 */
extern void KR_Check_Volume_Format(void);

/* Function 03h - Change volume
 *
 * INPUT: 	volume = volume index to be selected
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Change_Volume(UINT8 volume);

/* Function 04h - Get info about the storage volumes
 *
 * INPUT: 	Ptr to PROSE_VOLUME_INFO structure
 * OUTPUT:  Zero if OK, otherwise error code
 */
extern void KR_Get_Volume_Info(PROSE_VOLUME_INFO *info);

/* Function 05h - Format a device to FAT16
 *
 * INPUT: 	device = unit index for device
 *			label = ptr to 0-terminated string for label
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Format_Device(UINT8 device, char *label);

/* Function 06h - Make a directory
 *
 * INPUT: 	label = ptr to 0-terminated string for dir name
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Make_Dir(char *label);

/* Function 07h - Change current directory
 *
 * INPUT: 	label = ptr to 0-terminated string for dir name
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Change_Dir(char *label);

/* Function 08h - Move to the parent dir of the current
 *
 * INPUT: 	None
 * OUTPUT:  None, but see PROSE_Result
 */
extern void KR_Parent_Dir(void);

/* Function 09h - Set root as current directory (cd to root)
 *
 * INPUT: 	None
 * OUTPUT:  None, but see PROSE_Result
 */
extern void KR_Root_Dir(void);

/* Function 0ah - Delete directory
 *
 * INPUT: 	label = ptr to 0-terminated string for dir name
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Delete_Dir(char *label);

/* Function 0bh - Open file so that data may be loaded from it
 *
 * INPUT: 	fname = ptr to 0-terminated string with filename
 *			start = start cluster
 *			length = length of file
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Find_File(char *fname, UINT24 *start, UINT32 *length);

/* Function 0ch - Move file pointer to a position within the
 *				  currently opened file
 *
 * INPUT: 	offset = 32-bit offset value
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Set_File_Pointer(UINT32 offset);

/* Function 0dh - Set maximum data transfer length for
 *				  a file read
 *
 * INPUT: 	length = 24-bit load length
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Set_Load_Length(UINT24 length);

/* Function 0eh - Read data from the currently opened file
 *
 * INPUT: 	addr = load address
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Read_File(void *addr);

/* Function 0fh - Delete a file
 *
 * INPUT: 	fname = ptr to 0-terminated string for filename
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Erase_File(char *fname);

/* Function 10h - Rename a file
 *
 * INPUT: 	src = ptr to 0-terminated string for original filename
 *          dst = ptr to 0-terminated string for new filename
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Rename_File(char *src, char *dst);

/* Function 11h - Create a file
 *
 * INPUT: 	fname = ptr to 0-terminated string for filename
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Create_File(char *fname);

/* Function 12h - Append data to existing file
 *
 * INPUT: 	fname = ptr to 0-terminated string for filename
 *			data = ptr to start of data
 *			length = size of data to write
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Write_File(char *fname, void *data, UINT24 length);

/* Function 13h - Get total sector capacity of current volume
 *
 * INPUT: 	sectors = ptr to receive sector count
 * OUTPUT:  None, but check PROSE_Result
 */
extern UINT24 KR_Get_Total_Sectors(void);

/* Function 14h - Get first entry of a directory
 *
 * INPUT: 	dirrec = Pointer to PROSE_FILE_INFO structure
 * OUTPUT:  TRUE if successfull, otherwise check PROSE_Result
 */
extern BOOL KR_Dir_List_First_Entry(PROSE_FILE_INFO *dirrec);

/* Function 15h - Get an entry of a directory
 *
 * INPUT: 	dirrec = Pointer to PROSE_FILE_INFO structure
 * OUTPUT:  TRUE if successfull, otherwise check PROSE_Result
 */
extern BOOL KR_Dir_List_Get_Entry(PROSE_FILE_INFO *dirrec);

/* Function 16h - Get next entry of a directory
 *
 * INPUT: 	dirrec = Pointer to PROSE_FILE_INFO structure
 * OUTPUT:  TRUE if successfull, otherwise check PROSE_Result
 */
extern BOOL KR_Dir_List_Next_Entry(PROSE_FILE_INFO *dirrec);

/* Function 17h - Read a sector from the specified device to
 * 				  the target address provided
 *
 * INPUT: 	device = device number
 *			sector = sector number
 *			addr = destination address
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Read_Sector(UINT8 device, UINT32 sector, void *addr);

/* Function 18h - Write a sector to the specified device from
 * 				  the source address provided
 *
 * INPUT: 	device = device number
 *			sector = sector number
 *			addr = source address
 * OUTPUT:  None, but check PROSE_Result
 */
extern void KR_Write_Sector(UINT8 device, UINT32 sector, void *addr);

/* Function 19h - Obtain a list of the sectors that
 * 				  a file occupies
 *
 * INPUT: 	cluster = cluster number
 *			sector = sector offset
 *			addr = ptr to receive location of 32-bit sector
 * OUTPUT:  None, but check PROSE_Result
 * NOTES:	First call KR_Find_File with the filename. This will give the
 *			first cluster used by the file. Use that value as the initial
 *			cluster value, and offset of 0 and call KR_File_Sector_List.
 *			On succesful call, sector will contain the sector number, and
 *			cluster and offset will now point to the next values required 
 *			to get the next sector in the list by repeating this call. 
 *			Keep repeating for the size of the file (length / 512)
 */
extern void KR_File_Sector_List(UINT24 *cluster, UINT8 *offset, UINT32 *sector);

/* Function 1ah - Read the cluster location of the current dir
 *
 * INPUT: 	None
 * OUTPUT:  Current directory's cluster address, 
 *			but check PROSE_Result for validity
 */
extern UINT24 KR_Get_Dir_Cluster(void);

/* Function 1bh - Set the cluster location of current dir
 *
 * INPUT: 	Cluster addr to use as current dir
 * OUTPUT:  None, but check PROSE_Result 
 */
extern void KR_Set_Dir_Cluster(UINT24 cluster);

/* Function 1ch - Get current directory name
 *
 * INPUT: 	None
 * OUTPUT:  Ptr to directory name ASCII, 0-terminated
 *			but check PROSE_Result for validity
 */
extern char *KR_Get_Dir_Name(void);

/* Function 1dh - Pause until a key is pressed
 *
 * INPUT: 	Ptrs to receive:
 *				scan = scancode
 *				ascii = ASCII char modified by SHIFT/ALT/CTRL or 0
 * OUTPUT:  Check PROSE_Result for validity
 */
extern void KR_Wait_Key(UINT8 *scan, UINT8 *ascii);

/* Function 1eh - Return keypress in the buffer (does not wait)
 *
 * INPUT: 	Ptrs to receive:
 *				scan = scancode
 *				ascii = ASCII char modified by SHIFT/ALT/CTRL or 0
 * OUTPUT:  BOOL true if keycode was received, otherwise buffer
 *			was empty
 */
extern BOOL KR_Get_Key(UINT8 *scan, UINT8 *ascii);

/* Function 1fh - Get status of modifier keys (shift etc)
 *
 * INPUT: 	None
 * OUTPUT:  Value of modifier keys (bitmapped):
 *				bit 	0 - left shift
 *						1 - left/right ctrl
 *						2 - left GUI
 *						3 - left/right alt
 *						4 - right shift
 *						5 - right GUI
 *						6 - Apps
 */
extern UINT8 KR_Get_Key_Mod_Flags(void);

/* Function 20h - Wait for file header from serial port
 *
 * INPUT: 	Ptr to filename
 *			timeout (seconds)
 *			ptr to buffer to receive header
 * OUTPUT:  BOOL true if header received ok
 *			see PROSE_Result for failure code
 */
extern BOOL KR_Serial_Receive_Header(char *fname, UINT8 timeout, void *hdr);

/* Function 21h - Wait for serial file transfer (following reception
 * 			      of a header)
 *
 * INPUT: 	Ptr to load address
 * OUTPUT:  see PROSE_Result for failure code
 */
extern void KR_Serial_Receive_File(void *addr);

/* Function 22h - Send a file to the serial port
 *
 * INPUT: 	Ptr to filename
 *			ptr to start address
 *			length of data
 * OUTPUT:  see PROSE_Result for failure code
 */
extern void KR_Serial_Send_File(char *fname, void *addr, UINT24 length);

/* Function 23h - Send a byte to the serial port
 *
 * INPUT: 	byte to send
 * OUTPUT:  None
 */
extern void KR_Serial_Tx_Byte(UINT8 data);

/* Function 24h - Receive a byte from the serial port
 *
 * INPUT: 	timeout (seconds)
 * OUTPUT:  None, but see PROSE_Result to check validity
 */
extern void KR_Serial_Rx_Byte(UINT8 timeout, UINT8 *data);

/* Function 25h - Print a string at current cursor position
 *                and in the current pen colour
 *
 * INPUT: 	Pointer to null-terminated string
 * OUTPUT: 	Address following null-terminating character in string
 */
extern char *KR_Print_String(char *message);

/* Function 26h - Clear the screen
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Clear_Screen(void);

/* Function 27h - Wait for Vertical Retrace
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Wait_VRT(void);

/* Function 28h - Set cursor position
 *
 * INPUT: 	x = x position, y = y position (both zero-based)
 * OUTPUT:  true if outside of display window, otherwise false
 */
extern BOOL KR_Set_Cursor_Position(UINT8 x, UINT8 y);

/* Function 29h - Plot character without moving cursor
 *
 * INPUT: 	x = x position, y = y position (both zero-based), c = character
 * OUTPUT:  true if outside of display window, otherwise false
 */
extern BOOL KR_Plot_Char(UINT8 x, UINT8 y, char c);

/* Function 2ah - Set Pen Colour
 *
 * INPUT: 	Pen colour. Bits 0:3 (LSB) is character colour, Bits 4:7 (MSB) is bg colour
 * OUTPUT:  true if outside of display window, otherwise false
 */
extern void KR_Set_Pen(UINT8 pen);

/* Function 2bh - Set Background Colour
 *
 * INPUT: 	ptr to colour palette (see PROSE_PAL16)
 * OUTPUT:  None
 */
extern void KR_Background_Colours(PROSE_PAL16 *ospal);

/* Function 2ch - Draw cursor image as defined by KR_Set_Cursor_Image
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Draw_Cursor(void);

/* Function 2dh - Get current pen colour
 *
 * INPUT: 	None
 * OUTPUT:  Current pen colour
 */
extern UINT8 KR_Get_Pen(void);

/* Function 2eh - Scroll the display up a line
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Scroll_Up(void);

/* Function 2fh - Restore display h/w settings to OS values 
 *                (does not clear screen)
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_OS_Display(void);

/* Function 30h - Get video mode
 *
 * INPUT: 	Pointers to receive:
 *          	mode = Video mode, 
 * 				cols = Columns, 
 * 				rows = Rows (lines)
 * OUTPUT:  None
 */
extern void KR_Get_Video_Mode(UINT8 *mode, UINT8 *cols, UINT8 *rows);

/* Function 31h - Get charmap and attribute map for location
 *
 * INPUT: 	x = x position (col)
 * 			y = y position (row)
 * OUTPUT:  Pointers to receive:
 *          	cmap = Char Map Addr, 
 * 				attrib = Attribute Addr, 
 */
extern void KR_Get_Charmap_Addr_XY(UINT8 x, UINT8 y, UINT8 *cmap, UINT8 *attrib);

/* Function 32h - Get cursor position
 *
 * INPUT: 	Pointers to receive:
 *				x = x position (col)
 * 				y = y position (row)
 * OUTPUT:  None
 */
extern void KR_Get_Cursor_Position(UINT8 *x, UINT8 *y);

/* Function 33h - Set Env Variable
 *
 * INPUT: 	Pointers containing
 *          	name = variable name, 
 * 				data = content to store against var
 * OUTPUT:  BOOL true if set OK
 */
extern BOOL KR_Set_Envar(char *name, char *data);

/* Function 34h - Get Env Variable
 *
 * INPUT: 	Pointer containing:
 *          	name = variable name
 * OUTPUT:  Pointer to variable data (NULL if not found)
 */
extern char *KR_Get_Envar(char *name);

/* Function 35h - Delete Env Variable
 *
 * INPUT: 	Pointer containing:
 *          	name = variable name
 * OUTPUT:  BOOL true if found and deleted OK
 */
extern BOOL KR_Delete_Envar(char *name);

/* Function 36h - Set mouse constraining window
 *
 * INPUT: 	width = Width in pixels, height = height in pixels
 * OUTPUT:  None
 */
extern void KR_Set_Mouse_Window(UINT16 width, UINT16 height);

/* Function 37h - Get mouse position (absolute)
 *
 * INPUT: 	Ptrs to:
 *				xpos = X Position, 
 *				ypos = Y Position, 
 *				btns = Buttons, 
 *				wheel = Wheel
 * OUTPUT:  BOOL true if mouse present, otherwise false
 */
extern BOOL KR_Get_Mouse_Position(UINT16 *xpos, UINT16 *ypos, UINT8 *btns, UINT8 *wheel);

/* Function 38h - Get mouse position (relative)
 *
 * INPUT: 	Ptrs to:
 *				xpos = X Position, 
 *				ypos = Y Position, 
 *				btns = Buttons, 
 *				wheel = Wheel
 * OUTPUT:  BOOL true if mouse present, otherwise false
 */
extern BOOL KR_Get_Mouse_Motion(INT16 *xpos, INT16 *ypos, UINT8 *btns, UINT8 *wheel);

/* Function 39h - Pause for up to 2 seconds
 *
 * INPUT: 	Number of 32768 Hz ticks to pause - max 65535
 * OUTPUT:  None
 */
extern void KR_Time_Delay(UINT16 ticks);

/* Function 3ah - Compare two strings, ignoring case
 *
 * INPUT: 	Pointers to strings 
 *				(str1 and str2)
 *          Number of bytes to compare
 * OUTPUT:  BOOL true if strings are the same
 */
extern BOOL KR_Compare_Strings(char *str1, char *str2, UINT8 count);

/* Function 3bh - Convert Hex byte to ASCII
 *
 * INPUT: 	Value to convert
 * 			Pointer to 2-byte buffer to receive conversion
 * OUTPUT:  None
 */
extern void KR_Hex_To_ASCII(UINT8 value, char *buffer);

/* Function 3ch - Convert ASCII to Hex word. Routine will
 *                begin conversion from first non-space
 *
 * INPUT: 	Ptr to string containing ASCII
 * OUTPUT:  Converted value
 */
extern UINT24 KR_ASCII_To_Hex(char *ascii);

/* Function 3dh - Wait for user to enter string of chars
 *                followed by RETURN (ESC quits)
 *
 * INPUT: 	Ptr to buffer to contain string
 *			Max number of chars
 * OUTPUT:  Num of chars entered. If zero, see PROSE_Result
 *			$80 = ESC pressed, $81 = No chars entered
 */
extern UINT8 KR_Get_String(char *buf, UINT8 maxlen);

/* Function 3eh - Get version info
 *
 * INPUT: 	Pointers to receive:
 *          	prose = Prose Version, 
 *				amoeba = Amoeba Version
 * OUTPUT:  None
 */
extern void KR_Get_Version(UINT16 *prose, UINT16 *amoeba);

/* Function 3fh - Don't store regs when an app returns
 *                control to PROSE
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Dont_Store_Registers(void);

/* Function 40h - Get Font Information
 *                **OBSOLETE** in PROSE v31+
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Get_Font_Info(void);

/* Function 41h - Read RTC
 *
 * INPUT: 	Pointer to receive RTC information
 *          (see PROSE_RTC structure)
 * OUTPUT:  None
 */
extern PROSE_RTC *KR_Read_RTC(void);

/* Function 42h - Set RTC
 *
 * INPUT: 	Pointer containing new RTC information
 *          (see PROSE_RTC structure)
 * OUTPUT:  None
 */
extern void KR_Write_RTC(PROSE_RTC *rtc);

/* Function 43h - Get keymap location within the OS
 *
 * INPUT: 	None
 * OUTPUT:  Address of keymap
 */
extern void *KR_Get_Keymap_Location(void);

/* Function 44h - Get first free address unused by OS
 *
 * INPUT: 	None
 * OUTPUT:  Pointer to first free RAM addr, vram a addr, vram b addr
 */
extern void KR_Get_OS_High_Mem(void *ram, void *vida, void *vidb);

/* Function 45h - Play an audio sample (from vram b)
 *
 * INPUT: 	Pointer to sample information structure (see PROSE_SAMPLE_INFO),
 *          Channels to play the sound
 *			Bit 0 (LSB) = channel 0, Bit 1 = channel 1 etc.
 * OUTPUT:  None
 */
extern void KR_Play_Audio(PROSE_SAMPLE_INFO *sample, UINT8 channels);

/* Function 46h - Silence all audio channels by disabling the audio
 *                hardware and silencing each channel's volume register
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Disable_Audio(void);

/* Function 47h - Read Joysticks
 *
 * INPUT: 	None
 * OUTPUT:  Joystick bits. High byte JS1, Low byte JS0. 
 *          A set bit means switch is pressed
 *               -===== Joystick 1 =====-               -===== Joystick 0 =====-
 *          x x x Fire1 Fire0 Right Left Down Up   x x x Fire1 Fire0 Right Left Down Up
 */
extern UINT16 KR_Get_Joysticks(void);

/* Function 48h - Set Video Mode
 *
 * INPUT: 	mode = new mode value (see PROSE_VIDEO_MODE enum type)
 * OUTPUT:  None
 * ERRORS:  PROSE_Result will contain 0x88 if the video mode is invalid
 */
extern void KR_Set_Video_Mode(PROSE_VIDEO_MODE mode);

/* Function 49h - Select which character to use for cursor
 *
 * INPUT: 	Character to use for cursor 
 *          (eg 0x5f = underscore, 0x7f = block)
 * OUTPUT:  None
 */
extern void KR_Set_Cursor_Image(char cursor);

/* Function 4ah - Remove cursor image (replacing with saved character)
 *
 * INPUT: 	None
 * OUTPUT:  None
 */
extern void KR_Remove_Cursor(void);

/* Function 4bh - Redefine a character in the PROSE font (for UDG)
 *
 * INPUT: 	ASCII Character to remap,
 *          Address of 8 bytes of pattern data to use
 * OUTPUT:  None
 */
extern void KR_Char_To_Font(char target, void *data);

extern BOOL ZZ_Test(BOOL bIn);

#endif // _LIBEZ80P_H_