#ifndef M6502_C
#define M6502_C

#define N 0x80
#define V 0x40
#define M 0x20
#define B 0x10
#define D 0x08
#define I 0x04
#define Z 0x02
#define C 0x01

static unsigned char accumulator, xRegister, yRegister, statusRegister = 0x24, stackPointer;
static int IRQ = 0, NMI = 0;
int programCounter;
static unsigned char btmp;
int op, opH, opL, ptr, ptrH, ptrL, tmp;
//static long lastTime = 0;
//static int //cycles = 0, //cyclesBeforeSynchro, _synchroMillis;

static void (*Cpu_Opcode[0xFF + 1])(void) = {NULL};

/*-------------------------------------------------------------------------------------*/

static unsigned short Mem_Read_Absolute(int adr)
{
	return (Mem_Read(adr) | Mem_Read(adr + 1) << 8);
}

/*static void Synchronize(void)
{
	long currentTime = Read_MSec_Counter();
	int realTimeMillis = (int)(currentTime - lastTime);
	int sleepMillis = _synchroMillis - realTimeMillis;
	
	if (sleepMillis < 0)
		sleepMillis = 5;
	
	mDelay(sleepMillis);
	
	lastTime = currentTime;
}*/

static void pushProgramCounter(void)
{
	Mem_Write((unsigned short)(stackPointer + 0x100), (unsigned char)(programCounter >> 8));	
	Mem_Write((unsigned short)(stackPointer + 0xFF), (unsigned char)programCounter);	
	
	stackPointer -= 2;
	
	//cycles += 2;
}

static void popProgramCounter(void)
{
	stackPointer++;
	
	programCounter = Mem_Read((unsigned short)(stackPointer + 0x100));
	
	stackPointer++;
	
	programCounter += Mem_Read((unsigned short)(stackPointer + 0x100)) << 8;
	
	//cycles += 2;
}

static void handleIRQ(void)
{
	pushProgramCounter();
	
	Mem_Write((unsigned short)(0x100 + stackPointer), (unsigned char)(statusRegister & ~0x10));
	
	stackPointer--;
	
	statusRegister |= I;
	
	programCounter = Mem_Read_Absolute(0xFFFE);
	
	//cycles += 8;
}

static void handleNMI(void)
{
	pushProgramCounter();
	
	Mem_Write((unsigned short)(0x100 + stackPointer), (unsigned char)(statusRegister & ~0x10));
	
	stackPointer--;
	
	statusRegister |= I;
	
	NMI = 0;
	
	programCounter = Mem_Read_Absolute(0xFFFA);
	
	//cycles += 8;
}

static void Imm(void)
{
	op = programCounter++;
}

static void Zero(void)
{
	op = Mem_Read(programCounter++);
	
	//cycles++;
}

static void ZeroX(void)
{
	op = (Mem_Read(programCounter++) + xRegister) & 0xFF;
	
	//cycles++;
}

static void ZeroY(void)
{
	op = (Mem_Read(programCounter++) + yRegister) & 0xFF;
	
	//cycles++;
}

static void Abs(void)
{
	op = Mem_Read_Absolute(programCounter);
	
	programCounter += 2;
	//cycles += 2;
}

static void AbsX(void)
{
	opL = Mem_Read(programCounter++) + xRegister;
	opH = Mem_Read(programCounter++) << 8;
	
	//cycles += 2;
	
	//if (opL >= 0x100)
		//cycles++;
	
	op = opH + opL;
}

static void AbsY(void)
{
	opL = Mem_Read(programCounter++) + yRegister;
	opH = Mem_Read(programCounter++) << 8;
	
	//cycles += 2;
	
	//if (opL >= 0x100)
		//cycles++;
	
	op = opH + opL;
}

static void Ind(void)
{
	ptrL = Mem_Read(programCounter++); 
	ptrH = Mem_Read(programCounter++) << 8;
	op = Mem_Read((unsigned short)(ptrH + ptrL));
	
	ptrL = (ptrL + 1) & 0xFF;
	
	op += Mem_Read((unsigned short)(ptrH + ptrL)) << 8;
	
	//cycles += 4;
}

static void IndZeroX(void)
{
	ptr = xRegister + Mem_Read(programCounter++);
	
	op = Mem_Read(ptr);	
	
	op += Mem_Read((unsigned short)((ptr + 1) & 0xFF)) << 8;
	
	//cycles += 3;
}

static void IndZeroY(void)
{
	ptr = Mem_Read(programCounter++);
	opL = Mem_Read(ptr) + yRegister;
	opH = Mem_Read((unsigned short)(ptr + 1)) << 8;
	
	//cycles += 3;
	
	//if (opL >= 0x100)
		//cycles++;
	
	op = opH + opL;
}

static void Rel(void)
{
	op = Mem_Read(programCounter++);
	
	if (op >= 0x80)
		op |= 0xFF00;
	
	op += programCounter;
	//cycles++;
}

static void WAbsX(void)
{
	opL = Mem_Read(programCounter++) + xRegister;
	opH = Mem_Read(programCounter++) << 8;
	
	//cycles += 3;
	op = opH + opL;
}

