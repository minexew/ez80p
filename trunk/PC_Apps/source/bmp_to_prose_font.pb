; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","Converts 256 Colour Windows .BMP File to linear sequence of 8bit by Y font characters" + Chr(13) , 0)
  
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
   
If (imwid.w & 7) <> 0 
 MessageRequester ("BMP sprite converter","Error! The image cannot be divided evenly into 8-pixel wide characters"+ Chr(13) , 0)
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
  
;-----------------------------------------------------------------------------------------

char_height$ = InputRequester("Font conversion", "Character height?", "8")
char_height = Val (char_height$) 

;-----------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------
; convert the pixel data
;------------------------------------------------------------------------------------------

  counter.l = 0
  *DestBuffer = AllocateMemory(imwid * imhei)  
   If *Destbuffer
    For blockrow = 0 To (imhei/char_height) -1
     For blockcolumn = 0 To (imwid/8) - 1
      For pixelrow = 0 To char_height - 1
       planarbyte.b = 0

       For pixelcolumn = 0 To 7
        srcindex.l = (blockrow * char_height * imwid) + (pixelrow * imwid) + (blockcolumn * 8) + pixelcolumn
        Databyte.b = PeekB(*Flipped_Buffer+srcindex)
        If Databyte <> 0
         planarbyte = planarbyte + (1 << (7-pixelcolumn))
        EndIf
       Next pixelcolumn

       PokeB (*DestBuffer + counter,planarbyte)
       counter = counter + 1
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
   
  dstfile$ = SaveFileRequester("Save Tile Data As..",FileName$+".fnt","Prose font (.fnt)|*.fnt|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new text file...
   WriteData(0,*DestBuffer,counter)                ; write data from the memory block into the file
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
; CursorPosition = 103
; FirstLine = 79
; Folding = -
; EnableAsm
; Executable = ..\bmp_to_8x8_tiles.exe