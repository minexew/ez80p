#ifndef SCREEN_C
#define SCREEN_C

#include "Screen.h"

char *MainFile, *MainDest;
unsigned int MainFileSize;

unsigned short Palette[256];

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
	asm ("ld hl, 1024 * 20");
	asm ("ld (ix), hl");
	asm ("ld (ix+04h), 1");
	asm ("ld (ix+08h), 0");
	asm ("ld (ix+0ch), 0");
	asm ("ld (ix+10h), 0 + (320 / 8) - 1");
	
	asm ("ld hl, (_VideoMem)");
	asm ("ld (hl), 0");
	asm ("push hl");
	asm ("pop de");
	asm ("inc de");
	asm ("ld bc, 320*240");
	asm ("dec bc");
	asm ("ldir");
	
	asm ("pop ix");
}

void Load_Raw_Data(const char *FName, const char *Dest, unsigned int Size)
{
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
	
	asm("FileError:");
}

void BlackOut(void)
{
	int i;
	
	for (i = 0; i < 256; i++)
		Palette[i] = RGB2WORD(0, 0, 0);
	
	memcpy(PaletteMem, Palette, sizeof(Palette));
}

static void PutPixel(int x, int y, unsigned char col)
{
	x += (y << 8) + (y << 6);
	
	VideoMem[x] = col;
}

#endif
