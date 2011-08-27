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

void Create_RawData(void)
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
	 
	 f = fopen("out.raw", "wb");
	 
	 if (f != NULL)
	 {
	  	   fwrite(Buffer, XSize * YSize, 1, f);
	  	   
	  	   fclose(f);
	 }
	 else
	 {
	  	 printf("Error write data\n\r");
	  	 
	  	 exit(0);
	 }
}

int main(int argc, char *argv[])
{
  if (argc != 2)
	{
	   		 printf("\n\n Usage pcx2raw filenam.pcx\n\r");
	   		 
	   		 exit(0);
    }
    
  Load_Header(argv[1]);
  Load_PcxPalette(argv[1]);
  Load_PcxImage(argv[1]);
  
  Create_RawData();
  
  if (Buffer != NULL)
  	 free(Buffer);  
  
  return 0;
}
