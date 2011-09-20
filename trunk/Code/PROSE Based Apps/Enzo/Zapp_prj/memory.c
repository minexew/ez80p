#ifndef MEMORY_C
#define MEMORY_C

#define MEMMAX					0xFFFF

unsigned char *mem = NULL;
static int mode = 8;
static int writeInRom = 1;

void Flip_Mode(void)
{
	if (mode == 8)
		mode = 32;
	else
		mode = 8;
}

int Mem_Mode(void)
{
	return mode;
}

int Load_Monitor(void)
{
	mem = (unsigned char *)malloc(MEMMAX + 1);
	
	return (Load_Bin_Data("MONITOR.ROM", &mem[0xFF00], 256));
}

void Reset_Memory(void)
{
	if (mode > 8)
		memset(mem, 0, 0xE000);
	else
		memset(mem, 0, 0x10000 - 256);
}

unsigned char Mem_Read(unsigned short address)
{
	if (address == 0xD013)
		return Read_DspCr();
	
	if (address == 0xD012)
		return Read_Dsp();
	
	if (address == 0xD011)
		return Read_KbdCr();
	
	if (address == 0xD010)
		return Read_Kbd();
	
	return mem[address];
}

void Mem_Write(unsigned short address, unsigned char value)
{
	if (address == 0xD013)
	{
		Write_DspCr(value);
		
		return;
	}
	
	if (address == 0xD012)
	{
		Write_Dsp(value);
		
		return;
	}
	
	if (address == 0xD011)
	{
		Write_KbdCr(value);
		
		return;
	}
	
	if (address == 0xD010)
	{
		Write_Kbd(value);
		
		return;
	}
	
	if (address >= 0xFF00 && !writeInRom)
		return;
	
	if (mode == 8 && address >= 0x2000 && address < 0xFF00)
		return;
	
	mem[address] = value;
}

#endif
