; PureBasic app to send and receive files to/from Z80 project via RS232 serial link
; By Phil Ruston '08-09. 8N1, no hardware flow control. v3.2

getprefs = OpenPreferences("serial_prefs.txt")
baud$ = ReadPreferenceString("baud_rate", "115200")
com$ = ReadPreferenceString("com_port", "undefined") 
ClosePreferences()
error.l = 0
calculated_crc.l = 0
time_out_seconds.l = 3

;- Window Description -------------------------------------------------------------
Enumeration
  #Window_0
EndEnumeration
;- Gadget Constants
Enumeration
  #Button_0
  #Button_1
  #ProgressBar_0
  #Text_0
  #CheckBox_0
  #Combo_0
EndEnumeration
;- StatusBar Constants
Enumeration
  #StatusBar_0
EndEnumeration

  If OpenWindow(#Window_0, 314, 107, 319, 210,  "xZ80P Serial Link V3.2", #PB_Window_SystemMenu | #PB_Window_TitleBar)
        ButtonGadget(#Button_0, 10, 10, 90, 40, "Send")
        ButtonGadget(#Button_1, 120, 10, 80, 40, "Receive")
        ProgressBarGadget(#ProgressBar_0, 10, 180, 300, 20, 0, 100)
        TextGadget(#Text_0, 10, 70, 300, 100, "", #PB_Text_Border)
        CheckBoxGadget(#CheckBox_0, 220, 40, 90, 20, "115200 Baud")
        ComboBoxGadget(#Combo_0, 220, 10, 90, 24)
        For a=1 To 9 : AddGadgetItem(#Combo_0,-1,"COM"+Str(a)+":") : Next
        SetGadgetState(#Combo_0,0)
        If baud$="115200"
         SetGadgetState(#CheckBox_0,1)
        EndIf
   EndIf
  
;---- Allocate memory for header buffer and file ----------------------------------------

*blockbuffer = AllocateMemory(258)                   ; 256 data + 2 CRC bytes
 If *blockbuffer = 0
  MessageRequester("Serial Link","Cant allocate memory buffer" + Chr(13) , 0)
  End
 EndIf
*junkbuffer = AllocateMemory(258)
 If *junkbuffer = 0
  MessageRequester("Serial Link","Cant allocate memory buffer" + Chr(13) , 0)
  End
 EndIf
 
 ;--- Open Com Port  ---------------------------------------------------------------- 

old_selection.l = 10
findcom.l = 0 
If com$ = "undefined"
 Repeat
  findcom = findcom + 1
  com$ = "COM"+Str(findcom)
  Gosub open_com_port
 Until comok=1 Or findcom = 9

 Else
  Gosub open_com_port
  If comok = 0
   old_selection = Asc (Mid(com$,4,1)) - 49
   SetGadgetState(#Combo_0,old_selection)
   MessageRequester("Serial Link","Cant open previously used com port!" + Chr(13) , 0)
  EndIf
EndIf

 If findcom = 9 And comok=0
  MessageRequester("Serial Link","Cant find a com port (COM1-C0M9 could not be opened)" + Chr(13) , 0)
  End
 EndIf

If comok = 1
 SetGadgetState(#Combo_0,Asc (Mid(com$,4,1)) - 49)
EndIf

;----- Wait for button clicks -----------------------------------------------------

text.s = "Status.. "

mainloop:

EventID = WaitWindowEvent()
 If EventID = #PB_Event_CloseWindow
                          
  If CreatePreferences("serial_prefs.txt")
   WritePreferenceString("baud_rate", baud$)
   WritePreferenceString("com_port", com$)
   ClosePreferences()
  EndIf
  End
 EndIf
  
 If EventID = #PB_Event_Gadget
  GadgetID = EventGadget()

  If GadgetID = #Button_0 And comok =1
   Gosub send_file
   FreeMemory(*sendbuffer)
   If error = 0
    moretext$="Completed OK"
    Gosub more_text 
   Else
    moretext$="Failed!"
    Gosub more_text 
   EndIf
  EndIf

  If GadgetID = #Button_1 And comok =1
   Gosub receive_file
   FreeMemory(*RecBuffer)
   If error = 0
    moretext$="Completed OK"
    Gosub more_text
   Else
    moretext$="Failed!"
    Gosub more_text
   EndIf
  EndIf

  If GadgetID = #CheckBox_0
   If GetGadgetState(#CheckBox_0) = 1
    baud$="115200"
    Else
    baud$="57600"
   EndIf
   CloseSerialPort(0)
	 SetGadgetText(#Text_0, "Closed Port")
 	 Gosub open_com_port
   If comok = 0
    MessageRequester("Serial Link","Cant open port" + mycom$ + Chr(13) , 0)
   EndIf
  EndIf

 If GadgetID = #Combo_0
  com_selection= GetGadgetState(#Combo_0)
  If com_selection <> old_selection
   old_selection = com_selection
   com$ = "COM"+Str(com_selection+1)
   If IsSerialPort(0)
    CloseSerialPort(0)
   EndIf
   SetGadgetText(#Text_0, "Closed Port")
   Gosub open_com_port
    If comok = 0
     MessageRequester("Serial Link","Cant open port" + mycom$ + Chr(13) , 0)
    EndIf
   EndIf
  EndIf
EndIf
Goto mainloop

;----Send a file------------------------------------------------------------------------------------

send_file:

bar.f = 0
SetGadgetState   (#ProgressBar_0, bar)  
time_out_seconds = 3
error = 0  
Gosub clear_text
moretext$="Send File.. "
Gosub more_text

;---- File requester (send) -------------------------------------------------------------
 
  srcfile$ = OpenFileRequester("Select a file to send","","All Files(*.*)|*.*",0)
  If ReadFile(0,srcfile$) 
   filesize.l = Lof(0)                             ; get the length of opened file
   *SendBuffer = AllocateMemory(filesize)          ; allocate memory for file  
   If *Sendbuffer = 0
    MessageRequester("Serial Link","Cant allocate memory buffer" + Chr(13) , 0)
    End
   EndIf
   ReadData(0,*SendBuffer, filesize)               ; read all data into the memory block
   CloseFile(0)                                    ; close the previously opened file
  Else
   MessageRequester("Serial Link","File error" + Chr(13) , 0)
   error = 1
   Return
  EndIf
 
;----- Make file header  ---------------------------------------------------------
  
  For addr = 0 To 255                         ; clear block buffer
   PokeB (*blockbuffer+addr,0)
  Next addr
     
  Filename$ = GetFilePart(srcfile$)           ; copy filename to header
  For n = 1 To 16
  If n <= Len(filename$)
    fnchar$ = Mid(filename$,n,1)
    fnascii = Asc(fnchar$)
   Else 
    fnascii = 0
   EndIf
  PokeB (*blockbuffer+(n-1),fnascii)
  Next n 
  PokeL (*blockbuffer+16,filesize)

  header_id$="Z80P.FHEADER"                  ; copy ID string to header
  For n = 1 To 12
    idchar$ = Mid(header_id$,n,1)
    idascii = Asc(idchar$)
   PokeB(*blockbuffer+20+(n-1),idascii)
  Next n

  Gosub calc_CRC
  PokeW (*blockbuffer+256,calculated_crc)
  
;---- Send File Header ---------------------------------------------------------------
 
Gosub clear_serial_receive_buffer

If IsSerialPort(0)
 result = WriteSerialPortData(0,*blockbuffer,258)
 If result <> 0             
  moretext$="Sending File Header"
  Gosub more_text
 Else
  moretext$="Error Sending Header"
  Gosub more_text
  error=1
  Return
 EndIf
Else
 moretext$="Port not ready"
 Gosub more_text
 error = 1
 Return
EndIf

 Repeat
  NbDataToWrite.l = AvailableSerialPortOutput(0)       ; wait for send buffer to empty
 Until NbDataToWrite = 0
  
 moretext$="Waiting for header acknowledge.."          ; wait for acknowledge
 Gosub more_text

 Gosub wait_ack
 If error = 1
  Return
 EndIf
 
 If ackstring$ = "WW"
  moretext$="OK, waiting for receiver to accept file.."
  Gosub more_text
  time_out_seconds = 15
  Gosub wait_ack
  time_out_seconds = 3
   If error = 1
    Return
   EndIf
 EndIf
 
 If ackstring$ <> "OK"
  moretext$="File refused.."+" (Ack received:"+ackstring$+ ")"
  Gosub more_text
  error = 1
  Return
 Else
  moretext$="Ack received..OK."
  Gosub more_text
 EndIf
  
;---- Send File Data ---------------------------------------------------------------
 
 For addr = 0 To 255                         ; clear block buffer
  PokeB (*blockbuffer+addr,0)
 Next addr
 
 moretext$="Sending File: " + Filename$
 Gosub more_text  
 
 *filepos.l = *sendbuffer
 bytestogo.l = filesize

Repeat
 
  bar.f = ((filesize-bytestogo)/filesize)*100
  SetGadgetState   (#ProgressBar_0, bar)   
   
    If bytestogo > 255
     bytecount.l = 256
    Else
     bytecount.l = bytestogo
    EndIf
  
    For addr=0 To bytecount-1
     filebyte.l = PeekB(*filepos+addr)&$ff
     PokeB (*blockbuffer+addr,filebyte)  
    Next addr
    Gosub calc_crc
    PokeW (*blockbuffer+256,calculated_crc)
 
   If WriteSerialPortData(0,*blockbuffer,258)             
    *filepos=*filepos+bytecount
    bytestogo=bytestogo-bytecount
   Else
    moretext$="Error Sending File"
    Gosub more_text
    error=1
    Return
   EndIf

   Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
   Until NbDataToWrite = 0

Gosub wait_ack
 If error = 1
  Return
 EndIf

If ackstring$ = "WW"
  time_out_seconds = 15
  Gosub wait_ack
  time_out_seconds = 3
   If error = 1
    Return
   EndIf
 EndIf
 
 If ackstring$ <> "OK"
  moretext$="Comms error.."
  Gosub more_text
  error = 1
  Return
 EndIf
  
Until bytestogo <= 0
SetGadgetState   (#ProgressBar_0, 100) 
Return

;--------- Receive a file ------------------------------------------------------------

receive_file:

bar.f = 0
SetGadgetState   (#ProgressBar_0, bar)  
 
Gosub clear_serial_receive_buffer
  
 timer.l = 0
 error = 0 
 Gosub clear_text
 moretext$="Waiting for file header.."
 Gosub more_text  

 start_time.l=Date()                                   ; allow 10 seconds for header to be sent
 Repeat
 Until AvailableSerialPortInput(0) >= 258 Or Date() > start_time+10
 If Date() > start_time+10
   moretext$="Timed out waiting for header."
   Gosub more_text
   error=1
   Return
 EndIf

 transfer = ReadSerialPortData(0,*blockbuffer,258)             ; Put the data in the buffer
 
;---- check file header ---------------------------------------------------------

 Gosub calc_crc
 received_crc.l=PeekW(*blockbuffer+256)&$FFFF

 If received_crc = calculated_crc
  moretext$="Header checksum OK."
  Gosub more_text 
 Else
  moretext$="Bad header checksum."
  Gosub more_text 
  moretext$="Calculated CRC:$"+Hex(calculated_crc)+" Received CRC:$"+Hex(received_crc)
  Gosub more_text
  Gosub bad_ack
  error=1
  Return
 EndIf

 header_id$="Z80P.FHEADER"                  ; test ID string in header
  For n = 1 To 12
    idchar$ = Mid(header_id$,n,1)
    idascii = Asc(idchar$)
    hdrbyte = PeekB(*blockbuffer+20+(n-1))
    If hdrbyte <> idascii
     moretext$="Error block received is not a file header!"
     Gosub more_text
     Gosub bad_ack
     error=1
     Return
    EndIf
  Next n

  For n = 32 To 255                              ;rest of block should be zeroes
   If PeekB(*blockbuffer+n) <> 0
    moretext$="Error block received is not a file header!"
    Gosub more_text
    Gosub bad_ack
    error=1
    Return
   EndIf
  Next n

filename$ = ""                                
 For n = 1 To 16
  fnchar = PeekB(*blockbuffer+n-1)
  If fnchar<>0
   filename$ = filename$ + Chr(fnchar)
  EndIf
 Next n
 filesize.l = PeekL(*blockbuffer+16)
  *RecBuffer = AllocateMemory(filesize+256)          ; allocate memory for file  
  If *Recbuffer = 0
    MessageRequester("Serial Link","Cant allocate memory buffer" + Chr(13) , 0)
    End
  EndIf

;---- Send acknowledge and get file blocks ----------------------------------

 Gosub Good_ack                             ; Send "OK" to initiate file body TX
  
 moretext$="Acknowledge Sent"
 Gosub more_text 
 moretext$="Receiving: " + filename$
 Gosub more_text 

 bytes_read.l=0

Repeat

 start_time.l=Date()                                   ; allow 2 seconds for block
 Repeat
 Until AvailableSerialPortInput(0) >= 258 Or Date() > start_time+2
 If Date() > start_time+2
   moretext$="Timed out during data block.."
   Gosub more_text
   error=1
   Return
 EndIf
 
 transfer = ReadSerialPortData(0,*blockbuffer,258)            ; Put the data in the buffer
 
;--- Check CRC of block -------------------------------------------------------

 Gosub calc_crc
 received_crc.l=PeekW(*blockbuffer+256)&$FFFF
 If received_crc <> calculated_crc
   moretext$="Bad file block checksum."
   Gosub more_text 
   moretext$="Calculated CRC:$"+Hex(calculated_crc)+" Received CRC:$"+Hex(received_crc)
   Gosub more_text
   Gosub bad_ack
   error=1
   Return
  EndIf

;--------------------------------------------------------------------------------

 For addr=0 To 255
  Data_byte.l = PeekB(*blockbuffer+addr)&$ff
  PokeB (*recbuffer+bytes_read,Data_byte)
  bytes_read = bytes_read + 1
 Next addr

 bar.f = (bytes_read/filesize)*100
 SetGadgetState   (#ProgressBar_0, bar)      

 Gosub Good_Ack

Until bytes_read >= filesize

SetGadgetState   (#ProgressBar_0, 100) 
      
;--- Save the file --------------------------------------------------------------

 dstfile$ = SaveFileRequester("Save As..",filename$,"All files (*.*)|*.*",0)
  If CreateFile(0,dstfile$)                      
   WriteData(0,*RecBuffer,filesize)               ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("Serial Link","File error" + Chr(13) , 0)
   error=1
   Return
  EndIf
 Return
 
;------ Make a CRC checksum ----------------------------------------------------- 

Calc_CRC:

hlreg.l = 65535                                       ; crc returned in "calculated_crc"
For bytecount = 0 To 255
byteval.w = PeekB(*blockbuffer+bytecount)&$ff
hlreg = (byteval << 8) ! hlreg
For n = 0 To 7
hlreg = hlreg + hlreg
If hlreg > 65535 
 hlreg = hlreg & $FFFF
 hlreg = hlreg ! $1021
EndIf
Next n
Next bytecount
calculated_crc = hlreg&$ffff
Return

;----- Acknowledge signals ------------------------------------------------------------

Bad_ack:

WriteSerialPortString(0, "XX")
  Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
  Until NbDataToWrite = 0
Return

Good_ack:

MyBuffer1.s = "OK"
WriteSerialPortString(0, "OK")
  Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
  Until NbDataToWrite = 0
Return

;------ Status Window Stuff -----------------------------------------------------------

clear_text:
 text$=""
 SetGadgetText(#Text_0, Text$)
 Return
  
more_text:
 text$=text$+moretext$+Chr(13)+Chr(10)
 SetGadgetText(#Text_0, Text$)
 Return

New_line:
 text$=text$+Chr(13)+Chr(10)
 SetGadgetText(#Text_0, Text$)
 Return

;---------------------------------------------------------------------------------------

clear_serial_receive_buffer:
  
Repeat                                           ; clear serial receive buffer
 NbDataToRead.l = AvailableSerialPortInput(0)
 If NbDataToRead > 0
  ditchbytes.l = NbDataToRead
  If ditchbytes > 258
   ditchbytes = 258
  EndIf
  transfer =  ReadSerialPortData(0, *junkbuffer, ditchbytes)
 EndIf
Until NbDataToRead = 0
Return

;---------------------------------------------------------------------------------------
 
 open_com_port:
 
 MyCom$ = Com$ + ": baud=" + Baud$ + " parity=N Data=8 stop=1"
 
 If OpenSerialPort(0, com$, Val(baud$), #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 258, 258)
    SetGadgetText(#Text_0, "Opened Port: " + Chr(13)+Chr(10) + MyCom$)
    comok = 1
  Else
    comok = 0
  EndIf
Return
 
;--------------------------------------------------------------------------------------
 
wait_ack:

 start_time.l=Date()                                   ; wait for ack
 Repeat
 Until AvailableSerialPortInput(0) => 2 Or Date() > start_time+time_out_seconds
 If Date() > start_time+time_out_seconds 
   moretext$="Timed out."
   Gosub more_text
   error=1
   Return
 EndIf
 ReadSerialPortData(0,*blockbuffer,2)                                    ; ack should be "OK", "WW" or "XX"  
 ackstring$ = Chr(PeekB(*blockbuffer)) + Chr(PeekB(*blockbuffer+1))
Return
;------------------------------------------------------------------------------------------
; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 29
; Folding = -
; Executable = ..\Serial_link_v3_0.exe