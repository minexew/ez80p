#include "libez80p.h"
#include "prose_funcs.h"
#include <defines.h>
#include <string.h>

void TraceClock(PROSE_RTC *pclock)
{
	UINT8 byte;
	
	KR_Print_String("Reading clock: ");
	if (pclock)
	{
		byte = pclock->hr;
		PrintHex2(byte);
		KR_Print_String(":");
		byte = pclock->min;
		PrintHex2(byte);
		KR_Print_String(":");
		byte = pclock->sec;
		PrintHex2(byte);
		KR_Print_String(" ");
		byte = pclock->day;
		PrintHex2(byte);
		KR_Print_String("-");
		byte = pclock->mon;
		PrintHex2(byte);
		KR_Print_String("-");
		byte = pclock->cen;
		PrintHex2(byte);
		byte = pclock->yr;
		PrintHex2(byte);
		KR_Print_String("/ Day: $");
		byte = pclock->dow;
		PrintHex2(byte);
		KR_Print_String("\r\n");
	}
	else
	{
		KR_Print_String("FAILED!\r\n");
	}
}

void PerformOSTests(void)
{
	UINT16 ProseVer, AmoebaVer;
	PROSE_RTC clock, clock2;
	PROSE_RTC *pclock;
	UINT8 x, y;
	void *addr, *addr2;
	UINT8 oldpen;
	char *cbuf;
	BOOL rv;
	void *ram, *vida, *vidb;
	UINT8 byte;
	
	KR_Clear_Screen();
	PrintAt(29, 0, "Operating System Tests");
	PrintAt(29, 1, "======================");
	
	KR_Set_Cursor_Position(0, 3);
	KR_Set_Cursor_Image(0x7f);	// Use block cursor
	KR_Draw_Cursor();
	KR_Remove_Cursor();
	
	// Read memory locations
	KR_Get_OS_High_Mem(&ram, &vida, &vidb);
	KR_Print_String("First free RAM: $");
	PrintHex6((UINT24)ram);
	KR_Print_String("\r\nFirst free VID1: $");
	PrintHex6((UINT24)vida);
	KR_Print_String("\r\nFirst free VID2: $");
	PrintHex6((UINT24)vidb);
	KR_Print_String("\r\n\r\n");
	
	// Read keyboard locations
	ram = KR_Get_Keymap_Location();
	KR_Print_String("Keymap Location: $");
	PrintHex6((UINT24)ram);
	KR_Print_String("\r\n\r\n");
	
	// Read versions
	KR_Get_Version(&ProseVer, &AmoebaVer);
	KR_Print_String("AMOEBA Version: $");
	PrintHex4(ProseVer);
	KR_Print_String("\r\nPROSE Version: $");
	PrintHex4(AmoebaVer);
	
	KR_Print_String("\r\n\r\nTesting Environment Variables...\r\n\r\n");
	
	KR_Set_Envar("_OSTEST", "DiAlToNe");
	if (PROSE_Result)
	{
		KR_Print_String("Failed to store _OSTEST with data DiAlToNe: ");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	else
	{
		KR_Print_String("Stored _OSTEST with data DiAlToNe\r\n");
		cbuf = KR_Get_Envar("_OSTEST");
		if (PROSE_Result)
		{
			KR_Print_String("Failed to retrieve _OSTEST: ");
			PrintHex2(PROSE_Result);
			KR_Print_String("\r\n");
		} 
		else
		{
			KR_Print_String("Retrieved _OSTEST with value: '");
			KR_Print_String(cbuf);
			KR_Print_String("'\r\n");
			
			if (!KR_Compare_Strings("dummy", "DUMMY", 5))
			{
				KR_Print_String("Comparison with dummy string no match\r\n");
			}
			else
			{
				KR_Print_String("Comparison with dummy string matched\r\n");
			}
			
			if (!KR_Compare_Strings(cbuf, "12345678", 8))
			{
				KR_Print_String("Comparison with incorrect string no match\r\n");
			}
			else
			{
				KR_Print_String("Comparison with incorrect string matched\r\n");
			}
			
			if (!KR_Compare_Strings(cbuf, "dialtone", 8))
			{
				KR_Print_String("Comparison with stored data failed\r\n");
			}
			else
			{
				KR_Print_String("Comparison with stored data matched\r\n");
				KR_Delete_Envar("_OSTEST");
				if (PROSE_Result)
				{
					KR_Print_String("Failed to delete _OSTEST: ");
					PrintHex2(PROSE_Result);
					KR_Print_String("\r\n");
				}
				else
				{
					KR_Print_String("Removed _OSTEST successfully\r\n");
				}
			}
		}
	}
	
	KR_Print_String("\r\nReal-Time Clock Tests\r\n\r\n");
	pclock = KR_Read_RTC();
	// Copy read clock (pclock) to spare struct (clock2) for setting back later
	memcpy(&clock2, pclock, sizeof(PROSE_RTC));
	TraceClock(pclock);
	clock.dow = 1;
	clock.cen = 0x20;
	clock.day = 0x01;
	clock.mon = 0x02;
	clock.yr = 0x21;
	clock.hr = 0x12;
	clock.min = 0x34;
	clock.sec = 0x56;
	KR_Print_String("Setting clock to 12:34:56 01-02-2021/ Day: $01\r\n");
	KR_Write_RTC(&clock);
	pclock = KR_Read_RTC();
	TraceClock(pclock);
	KR_Print_String("Restoring clock (you may lose some seconds, sorry!)\r\n");
	KR_Write_RTC(&clock2);
	pclock = KR_Read_RTC();
	TraceClock(pclock);
	
	KR_Print_String("\r\nTesting cursor handling");
	KR_Get_Cursor_Position(&x, &y);
	
	KR_Print_String("\r\n(Last line ended with cursor: x=$");
	PrintHex2(x);
	KR_Print_String(" y=$");
	PrintHex2(y);
	KR_Print_String(")\r\nCharmap Addr 0, 0: $");
	KR_Get_Charmap_Addr_XY(0, 0, (UINT8 *)&addr, (UINT8 *)&addr2);
	PrintHex6((UINT24)addr);
	KR_Print_String(" attrib: $");
	PrintHex6((UINT24)addr2);
	KR_Print_String("\r\n");
	
	oldpen = KR_Get_Pen();
	
	for (y = 0; y < 16; y++)
	{
		for (x = 0; x < 16; x++)
		{
			KR_Set_Pen((y << 4) | x);
			for (byte = 8; byte < 12; byte++)
			{
				KR_Plot_Char(byte + (4 * x), (34 + y), '*');
			}
		}
	}
	
	KR_Set_Pen(oldpen);
	KR_Set_Cursor_Position(0, 52);
	KR_Print_String("\r\n\r\nPress any key to continue...\r\n");
	WaitForKey();
}
