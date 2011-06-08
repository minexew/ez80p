; Convert binary to source code v0.02

;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a binary file to convert","","all files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)           ; allocate the required memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("Phils binary to source converter","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)

;-------------------------------------------------------------------------------------------

 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf

;-------------------------------------------------------------------------------------------

asm_buff_length.l=2*1024*1024                            ; work buffer = arbitary 2MB   
*Output_Buffer = AllocateMemory(Asm_buff_length)        ; allocate memory for .asm file

If *Output_Buffer = 0
  MessageRequester("Error","Cant allocate output buffer!",#PB_MessageRequester_Ok)
  End
EndIf

*addrcounter = *SourceBuffer
*start_addr = *output_buffer

;-------------------------------------------------------------------------------------------

bytes_per_line = 16

name$=InputRequester("Phils binary to source converter","Any label?", "")
If name$<>""
 text$ = name$ + ":" + Chr(13) + Chr(10)
 Gosub poke_string
EndIf
column.l = 0
lines=1
Repeat
   If column = 0
    text$="                db "
    Gosub poke_string
    lines=lines+1
   Else
    text$=","
    Gosub poke_string
   EndIf
    decval.w=PeekW(*addrcounter)&255
    digit$ = StrU(decval)
    text$=digit$
    Gosub poke_string
    *addrcounter = *addrcounter + 1
   column = column + 1
   If column = bytes_per_line 
    text$=Chr(13)+Chr(10)
    Gosub poke_string
    column = 0
   EndIf
  Until *addrcounter = (*sourcebuffer+sourcesize)

;----------------------------------------------------------------------------------------

 dstfile$ = SaveFileRequester("Save As..",filename$+".asm","All files (*.*)|*.*",0)
  If CreateFile(0,dstfile$)                      
   WriteData(0,*start_addr,*output_buffer - *start_addr) 
   CloseFile(0)        
  Else
   MessageRequester("Phils binary to source converter","File error" + Chr(13) , 0)
  EndIf

;----------------------------------------------------------------------------------------

   EndIf
  End
  
;----------------------------------------------------------------------------------------

poke_string:

 str_len.l = Len(text$)
 PokeS(*output_buffer, text$, str_len, #PB_Ascii)
 *output_buffer=*output_buffer+str_len
 Return

;----------------------------------------------------------------------------------------



; IDE Options = PureBasic 4.30 (Windows - x86)
; Folding = -
; Executable = ..\Z80_Project\svn_v6\PC_based_apps\ROM_bin_to_FPGA_ucf\source\BlockRAM_INIT.exe