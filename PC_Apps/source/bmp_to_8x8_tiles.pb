; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","Converts 256 Colour Windows .BMP File to linear sequence of 8x8 pixel tiles" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                 ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)               ; read all data into the memory block
      Else
       MessageRequester("BMP converter","File error" + Chr(13) , 0)
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
 ;Check format...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer

If PeekW(*sourcebuffer+0) <> $4d42
 MessageRequester("BMP sprite converter","Error! Not a .BMP format file" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+28) <> 8
 MessageRequester("BMP sprite converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+30) <> 0
 MessageRequester("BMP sprite converter","Error! Pic must have no compression!" + Chr(13) , 0)
 End
EndIf

imwid.w = PeekW(*SourceBuffer+18)             ; get data about file from its header
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
   
If (imwid.w & 7) <> 0 Or (imhei.w & 7) <> 0 
 MessageRequester ("BMP sprite converter","Error! The image cannot be divided cleanly into 8x8 blocks"+ Chr(13) , 0)
 End
EndIf

;----------------------------------------------------------------------------------------

;flip the buffer as BMPs are upside down
  
  counter.l = 0
  *Flipped_Buffer = AllocateMemory(imwid * imhei)  
   If *Flipped_Buffer
     For ypos = (imhei - 1) To 0 Step -1
      For xpos = 0 To (imwid - 1) 
       srcindex.l = pixelstartoffset + xpos + (ypos * imwid)
       Databyte.b = PeekB(*SourceBuffer + srcindex)
       PokeB (*Flipped_Buffer + counter,databyte)
       counter = counter + 1
     Next xpos
    Next ypos 
   Else
   MessageRequester("BMP Converter","Cant create work buffer!" + Chr(13) , 0)
   End
  EndIf

;------------------------------------------------------------------------------------------
; convert the pixel data
;------------------------------------------------------------------------------------------

  counter.l = 0
  *DestBuffer = AllocateMemory(imwid * imhei)  
   If *Destbuffer
    For blockrow = 0 To (Imhei/8) -1
     For blockcolumn = 0 To (Imwid/8) - 1
      For pixelrow = 0 To 7
       For pixelcolumn = 0 To 7
        srcindex.l = (blockrow * imwid * 8) + (blockcolumn * 8) + (pixelrow * imwid) + pixelcolumn
        pixel.w = PeekB(*Flipped_Buffer + srcindex) & 255
        PokeB (*DestBuffer + counter,pixel)
        counter = counter + 1
      Next pixelcolumn
     Next pixelrow
    Next blockcolumn
   Next blockrow
      
   Else
   MessageRequester("BMP converter","Cant create destination buffer!" + Chr(13) , 0)
   End
  EndIf

Else
 MessageRequester("BMP converter","No Source File Selected" + Chr(13) , 0)
 End
EndIf
 
 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Tile Data As..",FileName$+"_tiles.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new text file...
   WriteData(0,*DestBuffer,counter)                ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

 ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------
   
  pal_depth$ = InputRequester("BMP converter", "12 bit ($0RGB..) or 24 bit ($RR,$GG,$BB..) palette", "12")
 
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
     PokeB (*DestBuffer + (counter*2)+1,redbits)
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
   
  dstfile$ = SaveFileRequester("Save Palette Data As..",FileName$+"_"+pal_depth$+"bit_"+"palette.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; create a new file...
   WriteData(0,*DestBuffer,pal_size)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Phil's Utils..", "Done!" + Chr(13), 0)

End 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 144
; FirstLine = 109
; Folding = -
; EnableAsm
; Executable = ..\bmp_to_8x8_tiles.exe