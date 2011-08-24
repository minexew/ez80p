; This script can work in two modes.
; If no args in command line - GUI mode.
;
; If 6 args in command line - command line mode.
; Command line args:
; - input BMP file
; - output BIN file
; - output PAL file
; - format of output palette (for PAL file) '12' or '24'
; - palette index offset (for non-zero pixels) (e.g. 0)
; - skip all-zero 16x16 tiles? ('y' or 'n')


Global isGUI_Mode = 1;      ; default mode is GUI (not command line mode)

; ------------------------------------------------------------
; DoMessage Procedure
; ------------------------------------------------------------
  Procedure DoMessage(str1$, str2$, num)
    If isGUI_Mode
      ProcedureReturn MessageRequester(str1$, str2$, num)
    Else      
      ConsoleError (str1$)
      str2$ = ReplaceString(str2$, Chr(13),  Chr(13) + Chr(10))   ; replace 13 with 10,13 (console wants 10,13 as newline sequence)
      ConsoleError (str2$)
    EndIf  
  EndProcedure
  
; ------------------------------------------------------------
; Check, if we are executed in command line mode
; ------------------------------------------------------------
  countParams = CountProgramParameters()
  If countParams >= 6
    isGUI_Mode = 0
    OpenConsole()
  EndIf 
  
; ------------------------------------------------------------
; Phil's Utils
; ------------------------------------------------------------

DoMessage("Phil's Utils..","Makes raw '16 x Y' sprite data from a 256 colour Windows .BMP file. Pic is scanned top To bottom, left To right." + Chr(13) + "Scanning moves To Next column at bottom of pic Or when all pixels on a line equal a defined value" + Chr(13) , 0)

  If isGUI_Mode    
    endscan$ = InputRequester("Phil's Utils..", "Abort vertical scan when the 16 bytes are all colour:", "$FF")
  Else
    endscan$ = ProgramParameter(5);    
  EndIf
  
 
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------
  
  If isGUI_Mode        
    srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)
  Else
    srcfile$ = ProgramParameter(0);    
  EndIf

     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       DoMessage("BMP converter","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)
     EndIf
 
 ;-------------------------------------------------------------------------------------------

 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf

 ;-----------------------------------------------------------------------------------------
 ;Check file...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer

If PeekW(*sourcebuffer+0) <> $4d42
 DoMessage("BMP sprite converter","Error! Not a .BMP format file" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+28) <> 8
 DoMessage("BMP sprite converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+30) <> 0
 DoMessage("BMP sprite converter","Error! Pic must have no compression!" + Chr(13) , 0)
 End
EndIf

imwid.w = PeekW(*SourceBuffer+18)             ; get data about file from its header
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
   
If (imwid.w & 15) <> 0
 DoMessage ("BMP sprite converter","Error! Image width must be multiple of 16 pixels"+ Chr(13) , 0)
 End
EndIf

;-----------------------------------------------------------------------------------------


If isGUI_Mode        
  index_offset$ = InputRequester("BMP conversion", "Any palette index offset (for non-zero pixels)?", "0")  
Else
  index_offset$ = ProgramParameter(4);
EndIf
  
index_offset = Val (index_offset$) 

;-----------------------------------------------------------------------------------------
;Convert pixels
;-----------------------------------------------------------------------------------------

;  Debug imwid
;  Debug imhei
  counter.l = 0
  last_slice.l = 0
  
  *DestBuffer = AllocateMemory(imwid * imhei)  
   If *Destbuffer
    
    For vertstrip = 0 To (imwid / 16) - 1 

     For slice = 0 To (imhei - 1)
     last_slice = 0
       For pixelindex = 0 To 15
        srcindex.l = pixelstartoffset + pixelindex + (vertstrip * 16) + (((imhei-1) - slice) * imwid)
        pixel.w = PeekB(*SourceBuffer + srcindex) & 255
        If pixel = Val(endscan$)
         last_slice = last_slice + 1
        EndIf
       Next pixelindex
       
       If last_slice = 16
        Break
       EndIf
       
        For pixelindex = 0 To 15
        srcindex.l = pixelstartoffset + pixelindex + (vertstrip * 16) + (((imhei-1) - slice) * imwid)
        pixel.w = PeekB(*SourceBuffer + srcindex) & 255
         If pixel <> 0                                            
          pixel= pixel + index_offset
         EndIf        
         PokeB (*DestBuffer + counter,pixel)
         counter = counter + 1
        Next pixelindex
       Next slice

    Next vertstrip
      
   Else
   DoMessage("BMP converter","Cant create destination buffer!" + Chr(13) , 0)
   End
  EndIf

Else
 DoMessage("BMP converter","No Source File Selected" + Chr(13) , 0)
 End
EndIf
 
 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------  
  
  If isGUI_Mode            
    dstfile$ = SaveFileRequester("Save Sprite Data As..",FileName$+"_sprites.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
  Else
    dstfile$ = ProgramParameter(1);
  EndIf

  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*DestBuffer,counter)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   DoMessage("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

 ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------
    
  If isGUI_Mode            
    pal_depth$ = InputRequester("BMP converter", "12 bit ($0RGB) or 24 bit ($RR,$GG,$BB..) palette", "12")    
  Else
    pal_depth$ = ProgramParameter(3);
  EndIf
 
  If pal_depth$ = "12"
   offset = 54
    For counter = 0 To 255
     blue.w        = PeekB(*SourceBuffer + offset + 0) & 255
     bluebits.w    = (blue & 240) >> 4
     green.w       = PeekB(*SourceBuffer + offset + 1) & 255
     greenbits.w   = (green & 240) >> 4 
     red.w         = PeekB(*SourceBuffer + offset + 2) & 255
     redbits.w     = (red & 240) >> 4
     composite.b   = bluebits | (greenbits << 4)
     PokeB (*DestBuffer + (counter*2) +1,redbits)
     PokeB (*DestBuffer + (counter*2),composite)
     offset = offset + 4
   Next counter
   pal_size.l = 256 * 2
  Else
  pal_depth$ = "24"
   offset = 54
    For counter = 0 To 255
     blue.w        = PeekB(*SourceBuffer + offset + 0) & 255
     green.w       = PeekB(*SourceBuffer + offset + 1) & 255
     red.w         = PeekB(*SourceBuffer + offset + 2) & 255
     PokeB (*DestBuffer + (counter*3),red)
     PokeB (*DestBuffer + (counter*3) + 1,green)
     PokeB (*DestBuffer + (counter*3) + 2,blue)
     offset = offset + 4
   Next counter
   pal_size.l = 256 * 3
  EndIf
   
 ;------------------------------------------------------------------------------------------
 ; Save the palette
 ;------------------------------------------------------------------------------------------   
 
  If isGUI_Mode            
   dstfile$ = SaveFileRequester("Save Palette Data As..",FileName$+"_"+pal_depth$+"bit_"+"palette.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0) 
  Else
   dstfile$ = ProgramParameter(2);
  EndIf
    
  If CreateFile(0,dstfile$)                      ; create a new file...
   WriteData(0,*DestBuffer,pal_size)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   DoMessage("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

DoMessage("Phil's Utils..", "Done!" + Chr(13), 0)

End 

; IDE Options = PureBasic 4.30 (Windows - x86)
; ExecutableFormat = Console
; CursorPosition = 41
; FirstLine = 21
; Folding = -
; EnableAsm
; Executable = ..\bmp_to_amoeba_sprites.exe