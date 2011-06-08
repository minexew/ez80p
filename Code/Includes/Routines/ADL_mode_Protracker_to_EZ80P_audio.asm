;----------------------------------------------------------------------------------------
; Convert Amiga hardware values from eZ80 Protracker Player to eZ80P spec
; and writes to hardware registers
;-----------------------------------------------------------------------------------------
;
; V1.01 - ADL mode
;
; Writes 4 tracker channels to left channels, and copied to right
;----------------------------------------------------------------------------------------

.assume ADL = 1

firstchan_period	equ channel_data+period_lo
firstchan_volume	equ channel_data+volume
firstchan_location	equ channel_data+sample_location
firstchan_length	equ channel_data+sample_length
firstchan_control	equ channel_data+control_bits
firstchan_loop_loc	equ channel_data+sample_loop_location
firstchan_loop_len	equ channel_data+sample_loop_length

secondchan_period	equ channel_data+vars_per_channel+period_lo
secondchan_volume	equ channel_data+vars_per_channel+volume
secondchan_location	equ channel_data+vars_per_channel+sample_location
secondchan_length	equ channel_data+vars_per_channel+sample_length
secondchan_control	equ channel_data+vars_per_channel+control_bits
secondchan_loop_loc	equ channel_data+vars_per_channel+sample_loop_location
secondchan_loop_len	equ channel_data+vars_per_channel+sample_loop_length

thirdchan_period	equ channel_data+(vars_per_channel*2)+period_lo
thirdchan_volume	equ channel_data+(vars_per_channel*2)+volume
thirdchan_location	equ channel_data+(vars_per_channel*2)+sample_location
thirdchan_length	equ channel_data+(vars_per_channel*2)+sample_length
thirdchan_control	equ channel_data+(vars_per_channel*2)+control_bits
thirdchan_loop_loc	equ channel_data+(vars_per_channel*2)+sample_loop_location
thirdchan_loop_len	equ channel_data+(vars_per_channel*2)+sample_loop_length

fourthchan_period	equ channel_data+(vars_per_channel*3)+period_lo
fourthchan_volume	equ channel_data+(vars_per_channel*3)+volume
fourthchan_location	equ channel_data+(vars_per_channel*3)+sample_location
fourthchan_length	equ channel_data+(vars_per_channel*3)+sample_length
fourthchan_control	equ channel_data+(vars_per_channel*3)+control_bits
fourthchan_loop_loc	equ channel_data+(vars_per_channel*3)+sample_loop_location
fourthchan_loop_len	equ channel_data+(vars_per_channel*3)+sample_loop_length

;-----------------------------------------------------------------------------------------------------------------
; EZ80P specific code
;-----------------------------------------------------------------------------------------------------------------

update_audio_hardware

				ld a,1
				ld (hw_audio_registers+3),a			; enable playback / clear audio register status flag
				ld c,port_hw_flags
wait_audreg		tstio 40h							; wait for audio hardware to finish reading registers
				jr z,wait_audreg
				
;				ld a,0ffh							; for testing only
;				ld (hw_palette),a					; for testing only
				
;---------------------------------------------------------------------------------------------------------------
; Write Period Constants - must be done in max 1500 50mhz clocks
;---------------------------------------------------------------------------------------------------------------
								
				ld ix,hw_audio_registers			; start of channel 0 audio registers
				ld iy,hw_audio_registers+80h
				ld de,period_conv_table-200			; Convert Amiga period values to EZ80P constants

				ld bc,(firstchan_period)
				ld hl,0
				ld l,c
				ld h,b
				add hl,hl
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				ld (ix+08h),bc						;update chan 0 - 24 bit write mandatory
				ld (iy+08h),bc
				
				ld bc,(secondchan_period)
				ld hl,0
				ld l,c
				ld h,b	  	
				add hl,hl
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				ld (ix+28h),bc						;update chan 1
				ld (iy+28h),bc					
	
				ld bc,(thirdchan_period)
				ld hl,0
				ld l,c
				ld h,b  	
				add hl,hl
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				ld (ix+48h),bc						;update chan 2 
				ld (iy+48h),bc	

				ld bc,(fourthchan_period)
				ld hl,0
				ld l,c
				ld h,b  	
				add hl,hl
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				ld (ix+68h),bc						;update chan 3
				ld (iy+68h),bc
				
