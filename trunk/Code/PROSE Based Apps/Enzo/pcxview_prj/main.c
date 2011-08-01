/*
	PCXVIEW: simple pcx viewer for PROSE
	
	coded by Calogiuri Enzo Antonio for PROSE community.	
*/

#include <String.h>

#include "PROSE_Header.h"

#define RGB2WORD(r,g,b)         ((unsigned short) ((r/16<<8)+(g/16<<4)+(b/16)))

static char *UseTxt = "USE: PCXVIEW [filename]\n\r";
static char *FileOpenError = "File not found!\n\r";
static char *NonPcxFile = "Invalid PCX file!\n\r";
static char *PcxSize = "Graphics Resolution: ";

static char *TxtPnt;
static char Header[128];
char *PntHeader = Header;
char *VideoMem = (char *)0x0800000;
char *VideoMemTmp = (char *)0x0C00000;
char convBuf[4];
short MinX, MinY, MaxX, MaxY;
short XSize, YSize, StartX, StartY;
short VideoX, VideoY, PosX, PosY;
unsigned short PcxPalette[256];
unsigned char TmpPal[256*3];
unsigned char *PntPal = TmpPal;
unsigned int YOffset[480];

void ShowMsg(const char *Txt);
void Make_Short(unsigned char a, unsigned char b, short *Val);
void uitoa(unsigned int val, char *string);

void BuildOffset(void);

void LoadPcxPalette(void);
void LoadPcxFile(void);
void DecodePcxFile(void);

void PutPcxPixel(unsigned char Px);

void Set_320_240_Mode(void);
void Set_640_480_Mode(void);

void main(void)
{
	INIT_HARDWARE;
	INIT_KJT;
	
	CREATE_HEADER;
	
	asm ("ld a, (hl)");				//Test command line
	asm ("or a");
	asm ("jr z, no_param");
	
	asm ("ld (_K_xHL), hl");		//Save pointer to commandline in global pseudoregister
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("jr nz, FileError");
	
	asm ("ld de, 128");				//If kr_find_file = OK then load a pcx header (128 bytes length)
	asm ("ld a, kr_set_load_length");
	asm ("call.lil prose_kernal");
	
	asm ("ld hl, (_PntHeader)");
	asm ("ld a, kr_read_file");
	asm ("call.lil prose_kernal");
	
	if (Header[0] != 10)		//If the first byte of header is not 10 then error
	{
		ShowMsg(NonPcxFile);
		
		asm ("xor a");
		asm ("jp quitnow");
	}
	
	Make_Short(Header[4], Header[5], &MinX);	//Build the limits of image
	Make_Short(Header[6], Header[7], &MinY);
	Make_Short(Header[8], Header[9], &MaxX);
	Make_Short(Header[10], Header[11], &MaxY);
	
	XSize = MaxX - MinX + 1;					//Dimensions of image
	YSize = MaxY - MinY + 1;
	
	if (XSize > 1)								//If image is valid
	{
		uitoa(XSize, convBuf);
		
		ShowMsg(PcxSize);
		ShowMsg(convBuf);
		ShowMsg("x");
		
		uitoa(YSize, convBuf);
		ShowMsg(convBuf);
		ShowMsg("\n\r");						//Show on screen image dimensions
		
		if (XSize > 640)
		{
			ShowMsg("Image too big!\n\r");
			asm ("xor a");
			asm ("jp quitnow");
		}
		
		if (YSize > 480)
		{
			ShowMsg("Image too big!\n\r");
			asm ("xor a");
			asm ("jp quitnow");
		}		
			
		if ((XSize <= 320) && (YSize <= 240))
		{
			VideoX = 320;
			VideoY = 240;
		}
		else
		{
			VideoX = 640;
			VideoY = 480;
		}
		
		BuildOffset();						//Precalculation Y Offset table
		
		if (XSize < VideoX)					//Center the image?
			StartX = (VideoX - XSize) / 2;
		else
			StartX = 0;
		
		if (YSize < VideoY)
			StartY = (VideoY - YSize) / 2;
		else
			StartY = 0;		
		
		PosX = 0;
		PosY = 0;
		
		ShowMsg("Press a key...\n\r");
		asm ("ld a, kr_wait_key");
		asm ("call.lil prose_kernal");
		
		LoadPcxPalette();
		LoadPcxFile();
		
		if ((VideoX == 320) && (VideoY == 240))		//Choose right video mode
			Set_320_240_Mode();
		else
			Set_640_480_Mode();		
		
		memcpy((void *)0x0ff0000, PcxPalette, sizeof(PcxPalette));	//Copy local palette to sistem's palette
		
		DecodePcxFile();
		
		asm ("ld a, kr_wait_key");
		asm ("call.lil prose_kernal");
	}
	else
	{
		ShowMsg("Invalid image dimensions!\n\r");
		
		asm ("xor a");
		asm ("jp quitnow");
	}
	
	asm ("jp endprogram");
	
	asm ("no_param:");
	ShowMsg(UseTxt);
	asm ("xor a");
	asm ("jp quitnow");
	
	asm ("FileError:");
	ShowMsg(FileOpenError);
	asm ("xor a");
	asm ("jp quitnow");
	
	asm ("endprogram:");	
	asm ("ld a, kr_os_display");
	asm ("call.lil prose_kernal");
	asm ("ld a, kr_clear_screen");
	asm ("call.lil prose_kernal");	
	
	if ((VideoX == 320) && (VideoY == 240))		
		asm ("xor a");
	else
		asm ("ld a, 0ffh");
	
	asm ("quitnow:");	
	asm ("jp.lil prose_return");
}