static void WAbsY(void)
{
	opL = Mem_Read(programCounter++) + yRegister;
	opH = Mem_Read(programCounter++) << 8;
	
	//cycles += 3;
	op = opH + opL;
}

static void WIndZeroY(void)
{
	ptr = Mem_Read(programCounter++);
	opL = Mem_Read(ptr) + yRegister;
	opH = Mem_Read((unsigned short)((ptr + 1) & 0xFF)) << 8;
	
	//cycles += 4;
	op = opH + opL;
}

static void setStatusRegisterNZ(unsigned char val)
{
	if (val & 0x80)
		statusRegister |= N;
	else
		statusRegister &= ~N;
	
	if (!val)
		statusRegister |= Z;
	else
		statusRegister &= ~Z;
}

static void LDA(void)
{
	accumulator = Mem_Read(op);
	
	setStatusRegisterNZ(accumulator);
	
	//cycles++;
}

static void LDX(void)
{
	xRegister = Mem_Read(op);
	
	setStatusRegisterNZ(xRegister);
	
	//cycles++;
}

static void LDY(void)
{
	yRegister = Mem_Read(op);
	
	setStatusRegisterNZ(yRegister);
	
	//cycles++;
}

static void STA(void)
{
	Mem_Write(op, accumulator);
	
	//cycles++;
}

static void STX(void)
{
	Mem_Write(op, xRegister);
	
	//cycles++;
}

static void STY(void)
{
	Mem_Write(op, yRegister);
	
	//cycles++;
}

static void setFlagCarry(int val)
{
	if (val & 0x100)
		statusRegister |= C;
	else
		statusRegister &= ~C;
}

static void ADC(void)
{
	int Op1 = accumulator, Op2 = Mem_Read(op);
	char srtmp = (statusRegister & C ? 1 : 0);
	
	//cycles++;
	
	if (statusRegister & D)
	{
		if (!((Op1 + Op2 + srtmp) & 0xFF))
			statusRegister |= Z;
		else
			statusRegister &= ~Z;
		
		tmp = (Op1 & 0x0F) + (Op2 & 0x0F) + srtmp;
		accumulator = tmp < 0x0A ? tmp : tmp + 6;
		tmp = (Op1 & 0xF0) + (Op2 & 0xF0) + (tmp & 0xF0);
		
		if (tmp & 0x80)
			statusRegister |= N;
		else
			statusRegister &= ~N;
		
		if ((Op1 ^ tmp) & ~(Op1 ^ Op2) & 0x80)
			statusRegister |= V;
		else
			statusRegister &= ~V;
		
		tmp = (accumulator & 0x0F) | (tmp < 0xA0 ? tmp : tmp + 0x60);
		
		if (tmp >= 0x100)
			statusRegister |= C;
		else
			statusRegister &= ~C;
		
		accumulator = tmp & 0xFF;
	}
	else
	{
		tmp = Op1 + Op2 + srtmp;
		accumulator = tmp & 0xFF;
		
		if ((Op1 ^ accumulator) & ~(Op1 ^ Op2) & 0x80)
			statusRegister |= V;
		else
			statusRegister &= ~V;
		
		setFlagCarry(tmp);
		
		setStatusRegisterNZ(accumulator);
	}
}

static void setFlagBorrow(int val)
{
	if (!(val & 0x100))
		statusRegister |= C;
	else
		statusRegister &= ~C;
}

static void SBC(void)
{
	int Op1 = accumulator, Op2 = Mem_Read(op);
	char srtmp = (statusRegister & C ? 0 : 1);
	
	//cycles++;
	
	if (statusRegister & D)
	{
		tmp = (Op1 & 0x0F) - (Op2 & 0x0F) - srtmp;
		accumulator = !(tmp & 0x10) ? tmp : tmp - 6;
		tmp = (Op1 & 0xF0) - (Op2 & 0xF0) - (accumulator & 0x10);
		accumulator = (accumulator & 0x0F) | (!(tmp & 0x100) ? tmp : tmp - 0x60);
		tmp = Op1 - Op2 - srtmp;
		
		setFlagBorrow(tmp);
		
		setStatusRegisterNZ((unsigned char)tmp);
	}
	else
	{
		tmp = Op1 - Op2 - srtmp;
		accumulator = tmp & 0xFF;
		
		if ((Op1 ^ Op2) & (Op1 ^ accumulator) & 0x80)
			statusRegister |= V;
		else
			statusRegister &= ~V;
		
		setFlagBorrow(tmp);
		
		setStatusRegisterNZ(accumulator);
	}
}

static void CMP(void)
{
	tmp = accumulator - Mem_Read(op);
	
	//cycles++;
	
	setFlagBorrow(tmp);
	
	setStatusRegisterNZ((unsigned char)tmp);
}

static void CPX(void)
{
	tmp = xRegister - Mem_Read(op);
	
	//cycles++;
	
	setFlagBorrow(tmp);
	
	setStatusRegisterNZ((unsigned char)tmp);
}