;---------------------------------------------------------------------------------------------------------------
; Write Volume
;---------------------------------------------------------------------------------------------------------------


				ld a,(firstchan_volume)				;write volume values
				ld e,a
				ld (ix+0ch),de						;update chan 0 - vol - 24 bit write mandatory
				ld (iy+0ch),de
				
				ld a,(secondchan_volume)
				ld e,a
				ld (ix+2ch),de						;ch1		
				ld (iy+2ch),de
				
				ld a,(thirdchan_volume)
				ld e,a
				ld (ix+4ch),de						;ch2
				ld (iy+4ch),de
				
				ld a,(fourthchan_volume)
				ld e,a
				ld (ix+6ch),de						;ch3
				ld (iy+6ch),de
				
;---------------------------------------------------------------------------------------------------------------
; Write Loc and Len of triggered channels
;---------------------------------------------------------------------------------------------------------------

				ld hl,firstchan_control				 
				bit 0,(hl)							 
				jr z,no_rt_ch0						
				res 0,(hl)
				ld hl,(firstchan_location)
				ld (ix+00h),hl					;update chan 0 - loc (24 bit write mandatory)
				ld (iy+00h),hl
				ld hl,(firstchan_loop_loc)
				ld (ix+10h),hl					;update chan 1 - loop loc
				ld (iy+10h),hl	
				ld hl,(firstchan_length)
				ld (ix+04h),hl					;update chan 2 - len
				ld (iy+04h),hl
				ld hl,(firstchan_loop_len)
				ld (ix+14h),hl					;update chan 3 - loop len
				ld (iy+14h),hl

no_rt_ch0
				ld hl,secondchan_control
				bit 0,(hl)
				jr z,no_rt_ch1
				res 0,(hl)
				ld hl,(secondchan_location)
				ld (ix+20h),hl					
				ld (iy+20h),hl
				ld hl,(secondchan_loop_loc)
				ld (ix+30h),hl					
				ld (iy+30h),hl
				ld hl,(secondchan_length)
				ld (ix+24h),hl					
				ld (iy+24h),hl	
				ld hl,(secondchan_loop_len)			
				ld (ix+34h),hl						
				ld (iy+34h),hl	

no_rt_ch1
								
				ld hl,thirdchan_control
				bit 0,(hl)
				jr z,no_rt_ch2
				res 0,(hl)
				ld hl,(thirdchan_location)
				ld (ix+40h),hl		
				ld (iy+40h),hl
				ld hl,(thirdchan_loop_loc)
				ld (ix+50h),hl		
				ld (iy+50h),hl					
				ld hl,(thirdchan_length)
				ld (ix+44h),hl	
				ld (iy+44h),hl	
				ld hl,(thirdchan_loop_len)
				ld (ix+54h),hl		
				ld (iy+54h),hl	


no_rt_ch2		ld hl,fourthchan_control
				bit 0,(hl)
				jr z,no_rt_ch3
				res 0,(hl)
				ld hl,(fourthchan_location)
				ld (ix+60h),hl		
				ld (iy+60h),hl	
				ld hl,(fourthchan_loop_loc)
				ld (ix+70h),hl	
				ld (iy+70h),hl	
				ld hl,(fourthchan_length)
				ld (ix+64h),hl		
				ld (iy+64h),hl	
				ld hl,(fourthchan_loop_len)
				ld (ix+74h),hl		
				ld (iy+74h),hl	

no_rt_ch3		

;				ld a,0h							; for testing only
;				ld (hw_palette),a				; for testing only

				ret
	
;--------------------------------------------------------------------------------------------
; Table for equivalent EZ80P constants to Amiga period values
;--------------------------------------------------------------------------------------------
;
; Formula: (1/48828) / ((1/3579545) * period) * 65536   (IE: 4804396/period) 
;
; Starts at Amiga period 100, one 16-bit constant for each Amiga period. Runs up to period 950.

