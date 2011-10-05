; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","This util generates raw chunky pixel data from a 256 colour Windows .BMP File" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("BMP converter","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)
     EndIf
 
 ;-----------------------------------------------------------------------------------------
  
 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf

 ;-----------------------------------------------------------------------------------------
 ;Check file...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer                               ; get data about file from its header

 If PeekW(*sourcebuffer+0) <> $4d42
  MessageRequester("BMP converter","Error! Not a .BMP format file" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+28) <> 8
  MessageRequester("BMP converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+30) <> 0
  MessageRequester("BMP converter","Error! Pic must have no compression!" + Chr(13) , 0)
  End
 EndIf

imwid.w = PeekW(*SourceBuffer+18)             
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
counter.l = 0

If (imwid.w & 7) <> 0
 MessageRequester ("BMP converter","Error! Image width must be multiples of 8 pixels!"+ Chr(13) , 0)
 End
EndIf


;----------------------------------------------------------------------------------------

index_offset$ = InputRequester("BMP conversion", "Any palette index offset (for non-zero pixels)?", "0")
index_offset = Val (index_offset$) 
 
;----------------------------------------------------------------------------------------
 
;flip the buffer as BMPs are upside down
  
  *Flipped_Buffer = AllocateMemory(imwid * imhei)  
   If *Flipped_Buffer
     For ypos = (imhei - 1) To 0 Step -1
      For xpos = 0 To (imwid - 1) 
       srcindex = pixelstartoffset + xpos + (ypos * imwid)
       Databyte.b = PeekB(*SourceBuffer + srcindex)
       If databyte <> 0                                             ;offset
        databyte = databyte + index_offset
       EndIf
       PokeB (*Flipped_Buffer + counter,databyte)
       counter = counter + 1
     Next xpos
    Next ypos 
   Else
   MessageRequester("BMP Converter","Cant create work buffer!" + Chr(13) , 0)
   End
  EndIf


 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Bitplane Data As..",FileName$+"_chunky.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Flipped_Buffer,counter)            ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

 ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------
   
  pal_depth$ = InputRequester("BMP to raw chunky conversion", "12 bit ($0RGB,$0RGB..) or 24 bit ($RR,$GG,$BB..) palette", "12")
 
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
     PokeB (*Flipped_Buffer + (counter*2) + 1,redbits)
     PokeB (*Flipped_Buffer + (counter*2),composite)
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
     PokeB (*Flipped_Buffer + (counter*3),red)
     PokeB (*Flipped_Buffer + (counter*3) + 1,green)
     PokeB (*Flipped_Buffer + (counter*3) + 2,blue)
     offset = offset + 4
   Next counter
   pal_size.l = 256 * 3
  EndIf
   
 ;------------------------------------------------------------------------------------------
 ; Save the palette
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Palette Data As..",FileName$+"_"+pal_depth$+"bit_"+"palette.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; create a new file...
   WriteData(0,*Flipped_Buffer,pal_size)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Phil's Utils..", "Done!" + Chr(13), 0)

Else

MessageRequester("Phil's Utils..", "Failed!" + Chr(13), 0)

EndIf

End
 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 82
; FirstLine = 41
; Folding = -
; Executable = ..\bmp_to_raw_planar\source\bmp_to_raw_chunky.exe