static void CPY(void)
{
	tmp = yRegister - Mem_Read(op);
	
	//cycles++;
	
	setFlagBorrow(tmp);
	
	setStatusRegisterNZ((unsigned char)tmp);
}

static void AND(void)
{
	accumulator &= Mem_Read(op);
	
	//cycles++;
	
	setStatusRegisterNZ(accumulator);
}

static void ORA(void)
{
	accumulator |= Mem_Read(op);
	
	//cycles++;
	
	setStatusRegisterNZ(accumulator);
}

static void EOR(void)
{
	accumulator ^= Mem_Read(op);
	
	//cycles++;
	
	setStatusRegisterNZ(accumulator);
}

static void ASL(void)
{
	btmp = Mem_Read(op);
	
	if (btmp & 0x80)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	btmp <<= 1;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 3;
}

static void ASL_A(void)
{
	tmp = accumulator << 1;
	accumulator = tmp & 0xFF;
	
	setFlagCarry(tmp);
	
	setStatusRegisterNZ(accumulator);
}

static void LSR(void)
{
	btmp = Mem_Read(op);
	
	if (btmp & 1)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	btmp >>= 1;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 3;
}

static void LSR_A(void)
{
	if (accumulator & 1)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	accumulator >>= 1;
	
	setStatusRegisterNZ(accumulator);
}

static void ROL(void)
{
	int newCarry;
	
	btmp = Mem_Read(op);
	newCarry = btmp & 0x80;
	btmp = (btmp << 1) | (statusRegister & C ? 1 : 0);
	
	if (newCarry)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 3;
}

static void ROL_A(void)
{
	tmp = (accumulator << 1) | (statusRegister & C ? 1 : 0);
	accumulator = tmp & 0xFF;
	
	setFlagCarry(tmp);
	
	setStatusRegisterNZ(accumulator);
}

static void ROR(void)
{
	int newCarry;
	
	btmp = Mem_Read(op);
	newCarry = btmp & 1;
	btmp = (btmp >> 1) | (statusRegister & C ? 0x80 : 0);
	
	if (newCarry)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 3;
}

static void ROR_A(void)
{
	tmp = accumulator | (statusRegister & C ? 0x100 : 0);
	
	if (accumulator & 1)
		statusRegister |= C;
	else
		statusRegister &= ~C;
	
	accumulator = tmp >> 1;
	
	setStatusRegisterNZ(accumulator);
}

static void INC(void)
{
	btmp = Mem_Read(op);
	btmp++;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 2;
}

static void DEC(void)
{
	btmp = Mem_Read(op);
	btmp--;
	
	setStatusRegisterNZ(btmp);
	
	Mem_Write(op, btmp);
	
	//cycles += 2;
}

static void INX(void)
{
	xRegister++;
	
	setStatusRegisterNZ(xRegister);
}

static void INY(void)
{
	yRegister++;
	
	setStatusRegisterNZ(yRegister);
}

static void DEX(void)
{
	xRegister--;
	
	setStatusRegisterNZ(xRegister);
}

static void DEY(void)
{
	yRegister--;
	
	setStatusRegisterNZ(yRegister);
}

static void BIT(void)
{
	btmp = Mem_Read(op);
	
	if (btmp & 0x40)
		statusRegister |= V;
	else
		statusRegister &= ~V;
	
	if (btmp & 0x80)
		statusRegister |= N;
	else
		statusRegister &= ~N;
	
	if (!(btmp & accumulator))
		statusRegister |= Z;
	else
		statusRegister &= ~Z;
	
	//cycles++;
}

static void PHA(void)
{
	Mem_Write((unsigned short)(0x100 + stackPointer), accumulator);
	
	stackPointer--;
	
	//cycles++;
}

static void PHP(void)
{
	Mem_Write((unsigned short)(0x100 + stackPointer), statusRegister);
	
	stackPointer--;
	
	//cycles++;
}

static void PLA(void)
{
	stackPointer++;
	
	accumulator = Mem_Read((unsigned short)(stackPointer + 0x100));
	
	setStatusRegisterNZ(accumulator);
	
	//cycles += 2;
}

static void PLP(void)
{
	stackPointer++;
	
	statusRegister = Mem_Read((unsigned short)(stackPointer + 0x100));
	
	//cycles += 2;
}

static void BRK(void)
{
	pushProgramCounter();
	
	PHP();
	
	statusRegister |= B;
	
	programCounter = Mem_Read_Absolute(0xFFFE);
	
	//cycles += 3;
}

static void RTI(void)
{
	PLP();
	
	popProgramCounter();
	
	//cycles++;
}

static void JMP(void)
{
	programCounter = op;
}

static void RTS(void)
{
	popProgramCounter();
	
	programCounter++;
	
	//cycles += 2;
}

static void JSR(void)
{
	opL = Mem_Read(programCounter++);
	
	pushProgramCounter();
	
	programCounter = opL + (Mem_Read(programCounter) << 8);
	
	//cycles += 3;
}

static void branch(void)
{
	//cycles++;
	
	/*if ((programCounter & 0xFF00) != (op & 0xFF00))
		//cycles++;*/
	
	programCounter = op;
}