period_conv_table:

                db 0ABh,0BBh,0D0h,0B9h,0FDh,0B7h,034h,0B6h,074h,0B4h,0BCh,0B2h,00Ch,0B1h,064h,0AFh
                db 0C5h,0ADh,02Dh,0ACh,09Ch,0AAh,012h,0A9h,090h,0A7h,014h,0A6h,09Fh,0A4h,031h,0A3h
                db 0C9h,0A1h,067h,0A0h,00Bh,09Fh,0B5h,09Dh,064h,09Ch,019h,09Bh,0D4h,099h,094h,098h
                db 059h,097h,023h,096h,0F2h,094h,0C5h,093h,09Eh,092h,07Bh,091h,05Ch,090h,042h,08Fh
                db 02Ch,08Eh,01Bh,08Dh,00Dh,08Ch,004h,08Bh,0FEh,089h,0FCh,088h,0FEh,087h,004h,087h
                db 00Dh,086h,019h,085h,029h,084h,03Dh,083h,053h,082h,06Dh,081h,08Ah,080h,0AAh,07Fh
                db 0CEh,07Eh,0F4h,07Dh,01Dh,07Dh,049h,07Ch,077h,07Bh,0A9h,07Ah,0DDh,079h,014h,079h
                db 04Dh,078h,089h,077h,0C7h,076h,008h,076h,04Bh,075h,090h,074h,0D8h,073h,022h,073h
                db 06Fh,072h,0BDh,071h,00Eh,071h,060h,070h,0B5h,06Fh,00Ch,06Fh,065h,06Eh,0BFh,06Dh
                db 01Ch,06Dh,07Bh,06Ch,0DBh,06Bh,03Dh,06Bh,0A1h,06Ah,007h,06Ah,06Eh,069h,0D8h,068h
                db 043h,068h,0AFh,067h,01Dh,067h,08Dh,066h,0FEh,065h,071h,065h,0E6h,064h,05Bh,064h
                db 0D3h,063h,04Ch,063h,0C6h,062h,041h,062h,0BEh,061h,03Dh,061h,0BCh,060h,03Dh,060h
                db 0C0h,05Fh,043h,05Fh,0C8h,05Eh,04Eh,05Eh,0D5h,05Dh,05Eh,05Dh,0E8h,05Ch,072h,05Ch
                db 0FEh,05Bh,08Ch,05Bh,01Ah,05Bh,0A9h,05Ah,03Ah,05Ah,0CBh,059h,05Eh,059h,0F1h,058h
                db 086h,058h,01Bh,058h,0B2h,057h,04Ah,057h,0E2h,056h,07Ch,056h,016h,056h,0B1h,055h
                db 04Eh,055h,0EBh,054h,089h,054h,028h,054h,0C8h,053h,068h,053h,00Ah,053h,0ACh,052h
                db 04Fh,052h,0F3h,051h,098h,051h,03Eh,051h,0E4h,050h,08Bh,050h,033h,050h,0DCh,04Fh
                db 085h,04Fh,02Fh,04Fh,0DAh,04Eh,086h,04Eh,032h,04Eh,0DFh,04Dh,08Ch,04Dh,03Bh,04Dh
                db 0EAh,04Ch,099h,04Ch,04Ah,04Ch,0FAh,04Bh,0ACh,04Bh,05Eh,04Bh,011h,04Bh,0C5h,04Ah
                db 079h,04Ah,02Dh,04Ah,0E2h,049h,098h,049h,04Fh,049h,006h,049h,0BDh,048h,075h,048h
                db 02Eh,048h,0E7h,047h,0A1h,047h,05Bh,047h,016h,047h,0D1h,046h,08Dh,046h,049h,046h
                db 006h,046h,0C4h,045h,082h,045h,040h,045h,0FFh,044h,0BEh,044h,07Eh,044h,03Eh,044h
                db 0FFh,043h,0C0h,043h,082h,043h,044h,043h,006h,043h,0C9h,042h,08Ch,042h,050h,042h
                db 014h,042h,0D9h,041h,09Eh,041h,064h,041h,029h,041h,0F0h,040h,0B6h,040h,07Dh,040h
                db 045h,040h,00Dh,040h,0D5h,03Fh,09Eh,03Fh,067h,03Fh,030h,03Fh,0FAh,03Eh,0C4h,03Eh
                db 08Eh,03Eh,059h,03Eh,024h,03Eh,0F0h,03Dh,0BBh,03Dh,088h,03Dh,054h,03Dh,021h,03Dh
                db 0EEh,03Ch,0BCh,03Ch,08Ah,03Ch,058h,03Ch,026h,03Ch,0F5h,03Bh,0C4h,03Bh,094h,03Bh
                db 063h,03Bh,033h,03Bh,004h,03Bh,0D4h,03Ah,0A5h,03Ah,076h,03Ah,048h,03Ah,01Ah,03Ah
                db 0ECh,039h,0BEh,039h,091h,039h,064h,039h,037h,039h,00Bh,039h,0DEh,038h,0B2h,038h
                db 087h,038h,05Bh,038h,030h,038h,005h,038h,0DAh,037h,0B0h,037h,086h,037h,05Ch,037h
                db 032h,037h,009h,037h,0DFh,036h,0B6h,036h,08Eh,036h,065h,036h,03Dh,036h,015h,036h
                db 0EDh,035h,0C6h,035h,09Eh,035h,077h,035h,050h,035h,02Ah,035h,003h,035h,0DDh,034h
                db 0B7h,034h,091h,034h,06Ch,034h,046h,034h,021h,034h,0FCh,033h,0D7h,033h,0B3h,033h
                db 08Eh,033h,06Ah,033h,046h,033h,022h,033h,0FFh,032h,0DCh,032h,0B8h,032h,095h,032h
                db 073h,032h,050h,032h,02Dh,032h,00Bh,032h,0E9h,031h,0C7h,031h,0A6h,031h,084h,031h
                db 063h,031h,041h,031h,020h,031h,000h,031h,0DFh,030h,0BEh,030h,09Eh,030h,07Eh,030h
                db 05Eh,030h,03Eh,030h,01Eh,030h,0FFh,02Fh,0E0h,02Fh,0C0h,02Fh,0A1h,02Fh,083h,02Fh
                db 064h,02Fh,045h,02Fh,027h,02Fh,009h,02Fh,0EAh,02Eh,0CDh,02Eh,0AFh,02Eh,091h,02Eh
                db 074h,02Eh,056h,02Eh,039h,02Eh,01Ch,02Eh,0FFh,02Dh,0E2h,02Dh,0C6h,02Dh,0A9h,02Dh
                db 08Dh,02Dh,070h,02Dh,054h,02Dh,038h,02Dh,01Dh,02Dh,001h,02Dh,0E5h,02Ch,0CAh,02Ch
                db 0AFh,02Ch,093h,02Ch,078h,02Ch,05Dh,02Ch,043h,02Ch,028h,02Ch,00Dh,02Ch,0F3h,02Bh
                db 0D9h,02Bh,0BFh,02Bh,0A5h,02Bh,08Bh,02Bh,071h,02Bh,057h,02Bh,03Eh,02Bh,024h,02Bh
                db 00Bh,02Bh,0F2h,02Ah,0D8h,02Ah,0BFh,02Ah,0A7h,02Ah,08Eh,02Ah,075h,02Ah,05Dh,02Ah
                db 044h,02Ah,02Ch,02Ah,014h,02Ah,0FCh,029h,0E4h,029h,0CCh,029h,0B4h,029h,09Ch,029h
                db 085h,029h,06Dh,029h,056h,029h,03Fh,029h,027h,029h,010h,029h,0F9h,028h,0E3h,028h
                db 0CCh,028h,0B5h,028h,09Fh,028h,088h,028h,072h,028h,05Ch,028h,045h,028h,02Fh,028h
                db 019h,028h,003h,028h,0EEh,027h,0D8h,027h,0C2h,027h,0ADh,027h,097h,027h,082h,027h
                db 06Dh,027h,058h,027h,043h,027h,02Eh,027h,019h,027h,004h,027h,0EFh,026h,0DAh,026h
                db 0C6h,026h,0B1h,026h,09Dh,026h,089h,026h,075h,026h,060h,026h,04Ch,026h,038h,026h
                db 025h,026h,011h,026h,0FDh,025h,0E9h,025h,0D6h,025h,0C2h,025h,0AFh,025h,09Ch,025h
                db 088h,025h,075h,025h,062h,025h,04Fh,025h,03Ch,025h,029h,025h,016h,025h,004h,025h
                db 0F1h,024h,0DEh,024h,0CCh,024h,0B9h,024h,0A7h,024h,095h,024h,083h,024h,070h,024h
                db 05Eh,024h,04Ch,024h,03Ah,024h,029h,024h,017h,024h,005h,024h,0F3h,023h,0E2h,023h
                db 0D0h,023h,0BFh,023h,0ADh,023h,09Ch,023h,08Bh,023h,07Ah,023h,068h,023h,057h,023h
                db 046h,023h,035h,023h,024h,023h,014h,023h,003h,023h,0F2h,022h,0E2h,022h,0D1h,022h
                db 0C1h,022h,0B0h,022h,0A0h,022h,08Fh,022h,07Fh,022h,06Fh,022h,05Fh,022h,04Fh,022h
                db 03Fh,022h,02Fh,022h,01Fh,022h,00Fh,022h,0FFh,021h,0EFh,021h,0E0h,021h,0D0h,021h
                db 0C1h,021h,0B1h,021h,0A2h,021h,092h,021h,083h,021h,073h,021h,064h,021h,055h,021h
                db 046h,021h,037h,021h,028h,021h,019h,021h,00Ah,021h,0FBh,020h,0ECh,020h,0DEh,020h
                db 0CFh,020h,0C0h,020h,0B2h,020h,0A3h,020h,094h,020h,086h,020h,078h,020h,069h,020h
                db 05Bh,020h,04Dh,020h,03Eh,020h,030h,020h,022h,020h,014h,020h,006h,020h,0F8h,01Fh
                db 0EAh,01Fh,0DCh,01Fh,0CFh,01Fh,0C1h,01Fh,0B3h,01Fh,0A5h,01Fh,098h,01Fh,08Ah,01Fh
                db 07Dh,01Fh,06Fh,01Fh,062h,01Fh,054h,01Fh,047h,01Fh,03Ah,01Fh,02Ch,01Fh,01Fh,01Fh
                db 012h,01Fh,005h,01Fh,0F8h,01Eh,0EAh,01Eh,0DDh,01Eh,0D0h,01Eh,0C4h,01Eh,0B7h,01Eh
                db 0AAh,01Eh,09Dh,01Eh,090h,01Eh,084h,01Eh,077h,01Eh,06Ah,01Eh,05Eh,01Eh,051h,01Eh
                db 045h,01Eh,038h,01Eh,02Ch,01Eh,01Fh,01Eh,013h,01Eh,007h,01Eh,0FAh,01Dh,0EEh,01Dh
                db 0E2h,01Dh,0D6h,01Dh,0CAh,01Dh,0BDh,01Dh,0B1h,01Dh,0A5h,01Dh,099h,01Dh,08Dh,01Dh
                db 082h,01Dh,076h,01Dh,06Ah,01Dh,05Eh,01Dh,052h,01Dh,047h,01Dh,03Bh,01Dh,02Fh,01Dh
                db 024h,01Dh,018h,01Dh,00Dh,01Dh,001h,01Dh,0F6h,01Ch,0EAh,01Ch,0DFh,01Ch,0D4h,01Ch
                db 0C8h,01Ch,0BDh,01Ch,0B2h,01Ch,0A6h,01Ch,09Bh,01Ch,090h,01Ch,085h,01Ch,07Ah,01Ch
                db 06Fh,01Ch,064h,01Ch,059h,01Ch,04Eh,01Ch,043h,01Ch,038h,01Ch,02Dh,01Ch,022h,01Ch
                db 018h,01Ch,00Dh,01Ch,002h,01Ch,0F8h,01Bh,0EDh,01Bh,0E2h,01Bh,0D8h,01Bh,0CDh,01Bh
                db 0C3h,01Bh,0B8h,01Bh,0AEh,01Bh,0A3h,01Bh,099h,01Bh,08Eh,01Bh,084h,01Bh,07Ah,01Bh
                db 06Fh,01Bh,065h,01Bh,05Bh,01Bh,051h,01Bh,047h,01Bh,03Ch,01Bh,032h,01Bh,028h,01Bh
                db 01Eh,01Bh,014h,01Bh,00Ah,01Bh,000h,01Bh,0F6h,01Ah,0ECh,01Ah,0E3h,01Ah,0D9h,01Ah
                db 0CFh,01Ah,0C5h,01Ah,0BBh,01Ah,0B2h,01Ah,0A8h,01Ah,09Eh,01Ah,095h,01Ah,08Bh,01Ah
                db 081h,01Ah,078h,01Ah,06Eh,01Ah,065h,01Ah,05Bh,01Ah,052h,01Ah,048h,01Ah,03Fh,01Ah
                db 036h,01Ah,02Ch,01Ah,023h,01Ah,01Ah,01Ah,010h,01Ah,007h,01Ah,0FEh,019h,0F5h,019h
                db 0EBh,019h,0E2h,019h,0D9h,019h,0D0h,019h,0C7h,019h,0BEh,019h,0B5h,019h,0ACh,019h
                db 0A3h,019h,09Ah,019h,091h,019h,088h,019h,07Fh,019h,076h,019h,06Eh,019h,065h,019h
                db 05Ch,019h,053h,019h,04Ah,019h,042h,019h,039h,019h,030h,019h,028h,019h,01Fh,019h
                db 016h,019h,00Eh,019h,005h,019h,0FDh,018h,0F4h,018h,0ECh,018h,0E3h,018h,0DBh,018h
                db 0D3h,018h,0CAh,018h,0C2h,018h,0B9h,018h,0B1h,018h,0A9h,018h,0A0h,018h,098h,018h
                db 090h,018h,088h,018h,080h,018h,077h,018h,06Fh,018h,067h,018h,05Fh,018h,057h,018h
                db 04Fh,018h,047h,018h,03Fh,018h,037h,018h,02Fh,018h,027h,018h,01Fh,018h,017h,018h
                db 00Fh,018h,007h,018h,0FFh,017h,0F7h,017h,0F0h,017h,0E8h,017h,0E0h,017h,0D8h,017h
                db 0D0h,017h,0C9h,017h,0C1h,017h,0B9h,017h,0B2h,017h,0AAh,017h,0A2h,017h,09Bh,017h
                db 093h,017h,08Ch,017h,084h,017h,07Dh,017h,075h,017h,06Dh,017h,066h,017h,05Fh,017h
                db 057h,017h,050h,017h,048h,017h,041h,017h,03Ah,017h,032h,017h,02Bh,017h,024h,017h
                db 01Ch,017h,015h,017h,00Eh,017h,006h,017h,0FFh,016h,0F8h,016h,0F1h,016h,0EAh,016h
                db 0E3h,016h,0DBh,016h,0D4h,016h,0CDh,016h,0C6h,016h,0BFh,016h,0B8h,016h,0B1h,016h
                db 0AAh,016h,0A3h,016h,09Ch,016h,095h,016h,08Eh,016h,087h,016h,080h,016h,079h,016h
                db 072h,016h,06Ch,016h,065h,016h,05Eh,016h,057h,016h,050h,016h,049h,016h,043h,016h
                db 03Ch,016h,035h,016h,02Eh,016h,028h,016h,021h,016h,01Ah,016h,014h,016h,00Dh,016h
                db 006h,016h,000h,016h,0F9h,015h,0F3h,015h,0ECh,015h,0E6h,015h,0DFh,015h,0D9h,015h
                db 0D2h,015h,0CCh,015h,0C5h,015h,0BFh,015h,0B8h,015h,0B2h,015h,0ABh,015h,0A5h,015h
                db 09Fh,015h,098h,015h,092h,015h,08Bh,015h,085h,015h,07Fh,015h,079h,015h,072h,015h
                db 06Ch,015h,066h,015h,05Fh,015h,059h,015h,053h,015h,04Dh,015h,047h,015h,040h,015h
                db 03Ah,015h,034h,015h,02Eh,015h,028h,015h,022h,015h,01Ch,015h,016h,015h,010h,015h
                db 00Ah,015h,004h,015h,0FEh,014h,0F8h,014h,0F2h,014h,0ECh,014h,0E6h,014h,0E0h,014h
                db 0DAh,014h,0D4h,014h,0CEh,014h,0C8h,014h,0C2h,014h,0BCh,014h,0B6h,014h,0B1h,014h
                db 0ABh,014h,0A5h,014h,09Fh,014h,099h,014h,093h,014h,08Eh,014h,088h,014h,082h,014h
                db 07Ch,014h,077h,014h,071h,014h,06Bh,014h,066h,014h,060h,014h,05Ah,014h,055h,014h
                db 04Fh,014h,049h,014h,044h,014h,03Eh,014h,039h,014h,033h,014h,02Eh,014h,028h,014h
                db 022h,014h,01Dh,014h,017h,014h,012h,014h,00Ch,014h,007h,014h,001h,014h,0FCh,013h
                db 0F7h,013h,0F1h,013h,0ECh,013h,0E6h,013h,0E1h,013h,0DCh,013h,0D6h,013h,0D1h,013h
                db 0CBh,013h,0C6h,013h,0C1h,013h
				
				
;----------------------------------------------------------------------------------------
; EZ80P specific code ends
;----------------------------------------------------------------------------------------

