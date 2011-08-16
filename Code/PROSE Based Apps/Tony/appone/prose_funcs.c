#include "libez80p.h"
#include "prose_funcs.h"

void WaitMillis(int millis)
{
	UINT16 ticks = (millis * 32);
	KR_Time_Delay(ticks);
}

void PrintAt(UINT8 x, UINT8 y, char *msg)
{
	KR_Set_Cursor_Position(x, y);
	KR_Print_String(msg);
}

void WaitForKey(void)
{
	UINT8 ascii, scan;
	
	KR_Wait_Key(&scan, &ascii);
}

void PrintHex2(UINT8 bin)
{
	char buf[3] = '\0\0\0';
	KR_Hex_To_ASCII(bin, buf);
	KR_Print_String(buf);
}

void PrintHex4(UINT16 bin)
{
	UINT8 tmp = (bin >> 8);
	PrintHex2(tmp);
	tmp = (bin & 0xff);
	PrintHex2(tmp);
}

void PrintHex6(UINT24 bin)
{
	UINT8 tmp = (bin >> 16);
	PrintHex2(tmp);
	PrintHex4(bin & 0xffff);
}

void PrintHex8(UINT32 bin)
{
	UINT16 tmp = (bin >> 16);
	PrintHex4(tmp);
	tmp = (bin & 0xffff);
	PrintHex4(tmp);
}