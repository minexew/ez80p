;------------------------------------------------------------------------------------------------------------------
; Command line based Intel .hex byte To binary file ** With no front padding ** converter
; By Phil Ruston 2010
;
; V0.02 added record type 4 for > 64KB support
; 
;------------------------------------------------------------------------------------------------------------------

OpenConsole()

PrintN("Non-front padding Intel hex to raw binary file converter")
PrintN("V0.02 by Phil @ retroleum.co.uk")
PrintN("")

srcfile$ = ProgramParameter()

;srcfile$="test.hex"                                ; for testing only..

If ReadFile(0,srcfile$) 
   filesize.l = Lof(0)                               ; get the length of opened file
   *FileBuffer = AllocateMemory(filesize)            ; allocate memory for .hex file
     If *FileBuffer
      ReadData(0,*FileBuffer, filesize)              ; read all the .hex file into allocated memory
      Else
       PrintN("Cant allocate source buffer")
       Delay (1000)
       End
    EndIf
   Else
     PrintN("File not found..")
     Delay (5000)
     End
   EndIf

;-------------------------------------------------------------------------------------------------------------------
    
bin_buff_length.l=1024*512                            ; work buffer = arbitary 512kB   

*OutputBuffer = AllocateMemory(bin_buff_length)       ; allocate memory for ,bin file
If *OutputBuffer = 0
  PrintN("Cant allocate output buffer!")
  Delay (2000)
  End
EndIf
  
min_offset.l = (32768*65536)-1 
max_offset.l = 0
lower_addr_word.l = 0
upper_addr_word.l = 0
addr_offset.l = 0
*source = *filebuffer

;-------------------------------------------------------------------------------------------------------------------

Repeat
 
  Repeat
     text$=PeekS(*source,1)                          ; find start of line (colon char)
     *source=*source+1
     If *source >= *filebuffer+filesize              ; stops program if EOF is not encountered before last byte  
     PrintN("Error - no EOF record found!")
     Delay (2000)
     End
    EndIf
  Until text$=":"

  text$=PeekS(*source,2)                            ; get number of bytes on this line
  byte_count=Val("$"+text$)
  *source=*source+2      

  text$=PeekS(*source,4)                            ; get memory offset address for first byte of line
  address=Val("$"+text$)
  *source=*source+4

  text$=PeekS(*source,2)                            ; get "record type"
  record_type.l = Val("$"+text$)
  *source=*source+2

  addr_offset = address + (65536*upper_addr_word)

;-------------------------------------------------------------------------------------------------------------

 If record_type=0                                    ; record type 0

  If addr_offset < min_offset
   min_offset = addr_offset
  EndIf
  
    For index=1 To byte_count                        ; copy the bytes from the line to output binary buffer
    text$=PeekS(*source,2)
     rawbyte=Val("$"+text$)
      PokeB(*outputbuffer+addr_offset,rawbyte)
     addr_offset=addr_offset+1
     *source=*source+2
   Next index

   If addr_offset > max_offset
    max_offset = addr_offset
   EndIf
EndIf

;------------------------------------------------------------------------------------------------------------

  If record_type=1                                  ; is record type 1 (EOF)? Save file and quit if so..
   output_length = (max_offset-min_offset)

   dstfile$ = srcfile$                              ; trim off source filename's (.hex) extention
   Position = FindString(dstfile$, ".", 1)
   If position > 0
    dstfile$=Left (dstfile$,position-1)
   EndIf
   dstfile$=dstfile$+".ezp"                          ; add ".ezp" extension to filename for EZ80P Executables

   If CreateFile(0,dstfile$)                        
    WriteData(0,*outputbuffer+min_offset,output_length) 
    CloseFile(0)                                     
    PrintN("Done!")
    Delay (1000)
    End
   Else
    PrintN("Error writing file!")
    Delay (2000)
    End
  EndIf
 End
 EndIf

;-------------------------------------------------------------------------------------------------------------

If record_type = 4
  text$=PeekS(*source,4)                            ; get upper memory address word
  upper_addr_word=Val("$"+text$)
  *source=*source+4
EndIf

;--------------------------------------------------------------------------------------------------------------

 If record_type = 2 Or record_type = 3 Or record_type > 4
  PrintN ("Skipping unimplemented record type: " + text$)  
  Delay (500)
 EndIf
 
 ;------------------------------------------------------------------------------------------------------------
 
ForEver

End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 101
; FirstLine = 78
; Folding = -
; EnableXP
; Executable = ..\..\Code\PROSE Apps\test\Debug\_hex_to_ezp_v02.exe