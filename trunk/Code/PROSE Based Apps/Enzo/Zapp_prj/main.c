#include <Stdio.h>
#include <Stdlib.h>
#include <String.h>

#define ENABLE_MSEC_COUNTER			1
#define DISABLE_MSEC_COUNTER		0

#include "PROSE_Header.h"

/*-------------------------------------------------------------------------------------*/
unsigned int mlSec = 0;
short int mlMSec = 0;
static char *TxtPnt;
char *MainFile, *Param;
unsigned char *MainDest;
unsigned int MainFileSize;
static unsigned char g_AValue, g_SValue;
unsigned int K_xHL;

void MyMain(void);

void MSec_Counter(char Enable);
unsigned long Read_MSec_Counter(void);
void print(const char *Txt);

int Load_Bin_Data(const char *FName, const unsigned char *Dest, unsigned int Size);
int File_Exists(const char *FName);
int Create_File(const char *FName);
void mDelay(int Millisec);
void ReadKbd(unsigned char *Ascii, unsigned char *Scancode);

int Handle_Input(void);
void Load_Basic(void);

void uitoa(unsigned int val, char *string);

int Dump_Memory(const char *FName);
void Dump_In_File(void);
int Load_Dump(void);
/*-------------------------------------------------------------------------------------*/

void main(void)
{
	INIT_HARDWARE;
	INIT_KJT;
	
	CREATE_HEADER;
	
	Param = NULL;
	
	asm ("ld a, (hl)");
	asm ("or a");
	asm ("jr z, no_param");
	asm ("ld (_K_xHL), hl");
	
	Param = (char *)K_xHL;
	
	asm ("no_param:");
	
	MyMain();
	
	QUIT_TO_PROSE;
}

#include "Screen.c"
#include "Pia6820.c"
#include "Memory.c"
#include "M6502.c"

void MyMain(void)
{
	MSec_Counter(ENABLE_MSEC_COUNTER);
	
	Init_Opcode_Table();
	
	print("\n\r");
	print("Zapp - eZ80P Apple 1 Emulator\n\r");
	print ("Load system roms...\n\r");
	
	if (LoadCharMap() == 1)
	{
		print("Error while loading charmap.rom. Exit to PROSE.\n\r");
		
		goto EndProgram;
	}
	
	if (Load_Monitor() == 1)
	{
		print("Error while loading monitor.rom. Exit to PROSE.\n\r");
		
		goto EndProgram;
	}
		
	Set_Screen();

	Reset_Screen();
	
	Reset_Memory();
	
	//Set_Speed(1000, 50);
	
	if (Param != NULL)
		if (Load_Dump() == 0)
		{
			if ((mem[0xF000] != 0) && (Mem_Mode() == 8))
			{
				Flip_Mode();
				
				Show_Mode();
			}				
			
			Reset_Pia6820();			
		}
	
	Reset_M6502();
	
	while (Handle_Input())
		Run_M6502();
	
	Close_Screen();
	
	EndProgram:
	MSec_Counter(DISABLE_MSEC_COUNTER);	
	
	free(Characters);
	free(mem);
	
	print("Zapp - eZ80P Apple 1 Emulator\n\r");
	print("Programmed By Calogiuri Enzo Antonio.\n\r");
	
	print("\n\r");
}

