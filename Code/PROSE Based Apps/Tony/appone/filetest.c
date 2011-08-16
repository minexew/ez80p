#include "libez80p.h"
#include "prose_funcs.h"
#include <defines.h>
#include <string.h>
#include <Stdlib.h>

UINT8 sourceBuf[1024];
UINT8 destBuf[1024];

void PrintCurrentDir(void)
{
	char *pbuf;

	pbuf = KR_Get_Dir_Name();
	if (!PROSE_Result)
	{
		KR_Print_String("Current Directory: ");
		KR_Print_String(pbuf);
		KR_Print_String("\r\n");
	}
	else
	{
		KR_Print_String("Current directory could not be retrieved\r\n");
	}
}

void TestDirectoryHandling(void)
{
	PROSE_FILE_INFO finfo;
	
	// Print current directory
	PrintCurrentDir();
	
	// Change to root
	KR_Root_Dir();
	if (!PROSE_Result)
	{
		KR_Print_String("Changed to Root Dir\r\n");
	}
	else
	{
		KR_Print_String("Failed to change to root dir: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	// Make a new directory
	KR_Make_Dir("QZWXECRV");
	if (!PROSE_Result)
	{
		KR_Print_String("Created directory 'QZWXECRV'\r\n");
	}
	else
	{
		KR_Print_String("Failed to create dir 'QZWXECRV': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Change to new directory
	KR_Change_Dir("QZWXECRV");
	if (!PROSE_Result)
	{
		KR_Print_String("Changed to dir 'QZWXECRV'\r\n");
		PrintCurrentDir();
	}
	else
	{
		KR_Print_String("Failed to change to dir 'QZWXECRV': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Change back to parent
	KR_Parent_Dir();
	if (!PROSE_Result)
	{
		KR_Print_String("Changed to parent directory\r\n");
		PrintCurrentDir();
	}
	else
	{
		KR_Print_String("Failed to change to parent directory: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Remove dir we just created
	KR_Delete_Dir("QZWXECRV");
	if (!PROSE_Result)
	{
		KR_Print_String("Deleted directory 'QZWXECRV'\r\n");
	}
	else
	{
		KR_Print_String("Failed to delete dir 'QZWXECRV': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Print out a directory listing
	KR_Dir_List_First_Entry(&finfo);
	// Technically this isn't required - just
	// included here in order to test the function call!
	KR_Dir_List_Get_Entry(&finfo);
	
	KR_Print_String("\r\n");
	if (!PROSE_Result)
	{
		do
		{
			if (finfo.FileType == TYPE_DIR)
			{
				KR_Print_String(" [DIR ] ");
			}
			else
			{
				KR_Print_String("$");
				PrintHex8(finfo.FileLength);
				KR_Print_String(" ");
			}
			KR_Print_String(finfo.FileName);
			KR_Print_String("\r\n");
			KR_Dir_List_Next_Entry(&finfo);
		} 
		while (!PROSE_Result);
	}
	else
	{
		KR_Print_String("Failed to get first directory entry: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	KR_Print_String("\r\n");
}

void TestFileHandling(void)
{
	int i, j;
	UINT24 start;
	UINT32 length;
	
	// Populate source buffer with random
	for (i = 0; i < 1024; i++)
	{
		sourceBuf[i] = (rand() & 0xff);
	}
	
	KR_Create_File("RVTBYNUM.BIN");
	if (!PROSE_Result)
	{
		KR_Print_String("Created test file 'RVTBYNUM.BIN'\r\n");
	}
	else
	{
		KR_Print_String("Failed to create test file 'RVTBYNUM.BIN': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Write 1024 bytes to the file
	KR_Write_File("RVTBYNUM.BIN", sourceBuf, 1024);
	if (!PROSE_Result)
	{
		KR_Print_String("Wrote 1k bytes to test file 'RVTBYNUM.BIN'\r\n");
	}
	else
	{
		KR_Print_String("Failed to write 1k bytes to test file 'RVTBYNUM.BIN': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
	
	// Read back 1024 bytes from file
	KR_Find_File("RVTBYNUM.BIN", &start, &length);
	if (!PROSE_Result)
	{
		KR_Print_String("Opened test file 'RVTBYNUM.BIN'\r\n");
		KR_Print_String("Start cluster: $");
		PrintHex6(start);
		KR_Print_String(" Length: $");
		PrintHex8(length);
		KR_Print_String("\r\n");
	}
	else
	{
		KR_Print_String("Failed to open test file 'RVTBYNUM.BIN': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	KR_Set_Load_Length(512);
	if (!PROSE_Result)
	{
		KR_Print_String("Set load length to 512\r\n");
	}
	else
	{
		KR_Print_String("Failed to set load length to 512: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	KR_Set_File_Pointer(512);
	if (!PROSE_Result)
	{
		KR_Print_String("Set file pointer to 512\r\n");
	}
	else
	{
		KR_Print_String("Failed to set file pointer to 512: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	KR_Read_File(&destBuf[512]);
	if (!PROSE_Result)
	{
		KR_Print_String("Read 512 bytes from file\r\n");
	}
	else
	{
		KR_Print_String("Failed to read 512 bytes from file: $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	KR_Print_String("Comparing written contents with readback...\r\n");
	j = 512;
	for (i = 512; i < 1024; i++)
	{
		if (sourceBuf[i] == destBuf[i])
		{
			j++;
		}
		else
		{
			break;
		}
	}
	if (j == 1024)
	{
		KR_Print_String("Readback was good\r\n");
	}
	else
	{
		KR_Print_String("Readback failed at: $");
		PrintHex4((UINT16)j);
		KR_Print_String("\r\n");
	}
	
	KR_Rename_File("RVTBYNUM.BIN", "CRVTBYNU.BIN");
	if (!PROSE_Result)
	{
		KR_Print_String("Renamed 'RVTBYNUM.BIN' to 'CRVTBYNU.BIN'\r\n");
	}
	else
	{
		KR_Print_String("Failed to Rename 'RVTBYNUM.BIN' to 'CRVTBYNU.BIN': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}

	KR_Erase_File("CRVTBYNU.BIN");
	if (!PROSE_Result)
	{
		KR_Print_String("Erased 'CRVTBYNU.BIN'\r\n");
	}
	else
	{
		KR_Print_String("Failed to erase 'CRVTBYNU.BIN': $");
		PrintHex2(PROSE_Result);
		KR_Print_String("\r\n");
	}
}

void PerformFileTests(void)
{
	UINT24 counter;
	char buffer[200];
	
	KR_Clear_Screen();
	PrintAt(32, 0, "File/SDMMC Tests");
	PrintAt(32, 1, "================");
	KR_Set_Cursor_Position(0, 3);

	KR_Check_Volume_Format();
	KR_Print_String("Check Volume Format: $");
	PrintHex2(PROSE_Result);
	KR_Print_String("\r\n");
	
	counter = KR_Get_Total_Sectors();
	KR_Print_String("Total Sectors: $");
	PrintHex6(counter);
	KR_Print_String(" (Error code: $");
	PrintHex2(PROSE_Result);
	KR_Print_String(")\r\n");
	
	TestDirectoryHandling();
	TestFileHandling();
	
	KR_Set_Cursor_Position(0, 52);
	KR_Print_String("\r\n\r\nPress any key to continue...\r\n");
	WaitForKey();
}
