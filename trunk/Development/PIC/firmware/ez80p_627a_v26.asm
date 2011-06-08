; -------------------------------------------------------
; PIC 16F627A Spartan3 XC3S200 FPGA config code for EZ80P
; -------------------------------------------------------
;
; By Phil Ruston 2010
;
;           v.26....... SST25VF chip support added (32MB)
;                       New command: $88,$5c = "Send eeprom capacity" (should be used in favour of "Get EEPROM ID")
;                       New command: $88,$71 = "Request PIC sends the slot it last configured from" (MSB of the config base address/2)
;                       New command: $88,$79  = "Request PIC sends the EEPROM type byte" ($00 = 25X, $01 = 25VF)
;                       Removed 128-byte write command
;
; ----------------------------------------------------------------------------------------------------------------------
;
;  Pin connections:
;  ----------------
;
;							16F627/8A
;                            ___   __
;		 					|   '-'  |
;		 EEPROM /CS   <- A2 |1     18| A1 -> EEPROM CLK
;         FPGA CCLK   <- A3 |2     17| A0 -> EEPROM D_IN
;		  FPGA DONE   -> A4 |3     16| XTAL 20MHz
;    FPGA p81 COM CLK -> A5 |4     15| XTAL 20MHz
;	 				    GND |5     14| 3.3V
;	    EEPROM D_OUT  -> B0 |6     13| B7 -> FPGA PROGRAM
;		   FPGA INIT  -> B1 |7     12| B6 -> RED LED
; FPGA p65 COMMS CLK  <- B2 |8     11| B5 -> GREEN LED
;            /BUTTON  -> B3 |9     10| B4 -> SYSTEM /RESET OUT
;					        |________|
;
;  Notes: 
;
; * Connections to dedicated FPGA pins (DONE, PROGRAM, CCLK) must have current limit resistors 
;   (270 ohm) as these pins are powered from VCCAUX (2.5v) on the Spartan 3. 
;
; * The data direction of B0 is temporarily switched to output when the PIC needs to send data
;   to the FPGA
;
; * "/BUTTON" pulls the pin low.
;
;
;			            25X-- SPI EEPROM
;					       .---_----.
;			           /CS |1      8| 3.3V              
;			         D_OUT |2      7| /HOLD           
;			            WP |3      6| CLK     
;					   GND |4      5| D_IN     
;			               |________|
;
;  Notes:
;  
;  * "/HOLD" and "WP" tied to Vcc.
;
;  * "/CS" to VCC via 10K resistor (to ensure good start-up, as per datasheet)
; 
; * "D_OUT" becomes hi-impedance when chip is unselected so weak pull-up advised to prevent floating input at FPGA.
;
;-----------------------------------------------------------------------------------------------------------------------
; Post configuration commands: Send commands using "COMMS_CLOCK_IN" (clock) and "INIT" (data) - bytes should be sent MSB
; first, bits are clocked by the PIC on the rising edge of the clock. Max bitrate ~ 100KHz, min bitrate ~ 7 Hz  
; ----------------------------------------------------------------------------------------------------------------------