static void BNE(void)
{
	if (!(statusRegister & Z))
		branch();
}

static void BEQ(void)
{
	if (statusRegister & Z)
		branch();
}

static void BVC(void)
{
	if (!(statusRegister & V))
		branch();
}

static void BVS(void)
{
	if (statusRegister & V)
		branch();
}

static void BCC(void)
{
	if (!(statusRegister & C))
		branch();
}

static void BCS(void)
{
	if (statusRegister & C)
		branch();
}

static void BPL(void)
{
	if (!(statusRegister & N))
		branch();
}

static void BMI(void)
{
	if (statusRegister & N)
		branch();
}

static void TAX(void)
{
	xRegister = accumulator;
	
	setStatusRegisterNZ(accumulator);
}

static void TXA(void)
{
	accumulator = xRegister;
	
	setStatusRegisterNZ(accumulator);
}

static void TAY(void)
{
	yRegister = accumulator;
	
	setStatusRegisterNZ(accumulator);
}

static void TYA(void)
{
	accumulator = yRegister;
	
	setStatusRegisterNZ(accumulator);
}

static void TXS(void)
{
	stackPointer = xRegister;
}

static void TSX(void)
{
	xRegister = stackPointer;
	
	setStatusRegisterNZ(xRegister);
}

static void CLC(void)
{
	statusRegister &= ~C;
}

static void SEC(void)
{
	statusRegister |= C;
}

static void CLI(void)
{
	statusRegister &= ~I;
}

static void SEI(void)
{
	statusRegister |= I;
}

static void CLV(void)
{
	statusRegister &= ~V;
}

static void CLD(void)
{
	statusRegister &= ~D;
}

static void SED(void)
{
	statusRegister |= D;
}

/*-------------------------------------------------------------------------*/
void Opcode_0x00(void)
{
	Imm();
	BRK();
}

void Opcode_0x01(void)
{
	IndZeroX();
	ORA();
}

void Multi_UnDoc1(void)
{
	programCounter--;
}

void Multi_UnDoc2(void)
{
	programCounter++;
}

void Multi_UnDoc3(void)
{
	programCounter += 2;
}

void Opcode_0x05(void)
{
	Zero();
	ORA();
}

void Opcode_0x06(void)
{
	Zero();
	ASL();
}

void Opcode_0x09(void)
{
	Imm();
	ORA();
}

void Opcode_0x0B(void)
{
	Imm();
	AND();
}

void Opcode_0x0D(void)
{
	Abs();
	ORA();
}

void Opcode_0x0E(void)
{
	Abs();
	ASL();
}

void Opcode_0x10(void)
{
	Rel();
	BPL();
}

void Opcode_0x11(void)
{
	IndZeroY();
	ORA();
}

void Opcode_0x15(void)
{
	ZeroX();
	ORA();
}

void Opcode_0x16(void)
{
	ZeroX();
	ASL();
}

void Opcode_0x19(void)
{
	AbsY();
	ORA();
}

void Opcode_0x1D(void)
{
	AbsX();
	ORA();
}

void Opcode_0x1E(void)
{
	WAbsX();
	ASL();
}

void Opcode_0x21(void)
{
	IndZeroX();
	AND();
}

void Opcode_0x24(void)
{
	Zero();
	BIT();
}

void Opcode_0x25(void)
{
	Zero();
	AND();
}

void Opcode_0x26(void)
{
	Zero();
	ROL();
}

void Opcode_0x29(void)
{
	Imm();
	AND();
}

void Opcode_0x2C(void)
{
	Abs();
	BIT();
}

void Opcode_0x2D(void)
{
	Abs();
	AND();
}

void Opcode_0x2E(void)
{
	Abs();
	ROL();
}

void Opcode_0x30(void)
{
	Rel();
	BMI();
}

void Opcode_0x31(void)
{
	IndZeroY();
	AND();
}

void Opcode_0x35(void)
{
	ZeroX();
	AND();
}

void Opcode_0x36(void)
{
	ZeroX();
	ROL();
}

void Opcode_0x39(void)
{
	AbsY();
	AND();
}

void Opcode_0x3D(void)
{
	AbsX();
	AND();
}

void Opcode_0x3E(void)
{
	WAbsX();
	ROL();
}

void Opcode_0x3F(void)
{	
}

void Opcode_0x41(void)
{
	IndZeroX();
	EOR();
}

void Opcode_0x45(void)
{
	Zero();
	EOR();
}

void Opcode_0x46(void)
{
	Zero();
	LSR();
}

void Opcode_0x49(void)
{
	Imm();
	EOR();
}

void Opcode_0x4C(void)
{
	Abs();
	JMP();
}

void Opcode_0x4D(void)
{
	Abs();
	EOR();
}

void Opcode_0x4E(void)
{
	Abs();
	LSR();
}

void Opcode_0x50(void)
{
	Rel();
	BVC();
}

void Opcode_0x51(void)
{
	IndZeroY();
	EOR();
}

void Opcode_0x55(void)
{
	ZeroX();
	EOR();
}

void Opcode_0x56(void)
{
	ZeroX();
	LSR();
}

