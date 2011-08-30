/*

Chess Figth. A chess game cpu vs human developed by Enzo Antonio Calogiuri for eZ80P fans :-)

*/

#include <Stdlib.h>
#include <String.h>

#include "PROSE_Header.h"

#include "screen.h"
#include "game.h"

typedef struct {
	char *loc;
	int len;
	char *looploc;
	int looplen;
	unsigned short period;
	unsigned char volume;
} SndRec;

static char *TxtPnt;
static SndRec *Snd;

static SndRec Click, Chs1, Chs2;

void WaitKeyPress(void);
unsigned char GetKeyScanCode(void);
unsigned char ReadScancode(void);
void print(const char *txt);
void Disable_Audio(void);
void Play_Raw_Audio(const SndRec *S);

void MyMain(void);
/*------------------------------------------------------------------------------------------------------------------------*/

typedef struct{
	char ri, co;
	char *Img;
} PlSel;

char *mSelect, *mWhite, *mBlack, *mNormal, *mHard, *Think, *wPlay, *bPlay;
char *wSel, *rSel, *bsel, *wPiece, *bPiece;
char *Bianchi[6], *Neri[6];
char mColore = 0, mLivello = 0, chAbort, DeleteBack = 0;
unsigned char gScanCode, BufKey;
char Mossa1[2], Mossa2[2];
PlSel User;
char PlayerColor;


void Load_Components(void);
void Draw_Image(int PosX, int PosY, int W, int H, char *ImgBuf);
void Draw_Trans_Image(int PosX, int PosY, int W, int H, char *ImgBuf, unsigned char Trans);
void Fill_Rectangle(int PosX, int PosY, int W, int H, unsigned char col);
char MainMenu(void);

void Crea_Mossa(void);

void Show_End_Screen(char win);

void Free_All_Mem(void);
/*------------------------------------------------------------------------------------------------------------------------*/

void main(void)
{
	INIT_HARDWARE;
	INIT_KJT;
	
	CREATE_HEADER;
	
	MyMain();	
	
	QUIT_TO_PROSE;
}

#include "Screen.c"
#include "game.c"

