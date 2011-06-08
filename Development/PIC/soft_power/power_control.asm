; ------------------------------------------------------------
; PIC 12F629 - single button power cycle
; ------------------------------------------------------------
; By Phil Ruston 2011
; Version : V1.00
 
; Press button on GPIO3 to select power on, then press again to power off

; Button should pull GPIO3 to GND, requires external Pull up resistor
; Power output control is on GPIO4

;------- MASM directives -----------------------------------------------------------------------

	list      p=12f629           ; list directive to define processor
	#include <p12f629.inc>       ; processor specific variable definitions

;------ Chip configuration -------------------------------------------------------------------

	__CONFIG   0xF1FF & _CP_OFF & _CPD_OFF & _BODEN_OFF & _MCLRE_OFF & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT  
	
;--------------------------------------------------------------------------------------------

	#define bank0             bcf STATUS,RP0               ;macros
	#define bank1             bsf STATUS,RP0
	#define skipifzero        btfss STATUS,Z        
	#define skipifnotzero     btfsc STATUS,Z
	#define skipifcarry       btfss STATUS,C        
	#define skipifnotcarry    btfsc STATUS,C
	
	errorlevel  -302              ; suppress message 302 from list file


;***** VARIABLE DEFINITIONS (Chip register locations) ----------------------------------------

w_temp			EQU     0x20
status_temp		EQU     0x21
count1			equ		0x22
count2			equ 	0x23

button			equ		3				; button connected from GPIO 3 to GND (req ext pull up)
mainpower		equ		4				; main power connected to GPIO 4

;********************************************************************************************
;********** Generic Code Header *************************************************************
;********************************************************************************************

			ORG     0x000           	 ; processor reset vector
			goto    mainstart        	 ; go to beginning of program

			ORG     0x004            	 ; interrupt vector location
			retfie                   	 ; return from interrupt

; --- Calibrate internal oscillator  ----------------------------------------------------------

mainstart	call    0x3FF          	  	; retrieve factory calibration value
			bank1		   	 	   	 	; set file register bank to 1 
			movwf   OSCCAL           	; update register with factory cal value 
			bank0

; --- Initialization -------------------------------------------------------------------------

			movlw 0						; Zero port at init
			movwf GPIO					
			movlw b'00111111'		
			movwf CMCON					; All GPIO pins in digital mode - part 1

			bank1
;			clrf ANSEL					; set all GPIOs to digital mode - part 2 (only required for 12f675)
			movlw b'00001000'
			movwf TRISIO				; set GPIO dirs (GPIO3 is always an input on 12f629 / 12f675)
			clrf WPU					; all pull-ups off (GPIO3 doesnt have one)
			bank0

;----------- Begin Operations ---------------------------------------------------------------

mainloop	call waitbutton_release
			
			call waitbutton_press
			movlw (1<<mainpower)
			movwf GPIO 						; main power on
			
			call waitbutton_release

			call waitbutton_press
			clrf GPIO						; main power off
			goto mainloop
		
;--------------------------------------------------------------------------------------------
	
waitbutton_press

			clrf count2						; count must reach about 0.25 seconds 				 
			clrf count1						; 
swlp1		btfsc GPIO,button				; if button is released restart count	
			goto waitbutton_press
			nop
			incfsz count1,f			
			goto swlp1			
			incfsz count2,f			
			goto swlp1
			return


waitbutton_release

			clrf count2						; wait must reach about 0.25 seconds 				 
			clrf count1						; 
swlp2		btfss GPIO,button				; if button is released restart count	
			goto waitbutton_release
			nop
			incfsz count1,f			
			goto swlp2			
			incfsz count2,f			
			goto swlp2
			return


;********************************************************************************************

			END                       ; directive 'end of program'

