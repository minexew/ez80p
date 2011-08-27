#include <stdio.h>
#include <stdlib.h>

#define RGB2WORD(r,g,b)         ((unsigned short int) ((r/16<<8)+(g/16<<4)+(b/16)))

static char Header[128];
short int XSize, YSize;
unsigned short int PcxPalette[256];
unsigned char *Buffer = NULL;

void Make_Short(unsigned char a, unsigned char b, short int *Val)
{
 	 *Val = (a + (b << 8));
}

void Load_Header(char *FName)
{
 	 FILE *f;
 	 short int MinX, MinY, MaxX, MaxY;
 	 
 	 f = fopen(FName, "rb");
 	 
 	 if (f != NULL)
 	 {
	  	  fread(&Header, 128, 1, f);
			
		  Make_Short(Header[4], Header[5], &MinX);	//Build the limits of image
		  Make_Short(Header[6], Header[7], &MinY);
		  Make_Short(Header[8], Header[9], &MaxX);
		  Make_Short(Header[10], Header[11], &MaxY);
		  
		  XSize = MaxX - MinX + 1;
		  YSize = MaxY - MinY + 1;
		  
		  printf("Image size = %dx%d\n", XSize, YSize);
		  
		  fclose(f);
	 }
	 else
	 {
	 	 printf("Error read file\n\r");
	 	 
	 	 exit(0);
	 }
}

void Load_PcxPalette(char *FName)
{
 	 FILE *f;
 	 int Ind;
 	 unsigned char r, g, b;
 	 
 	 f = fopen(FName, "rb");
 	 
 	 if (f != NULL)
 	 {
	  	   fseek(f , -768L, SEEK_END);
	  	   
	  	   for(Ind = 0; Ind < 256; Ind++)
	  	   {
  		   		   r = getc(f);
  		   		   g = getc(f);
  		   		   b = getc(f);
  		   		   
  		   		   PcxPalette[Ind] = RGB2WORD(r, g, b);
  		   }
  		   
  		   fclose(f);
  	 }
}

void Load_PcxImage(char *FName)
{
 	 FILE *f;
 	 long Num_Byte;
 	 unsigned char Data;
 	 unsigned int Num_Data;
 	 
 	 f = fopen(FName, "rb");
 	 
 	 if (f != NULL)
 	 {
	  	   for(Num_Byte = 0; Num_Byte < 128; Num_Byte++)
				   getc(f);
				   
           Buffer = (unsigned char *)malloc(XSize * YSize);
           
           Num_Byte = 0;
           
           while (Num_Byte < (XSize * YSize))
           {
 				  Data = (unsigned char)getc(f);
 				  
 				  if (Data >= 192)
 				  {
 	 	   		   	 Num_Data = Data & 0x3F;
 	 	   		   	 
 	 	   		   	 Data = (unsigned char)getc(f);
 	 	   		   	 
 	 	   		   	 while (Num_Data-- > 0)
 	 	   		   	 	   Buffer[Num_Byte++] = Data;
 	 	   		  }
 	 	   		  else
 	 	   		  	  Buffer[Num_Byte++] = Data;
	  	   }
	  	   
	  	   fclose(f);
	 }
}

void Save_RAW_Palette(void)
{
 	 FILE *f;
 	 
 	 f = fopen("out.pal", "wb");
 	 
 	 if (f != NULL)
 	 {
	  	   fwrite(&PcxPalette, sizeof(PcxPalette), 1, f);
	  	   
	  	   fclose(f);
	 }
	 else
	 {
	  	 printf("Error write data\n\r");
	  	 
	  	 exit(0);
	 }
}

void Save_RAW_Block(int StartX, int StartY, int W, int H, const char *FName)
{
 	 unsigned char *TmpBuf = NULL;
 	 int i, j, PosTmp = 0;
 	 FILE *f;
 	 
 	 TmpBuf = (unsigned char *)malloc(W * H);
 	 
 	 if (TmpBuf != NULL)
 	 {
	  	for (j = StartY; j < StartY + H; j++)
	  		for (i = StartX; i < StartX + W; i++)
	  			TmpBuf[PosTmp++] = Buffer[(j * XSize) + i];
	  			
        f = fopen(FName, "wb");
        
        if (f != NULL)
        {
		   	  fwrite(TmpBuf, W * H, 1, f);
		   	  
		   	  fclose(f);
	    }
	    
	    free(TmpBuf);
	 }
}

int main(int argc, char *argv[])
{
  Load_Header("board.Pcx");
  Load_PcxPalette("board.Pcx");
  Load_PcxImage("board.Pcx");
  
  Save_RAW_Palette();
  
  Save_RAW_Block(0, 0, 320, 240, "board.raw");
  Save_RAW_Block(1, 241, 25, 25, "bsel.raw");
  Save_RAW_Block(26, 241, 25, 25, "rsel.raw");
  
  Save_RAW_Block(51, 243, 22, 23, "bped.raw");
  Save_RAW_Block(74, 243, 22, 23, "bcav.raw");
  Save_RAW_Block(97, 243, 22, 23, "balf.raw");
  Save_RAW_Block(120, 243, 22, 23, "btor.raw");
  Save_RAW_Block(143, 243, 22, 23, "breg.raw");
  Save_RAW_Block(166, 243, 22, 23, "bre.raw");
  
  Save_RAW_Block(51, 267, 22, 23, "nped.raw");
  Save_RAW_Block(74, 267, 22, 23, "ncav.raw");
  Save_RAW_Block(97, 267, 22, 23, "nalf.raw");
  Save_RAW_Block(120, 267, 22, 23, "ntor.raw");
  Save_RAW_Block(143, 267, 22, 23, "nreg.raw");
  Save_RAW_Block(166, 267, 22, 23, "nre.raw");
  
  Save_RAW_Block(189, 243, 42, 10, "pwhite.raw");
  Save_RAW_Block(191, 254, 48, 10, "pblack.raw");
  
  Save_RAW_Block(191, 266, 102, 10, "pthink.raw");
  
  Save_RAW_Block(1, 267, 25, 25, "wpiece.raw");
  Save_RAW_Block(26, 267, 25, 25, "bpiece.raw");
  
  return 0;
}
