#ifndef PIA6820_C
#define PIA6820_C

static unsigned char _dspCr = 0, _dsp = 0, _kbdCr = 0, _kbd = 0;
static int kbdInterrups = 0, dspOutput = 0;

void Reset_Pia6820(void)
{
	kbdInterrups = dspOutput = 0;
	_kbdCr = _dspCr = 0;
}

void Set_KdbInterrups(int b)
{
	kbdInterrups = b;
}

int Get_KdbInterrups(void)
{
	return kbdInterrups;
}

int Get_DspOutput(void)
{
	return dspOutput;
}

void Write_DspCr(unsigned char DspCr)
{
	if (!dspOutput && DspCr >= 0x80)
		dspOutput = 1;
	else
		_dspCr = DspCr;
}

void Write_Dsp(unsigned char Dsp)
{
	if (Dsp >= 0x80)
		Dsp -= 0x80;
	
	Output_Dsp(Dsp);
	
	_dsp = Dsp;
}

void Write_KbdCr(unsigned char KbdCr)
{
	if (!kbdInterrups && KbdCr >= 0x80)
		kbdInterrups = 1;
	else
		_kbdCr = KbdCr;
}

void Write_Kbd(unsigned char Kbd)
{
	_kbd = Kbd;
}

unsigned char Read_DspCr(void)
{
	return _dspCr;
}

unsigned char Read_Dsp(void)
{
	return _dsp;
}

unsigned char Read_KbdCr(void)
{
	if (kbdInterrups && _kbdCr >= 0x80)
	{
		_kbdCr = 0;
		
		return 0xA7;
	}
	
	return _kbdCr;
}

unsigned char Read_Kbd(void)
{
	return _kbd;
}

#endif