//Join to bytes and make a 16 bit value
void Make_Short(unsigned char a, unsigned char b, short *Val)
{
	*Val = (a + (b << 8));
}

//convert an integer in ascii string
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

//Show a text :-)
void ShowMsg(const char *Txt)
{
	TxtPnt = Txt;
	
	asm ("push ix");
	asm ("ld hl, (_TxtPnt)");
	asm ("ld a, kr_print_string");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
}

//Load a 768 bytes palette, then convert it in a palette useful for eZ80P
void LoadPcxPalette(void)
{
	short i, a;
	
	ShowMsg("Loading Palette...\n\r");
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, PaletteError");
	asm ("ld (_K_xDE), de");
	
	K_xDE -= 768;
	
	asm ("push ix");
	asm ("ld de, (_K_xDE)");	
	asm ("ld a, kr_set_file_pointer");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	asm ("push ix");
	asm ("ld de, 768");
	asm ("ld a, kr_set_load_length");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	asm ("push ix");
	asm ("ld hl, (_PntPal)");
	asm ("ld a, kr_read_file");
	asm ("call.lil prose_kernal");
	asm ("jr nz, PaletteError");
	asm ("pop ix");
	
	a = 0;
	for (i = 0; i < 256; i++)
	{
		PcxPalette[i] = RGB2WORD(TmpPal[a], TmpPal[a + 1], TmpPal[a + 2]);
		
		a+=3;
	}
	
	asm ("jp EndPalette");
	
	asm("PaletteError:");
	ShowMsg("Palette Reading error\n\r");
	
	asm ("EndPalette:");
}

//Load the Pcx compress data in second video page mem
void LoadPcxFile(void)
{
	ShowMsg("Loading Pcx Data...\n\r");
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, LoadPcxError");
	asm ("ld (_K_xDE), de");
	
	asm ("push ix");
	asm ("ld de, 128");
	asm ("ld a, kr_set_file_pointer");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	K_xDE = K_xDE - (128 + 768);
	
	asm ("push ix");
	asm ("ld de, (_K_xDE)");
	asm ("ld a, kr_set_load_length");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	asm ("push ix");
	asm ("ld hl, (_VideoMemTmp)");
	asm ("ld a, kr_read_file");
	asm ("call.lil prose_kernal");
	asm ("jr nz, LoadPcxError");
	asm ("pop ix");
	
	asm ("jp EndLoadPcx");
	
	asm("LoadPcxError:");
	ShowMsg("PCX Reading error\n\r");
	
	asm ("EndLoadPcx:");
}

//Enable 320x240x256 colors
void Set_320_240_Mode(void)
{
	asm ("push ix");
	
	asm ("ld a, 0110b");
	asm ("ld (video_control), a");
	asm ("ld a, 0");
	asm ("ld (bgnd_palette_select), a");
	asm ("ld a, 99");
	asm ("ld (right_border_position), a");
	asm ("ld ix, bitmap_parameters");
	asm ("ld (ix), 0");
	asm ("ld (ix+04h), 1");
	asm ("ld (ix+08h), 0");
	asm ("ld (ix+0ch), 0");
	asm ("ld (ix+10h), 0 + (320 / 8) - 1");
	
	asm ("ld hl, vram_a_addr");
	asm ("ld (hl), 0");
	asm ("push hl");
	asm ("pop de");
	asm ("inc de");
	asm ("ld bc, 320*240");
	asm ("dec bc");
	asm ("ldir");
	
	asm ("pop ix");
}

//Enable 640x480x256 colors
void Set_640_480_Mode(void)
{
	asm ("push ix");
	
	asm ("ld a, 0000b");
	asm ("ld (video_control), a");
	asm ("ld a, 0");
	asm ("ld (bgnd_palette_select), a");
	asm ("ld a, 99");
	asm ("ld (right_border_position), a");
	asm ("ld ix, bitmap_parameters");	
	asm ("ld (ix), 0");
	asm ("ld (ix+04h), 1");
	asm ("ld (ix+08h), 0");
	asm ("ld (ix+0ch), 0");
	asm ("ld (ix+10h), 0 + (640 / 8) - 1");
	
	asm ("ld hl, vram_a_addr");
	asm ("ld (hl), 0");
	asm ("push hl");
	asm ("pop de");
	asm ("inc de");
	asm ("ld bc, 640*480");
	asm ("dec bc");
	asm ("ldir");
	
	asm ("pop ix");
}

//Expand compress Pcx data into raw image
void DecodePcxFile(void)
{
	unsigned int NumData, fsize, tmp;
	register unsigned char Data;
	
	fsize = 0;
	tmp = (unsigned int)XSize * (unsigned int)YSize;
	
	while (fsize <= tmp)
	{
		Data = *VideoMemTmp++;
		
		if (Data < 192)
		{
			PutPcxPixel(Data);
			
			fsize++;
			
			continue;
		}
		
		NumData = Data & 0x3F;
		fsize += NumData;
		Data = *VideoMemTmp++;
		
		while(NumData-- > 0)
			PutPcxPixel(Data);
	}
}

//Put image pixel on screen
void PutPcxPixel(unsigned char Px)
{
	VideoMem[YOffset[PosY + StartY] + (PosX + StartX)] = Px;
	
	PosX++;
	
	if (PosX >= XSize)
	{
		PosX = 0;
		PosY++;
	}
}

void BuildOffset(void)
{
	short i;
	
	for (i = 0; i < VideoY; i++)
		YOffset[i] = (unsigned int)i * (unsigned int)VideoX;
}