void Opcode_0x59(void)
{
	AbsY();
	EOR();
}

void Opcode_0x5D(void)
{
	AbsX();
	EOR();
}

void Opcode_0x5E(void)
{
	WAbsX();
	LSR();
}

void Opcode_0x61(void)
{
	IndZeroX();
	ADC();
}

void Opcode_0x65(void)
{
	Zero();
	ADC();
}

void Opcode_0x66(void)
{
	Zero();
	ROR();
}

void Opcode_0x69(void)
{
	Imm();
	ADC();
}

void Opcode_0x6C(void)
{
	Ind();
	JMP();
}

void Opcode_0x6D(void)
{
	Abs();
	ADC();
}

void Opcode_0x6E(void)
{
	Abs();
	ROR();
}

void Opcode_0x70(void)
{
	Rel();
	BVS();
}

void Opcode_0x71(void)
{
	IndZeroY();
	ADC();
}

void Opcode_0x75(void)
{
	ZeroX();
	ADC();
}

void Opcode_0x76(void)
{
	ZeroX();
	ROR();
}

void Opcode_0x79(void)
{
	AbsY();
	ADC();
}

void Opcode_0x7D(void)
{
	AbsX();
	ADC();
}

void Opcode_0x7E(void)
{
	WAbsX();
	ROR();
}

void Opcode_0x81(void)
{
	IndZeroX();
	STA();
}

void Opcode_0x84(void)
{
	Zero();
	STY();
}

void Opcode_0x85(void)
{
	Zero();
	STA();
}

void Opcode_0x86(void)
{
	Zero();
	STX();
}

void Opcode_0x8C(void)
{
	Abs();
	STY();
}

void Opcode_0x8D(void)
{
	Abs();
	STA();
}

void Opcode_0x8E(void)
{
	Abs();
	STX();
}

void Opcode_0x90(void)
{
	Rel();
	BCC();
}

void Opcode_0x91(void)
{
	WIndZeroY();
	STA();
}

void Opcode_0x94(void)
{
	ZeroX();
	STY();
}

void Opcode_0x95(void)
{
	ZeroX();
	STA();
}

void Opcode_0x96(void)
{
	ZeroY();
	STX();
}

void Opcode_0x99(void)
{
	WAbsY();
	STA();
}

void Opcode_0x9D(void)
{
	WAbsX();
	STA();
}

void Opcode_0xA0(void)
{
	Imm();
	LDY();
}

void Opcode_0xA1(void)
{
	IndZeroX();
	LDA();
}

void Opcode_0xA2(void)
{
	Imm();
	LDX();
}

void Opcode_0xA4(void)
{
	Zero();
	LDY();
}

void Opcode_0xA5(void)
{
	Zero();
	LDA();
}

void Opcode_0xA6(void)
{
	Zero();
	LDX();
}

void Opcode_0xA9(void)
{
	Imm();
	LDA();
}

void Opcode_0xAC(void)
{
	Abs();
	LDY();
}

void Opcode_0xAD(void)
{
	Abs();
	LDA();
}

void Opcode_0xAE(void)
{
	Abs();
	LDX();
}

void Opcode_0xB0(void)
{
	Rel();
	BCS();
}

void Opcode_0xB1(void)
{
	IndZeroY();
	LDA();
}

void Opcode_0xB4(void)
{
	ZeroX();
	LDY();
}

void Opcode_0xB5(void)
{
	ZeroX();
	LDA();
}

void Opcode_0xB6(void)
{
	ZeroY();
	LDX();
}

void Opcode_0xB9(void)
{
	AbsY();
	LDA();
}

void Opcode_0xBC(void)
{
	AbsX();
	LDY();
}

void Opcode_0xBD(void)
{
	AbsX();
	LDA();
}

void Opcode_0xBE(void)
{
	AbsY();
	LDX();
}

void Opcode_0xC0(void)
{
	Imm();
	CPY();
}

void Opcode_0xC1(void)
{
	IndZeroX();
	CMP();
}

void Opcode_0xC4(void)
{
	Zero();
	CPY();
}

void Opcode_0xC5(void)
{
	Zero();
	CMP();
}

void Opcode_0xC6(void)
{
	Zero();
	DEC();
}

void Opcode_0xC9(void)
{
	Imm();
	CMP();
}

void Opcode_0xCC(void)
{
	Abs();
	CPY();
}

void Opcode_0xCD(void)
{
	Abs();
	CMP();
}

void Opcode_0xCE(void)
{
	Abs();
	DEC();
}

void Opcode_0xD0(void)
{
	Rel();
	BNE();
}

void Opcode_0xD1(void)
{
	IndZeroY();
	CMP();
}

void Opcode_0xD5(void)
{
	ZeroX();
	CMP();
}

void Opcode_0xD6(void)
{
	ZeroX();
	DEC();
}

void Opcode_0xD9(void)
{
	AbsY();
	CMP();
}

void Opcode_0xDD(void)
{
	AbsX();
	CMP();
}

void Opcode_0xDE(void)
{
	WAbsX();
	DEC();
}

void Opcode_0xE0(void)
{
	Imm();
	CPX();
}