void MSec_Counter(char Enable)
{
	asm ("push ix");	
	
	if (Enable == 1)
		asm ("ld e, 1");
	else
		asm ("ld e, 0");
	
	asm ("ld a, kr_init_msec_counter");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

unsigned long Read_MSec_Counter(void)
{
	asm ("push ix");
	asm ("push de");
	asm ("ld a, kr_read_msec_counter");
	asm ("call.lil prose_kernal");
	asm ("ld (_mlSec), hl");
	asm ("ld (_mlMSec), de");
	asm ("pop de");
	asm ("pop ix");
	
	return (unsigned long)((mlSec * 1000) + mlMSec);
}

void print(const char *Txt)
{
	TxtPnt = Txt;
	
	asm ("push ix");
	asm ("ld hl, (_TxtPnt)");
	asm ("ld a, kr_print_string");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

int Load_Bin_Data(const char *FName, const unsigned char *Dest, unsigned int Size)
{
	int ret = 0;
	
	MainFile = FName;
	MainDest = Dest;
	MainFileSize = Size;
	
	asm ("push ix");
	asm ("ld hl, (_MainFile)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, FileError");
	
	asm ("push ix");
	asm ("ld de, (_MainFileSize)");
	asm ("ld a, kr_set_load_length");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	asm ("push ix");
	asm ("ld hl, (_MainDest)");
	asm ("ld a, kr_read_file");
	asm ("call.lil prose_kernal");
	asm ("jr nz, FileError");
	asm ("pop ix");
	
	asm ("jr LBD_Quit");
	
	asm("FileError:");
	
	ret = 1;
	
	asm("LBD_Quit:");
	
	return ret;
}

int File_Exists(const char *FName)
{
	int ret;
	
	MainFile = FName;
	
	asm ("push ix");
	asm ("ld hl, (_MainFile)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, FileExistsError");
	
	ret = 0;
	
	asm ("jr FE_Quit");
	
	asm ("FileExistsError:");
	
	ret = 1;
	
	asm ("FE_Quit:");
	
	return ret;
}

int Create_File(const char *FName)
{
	int ret;
	
	MainFile = FName;
	
	asm ("push ix");
	asm ("ld hl, (_MainFile)");
	asm ("ld a, kr_create_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, CreateFileError");
	
	ret = 0;
	
	asm ("jr CF_Quit");
	
	asm ("CreateFileError:");
	
	ret = 1;
	
	asm ("CF_Quit:");
	
	return ret;
}

void mDelay(int Millisec)
{
	int Microsec = Millisec * 1000;
	int Granularity = Microsec / 30;
	
	mlMSec = Granularity;
	
	asm ("push ix");
	asm ("push de");
	asm ("ld de, (_mlMSec)");
	asm ("ld a, kr_time_delay");
	asm ("call.lil prose_kernal");
	asm ("pop de");
	asm ("pop ix");
}

void Get_Key(void)
{
	asm ("ld a, kr_get_key");
	asm ("call.lil prose_kernal");
	asm ("jr nz, NoKeyInB");
	asm ("ld (_g_SValue), a");
	asm ("ld a, b");
	asm ("ld (_g_AValue), a");
	asm ("NoKeyInB:");
}

void ReadKbd(unsigned char *Ascii, unsigned char *Scancode)
{
	g_AValue = 0;
	g_SValue = 0;
	
	Get_Key();
	
	*Ascii = g_AValue;
	*Scancode = g_SValue;
}

int Handle_Input(void)
{
	unsigned char Ak, Sk;	
	
	ReadKbd(&Ak, &Sk);
	
	if (Sk != 0)
	{
		if (Sk == 0x07)
			return 0;
		
		if (Sk == 0x09)
		{
			Reset_Pia6820();
			Reset_M6502();
			
			return 1;
		}
		
		if (Sk == 0x01)
		{
			Reset_Screen();
			Reset_Pia6820();
			Reset_Memory();
			Reset_M6502();
			
			memset(VideoMem, 0, 320 * 200);
			
			return 1;
		}
		
		if (Sk == 0x04)
		{
			Flip_Mode();
			
			Reset_Pia6820();
			Reset_M6502();
			
			Show_Mode();
			
			return 1;
		}
		
		if (Sk == 0x0A)
		{
			Load_Basic();
			
			Reset_Pia6820();
			Reset_M6502();
			
			return 1;
		}
		
		if (Sk == 0x03)
		{
			Dump_In_File();
			
			return 1;
		}
		
		if (Sk == 0x5A)
			Ak = '\r';		
		
		if (Sk == 0x66)
			return 1;
		
		if (Ak >= 'a' && Ak <= 'z')
			Ak = Ak - 'a' + 'A';
		
		Write_Kbd((unsigned char)(Ak + 0x80));
		Write_KbdCr(0xA7);
	}	
	
	return 1;
}

void Load_Basic(void)
{
	int r;
	unsigned char Ak = 0, Sk = 0;
	
	r = Load_Bin_Data("BASIC.ROM", &mem[0xE000], 4096);
	
	if (r == 1)	
		Blit_String(0, 230, "FAILED TO LOAD BASIC. HIT A KEY!");
	else
		Blit_String(0, 230, "TYPE E000R TO RUN BASIC. HIT A KEY!");
	
	while (Sk == 0)
		ReadKbd(&Ak, &Sk);
		
	Blit_String(0, 230, "                                     ");
}

void uitoa(unsigned int val, char *string)
{
	char index = 0, i = 0;
	
	do {
		string[index] = '0' + (val % 10);
		
		if (string[index] > '9')
			string[index] += 'A' - '9' - 1;
		
		val /= 10;
		++index;
  } while (val != 0);
  
  string[index--] = '\0'; 
  
  while (index > i)
  {
    char tmp = string[i];
	  
    string[i] = string[index];
    string[index] = tmp;
    ++i;
    --index;
  }
}

int Dump_Memory(const char *FName)
{
	int ret;
	
	MainFile = FName;
	
	asm ("push ix");
	asm ("ld hl, (_MainFile)");
	asm ("ld de, (_mem)");
	asm ("ld bc, FFFFh");
	asm ("ld a, kr_write_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	asm ("jr nz, DumpMemoryError");
	
	ret = 0;
	
	asm ("jr DM_Quit");
	
	asm ("DumpMemoryError:");
	
	ret = 1;
	
	asm ("DM_Quit:");
	
	return ret;
}

void Dump_In_File(void)
{
	char buf[4];
	int i;
	char FileName[14];
	unsigned char Ak = 0, Sk = 0;	
	
	for (i = 0; i <= 10000; i++)
	{
		memset(FileName, 0, 14);		
		
		uitoa(i, buf);
		
		strcat(FileName, "DUMP");
		strcat(FileName, buf);
		strcat(FileName, ".BIN");
		
		if (File_Exists(FileName) == 1)
			break;
	}
	
	if (Create_File(FileName) == 0)
		if (Dump_Memory(FileName) == 0)
		{
			Blit_String(0, 230, "MEMORY DUMP AT:");
			Blit_String(120, 230, FileName);
			Blit_String(232, 230, "HIT A KEY!");
			
			while (Sk == 0)
				ReadKbd(&Ak, &Sk);
		
			Blit_String(0, 230, "                                      ");
		}
}

int Load_Dump(void)
{
	int ret = 0;
	
	if (Param != NULL)
		if (File_Exists(Param) == 0)
			ret = Load_Bin_Data(Param, mem, 0xFFFF);
		
	return ret;
}