#include "libez80p.h"
#include "prose_funcs.h"
#include "tests.h"

void SignOnScreen(void)
{
	int i;
	UINT8 mode, rows, cols;
	
	// First clear the screen and engage 40x30 text mode
	KR_Clear_Screen();
	KR_Set_Video_Mode(TEXT_40x30);
	
	// Call utility functions to print text on screen
	PrintAt(12, 10, "PROSE C Wrapper");
	PrintAt(7, 11, "Test/Demonstration Program");
	PrintAt(13, 28, "Press Any Key!");
	
	KR_Get_Video_Mode(&mode, &cols, &rows);
	if ((mode == TEXT_40x30) && (rows == 30) && (cols == 40))
	{
		PrintAt(7, 15, "Confirmed video mode 40x30");
	}
	else
	{
		PrintAt(7, 15, "Did not detect mode 40x30");
		PrintAt(7, 16, "Mode: $");
		PrintHex2(mode);
		KR_Print_String(" Rows:$");
		PrintHex2(rows);
		KR_Print_String(" Cols:$");
		PrintHex2(cols);
	}
	
	// Wait for key to be pressed
	WaitForKey();
	
	for (i = 0; i < 30; i++)
	{
		KR_Scroll_Up();
		KR_Time_Delay(250);
	}
	
	KR_Set_Video_Mode(TEXT_80x60);
}

void main(void)
{
	// Start with correct OS Setting
	KR_OS_Display();
	
	// Display sign-on screen
	SignOnScreen();
	
	// Run OS Tests (env. variables, version info)
	PerformOSTests();
	
	// Run file/SDMMC card handling tests
	PerformFileTests();
}