void Opcode_0xE1(void)
{
	IndZeroX();
	SBC();
}

void Opcode_0xE4(void)
{
	Zero();
	CPX();
}

void Opcode_0xE5(void)
{
	Zero();
	SBC();
}

void Opcode_0xE6(void)
{
	Zero();
	INC();
}

void Opcode_0xE9(void)
{
	Imm();
	SBC();
}

void Opcode_0xEB(void)
{
	Imm();
	SBC();
}

void Opcode_0xEC(void)
{
	Abs();
	CPX();
}

void Opcode_0xED(void)
{
	Abs();
	SBC();
}

void Opcode_0xEE(void)
{
	Abs();
	INC();
}

void Opcode_0xF0(void)
{
	Rel();
	BEQ();
}

void Opcode_0xF1(void)
{
	IndZeroY();
	SBC();
}

void Opcode_0xF5(void)
{
	ZeroX();
	SBC();
}

void Opcode_0xF6(void)
{
	ZeroX();
	INC();
}

void Opcode_0xF9(void)
{
	AbsY();
	SBC();
}

void Opcode_0xFD(void)
{
	AbsX();
	SBC();
}

void Opcode_0xFE(void)
{
	WAbsX();
	INC();
}

void Init_Opcode_Table(void)
{
	Cpu_Opcode[0x00] = &Opcode_0x00;
	Cpu_Opcode[0x01] = &Opcode_0x01;
	
	Cpu_Opcode[0x02] = &Multi_UnDoc1;
	Cpu_Opcode[0x12] = &Multi_UnDoc1;
	Cpu_Opcode[0x22] = &Multi_UnDoc1;
	Cpu_Opcode[0x32] = &Multi_UnDoc1;
	Cpu_Opcode[0x42] = &Multi_UnDoc1;
	Cpu_Opcode[0x52] = &Multi_UnDoc1;
	Cpu_Opcode[0x62] = &Multi_UnDoc1;
	Cpu_Opcode[0x72] = &Multi_UnDoc1;
	Cpu_Opcode[0x92] = &Multi_UnDoc1;
	Cpu_Opcode[0xB2] = &Multi_UnDoc1;
	Cpu_Opcode[0xD2] = &Multi_UnDoc1;
	Cpu_Opcode[0xF2] = &Multi_UnDoc1;
	
	Cpu_Opcode[0x04] = &Multi_UnDoc2;
	Cpu_Opcode[0x14] = &Multi_UnDoc2;
	Cpu_Opcode[0x34] = &Multi_UnDoc2;
	Cpu_Opcode[0x44] = &Multi_UnDoc2;
	Cpu_Opcode[0x54] = &Multi_UnDoc2;
	Cpu_Opcode[0x64] = &Multi_UnDoc2;
	Cpu_Opcode[0x74] = &Multi_UnDoc2;
	Cpu_Opcode[0x80] = &Multi_UnDoc2;
	Cpu_Opcode[0x82] = &Multi_UnDoc2;
	Cpu_Opcode[0x89] = &Multi_UnDoc2;
	Cpu_Opcode[0xC2] = &Multi_UnDoc2;
	Cpu_Opcode[0xD4] = &Multi_UnDoc2;
	Cpu_Opcode[0xE2] = &Multi_UnDoc2;
	Cpu_Opcode[0xF4] = &Multi_UnDoc2;
	
	Cpu_Opcode[0x05] = &Opcode_0x05;
	Cpu_Opcode[0x06] = &Opcode_0x06;
	Cpu_Opcode[0x08] = &PHP;
	Cpu_Opcode[0x09] = &Opcode_0x09;
	Cpu_Opcode[0x0A] = &ASL_A;
	Cpu_Opcode[0x0B] = &Opcode_0x0B;
	
	Cpu_Opcode[0x0C] = &Multi_UnDoc3;
	Cpu_Opcode[0x1C] = &Multi_UnDoc3;
	Cpu_Opcode[0x3C] = &Multi_UnDoc3;
	Cpu_Opcode[0x5C] = &Multi_UnDoc3;
	Cpu_Opcode[0x7C] = &Multi_UnDoc3;
	Cpu_Opcode[0xDC] = &Multi_UnDoc3;
	Cpu_Opcode[0xFC] = &Multi_UnDoc3;
	
	Cpu_Opcode[0x0D] = &Opcode_0x0D;
	Cpu_Opcode[0x0E] = &Opcode_0x0E;
	Cpu_Opcode[0x10] = &Opcode_0x10;
	Cpu_Opcode[0x11] = &Opcode_0x11;
	Cpu_Opcode[0x15] = &Opcode_0x15;
	Cpu_Opcode[0x16] = &Opcode_0x16;
	Cpu_Opcode[0x18] = &CLC;
	Cpu_Opcode[0x19] = &Opcode_0x19;
	Cpu_Opcode[0x1D] = &Opcode_0x1D;
	Cpu_Opcode[0x1E] = &Opcode_0x1E;
	Cpu_Opcode[0x20] = &JSR;
	Cpu_Opcode[0x21] = &Opcode_0x21;
	Cpu_Opcode[0x24] = &Opcode_0x24;
	Cpu_Opcode[0x25] = &Opcode_0x25;
	Cpu_Opcode[0x26] = &Opcode_0x26;
	Cpu_Opcode[0x28] = &PLP;
	Cpu_Opcode[0x29] = &Opcode_0x29;
	Cpu_Opcode[0x2A] = &ROL_A;
	Cpu_Opcode[0x2B] = &Opcode_0x29;
	Cpu_Opcode[0x2C] = &Opcode_0x2C;
	Cpu_Opcode[0x2D] = &Opcode_0x2D;
	Cpu_Opcode[0x2E] = &Opcode_0x2E;
	Cpu_Opcode[0x30] = &Opcode_0x30;
	Cpu_Opcode[0x31] = &Opcode_0x31;
	Cpu_Opcode[0x35] = &Opcode_0x35;
	Cpu_Opcode[0x36] = &Opcode_0x36;
	Cpu_Opcode[0x38] = &SEC;
	Cpu_Opcode[0x39] = &Opcode_0x39;
	Cpu_Opcode[0x3D] = &Opcode_0x3D;
	Cpu_Opcode[0x3E] = &Opcode_0x3E;
	Cpu_Opcode[0x3F] = &Opcode_0x3F;
	Cpu_Opcode[0x40] = &RTI;
	Cpu_Opcode[0x41] = &Opcode_0x41;
	Cpu_Opcode[0x45] = &Opcode_0x45;
	Cpu_Opcode[0x46] = &Opcode_0x46;
	Cpu_Opcode[0x48] = &PHA;
	Cpu_Opcode[0x49] = &Opcode_0x49;
	Cpu_Opcode[0x4A] = &LSR_A;
	Cpu_Opcode[0x4C] = &Opcode_0x4C;
	Cpu_Opcode[0x4D] = &Opcode_0x4D;
	Cpu_Opcode[0x4E] = &Opcode_0x4E;
	Cpu_Opcode[0x50] = &Opcode_0x50;
	Cpu_Opcode[0x51] = &Opcode_0x51;
	Cpu_Opcode[0x55] = &Opcode_0x55;
	Cpu_Opcode[0x56] = &Opcode_0x56;
	Cpu_Opcode[0x58] = &CLI;
	Cpu_Opcode[0x59] = &Opcode_0x59;
	Cpu_Opcode[0x5D] = &Opcode_0x5D;
	Cpu_Opcode[0x5E] = &Opcode_0x5E;
	Cpu_Opcode[0x60] = &RTS;
	Cpu_Opcode[0x61] = &Opcode_0x61;
	Cpu_Opcode[0x65] = &Opcode_0x65;
	Cpu_Opcode[0x66] = &Opcode_0x66;
	Cpu_Opcode[0x68] = &PLA;
	Cpu_Opcode[0x69] = &Opcode_0x69;
	Cpu_Opcode[0x6A] = &ROR_A;
	Cpu_Opcode[0x6C] = &Opcode_0x6C;
	Cpu_Opcode[0x6D] = &Opcode_0x6D;
	Cpu_Opcode[0x6E] = &Opcode_0x6E;
	Cpu_Opcode[0x70] = &Opcode_0x70;
	Cpu_Opcode[0x71] = &Opcode_0x71;
	Cpu_Opcode[0x75] = &Opcode_0x75;
	Cpu_Opcode[0x76] = &Opcode_0x76;
	Cpu_Opcode[0x78] = &SEI;
	Cpu_Opcode[0x79] = &Opcode_0x79;
	Cpu_Opcode[0x7D] = &Opcode_0x7D;
	Cpu_Opcode[0x7E] = &Opcode_0x7E;
	Cpu_Opcode[0x81] = &Opcode_0x81;
	Cpu_Opcode[0x84] = &Opcode_0x84;
	Cpu_Opcode[0x85] = &Opcode_0x85;
	Cpu_Opcode[0x86] = &Opcode_0x86;
	Cpu_Opcode[0x88] = &DEY;
	Cpu_Opcode[0x8A] = &TXA;
	Cpu_Opcode[0x8C] = &Opcode_0x8C;
	Cpu_Opcode[0x8D] = &Opcode_0x8D;
	Cpu_Opcode[0x8E] = &Opcode_0x8E;
	Cpu_Opcode[0x90] = &Opcode_0x90;
	Cpu_Opcode[0x91] = &Opcode_0x91;
	Cpu_Opcode[0x94] = &Opcode_0x94;
	Cpu_Opcode[0x95] = &Opcode_0x95;
	Cpu_Opcode[0x96] = &Opcode_0x96;
	Cpu_Opcode[0x98] = &TYA;
	Cpu_Opcode[0x99] = &Opcode_0x99;
	Cpu_Opcode[0x9A] = &TXS;
	Cpu_Opcode[0x9D] = &Opcode_0x9D;
	Cpu_Opcode[0xA0] = &Opcode_0xA0;
	Cpu_Opcode[0xA1] = &Opcode_0xA1;
	Cpu_Opcode[0xA2] = &Opcode_0xA2;
	Cpu_Opcode[0xA4] = &Opcode_0xA4;
	Cpu_Opcode[0xA5] = &Opcode_0xA5;
	Cpu_Opcode[0xA6] = &Opcode_0xA6;
	Cpu_Opcode[0xA8] = &TAY;
	Cpu_Opcode[0xA9] = &Opcode_0xA9;
	Cpu_Opcode[0xAA] = &TAX;
	Cpu_Opcode[0xAC] = &Opcode_0xAC;
	Cpu_Opcode[0xAD] = &Opcode_0xAD;
	Cpu_Opcode[0xAE] = &Opcode_0xAE;
	Cpu_Opcode[0xB0] = &Opcode_0xB0;
	Cpu_Opcode[0xB1] = &Opcode_0xB1;
	Cpu_Opcode[0xB4] = &Opcode_0xB4;
	Cpu_Opcode[0xB5] = &Opcode_0xB5;
	Cpu_Opcode[0xB6] = &Opcode_0xB6;
	Cpu_Opcode[0xB8] = &CLV;
	Cpu_Opcode[0xB9] = &Opcode_0xB9;
	Cpu_Opcode[0xBA] = &TSX;
	Cpu_Opcode[0xBC] = &Opcode_0xBC;
	Cpu_Opcode[0xBD] = &Opcode_0xBD;
	Cpu_Opcode[0xBE] = &Opcode_0xBE;
	Cpu_Opcode[0xC0] = &Opcode_0xC0;
	Cpu_Opcode[0xC1] = &Opcode_0xC1;
	Cpu_Opcode[0xC4] = &Opcode_0xC4;
	Cpu_Opcode[0xC5] = &Opcode_0xC5;
	Cpu_Opcode[0xC6] = &Opcode_0xC6;
	Cpu_Opcode[0xC8] = &INY;
	Cpu_Opcode[0xC9] = &Opcode_0xC9;
	Cpu_Opcode[0xCA] = &DEX;
	Cpu_Opcode[0xCC] = &Opcode_0xCC;
	Cpu_Opcode[0xCD] = &Opcode_0xCD;
	Cpu_Opcode[0xCE] = &Opcode_0xCE;
	Cpu_Opcode[0xD0] = &Opcode_0xD0;
	Cpu_Opcode[0xD1] = &Opcode_0xD1;
	Cpu_Opcode[0xD5] = &Opcode_0xD5;
	Cpu_Opcode[0xD6] = &Opcode_0xD6;
	Cpu_Opcode[0xD8] = &CLD;
	Cpu_Opcode[0xD9] = &Opcode_0xD9;
	Cpu_Opcode[0xDD] = &Opcode_0xDD;
	Cpu_Opcode[0xDE] = &Opcode_0xDE;
	Cpu_Opcode[0xE0] = &Opcode_0xE0;
	Cpu_Opcode[0xE1] = &Opcode_0xE1;
	Cpu_Opcode[0xE4] = &Opcode_0xE4;
	Cpu_Opcode[0xE5] = &Opcode_0xE5;
	Cpu_Opcode[0xE6] = &Opcode_0xE6;
	Cpu_Opcode[0xE8] = &INX;
	Cpu_Opcode[0xE9] = &Opcode_0xE9;
	Cpu_Opcode[0xEA] = &Opcode_0x3F;
	Cpu_Opcode[0xEB] = &Opcode_0xEB;
	Cpu_Opcode[0xEC] = &Opcode_0xEC;
	Cpu_Opcode[0xED] = &Opcode_0xED;
	Cpu_Opcode[0xEE] = &Opcode_0xEE;
	Cpu_Opcode[0xF0] = &Opcode_0xF0;
	Cpu_Opcode[0xF1] = &Opcode_0xF1;
	Cpu_Opcode[0xF5] = &Opcode_0xF5;
	Cpu_Opcode[0xF6] = &Opcode_0xF6;
	Cpu_Opcode[0xF8] = &SED;
	Cpu_Opcode[0xF9] = &Opcode_0xF9;
	Cpu_Opcode[0xFD] = &Opcode_0xFD;
	Cpu_Opcode[0xFE] = &Opcode_0xFE;
}
/*-------------------------------------------------------------------------*/

static void Execute_Opcode(void)
{
	unsigned char opcode = Mem_Read(programCounter++);
	
	if (Cpu_Opcode[opcode] != NULL)
		Cpu_Opcode[opcode]();
}

static void Run_M6502(void)
{
	if (!(statusRegister & I) && IRQ)
		handleIRQ();
	
	if (NMI)
		handleNMI();
	
	Execute_Opcode();
}

void Reset_M6502(void)
{
	statusRegister |= I;
	stackPointer = 0xFF;
	programCounter = Mem_Read_Absolute(0xFFFC);
}

/*void Set_Speed(int freq, int synchroMillis)
{
	//cyclesBeforeSynchro = synchroMillis * freq;
	_synchroMillis = synchroMillis;
}*/

void Set_IRQ(int state)
{
	IRQ = state;
}

void setNMI(void)
{
	NMI = 1;
}

#endif
