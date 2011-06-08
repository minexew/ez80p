; ------------------------------------------------------------
; Phil's Run Length Compressor
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","Phils run length file compressor" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize+256)      ; allocate the needed memory (plus a bit extra)
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("Compressor","Source buffer error" + Chr(13) , 0)
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
 
 srcindex.l = 0
 dstindex.l = 0

 *Dest_Buffer = AllocateMemory(sourcesize*4)           ; Extra space in case of "uncompressibles"

  If *Dest_Buffer
   best_token.l = 0 
   best_size.l = 4 * sourcesize
   Tokentrial.w = 0
 
   For tokentrial = 0 To 255                           ; Find which token gives the smallest pack file
    Gosub packer
     If dstindex < best_size
      best_size = dstindex
      best_token = Tokentrial
    EndIf 
   Next Tokentrial

  Else
   MessageRequester("Compressor", "Couldnt allocate destination buffer!" + Chr(13), 0)
   End
  EndIf

Tokentrial = best_token                                   ;recreate best result
PokeB (*dest_buffer,best_token)                           ;prefix file with token byte
Gosub packer

 ;------------------------------------------------------------------------------------------
 ; Save the data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Data As..",FileName$+"_packed.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                       ; we create a new file...
   WriteData(0,*Dest_Buffer,best_size)            ; write data from the memory block into the file
   CloseFile(0)                                   ; close the previously opened file and so store the written data 
  Else
   MessageRequester("Compressor","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Compressor", "Done!" + Chr(13), 0)

End

;--------------------------------------------------------------------------------------------------

triplet:

  PokeB (*dest_buffer + dstindex, Tokentrial)
  dstindex = dstindex + 1
  PokeB (*dest_buffer + dstindex, Databyte)
  dstindex = dstindex + 1
  count.l = 0
  Repeat
   srcindex=srcindex+1
   count = count + 1
  Until PeekW(*SourceBuffer + srcindex) & 255 <> Databyte  Or count = 255 Or srcindex >= sourcesize
  PokeB (*Dest_buffer + dstindex, count) 
  dstindex = dstindex + 1
  Return
  



packer:

    srcindex.l = 0
    dstindex.l = 1
     
    Repeat

     databyte = PeekW(*SourceBuffer + srcindex) & 255 
 
     If Databyte = tokentrial
      Gosub triplet
     Else
     
       If srcindex+1 = sourcesize Or srcindex+2 = sourcesize Or PeekW(*SourceBuffer + srcindex+1) & 255 <> Databyte Or PeekW(*SourceBuffer + srcindex+2) & 255 <> Databyte 
        PokeB (*Dest_buffer + dstindex, Databyte)
        dstindex = dstindex + 1
        srcindex = srcindex + 1
       Else
        Gosub triplet
       EndIf
     
      EndIf
    
    Until srcindex >= sourcesize 
 Return

;---------------------------------------------------------------------------------------------------

 
; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 36
; Folding = -
; Executable = ..\bmp_to_raw_planar\source\bmp_to_raw_chunky.exe