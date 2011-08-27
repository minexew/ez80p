#ifndef SCREEN_H
#define SCREEN_H

#define RGB2WORD(r,g,b)         ((unsigned short) ((r/16<<8)+(g/16<<4)+(b/16)))

#define VMEMOFFSET				(1024 * 20)

char *VideoMem = (char *)(0x0800000 + VMEMOFFSET);
char *PaletteMem = (char *)0x0ff0000;

void Set_320_240_Mode(void);
void Load_Raw_Data(const char *FName, const char *Dest, unsigned int Size);

void BlackOut(void);

static void PutPixel(int x, int y, unsigned char col);

#endif
