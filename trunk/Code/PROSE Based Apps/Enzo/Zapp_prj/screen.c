#ifndef SCREEN_C
#define SCREEN_C

#define RGB2WORD(r,g,b)         ((unsigned short) ((r/16<<8)+(g/16<<4)+(b/16)))
#define VMEMOFFSET				(1024 * 20)

#define NROW					24
#define NCOL					40

char *VideoMem = (char *)(0x0800000 + VMEMOFFSET);
char *VideoMemScroll = (char *)((0x0800000 + VMEMOFFSET) + (320 * 8));
char *PaletteMem = (char *)0x0ff0000;
static unsigned char screenTbl[NCOL * NROW];
static unsigned char oldscreenTbl[NCOL * NROW];
static int indexX, indexY, terminalSpeed = 60;
static int oldindexX, oldindexY;
static int YOffset[240];
unsigned char *Characters = NULL;
static long lastTime;

unsigned short Palette[256];

extern int Mem_Mode(void);
/*-------------------------------------------------------------------------------------*/

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

int LoadCharMap(void)
{
	Characters = (unsigned char *)malloc(1024);
	
	return (Load_Bin_Data("CHARMAP.ROM", Characters, 1024));
}

void Blit_Char(int xc, int yc, unsigned char c)
{
	unsigned char *work_char;
	unsigned char bit_mask;	
	int offset = YOffset[yc] + xc;
	int x, y;
	
	work_char = Characters + (c << 3);
	
	for (y = 0; y < 8; y++)
	{
		bit_mask = 0x80;
		
		for (x = 8; x > 0; x--)
		{
			if (*work_char & bit_mask)
				VideoMem[offset + x] = 255;
			else
				VideoMem[offset + x] = 0;
			
			bit_mask >>= 1;
		}
		
		offset += 320;
		work_char++;
	}
}

void Blit_String(int x, int y, char *str)
{
	int index;
	
	for(index = 0; index < strlen(str); index++)
		Blit_Char((x + (index << 3)), y,  str[index]);
}

void Show_Mode(void)
{
	Blit_String(80, 219, "          ");
	
	if (Mem_Mode() == 8)	
		Blit_String(80, 219, "MODE: 8KB");
	else
		Blit_String(80, 219, "MODE: 64KB");
	
	Blit_String(168, 219, "F3:CHANGE MODE");
}

void Set_Screen(void)
{
	int i;
	
	for (i = 0; i < 240; i++)
		YOffset[i] = i * 320;
	
	Set_320_240_Mode();
	
	memset(Palette, 0, sizeof(Palette));
	
	Palette[0] = RGB2WORD(0, 0, 0);
	Palette[255] = RGB2WORD(0, 255, 0);
	
	memcpy(PaletteMem, Palette, sizeof(Palette));
	
	for (i = 0; i < 320; i++)
		VideoMem[YOffset[200] + i] = 255;
	
	Blit_String(0, 210, "F12:EXIT  F10:RESET  F9:HARD  F8:BASIC");
	Blit_String(0, 219, "F5:DUMP");
	
	Show_Mode();
}

void Close_Screen(void)
{
	asm ("push ix");
	asm ("ld a, kr_os_display");
	asm ("call.lil prose_kernal");
	
	asm ("ld a, kr_clear_screen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

void Update_Screen(void)
{
	int i, j, ofs;
	unsigned char c, oc;
	
	Blit_Char(oldindexX * 7, oldindexY * 8, ' ');
	
	for (i = 0; i < NCOL; i++)
		for (j = 0; j < NROW; j++)
		{
			ofs = j * NCOL + i;
			
			c = screenTbl[ofs];
			oc = oldscreenTbl[ofs];
			
			if (c != oc)			
			{
				Blit_Char(i * 7, j * 8, c);
				
				oldscreenTbl[ofs] = screenTbl[ofs];
			}
		}
	
	Blit_Char(indexX * 7, indexY * 8, 0x40);
		
	oldindexX = indexX;
	oldindexY = indexY;	
}

void Reset_Screen(void)
{
	indexX = indexY = 0;
	oldindexX = oldindexY = 0;
	
	memset(screenTbl, 0, NROW * NCOL);
	memset(oldscreenTbl, 0, NROW * NCOL);
	
	Update_Screen();
}

void New_Line(void)
{
	int i;
	
	for (i = 0; i < (NROW - 1); i++)
	{
		memcpy(&screenTbl[i * NCOL], &screenTbl[(i + 1) * NCOL], NCOL);
		memcpy(&oldscreenTbl[i * NCOL], &oldscreenTbl[(i + 1) * NCOL], NCOL);
	}		
	
	memset(&screenTbl[NCOL * (NROW - 1)], 0, NCOL);
	memset(&oldscreenTbl[NCOL * (NROW - 1)], 0, NCOL);
	
	Blit_Char(oldindexX * 7, oldindexY * 8, ' ');
	
	memcpy(VideoMem, VideoMemScroll, (320 * 184));	
	
	memset(VideoMem + (320 * 184), 0, 320 * 8);
}

void Output_Dsp(unsigned char Dsp)
{
	switch (Dsp)
	{
		case 0x0D:
			indexX = 0;
			indexY++;
			break;
		
		default:
			if (Dsp > 0x1F && Dsp < 0x60)
			{
				screenTbl[indexY * NCOL + indexX] = Dsp;
				indexX++;
			}
			break;
	}
	
	if (indexX == NCOL)
	{
		indexX = 0;
		indexY++;
	}
	
	if (indexY == NROW)
	{
		New_Line();
		
		indexY--;
	}
	
	Update_Screen();
}

#endif