; CONFIG:
; -------
; $88, $a1, $3f, $62 = Reconfigure FPGA from current config address base (and reset cpu)
; $88, $b8, $16, $slot = Change config slot
; $88, $37, $d8, $06 = make current FPGA config base address permanent (in PIC's EEPROM)*


; DATABURST:
; ----------
; $88, $d4, $low, $middle, $high address bytes = Set databurst start address
; $88, $e2, $low, $middle, $high count bytes = Set databurst length
; $88, $c0 = send databurst to FPGA using current databurst base address and length


; CONTROL:
; --------
; $88, $25, $fa, $99 = Enable EEPROM programming (set programming permission to 1)
; $88, $1f = Disable EEPROM programming (set programming permission to 0) 


; WRITE TO EEPROM:
; ----------------
; $88, $f5, $low, $middle, $high address bytes = Erase 64KB block of EEPROM ($middle and $low = 00)*
; $88, $98, $low, $middle, $high address bytes, 64 data bytes = Program bytes into EEPROM #*
; $88, $8b, $xx = write $xx to EEPROM's Status Register (IE: Set protection bits: Irrelevant on SST25VF)*


; GET INFO:
; ---------
; $88, $5c = Request PIC sends EEPROM capacity (in 128K slots)
; $88, $76 = Request PIC sends the power-on boot slot
; $88, $71 = Request PIC sends the slot it last configured from (MSB of the config base address used/2)
; $88, $4e = Request PIC sends the firmware version
; $88, $06 = Request EEPROM sends its Status Register (read the protection bits, bit 7 always reported as zero)
; $88, $69 = Request PIC sends the "programming permission" status (0= programming disallowed, 1 = allowed)
; $88, $79 = Request PIC sends the EEPROM type byte ($00 = original 25Xabc, $01 = SST25VFabc)
; $88, $53 = Request EEPROM sends its ID byte [OBSOLETE! use capacity request command instead: $88,$5c]

; * - Programming mode must be enabled first
; # - The 64KB EEPROM block in which the bytes are to be located must be erased prior to programming new data

;-----------------------------------------------------------------------------------------------------------

; Comms protocol:

; Databurst:
; ----------

; First, set up read length / location with appropriate commands..

; 1. Host clears receive buffer
; 2. Host sends command code sequence
; 3. Host waits for "OK" command acknowledge byte from PIC
; 4. Host sets com data_out high
; 5. Host waits for data byte in receive buffer - reads/stores it
; 6. Host sets com data_out low
; 7. Host waits for data byte in receive buffer - reads/stores it
; 8. Loop to step 4 until all bytes received.

; All other commands:
; -------------------
; 1. Host clears receive buffer
; 2. Host sends command code sequence (incl any arguments)
; 3. Host wait for byte in receive buffer - reads it
; 4. If MSB of byte is set - there was an error:
;     0x8c = "Bad command" 
;     0x8b = "Write timed out"
;     0x8f = "Writes are disabled"  
;    Else OK / data in [6:0]

;--- GENERIC HEADER AND CLOCK OPTIONS ----------------------------------------------------------------------

	list    p=16f627A           				 ; list directive to define processor
	list	r=decimal

	#include <p16f627A.inc>       				 ; processor specific variable definitions

	#define skipifzero        btfss STATUS,Z        
	#define skipifnotzero     btfsc STATUS,Z
	#define skipifcarry       btfss STATUS,C        
	#define skipifnotcarry    btfsc STATUS,C
	#define skipifborrow      btfsc STATUS,C        
	#define skipifnotborrow   btfss STATUS,C

	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _MCLRE_OFF & _LVP_OFF


;-----Defaults ----------------------------------------------------------------------------------------

firmware_vers		equ 0x26

fpga_config_length 	equ 130952	 				; Length of FPGA's .bin config file (FPGA: XC3S200)
						
databurst_address	equ 0x0						; Default location of databurst in EEPROM
databurst_length	equ 2048					; Default length of databurst (2KB)

;----- Project Variables -------------------------------------------------------------------------------

temp1				EQU     0x20
temp2				EQU		0x21
temp3				EQU		0x22
bitcount			EQU     0x23
bytecount_h			EQU		0x24
bytecount_m			EQU		0x25
bytecount_l			EQU		0x26

config_base_low		EQU		0x27
config_base_med		EQU		0x28
config_base_high	EQU		0x29

eeprom_address_low	EQU		0x2a
eeprom_address_med	EQU		0x2b
eeprom_address_high	EQU		0x2c

databurst_base_low	EQU		0x2d
databurst_base_med	EQU		0x2e
databurst_base_high	EQU		0x2f
databurst_len_low	EQU     0x30
databurst_len_med	EQU		0x31
databurst_len_high	EQU     0x32

received_byte		EQU		0x33
allow_program		EQU     0x34
time_out			EQU     0x35
buffer_count		EQU     0x36
flash_count			EQU 	0x37
slot_cycle			EQU     0x38
temp4				EQU     0x39
byte_to_send		EQU 	0x3a
protection_bits		EQU 	0x3b
ready_flip			EQU     0x3c
packet_size			EQU		0x3d
led_flash_accum		EQU		0x3e
clock_out_value		EQU		0x3f

pic_eeprom_addr			EQU		0x70
eeprom_size				EQU		0x71
salvo					EQU		0x72
eeprom_id				EQU 	0x73
configured_from_slot	EQU		0x74
eeprom_type				EQU		0x75

;-----------------------------------------------------------------------------
; NOTE: SRAM Locations 0xA0-0xEF used for a data buffer when writing to EEPROM
;-----------------------------------------------------------------------------


;---  Project constants ---------------------------------------------------------------------

eeprom_data_in		equ 0	;out			Port A bit assignments
eeprom_clock		equ 1	;out
eeprom_cs			equ	2	;out				 
fpga_cclk			equ 3	;out				 
fpga_done			equ 4	;in
comms_clock_in		equ 5	;in

eeprom_data_out		equ 0	;in				Port B bit assignments
fpga_init			equ 1	;in
comms_clock_out		equ 2	;out
button 				equ 3	;in
reset_out			equ 4	;out
green_led			equ 5	;out
red_led				equ 6	;out
fpga_program  		equ 7   ;out				 

;25X series eeprom commands:

spi_write_sr_cmd	equ 0x01
spi_write_page_cmd	equ 0x02
spi_read_cmd		equ 0x03
spi_read_status_cmd	equ 0x05
spi_write_en_cmd	equ 0x06
spi_id_cmd			equ 0xab
spi_erase_cmd		equ 0xd8

; 25VF series eeprom commands:

sst_aai_write_cmd	equ 0xad	
sst_wrdi_cmd		equ 0x04

porta_default		equ (1<<eeprom_cs)						; EEPROM /CS inactive
portb_default		equ (1<<fpga_program)+(1<<reset_out)	; FPGA program high (inactive) / reset high (inactive)

;*****************************************************************************************************

	ORG     0x000      			 							; processor reset vector

			goto init_code    								; go to beginning of program

	ORG     0x004       									; interrupt vector location

			retfie            								; return from interrupt

;---------- INITIALIZE PIC FOR THIS PROJECT ----------------------------------------------------------

init_code	movlw b'00000111'		
			movwf CMCON										; use digital mode for PORTA (disable comparitors)
			banksel TRISA
			movlw b'00110000'								; set data direction for port A
			movwf TRISA
			movlw b'00001011'								; set data direction for port B
			movwf TRISB
			banksel PORTA

			movlw porta_default							
			movwf PORTA
			movlw portb_default								
			movwf PORTB											

;---------------------------------------------------------------------------------------------------------------
; Init code
;---------------------------------------------------------------------------------------------------------------

main_start
			movlw 0												; get default values for FPGA config location from PIC's flash RAM
			call pic_eeprom_read
			movwf config_base_low
			movlw 1										
			call pic_eeprom_read
			movwf config_base_med
			movlw 2											
			call pic_eeprom_read
			movwf config_base_high

			movlw databurst_address & 0xff						; set default values for databurst loc/len	
			movwf databurst_base_low
			movlw (databurst_address >> 8) & 0xff
			movwf databurst_base_med
			movlw (databurst_address >> 16) & 0xff					
			movwf databurst_base_high
			movlw (0x1000000-databurst_length) & 0xff		
			movwf  databurst_len_low
			movlw ((0x1000000-databurst_length) >> 8) & 0xff
			movwf databurst_len_med
			movlw ((0x1000000-databurst_length) >> 16) & 0xff
			movwf databurst_len_high

			clrf allow_program
			clrf led_flash_accum


configure_fpga
		
			call disallow_programming							; PIC/EEPROM programming disabled by default (software flag)	

			movlw porta_default									; deselect the EEPROM (set its /CS = high)
			movwf PORTA
			movlw portb_default									; set FPGA program and sys_reset lines inactive
			movwf PORTB											

			call short_pause

			call read_eeprom_id


;----------- JTAG Mode? ------------------------------------------------------------------------------------------------------

check_jtag	btfsc PORTB,button									; Button held = JTAG CONFIG, else configure as normal
			goto go_configure									
			
			call wait_button_release							; wait for button to be released (debounced)

wait_jtag	movlw 0xf8											; JTAG mode: Flash green LED quickly until JTAG config completed
			movwf temp2											; ie: DONE is high
			clrf temp1
chk_done	btfss PORTA,fpga_done								
			goto done_low
			incfsz temp1,f										; resample "done" - ensure it is permanently high
			goto chk_done
			incfsz temp2,f
			goto chk_done
			goto fpga_done_hi									; when JTAG config complete, reset CPU and wait for commands.

done_low	movlw portb_default+(1<<green_led)					; flash green LED when waiting for JTAG config			
			movwf PORTB											; LED: on
			call short_pause_esc_if_done
			movlw portb_default									; LED: off
			movwf PORTB				
			call short_pause_esc_if_done

chkjtag2	btfsc PORTB,button									; if button pressed (again) in JTAG config mode, go to manual slot setting
			goto wait_jtag										; procedure


;---------- Manual active slot setting system --------------------------------------------------------------------------------

			call wait_button_release							; wait for button to be released (debounced)
			call long_pause										
					
mset_slot	clrf slot_cycle
slot_loop	clrf salvo
			movf slot_cycle,w		
			addlw 1
			movwf temp4
s2_ledfl	call long_pause										; flash the LED "SLOT" number of times
			bsf PORTB,red_led								
			call long_pause
			bcf PORTB,red_led			
			incf salvo,f										; put a extra pause between groups of 4 flashes to make interpretation easier
			movf salvo,w
			xorlw 4
			skipifzero
			goto no_gap
			clrf salvo
			call long_pause
no_gap		decfsz temp4,f
			goto s2_ledfl

			movlw 75
			movwf temp3											
wait_but	btfss PORTB,button									; wait about 4 seconds - if button pressed, set the slot
			goto set_slot									
			call short_pause
			decfsz temp3,f
			goto wait_but

			incf slot_cycle,f									
			movf eeprom_size,w
			xorwf slot_cycle,w
			skipifzero		
			goto slot_loop
			goto mset_slot


set_slot	clrf pic_eeprom_addr								; write the slot number	to PIC flashram
			movlw 0											
			call pic_eeprom_write							
			incf pic_eeprom_addr,f								
			movlw 0
			call pic_eeprom_write
			incf pic_eeprom_addr,f
			movf slot_cycle,w
			call pic_eeprom_write

			call wait_button_release							; wait for button to be released. Config from select slot then takes place.
			call long_pause
			goto main_start									


;----------- Configure FPGA - Slave Serial mode via PIC and EEPROM ----------------------------------------------------------------------

go_configure

			bcf PORTB,fpga_program								; force reload config on FPGA
			call short_pause									; IE: pulse "Program" low
			bsf PORTB,fpga_program
			call short_pause

wait_init_1	btfss PORTB,fpga_init								; wait for FPGA to be ready (fpga_init = high)
			goto wait_init_1									; before sending data

			movlw ((0x1000000-fpga_config_length) >> 16) & 0xff					
			movwf  bytecount_h
			movlw ((0x1000000-fpga_config_length) >> 8) & 0xff
			movwf  bytecount_m
			movlw (0x1000000-fpga_config_length) & 0xff			
			movwf  bytecount_l


;---------- Send sequential read command to SPI EEPROM -----------------------------------------------------------------------------------


			call select_eeprom									; select EEPROM (new instruction)
			movlw spi_read_cmd									; send read data command ($03) to SPI EEPROM 
			call send_byte_to_eeprom						
			movf config_base_high,w								; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf config_base_med,w
			call send_byte_to_eeprom
			movf config_base_low,w		
			call send_byte_to_eeprom


;---------- Read the data from EEPROM and configure the FPGA  ------------------------------------------------------------------------------


read_loop	movlw (1<<eeprom_clock)+(1<<fpga_cclk)				;W = EEPROM and FPGA clocks = high
			movwf PORTA											;fpga latches bit 7
			CLRF PORTA											;spi eeprom shifts out bit 6
			movwf PORTA											;fpga latches bit 6		
			CLRF PORTA											;spi eeprom shifts out bit 5	
			movwf PORTA											;fpga latches bit 5
			CLRF PORTA											;spi eeprom shifts out bit 4
			movwf PORTA											;fpga latches bit 4
			CLRF PORTA											;spi eeprom shifts out bit 3
			movwf PORTA											;fpga latches bit 3
			CLRF PORTA											;spi eeprom shifts out bit 2
			movwf PORTA											;fpga latches bit 2
			CLRF PORTA											;spi eeprom shifts out bit 1
			movwf PORTA											;fpga latches bit 1
			CLRF PORTA											;spi eeprom shifts out bit 0
			movwf PORTA											;fpga latches bit 0
			CLRF PORTA											;spi eeprom shifts out bit 7

			incfsz bytecount_l,f								;count bytes sent - loop if more to go
			goto read_loop					
			incfsz bytecount_m,f			
			goto read_loop					
			incfsz bytecount_h,f
			goto read_loop


;---------- Check FPGA configured OK -------------------------------------------------------------------------------------------------------------------

			call deselect_eeprom								;  Deselect the EEPROM (set its /CS = high)

			call vshort_pause

			btfsc PORTA,fpga_done								; All bytes sent - Check that the FPGA started up 
			goto fpga_done_hi									; (Its "DONE" line should be high now)

			bsf PORTB,green_led									; If not,flash the green LED once and re-try							
			call long_pause
			call long_pause
			bcf PORTB,green_led
			call long_pause
			call long_pause
  			goto configure_fpga				

fpga_done_hi

			call reset_pulse									; FPGA configured, reset the CPU
			
			bcf STATUS,C
			rrf config_base_high,w
			movwf configured_from_slot							; note the slot that the FPGA last configured from

;--------------------------------------------------------------------------------------------------------------------			
; After config, wait for commands from CPU (via FPGA) - At the same time check button (which now acts as system reset)
;--------------------------------------------------------------------------------------------------------------------

wait_command

			movlw portb_default+(1<<green_led)					; Normally, GREEN LED on = FPGA configured / PIC waiting for command..	
			btfsc allow_program,0
			movlw portb_default+(1<<red_led)					; (if PIC/EEPROM programming enabled, RED LED is on instead)
			movwf PORTB

wait_cmd_lp	clrf temp1											; pressed button? Button must be held for 256 loops to do a system reset
sysrescnt	btfsc PORTB,button
			goto no_reset
			incfsz temp1,f
			goto sysrescnt
			call reset_pulse
			call disallow_programming
			movlw portb_default+(1<<green_led)						
			movwf PORTB
			call wait_button_release							; after reset pulse, wait for button to be released
			goto wait_command

no_reset	call get_byte_from_fpga								; all commands must begin with $88
			xorlw 0x88
			skipifzero
			goto wait_cmd_lp

			call get_byte_from_fpga								; next byte is the actual command code
		
			movf received_byte,w
			xorlw 0xa1
			skipifnotzero
			goto configure_fpga_test

			movf received_byte,w
			xorlw 0xb8
			skipifnotzero
			goto set_config_slot

			movf received_byte,w
			xorlw 0x37
			skipifnotzero
			goto make_slot_permanent

			movf received_byte,w
			xorlw 0xc0
			skipifnotzero
			goto send_databurst_to_fpga
			
			movf received_byte,w
			xorlw 0xd4
			skipifnotzero
			goto set_databurst_start_address

			movf received_byte,w
			xorlw 0xe2
			skipifnotzero
			goto set_databurst_length

			movf received_byte,w
			xorlw 0xf5
			skipifnotzero
			goto erase_eeprom_block

			movf received_byte,w
			xorlw 0x98
			skipifnotzero
			goto write_bytes_to_eeprom

			movf received_byte,w
			xorlw 0x25
			skipifnotzero
			goto set_programming_mode

			movf received_byte,w
			xorlw 0x1f
			skipifnotzero
			goto exit_programming_mode

			movf received_byte,w
			xorlw 0x53
			skipifnotzero
			goto report_chip_id

			movf received_byte,w
			xorlw 0x76
			skipifnotzero
			goto report_boot_slot

			movf received_byte,w
			xorlw 0x4e
			skipifnotzero
			goto report_firmware_vers

			movf received_byte,w
			xorlw 0x8b
			skipifnotzero
			goto set_protection_bits

			movf received_byte,w
			xorlw 0x06
			skipifnotzero
			goto read_status_register

			movf received_byte,w
			xorlw 0x69
			skipifnotzero
			goto return_programming_permission

			movf received_byte,w
			xorlw 0x5c
			skipifnotzero
			goto report_eeprom_capacity

			movf received_byte,w
			xorlw 0x71
			skipifnotzero
			goto report_configured_from_slot

			movf received_byte,w
			xorlw 0x79
			skipifnotzero
			goto report_eeprom_type

			goto wait_cmd_lp

;=====================================================================================================================

configure_fpga_test

			call get_byte_from_fpga								
			btfsc time_out,0
			goto bad_command
			xorlw 0x3f											; next command code byte should be $3f..
			skipifzero
			goto bad_command
			call get_byte_from_fpga								
			btfsc time_out,0
			goto bad_command
			xorlw 0x62											; next command code byte should be $62..
			skipifzero
			goto bad_command
			goto configure_fpga

;=====================================================================================================================

return_programming_permission

			movf allow_program,w								; returns value of "program permission" flag (as set by
			andlw 0x01
			call send_w_to_fpga 								; allow/disallow programming commands)
			goto wait_command

;=====================================================================================================================

read_status_register

			call select_eeprom
			movlw spi_read_status_cmd							; send EEPROM "READ STATUS" command
			call send_byte_to_eeprom

			call get_byte_from_eeprom							; read the EEPROM's Status Register
			movwf received_byte
			call deselect_eeprom							   	; deselect the EEPROM (set its /CS = high)

			movf received_byte,w														
			andlw 0x7f											; ensure MSB is clear to avoid being interpreted as an error code
			call send_w_to_fpga								    ; send ID byte to FPGA
			goto wait_command

;=====================================================================================================================

set_protection_bits

			call get_byte_from_fpga								
			btfsc time_out,0
			goto bad_command
			xorlw 0x8b											; next command code byte should be $8b..
			skipifzero
			goto bad_command

			call get_byte_from_fpga								; wait for the new protection setting byte from the FPGA
			btfsc time_out,0
			goto bad_command
			andlw 0xfc
			movwf protection_bits

			btfss allow_program,0								; cannot proceed if host has not previously sent command to unlock writes
			goto cant_program									

			movlw portb_default+(1<<red_led)+(1<<green_led)		; both LEDs on during eeprom write command
			movwf PORTB											

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_en_cmd								; send EEPROM "WRITE ENABLE" command
			call send_byte_to_eeprom
			call deselect_eeprom

			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set
			btfsc time_out,0
			goto write_timed_out
			
			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_sr_cmd								; send EEPROM "Write to status register" command 
			call send_byte_to_eeprom
			movf protection_bits,w								; send the protection settings byte 
			call send_byte_to_eeprom
			call deselect_eeprom								; deselecting the SPI EEPROM initiates the EEPROM's internal programming operation
	
			call wait_eeprom_busy								; wait for write to finish
			btfsc time_out,0
			goto write_timed_out
			call send_ok_ack
			goto wait_command

;=====================================================================================================================

report_firmware_vers

			movlw firmware_vers		
			andlw 0x7f											; ensure MSB is clear to avoid being interpreted as an error code								
			call send_w_to_fpga									; send to FPGA
			goto wait_command

;=====================================================================================================================

report_chip_id

			movf eeprom_id,w									; THIS IS NOW OBSOLETE - DONT USE THIS					
			andlw 0x7f											; ensure MSB is clear to avoid being interpreted as an error code
			call send_w_to_fpga								    ; send ID byte to FPGA
			goto wait_command

;======================================================================================================================

report_eeprom_capacity

			movf eeprom_size,w														
			andlw 0x7f											; ensure MSB is clear to avoid being interpreted as an error code
			call send_w_to_fpga								    ; send ID byte to FPGA
			goto wait_command

;======================================================================================================================

report_eeprom_type

			movf eeprom_type,w														
			andlw 0x7f											; ensure MSB is clear to avoid being interpreted as an error code
			call send_w_to_fpga								    ; send ID byte to FPGA
			goto wait_command

;=====================================================================================================================

report_boot_slot

			movlw 2											
			call pic_eeprom_read								; get MSB of config base (slot * 2)
			movwf temp1
			bcf STATUS,C
			rrf temp1,w											; divide by 2 to give slot number
			call send_w_to_fpga
			goto wait_command

;=====================================================================================================================

report_configured_from_slot

			movf configured_from_slot,w
			call send_w_to_fpga
			goto wait_command

;=====================================================================================================================

set_config_slot

			call get_byte_from_fpga								
			btfsc time_out,0
			goto bad_command
			xorlw 0x16											; next command code byte should be $16..
			skipifzero
			goto bad_command

			call get_byte_from_fpga								; next byte is slot number
			btfsc time_out,0
			goto bad_command
			movwf temp1
			rlf temp1,w
			andlw 0xfe
			movwf config_base_high
			clrf config_base_med
			clrf config_base_low

			call send_ok_ack
			goto wait_command

;=====================================================================================================================

make_slot_permanent

			call get_byte_from_fpga								
			btfsc time_out,0
			goto bad_command
			xorlw 0xd8											; op requires code $d8..
			skipifzero
			goto bad_command
			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			xorlw 0x06											; ...followed by $06
			skipifzero
			goto bad_command

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									

			clrf pic_eeprom_addr								; write the received address to PIC's EEPROM memory.	
			movf config_base_low,w								; upon power on, the FPGA will get its config code from
			call pic_eeprom_write								; this address
			incf pic_eeprom_addr,f								
			movf config_base_med,w
			call pic_eeprom_write
			incf pic_eeprom_addr,f
			movf config_base_high,w
			call pic_eeprom_write

			call send_ok_ack
			goto wait_command

;=====================================================================================================================

set_databurst_start_address

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_base_low

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_base_med

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_base_high

			call send_ok_ack
			goto wait_command

;=====================================================================================================================

set_databurst_length

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_len_low

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_len_med

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf databurst_len_high

			call send_ok_ack
			goto wait_command

;=====================================================================================================================

send_databurst_to_fpga

			call send_ok_ack
	
			clrf bytecount_l									; subtract length from $1000000 for loop
			clrf bytecount_m
			clrf bytecount_h
        	movf databurst_len_low,w 						 	
        	subwf bytecount_l,f    								 
        	movf databurst_len_med,w 							 
        	skipifcarry                            				 
           	incfsz databurst_len_med,w 							 
            subwf bytecount_m,f									 
        	movf databurst_len_high,w    						 
        	skipifcarry
           	incfsz databurst_len_high,w
            subwf bytecount_h,f

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_read_cmd									; send read data command (0x03) to EEPROM 
			call send_byte_to_eeprom						
			movf databurst_base_high,w						    ; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf databurst_base_med,w
			call send_byte_to_eeprom
			movf databurst_base_low,w			
			call send_byte_to_eeprom

			clrf ready_flip

			movlw portb_default+(1<<comms_clock_out)+(1<<green_led)
			movwf clock_out_value			

rom_read_lp	incf ready_flip,f									; PIC requires INIT to change state between bytes
			btfss ready_flip,0
			goto waitdatalo
	
			movlw 0xfb											; this is the wait INIT = high routine for even bytes
			movwf temp3
			clrf temp2											
			clrf temp1											; PIC will wait about 0.5 seconds for this before timing out
wdbhi		btfsc PORTB,fpga_init					
			goto next_byte
			incfsz temp1,f										
			goto wdbhi										
			incfsz temp2,f
			goto wdbhi
			incfsz temp3,f
			goto wdbhi
			goto db_timeout

waitdatalo	movlw 0xfb											; this is the wait INIT = low routine for odd bytes
			movwf temp3
			clrf temp2											
			clrf temp1											; PIC will wait about 0.5 seconds for this before timing out
wdbilo		btfss PORTB,fpga_init				
			goto next_byte
			incfsz temp1,f										
			goto wdbilo										
			incfsz temp2,f
			goto wdbilo
			incfsz temp3,f
			goto wdbilo
			goto db_timeout

next_byte	movlw 8										  		; Clock out a byte from the EEPROM							
			movwf temp1											
rombit_lp	movfw clock_out_value					   	        ; set com clock hi = FPGA latches data bit 
			movwf PORTB
			xorlw (1<<comms_clock_out)		   					; return clock low
			movwf PORTB
			movlw (1<<eeprom_clock)								; set EEPROM clock high
			movwf PORTA												  	
			movlw 0
			movwf PORTA											; set EEPROM clock low = EEPROM shifts out a new bit				
			decfsz temp1,f
			goto rombit_lp
					
			incfsz bytecount_l,f								; count bytes sent - loop if more to go
			goto rom_read_lp					

			bcf clock_out_value,green_led						; handle led flash
			incf led_flash_accum,f								
			btfsc led_flash_accum,3
			bsf clock_out_value,green_led

			incfsz bytecount_m,f			
			goto rom_read_lp					
			incfsz bytecount_h,f
			goto rom_read_lp
			call deselect_eeprom								; all done - Deselect the EEPROM (set its /CS = high)
			goto wait_command									; and wait for next command

db_timeout	call deselect_eeprom								; deselect the EEPROM (set its /CS = high)
			movlw 4
			call flash_leds										; flash leds 4 times to signify time out error
			goto wait_command


;=====================================================================================================================

set_programming_mode

			call get_byte_from_fpga				
			btfsc time_out,0
			goto bad_command
			xorlw 0xfa											; command code requires 0xfa...
			skipifzero
			goto bad_command

			call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			xorlw 0x99											; then 0x99..								
			skipifzero
			goto bad_command
			call allow_programming
			
			call send_ok_ack
			goto wait_command

;=====================================================================================================================

exit_programming_mode

			call disallow_programming
			call send_ok_ack
			goto wait_command


;=====================================================================================================================

erase_eeprom_block

			call get_eeprom_address								; read in 3 bytes
			btfsc time_out,0
			goto bad_command

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address

			movlw portb_default+(1<<red_led)+(1<<green_led)		; both LEDs on during erase command
			movwf PORTB											
	
			call sst_write_enable
			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_en_cmd								; send EEPROM "WRITE ENABLE" command
			call send_byte_to_eeprom
			call deselect_eeprom

			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set
			btfsc time_out,0
			goto write_timed_out

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_erase_cmd									; send EEPROM "Erase Block" command 
			call send_byte_to_eeprom
			call send_eeprom_address							; send the 3 address bytes
			call deselect_eeprom								; deselecting the SPI EEPROM initiates the EEPROM's internal programming operation
	
			call short_pause

			call wait_eeprom_busy								; wait for EEPROMS's block erase to finish
			btfsc time_out,0
			goto write_timed_out
	
			call short_pause

			call sst_write_protect
			call send_ok_ack
			goto wait_command


;=====================================================================================================================

write_bytes_to_eeprom

			call get_eeprom_address								; get 3 bytes for write address
			btfsc time_out,0
			goto bad_command

			movlw 64
			movwf buffer_count									; get 64 bytes to program into EEPROM
			movlw 0xa0											
			movwf FSR											; temporarily store them in PIC RAM $a0-$df
readb_loop	call get_byte_from_fpga
			btfsc time_out,0
			goto bad_command
			movwf INDF
			incf FSR,f
			decfsz buffer_count,f
			goto readb_loop

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address/datapacket
	
			movlw portb_default+(1<<red_led)+(1<<green_led)		; flash LEDs during write command
			incf led_flash_accum,f
			btfsc led_flash_accum,3
			movwf PORTB											

			btfsc eeprom_type,0									; if EEPROM is SST type switch to appropriate programming code
			goto sst_write_bytes

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_en_cmd								; send "WRITE ENABLE" command
			call send_byte_to_eeprom
			call deselect_eeprom								; EEPROM /CS = High = End of instruction
														
			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set
			btfsc time_out,0
			goto write_timed_out

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_page_cmd							; send "Write Page" EEPROM command 
			call send_byte_to_eeprom
			call send_eeprom_address							; send the destination address
			movlw 64
			movwf buffer_count									; write the 64 bytes from PIC RAM to the EEPROM
			movlw 0xa0													
			movwf FSR											; read them from PIC RAM addresses $a0-$bf
writeb_loop	movf INDF,w
			call send_byte_to_eeprom
			incf FSR,f
			decfsz buffer_count,f
			goto writeb_loop

			call deselect_eeprom								; deselecting the EEPROM initiates its internal programming operation
			call wait_eeprom_busy								; wait for EEPROM's internal write operation to complete
			btfsc time_out,0
			goto write_timed_out
			call send_ok_ack
			goto wait_command


;---------------------------------------------------------------------------------------------------------------------

sst_write_bytes
			
			call sst_write_enable								; clear SR [5:2] 

			call select_eeprom
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			call deselect_eeprom
														
			call select_eeprom
			movlw sst_aai_write_cmd								; send SST style write bytes command 
			call send_byte_to_eeprom

			call send_eeprom_address							; and send the destination address

			movlw 0xa0													
			movwf FSR											; send first two bytes from $a0 and $a1
			movf INDF,w
			call send_byte_to_eeprom							; send byte 0
			incf FSR,f
			movf INDF,w
			call send_byte_to_eeprom							; send byte 1
			incf FSR,f

			call deselect_eeprom								; deselect the SPI EEPROM (set its /CS = high)
										
			call wait_eeprom_busy								; check EEPROM is not busy
			btfsc time_out,0
			goto write_timed_out

			movlw 31
			movwf buffer_count									; write the next 31 words from PIC RAM to the EEPROM

sstwr_loop	call select_eeprom
			movlw sst_aai_write_cmd								; send sst write bytes command again - no address this time 
			call send_byte_to_eeprom							

			movf INDF,w
			call send_byte_to_eeprom							; send byte 0
			incf FSR,f
			movf INDF,w
			call send_byte_to_eeprom							; send byte 1
			incf FSR,f

			call deselect_eeprom								

			call wait_eeprom_busy								; check EEPROM busy is clear
			btfsc time_out,0
			goto write_timed_out

			decfsz buffer_count,f
			goto sstwr_loop

			call select_eeprom
			movlw sst_wrdi_cmd									; terminate AAI command
			call send_byte_to_eeprom							
			call deselect_eeprom													

			call wait_eeprom_busy								; check EEPROM busy is clear
			btfsc time_out,0
			goto write_timed_out

			call sst_write_protect
			call send_ok_ack
			goto wait_command


;------------------------------------------------------------------------------------------------------------------------


sst_write_enable

			btfss eeprom_type,0									; is EEPROM an SST type? If so clear bits 5:2 of SR
			return												; These bits are volatile on SST EEPROMS not flash

			call select_eeprom									; send EEPROM "WRITE ENABLE" command
			movlw spi_write_en_cmd								
			call send_byte_to_eeprom
			call deselect_eeprom

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_sr_cmd								; send EEPROM "Write to status register" command 
			call send_byte_to_eeprom
			movlw 0x00											; clear the SR protection bits [5:2] 
			call send_byte_to_eeprom
			call deselect_eeprom								 
			return


;------------------------------------------------------------------------------------------------------------------------


sst_write_protect

			btfss eeprom_type,0									; is EEPROM an SST type? If so set bits 5:2 of SR
			return												; These bits are volatile on SST EEPROMS not flash

			call select_eeprom									; NOTE: THE SR protect bits are VOLATILE on the SST
			movlw spi_write_en_cmd								; send EEPROM "WRITE ENABLE" command
			call send_byte_to_eeprom
			call deselect_eeprom

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_sr_cmd								; send EEPROM "Write to status register" command 
			call send_byte_to_eeprom
			movlw 0x3c											; set all block protect bits [5:2] 
			call send_byte_to_eeprom
			call deselect_eeprom								
			return

			
;---------------------------------------------------------------------------------------------------------------------

bad_command

			movlw 0x8c											; send "bad command" error code (0x8c) to FPGA
			call send_w_to_fpga
			movlw 1
			call flash_leds
			goto wait_command									


;---------------------------------------------------------------------------------------------------------------------


cant_program

			movlw 0x8f											; send "programming disabled" error code (0x8f) to FPGA
			call send_w_to_fpga
			movlw 2
			call flash_leds
			goto wait_command


;---------------------------------------------------------------------------------------------------------------------


write_timed_out


			movlw 0x8b											; send "write timed out" error code (0x8b) to FPGA
			call send_w_to_fpga
			movlw 3
			call flash_leds
			goto wait_command


;---------------------------------------------------------------------------------------------------------------------

flash_leds

			movwf flash_count									; flash both leds W times
			
flashloop	movlw portb_default+(1<<green_led)+(1<<red_led)		
			movwf PORTB
			call long_pause
			movlw portb_default		
			movwf PORTB
			call long_pause
			
			decfsz flash_count,f
			goto flashloop
			return


;********** Called routines **************************************************************************************

wait_eeprom_wel

			clrf time_out
			call select_eeprom									; New EEPROM instruction
			movlw spi_read_status_cmd							; send EEPROM "READ STATUS" command
			call send_byte_to_eeprom

			clrf temp1
			clrf temp2
			movlw 0xfa		
			movwf temp3

wel_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfsc received_byte,1								; loop until write enable flag (WEL: bit 1) is set
			goto wel_high
			incfsz temp1,f
			goto wel_loop
			incfsz temp2,f
			goto wel_loop
			incfsz temp3,f
			goto wel_loop
			bsf time_out,0										; time out if waited more than ~5 seconds
			
wel_high	call deselect_eeprom								; deselect the EEPROM - end of instruction	
			return

;-------------------------------------------------------------------------------------------------------------------
						
wait_eeprom_busy

			clrf time_out
		
			clrf temp1											; short delay before first test
wip_pdelay	incfsz temp1,f
			goto wip_pdelay
						
			call select_eeprom									; Select EEPROM - New instruction
			movlw spi_read_status_cmd							; send EEPROM "READ STATUS" command
			call send_byte_to_eeprom

			clrf temp1
			clrf temp2
			movlw 0xfa		
			movwf temp3

wip_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfss received_byte,0								; until "write in progress busy" flag (BSY: bit 0) is clear
			goto wip_low
			incfsz temp1,f
			goto wip_loop
			incfsz temp2,f
			goto wip_loop
			incfsz temp3,f
			goto wip_loop
			bsf time_out,0										; time out if waited more than ~5 seconds
			goto busyw_end

wip_low		call get_byte_from_eeprom							; double check WIP flag is indeed low
			btfsc received_byte,0
			goto wip_loop

busyw_end	call deselect_eeprom								; deselect the EEPROM - end of instruction
			return

										
;-------------------------------------------------------------------------------------------------------------------

get_byte_from_eeprom

			clrf received_byte
			movlw 8
			movwf bitcount									
gbfe_loop	bcf STATUS,0										; clear carry flag
			rlf received_byte,f
			btfsc PORTB,eeprom_data_out
			bsf received_byte,0
			movlw (1<<eeprom_clock)								; raise the EEPROM clock line
			movwf PORTA
			nop
			nop
			nop
			clrf PORTA											; drop EEPROM clock line
			decfsz bitcount,f
			goto gbfe_loop
			movf received_byte,w
			return

;-------------------------------------------------------------------------------------------------------------------

read_eeprom_id

			clrf eeprom_type
			movlw 1
			movwf eeprom_size

			call select_eeprom									; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_id_cmd									
			call send_byte_to_eeprom							; send eeprom ID command (0xab) to SPI EEPROM 											
			movlw 0
			call send_byte_to_eeprom							; send 3 dummy bytes
			movlw 0
			call send_byte_to_eeprom
			movlw 0
			call send_byte_to_eeprom
			call get_byte_from_eeprom							; 25X IDs: $10 = 128KB, $11 = 256KB, $12 = 512KB, $13 = 1MB, $14 = 2MB, $15 = 4MB, $16=8MB
			movwf eeprom_id										; If $BF, chip is SST25VF type
			
			xorlw 0xbf
			skipifzero											; is a an SST 25vf chip?
			goto not_25vf
			movlw 0x20
			movwf eeprom_size									; if so, set size as 32MBit
			movlw 0x01
			movwf eeprom_type									; and note the type as SST 25vf
			goto id_done

not_25vf	movf eeprom_id,w
			addlw 0xf0											; convert EEPROM ID to available slots
			skipifnotzero
			goto id_done
			movwf temp1
cap_loop	bcf STATUS,C
			rlf eeprom_size,f
			decfsz temp1,f
			goto cap_loop

id_done		call deselect_eeprom							   	; deselect the EEPROM (set its /CS = high)
			return

;---------------------------------------------------------------------------------------------------------------------

get_eeprom_address

			call get_byte_from_fpga								; get 3 bytes for address
			btfsc time_out,0
			return
			movwf eeprom_address_low
			
			call get_byte_from_fpga
			btfsc time_out,0
			return
			movwf eeprom_address_med
			
			call get_byte_from_fpga
			btfsc time_out,0
			return
			movwf eeprom_address_high
			return

;------------------------------------------------------------------------------------------------------------------

get_byte_from_fpga

			movlw 8												; This routine has transmission speed limits
			movwf bitcount										; Minimum speed ~ 7 Hz  
			clrf time_out										; Max recommended speed ~ 100 KHz
			clrf received_byte

next_fcbit	bcf STATUS,0										; clear carry flag
			rlf received_byte,f									; rotate serial register
			nop
			nop
			nop
			nop
			clrf temp1
			clrf temp2	
wait_bffch	btfsc PORTA,comms_clock_in							; wait for clock high
			goto gbff_clk_hi
			incfsz temp1,f										; loop 65536 times and then time out
			goto wait_bffch										
			incfsz temp2,f
			goto wait_bffch
			bsf time_out,0
			return

gbff_clk_hi	nop
			nop
			nop
			nop
			btfsc PORTB,fpga_init								; read bit from FPGA init line
			bsf received_byte,0
			nop
			nop
			nop
			nop
			clrf temp1
			clrf temp2
wait_bffcl	btfss PORTA,comms_clock_in							; wait for clock low
			goto gbff_clk_lo
			incfsz temp1,f										; loop 65536 times and then time out
			goto wait_bffcl										
			incfsz temp2,f
			goto wait_bffcl
			bsf time_out,0
			return
			
gbff_clk_lo	decfsz bitcount,f									; loop for 8 bits
			goto next_fcbit

			movf received_byte,w								; return byte in W
			return

;-------------------------------------------------------------------------------------------------------------------

send_eeprom_address

			movf eeprom_address_high,w							; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf eeprom_address_med,w
			call send_byte_to_eeprom
			movf eeprom_address_low,w			
			call send_byte_to_eeprom
			return

;-------------------------------------------------------------------------------------------------------------------

send_byte_to_eeprom

			movwf temp1											; send byte in W to SPI EEPROM
			movlw 8
			movwf bitcount									
sb_loop		movlw 0			
			rlf temp1,f
			skipifnotcarry
			movlw (1<<eeprom_data_in)							; present data bit to EEPROM
			movwf PORTA
			iorlw (1<<eeprom_clock)								; raise the EEPROM clock line
			movwf PORTA
			xorlw (1<<eeprom_clock)								; drop the EEPROM clock line
			movwf PORTA
			decfsz bitcount,f									; loop to next bit
			goto sb_loop
			return

;----------------------------------------------------------------------------------------------------

pic_eeprom_write

			banksel EEADR	 									;Bank 1
			movwf EEDATA										;put byte to write in W
			movf pic_eeprom_addr,w
			movwf EEADR											;address to write to
			BSF EECON1, WREN 									;Enable write
			MOVLW 0x55 											;
			MOVWF EECON2 										;Write 55h
			MOVLW 0xAA 											;
			MOVWF EECON2 										;Write AAh
			BSF EECON1,WR 										;Set WR bit
wait_epwr	btfsc EECON1,WR										;wait for WR bit to be cleared by HW
			goto wait_epwr	
			BCF EECON1, WREN 									;disable EE writes
			banksel PORTA
			return


pic_eeprom_read

		    banksel EEADR										; bank 1
			MOVWF EEADR 										; Put address to read in W
			BSF EECON1, RD 										; EE Read
			MOVF EEDATA, W 										; W = EEDATA
			banksel PORTA   									; Bank 0
			return

;-----------------------------------------------------------------------------------------------------

disallow_programming

			bcf allow_program,0									
			return


allow_programming

			bsf allow_program,0
			return


;--------------------------------------------------------------------------------------------------------------------------------

select_eeprom

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS Low (select EEPROM, new instruction)
			return


deselect_eeprom

			movlw porta_default
			movwf PORTA											; Bring SPI EEPROM /CS High (deselect EEPROM)
			return

;---------------------------------------------------------------------------------------------------------------------------------


long_pause	movlw 5												; approx 0.25 seconds (20MHz clock)
			movwf temp3
lp_loop		call short_pause
			decfsz temp3,f
			goto lp_loop
			return


short_pause	clrf temp2											; approx 0.052 seconds (20MHz clock)									 
			clrf temp1									
swlp1		nop
			incfsz temp1,f			
			goto swlp1			
			incfsz temp2,f			
			goto swlp1
			return


vshort_pause

			clrf temp1											; approx 200 microseconds (20MHz Clock)
vsh_pause	nop
			decfsz temp1,f
			goto vsh_pause
			return


pause_1ms	movlw 5
			movwf temp2											; approx 1 millisecond (20MHz clock)									 
			clrf temp1									
msplp1		nop
			incfsz temp1,f			
			goto msplp1			
			decfsz temp2,f			
			goto msplp1
			return


short_pause_esc_if_done

			movlw 160
			movwf temp2											; approx 0.05 seconds (20MHz clock)									 
			clrf temp1											; quits immediately if done is high
shpeidlp	btfsc PORTA,fpga_done
			return
			incfsz temp1,f			
			goto shpeidlp			
			decfsz temp2,f			
			goto shpeidlp
			return


;-----------------------------------------------------------------------------------------------------------------------------

wait_button_release

			clrf temp3											;button must be released for ~0.25 seconds for loop exit
butrelcnt	call pause_1ms									
			btfss PORTB,button									
			goto wait_button_release		
			incfsz temp3,f
			goto butrelcnt
			return

;-----------------------------------------------------------------------------------------------------------------------------

reset_pulse

			movlw portb_default-(1<<reset_out)					; pulse reset line low
			movwf PORTB
			call short_pause
			movlw portb_default
			movwf PORTB
			return

;-----------------------------------------------------------------------------------------------------------------------------

send_eeprom_byte_to_fpga

			movlw 8													  	; Clock out the byte from the EEPROM							
			movwf temp1											
sebbit_lp	movlw portb_default+(1<<comms_clock_out)+(1<<green_led)   	; set com clock hi = FPGA latches data bit
			movwf PORTB
			movlw portb_default				   				  		  	; return clock low
			movwf PORTB
			movlw (1<<eeprom_clock)							  		  	; set EEPROM clock high
			movwf PORTA												  	
			clrf PORTA													; set EEPROM clock low = EEPROM shifts out a new bit				
			decfsz temp1,f
			goto sebbit_lp
			return

;-----------------------------------------------------------------------------------------------------------------------------

send_w_to_fpga

			movwf byte_to_send									; Sends byte in W from PIC to FPGA
			call deselect_eeprom								; ensure eeprom's D_OUT pin is hi-impedence to avoid clash

			banksel TRISA
			movlw b'00001010'									; temp change data direction for port B bit 0 to output 
			movwf TRISB
			banksel PORTA

			movlw 8
			movwf bitcount
psb_bloop	movlw portb_default									
			btfsc byte_to_send,7
			iorlw (1<<eeprom_data_out)
			movwf PORTB											; present data bit 
			iorlw (1<<comms_clock_out)
			movwf PORTB											; clock high
			xorlw (1<<comms_clock_out)
			movwf PORTB											; clock low
			rlf byte_to_send,f
			decfsz bitcount,f
			goto psb_bloop

			banksel TRISA
			movlw b'00001011'									; change data direction for port B bit 0 back to input 
			movwf TRISB
			banksel PORTA

			movlw portb_default
			movwf PORTB
			return

;------------------------------------------------------------------------------------------------------------------------------

send_ok_ack

			movlw 0x00
			call send_w_to_fpga
			return

;-----------------------------------------------------------------------------------------------------------------------------
;------ EEPROM DATA ----------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------


			ORG 0x2100

    	    DE 0x00,0x00,0x00									; default FPGA config base address low,mid,high
																; 0x00000 ("slot 0")

;*****************************************************************************************************************************

			END                     						    ; directive 'end of program'