void MyMain(void)
{
	char MyMenuValue;
	char app[5], winner;	
	
	Load_Components();
	
	Set_320_240_Mode();
	
	BlackOut();
	
	Load_Raw_Data("logo.raw", VideoMem, 320*240);
	
	Load_Raw_Data("logo.pal", PaletteMem, 512);	
	
	WaitKeyPress();
	
	Play_Raw_Audio(&Click);
	
LabelMainMenu:
	
	MyMenuValue = MainMenu();
	
	if (MyMenuValue == 1)
	{
		DeleteBack = 0;
		livello = mLivello + 1;
		col_prof = bianco;
		PlayerColor = mColore;
		
		User.ri = 6;
		User.co = 0;
		
		BlackOut();
		
		Load_Raw_Data("board.raw", VideoMem, 320*240);
		Load_Raw_Data("board.pal", PaletteMem, 512);
		
		posiniz();		
		apertura();
		apri(col_prof);
		
		if (chAbort)
			goto LabelMainMenu;
		
		nmossa = 4;		
		
		while (1)
		{
			Fill_Rectangle(63, 221, 102, 10, 0);
			
			mossa_giocata = acquisisci();
			
			modifica(mossa_giocata);
			
			if (chAbort)
				goto LabelMainMenu;			
			
			stampap(DeleteBack);
			
			Play_Raw_Audio(&Chs1);
			
			winner = vincitore();
			
			if (winner != 0)
			{
				Show_End_Screen(winner);
				
				goto LabelMainMenu;
			}
			
			nmossa++;
			cambiacolore
			
			if (PlayerColor == 0)
				PlayerColor = 1;
			else
				PlayerColor = 0;
			
			Draw_Image(63, 221, 102, 10, Think);
	
			Fill_Rectangle(218, 75, 96, 10, 0);
	
			if (PlayerColor == 0)
				Draw_Image(245, 75, 42, 10, wPlay);
			else
				Draw_Image(243, 75, 48, 10, bPlay);
			
			inizializza();
			calcolamosse(0);
			modifica(mossa_giocata);
			nmossa++;
			
			cambiacolore
			stampap(DeleteBack);
			
			Play_Raw_Audio(&Chs2);
			
			winner = vincitore();
			
			if (winner != 0)
			{
				Show_End_Screen(winner);
				
				goto LabelMainMenu;
			}
			
			if (PlayerColor == 0)
				PlayerColor = 1;
			else
				PlayerColor = 0;
		}
		
	}
	
	Disable_Audio();
	
	Free_All_Mem();
	
	asm ("push ix");
	asm ("ld a, kr_os_display");
	asm ("call.lil prose_kernal");
	asm ("ld a, kr_clear_screen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	print("Chess Fight ver 1.0b for eZ80P.\n\r");
	print("Programmed by Enzo Antonio Calogiuri.\n\r");
	print("\n\r");
}

void WaitKeyPress(void)
{
	asm ("push ix");
	asm ("ld a, kr_wait_key");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

unsigned char GetKeyScanCode(void)
{
	gScanCode = 0;
	
	asm ("push ix");
	asm ("ld a, kr_wait_key");
	asm ("call.lil prose_kernal");	
	asm ("ld (_gScanCode), a");	
	asm ("pop ix");
	
	return gScanCode;
}

unsigned char ReadScancode(void)
{
	BufKey = 0;
	
	asm ("push ix");
	asm ("ld a, kr_get_key");
	asm ("call.lil prose_kernal");
	asm ("jr nz, NoKeyInB");
	asm ("ld (_BufKey), a");
	asm ("NoKeyInB:");
	asm ("pop ix");
	
	return BufKey;
}

void print(const char *txt)
{
	TxtPnt = txt;
	
	asm ("push ix");
	asm ("ld hl, (_TxtPnt)");
	asm ("ld a, kr_print_string");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
}

void Disable_Audio(void)
{
	asm ("push ix");
	asm ("ld a, kr_disable_audio");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
}

void Play_Raw_Audio(const SndRec *S)
{
	Snd = S;
	
	asm ("push ix");
	asm ("ld hl, (_Snd)");
	asm ("ld c, 11h");
	asm ("ld a, kr_play_audio");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
}
/*------------------------------------------------------------------------------------------------------------------------*/

void Free_All_Mem(void)
{
	int i;
	
	free(mSelect);
	free(mWhite);
	free(mBlack);
	free(mNormal);
	free(mHard);
	free(wSel);
	free(rSel);
	free(bsel);	
	
	for (i = 0; i < 6; i++)
	{
		free(Bianchi[i]);
		free(Neri[i]);
	}
	
	free(wPiece);
	free(bPiece);
	free(Think);
	free(wPlay);
	free(bPlay);	
}

void Load_Components(void)
{
	int i;
	
	print("\n\r Loading data...\n\r");
	
	mSelect = (char *)malloc(16 * 15);	//240
	Load_Raw_Data("msel.raw", mSelect, 16 * 15);
	
	mWhite = (char *)malloc(42 * 10);	//420
	Load_Raw_Data("white.raw", mWhite, 42 * 10);
	
	mBlack = (char *)malloc(48 * 10);	//480
	Load_Raw_Data("black.raw", mBlack, 48 * 10);
	
	mNormal = (char *)malloc(58 * 10);	//580
	Load_Raw_Data("normal.raw", mNormal, 58 * 10);
	
	mHard = (char *)malloc(38 * 10);	//380
	Load_Raw_Data("hard.raw", mHard, 38 * 10);
	
	wSel = (char *)malloc(25 * 25);	//625
	Load_Raw_Data("bsel.raw", wSel, 25 * 25);
	
	rSel = (char *)malloc(25 * 25);	//625
	Load_Raw_Data("rsel.raw", rSel, 25 * 25);
	
	bsel = (char *)malloc(25 * 25);	//625
	
	for (i = 0; i < 6; i++)
	{
		Bianchi[i] = (char *)malloc(22 * 23);
		Neri[i] = (char *)malloc(22 * 23);
	}
	
	Load_Raw_Data("bped.raw", Bianchi[0], 22 * 23);
	Load_Raw_Data("bcav.raw", Bianchi[1], 22 * 23);
	Load_Raw_Data("balf.raw", Bianchi[2], 22 * 23);
	Load_Raw_Data("btor.raw", Bianchi[3], 22 * 23);
	Load_Raw_Data("breg.raw", Bianchi[4], 22 * 23);
	Load_Raw_Data("bre.raw", Bianchi[5], 22 * 23);
	
	Load_Raw_Data("nped.raw", Neri[0], 22 * 23);
	Load_Raw_Data("ncav.raw", Neri[1], 22 * 23);
	Load_Raw_Data("nalf.raw", Neri[2], 22 * 23);
	Load_Raw_Data("ntor.raw", Neri[3], 22 * 23);
	Load_Raw_Data("nreg.raw", Neri[4], 22 * 23);
	Load_Raw_Data("nre.raw", Neri[5], 22 * 23);
	
	wPiece = (char *)malloc(25 * 25);	//625
	Load_Raw_Data("wpiece.raw", wPiece, 25 * 25);
	
	bPiece = (char *)malloc(25 * 25);	//625
	Load_Raw_Data("bpiece.raw", bPiece, 25 * 25);
	
	Think = (char *)malloc(102 * 10);
	Load_Raw_Data("pthink.raw", Think, 102 * 10);
	
	wPlay = (char *)malloc(42 * 10);
	Load_Raw_Data("pwhite.raw", wPlay, 42 * 10);
	
	bPlay = (char *)malloc(48 * 10);
	Load_Raw_Data("pblack.raw", bPlay, 48 * 10);
	
	Load_Raw_Data("click.snd", (char *)0x0C00000, 9220);
	
	Load_Raw_Data("chs1.snd", (char *)(0x0C00000 + (1024 * 15)), 2445);
	
	Load_Raw_Data("chs2.snd", (char *)(0x0C00000 + (1024 * 25)), 3311);
	
	Click.loc = (char *)0x0C00000;
	Click.len = 9220;
	Click.looploc = (char *)0x0C00000;
	Click.looplen = 1;
	Click.period = 0x73A3;
	Click.volume = 84;
	
	Chs1.loc = (char *)(0x0C00000 + (1024 * 15));
	Chs1.len = 2445;
	Chs1.looploc = (char *)(0x0C00000 + (1024 * 15));
	Chs1.looplen = 1;
	Chs1.period = 0x73A3;
	Chs1.volume = 84;
	
	Chs2.loc = (char *)(0x0C00000 + (1024 * 25));
	Chs2.len = 3311;
	Chs2.looploc = (char *)(0x0C00000 + (1024 * 25));
	Chs2.looplen = 1;
	Chs2.period = 0x73A3;
	Chs2.volume = 84;
}

void Draw_Image(int PosX, int PosY, int W, int H, char *ImgBuf)
{
	int x, y;
	
	for (y = PosY; y < PosY + H; y++)
		for (x = PosX; x < PosX + W; x++)
			PutPixel(x, y, *ImgBuf++);
}

void Draw_Trans_Image(int PosX, int PosY, int W, int H, char *ImgBuf, unsigned char Trans)
{
	int x, y;
	
	for (y = PosY; y < PosY + H; y++)
		for (x = PosX; x < PosX + W; x++)
		{
			if (*ImgBuf != Trans)
				PutPixel(x, y, *ImgBuf);
			
			*ImgBuf++;
		}
			
}

void Fill_Rectangle(int PosX, int PosY, int W, int H, unsigned char col)
{
	int x, y;
	
	for (y = PosY; y < PosY + H; y++)
		for (x = PosX; x < PosX + W; x++)
			PutPixel(x, y, col);
}

char MainMenu(void)
{
	char PosSel = 0, OldPosSel = 0;
	unsigned char SKey;	
	
	BlackOut();
	
	Load_Raw_Data("menu.raw", VideoMem, 320 * 240);
	Load_Raw_Data("menu.pal", PaletteMem, 512);
	
	if (mColore == 0)
		Draw_Image(190, 94, 42, 10, mWhite);
	else
		Draw_Image(190, 94, 48, 10, mBlack);
	
	Draw_Image(105, 91, 16, 15, mSelect);
	
	if (mLivello == 0)
		Draw_Image(190, 116, 58, 10, mNormal);
	else
		Draw_Image(190, 116, 38, 10, mHard);
	
	while (1)
	{
		SKey = GetKeyScanCode();
		
		if (SKey == 0x75)
		{
			PosSel -= 1;
			
			if (PosSel < 0)
				PosSel = 3;
		}
		
		if (SKey == 0x72)
		{
			PosSel += 1;
			
			if (PosSel > 3)
				PosSel = 0;
		}
		
		if (PosSel != OldPosSel)
		{
			Play_Raw_Audio(&Click);
			
			Fill_Rectangle(105, 91 + (OldPosSel * 22), 16, 15, 0);
			
			Draw_Image(105, 91 + (PosSel * 22), 16, 15, mSelect);
			
			OldPosSel = PosSel;
		}
		
		if (SKey == 0x29)
		{
			Play_Raw_Audio(&Click);
			
			switch (PosSel)
			{
				case 		0:
					
					if (mColore == 0)
					{
						Fill_Rectangle(190, 94, 42, 10, 0);
			
						Draw_Image(190, 94, 48, 10, mBlack);
						
						mColore = 1;
					}
					else
					{
						Fill_Rectangle(190, 94, 48, 10, 0);
			
						Draw_Image(190, 94, 42, 10, mWhite);
						
						mColore = 0;
					}
					break;
					
				case		1:
					if (mLivello == 0)
					{
						Fill_Rectangle(190, 116, 58, 10, 0);
						
						Draw_Image(190, 116, 38, 10, mHard);
						
						mLivello = 1;
					}
					else
					{
						Fill_Rectangle(190, 116, 38, 10, 0);
						
						Draw_Image(190, 116, 58, 10, mNormal);
						
						mLivello = 0;
					}
					break;
					
				case 		2:
					return 1;
				
				case 		3:
					return 2;
			}
		}
		
	}
	
	return 0;
}

void Save_Back_Selection(int PosX, int PosY, unsigned char Trans)
{
	unsigned char Val = VideoMem[(PosY << 8) + (PosY << 6) + PosX];
	char i, j;
	
	memset(bsel, Val, 25 * 25);
	
	for (j = 1; j < 24; j++)
		for (i = 1; i < 24; i++)
			bsel[(j * 25) + i] = Trans;
}

void Draw_User_Selection(PlSel *uS, char SaveBK)
{
	int PosX, PosY;
	
	PosX = (uS->co * 25) + 11;
	PosY = (uS->ri * 25) + 12;
	
	if (SaveBK)
		Save_Back_Selection(PosX, PosY, 0);
	
	Draw_Trans_Image(PosX, PosY, 25, 25, uS->Img, 0);
}

void Ottiemi_Mossa(PlSel *uS, char *OutBuf)
{
	PlSel Old;
	unsigned char SKey;
	
	OutBuf[0] = 0;
	OutBuf[1] = 0;
	chAbort = 0;
	
	Old.co = uS->co;
	Old.ri = uS->ri;
	Old.Img = bsel;
	
	Draw_User_Selection(uS, 1);
	
	while (1)
	{
		SKey = GetKeyScanCode();
		
		if (SKey == 0x6B)
		{
			uS->co--;
			
			if (uS->co < 0)
				uS->co = 0;
		}
		
		if (SKey == 0x74)
		{
			uS->co++;
			
			if (uS->co > 7)
				uS->co = 7;
		}
		
		if (SKey == 0x75)
		{
			uS->ri--;
			
			if (uS->ri < 0)
				uS->ri = 0;
		}
		
		if (SKey == 0x72)
		{
			uS->ri++;
			
			if (uS->ri > 7)
				uS->ri = 7;
		}
		
		if (SKey == 0x07)
		{
			chAbort = 1;
			
			Draw_User_Selection(&Old, 0);
			
			return;
		}
		
		if (SKey == 0x29)
		{
			Draw_User_Selection(&Old, 0);
			
			OutBuf[0] = 'a' + uS->co;
			OutBuf[1] = '8' - uS->ri;
			
			return;
		}			
		
		if ((Old.co != uS->co) || (Old.ri != uS->ri))
		{
			Draw_User_Selection(&Old, 0);
			
			Draw_User_Selection(uS, 1);
			
			Old.co = uS->co;
			Old.ri = uS->ri;
		}		
	}
}

void Crea_Mossa(void)
{
	User.Img = wSel;
	
	Ottiemi_Mossa(&User, Mossa1);
	
	if (!chAbort)
	{
		User.Img = rSel;
		
		Ottiemi_Mossa(&User, Mossa2);
	}
}

void Show_End_Screen(char win)
{
	unsigned int i, co, ri, x, y;	
	
	co = ((mossa_giocata / 10) % 10);
	ri = mossa_giocata % 10;
	
	x = PosScac[co][ri].X;
	y = PosScac[co][ri].Y;
	
	Draw_Trans_Image(x, y, 25, 25, rSel, 0);
	
	for (i = 0; i < 1500000; i++);	
	
	for (i = 0; i < 70; i++)
		ReadScancode();	
	
	BlackOut();
	
	switch (win)
	{
		case	1:
			
			Load_Raw_Data("win.raw", VideoMem, 320 * 240);
			Load_Raw_Data("win.pal", PaletteMem, 512);
			break;
			
		case	2:
			
			Load_Raw_Data("lose.raw", VideoMem, 320 * 240);
			Load_Raw_Data("lose.pal", PaletteMem, 512);
			break;
	}
	
	WaitKeyPress();
	
	Play_Raw_Audio(&Click);
}