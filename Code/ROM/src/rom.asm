;---------------------------------------------------------------------------------------------------
; Boot ROM for ez80p v0.05 - runs mainly in Z80 mode, runs OS in ADL mode
; Looks for "BOOT.EZO" OS file on SD card, this contains the filename of
; the OS, if either is not found ROM waits for serial download.
;
; V0.06 - Sets up video, and says "No OS" if no card / os file present
;---------------------------------------------------------------------------------------------------

os_location 	equ 0a00h
sector_buffer	equ 0800h

stack_l			equ 07ffffh
stack_s			equ 07ffh

include "ez80_cpu_equates.asm"

include "ez80p_hardware_equates.asm"

;--------------------------------------------------------------------------------------------------

				org 0

				jp.lil go_adl_1
				
		.assume	ADL = 1
				
go_adl_1		xor a
				ld MB,a
				jp.sis go_z80_1
go_z80_1				

		.assume ADL = 0
	
				jp init_system

;-- Interrupt Vectors ----------------------------------------------------------------------------------

				org 030h								; irq vector PB0 pin

				dw my_irq
				
my_irq			ei										
				reti.l

				org 066h								; nmi vector

				out0 (port_nmi_ack),a
				retn.l

;--------------------------------------------------------------------------------------------------

init_system		stmix
				di
				ld sp,stack_s
				ld.lil sp,stack_l
				
;-------------------------------------------------------------------------------------------------
; Set up eZ80 I/O Ports
;-------------------------------------------------------------------------------------------------

				xor a			
				out0 (PB_DR),a
				out0 (PB_DDR),a							; set eZ80 port B [0] to MODE 8, level sensitive IRQ
				ld a,1									; and bits [7:1] to MODE 0, standard output
				out0 (PB_ALT1),a
				out0 (PB_ALT2),a
				
				xor a
				out0 (PC_DR),a
				out0 (PC_DDR),a							; set eZ80 port C to standard output mode	
				out0 (PC_ALT1),a
				out0 (PC_ALT2),a
				
				out0 (PD_DR),a
				out0 (PD_ALT1),a						;set port PD0 pins [3:0] to mode 7 (peripheral control)
				ld a,00fh				
				out0 (PD_ALT2),a						;port PD0 = UART0_TX, port PD1 = UART0_RX
				out0 (PD_DDR),a							;port PD2 = UART0_RTS, port PD3 = UART0_CTS

;-------------------------------------------------------------------------------------------------
; Set up eZ80 Wait states
;-------------------------------------------------------------------------------------------------


				ld a,11101000b							; Set CS0 = 7 wait states/for memory/enabled
				out0 (CS0_CTL),a						; default memory range for CS0 (entire 16MB)
				ld a,000h
				out0 (CS0_LBR),a						; default memory range for CS1 (entire 16MB)
				ld a,0ffh	
				out0 (CS0_UBR),a
				ld a,0f8h
				out0 (CS1_CTL),a						;set CS1 to be active for IO ports - use 7 wait states
				ld a,0
				out0 (CS1_LBR),a						;set CS1 applicable to IO port range $0000-$007f

;-------------------------------------------------------------------------------------------------
; set up eZ80 com port
;-------------------------------------------------------------------------------------------------


				ld a,080h
				out0 (UART0_LCTL),a						; select DLAB to access Baud Rate Generators
				ld a,01bh
				out0 (UART0_BRG_L),a					; Set 115200 Baud for 50MHz master clock
				ld a,000h
				out0 (UART0_BRG_H),a
				ld a,00h
				out0 (UART0_LCTL),a						; disable DLAB after setting Baud rate
				ld a,000h
				out0 (UART0_FCTL),a						; FIFO control: buffer disabled
				ld a,003h
				out0 (UART0_LCTL),a						; Line control: 8-N-1 
				ld a,000h
				out0 (UART0_MCTL),a						; Modem control: Disable loopback, /RTS pin = 1
				ld a,000h
				out0 (UART0_IER),a						; All UART0 interrupts disabled

;-----------------------------------------------------------------------------------------------------
;--- Configure RTC -----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
				
				ld a,00100000b
				out0 (RTC_CTRL),a						; RTC = BCD mode / 32768 XTAL / locked

;-------------------------------------------------------------------------------------------------
;--- Configure timer 0 ---------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------

				ld a,00000001b
				out0 (TMR_ISS),a						; timer 0 to use the RTC as source clock (32768 Hz)		

;-------------------------------------------------------------------------------------------------
; Copy ROM to RAM 
;-------------------------------------------------------------------------------------------------


				xor a									; clear all AMOEBA ports
				ld bc,9
pclrlp			out (bc),a
				dec c
				jr nz,pclrlp

				ld a,07fh
				out0 (port_irq_ctrl),a					; disable IRQs

				ld hl,0									; copy ROM to RAM
				ld de,0
				ld bc,7f0h								; leave 16 bytes for stack
				ldir

				ld a,1
				out0 (port_memory_paging),a				; page in RAM at 000-7ff for reads and writes
				
				nop										; probably not necessary but NOPs ensure CPU isnt
				nop                                   	; doing much as ROM is paged out
				nop
				nop


;****************************************************************************************************
; Main code begins
;****************************************************************************************************

				ld de,0
				call change_colour					; colour 1 = black

				jp.lil adl_mode

	.assume ADL = 1

adl_mode		xor a								; bgnd = black
				ld hl,hw_palette
				ld (hl),a
				inc hl
				ld (hl),a
				
				ld hl,video_control
				ld (hl),0110b						;256 colours,  pixel doubling:on line doubling:on
				inc hl
				ld (hl),0							;sprites off
				inc hl
				ld (hl),0							;select palette 0
				inc hl
				inc hl
				ld (hl),99							;right border position
		
				ld hl,bitmap_parameters				; set up bitmap mode parameters 
				push hl
				pop ix
				xor a
				ld b,16
clregs			ld (hl),a
				inc hl
				djnz clregs
				ld (ix+04h),1
				ld (ix+10h),0+(320/8)-1			
				
				ld hl,vram_a_addr					; clear vram
				ld (hl),0
				push hl
				pop de
				inc de
				ld bc,320*240
				ldir
				
				ld de,gfx							; draw in "No OS" graphic
				ld hl,vram_a_addr+(320*116)+140
				ld b,7
lp3				push bc
				ld b,6
lp2				push bc
				ld b,80h
lp1				ld c,0
				ld a,(de)
				and b
				jr z,nopix
				inc c
nopix			ld (hl),c
				inc hl
				srl b
				jr nz,lp1
				inc de
				pop bc
				djnz lp2
				ld bc,320-(8*6)
				add hl,bc
				pop bc
				djnz lp3
				jp.sis z80_mode

z80_mode

	.assume ADL = 0

;-------------------------------------------------------------------------------------------
; Check for OS on SD Card (*.EZ0 file)
;-------------------------------------------------------------------------------------------

				call sdc_init_card						; Is there an SD/MMC card attached?
				jr nc,no_sd_card_os						; carry is set if initialized OK	
				ld hl,drives_present
				set 0,(hl)								; Set bit 0 - SD card present
	
				ld hl,bl_filename
				call find_file_fat16					; look for "BOOT.EZO" file on (assumed) FAT16 card
				jr c,no_bootezo							; hardware error?
				jr nz,no_bootezo						; file not found?
				ld hl,(fs_file_length_working)
				ld de,12
				xor a
				sbc hl,de
				jr c,bl_lenok
				ld hl,12
				ld (fs_file_length_working),hl
bl_lenok		ld hl,0
				ld (fs_file_length_working+2),hl		; truncate to 12 byte load max
				ld hl,os_filename
				ld (fs_z80_working_address),hl			; load to "os_filename" string
				call load_file_fat16
				jp c,os_load_error
				jp nz,os_load_error						; load error?
				
				ld hl,os_filename
				call find_file_fat16					; now find the file specified by the BOOT.EZO
				jr c,no_sd_card_os
				jr nz,no_sd_card_os
				ld hl,os_location						
				ld (fs_z80_working_address),hl						
				call load_file_fat16
				jp c,os_load_error
				jp nz,os_load_error						

				ld a,1
				ld (boot_drive),a						; Mark SD card as boot device (type 1)


;-------- TEST THE CRC CHECKSUM OF THE OS LOADED (FROM CARD/EEPROM) ------------------------


do_chksum		ld de,(os_location+8)					; OS length not including header (lo word, 64KB max)
				ld hl,os_location+16					; first address to check
				exx
				ld hl,0ffffh							; initial CRC value
				exx
mchkslp			ld a,(hl)
				call crc_calc
				inc hl
				dec de
				ld a,d
				or e
				jr nz,mchkslp
		
				exx										; get final CRC value in HL 
				ld de,(os_location+0ch)					; get checksum word from header
				xor a
				sbc hl,de								; compare 
;				jp nz,crc_fail							; if not same: bad checksum	(dont care at the moment)
	
				jp start_os

;-------------------------------------------------------------------------------------------------
; Receive file from serial link program
;-------------------------------------------------------------------------------------------------

no_bootezo		ld de,000fh								; flash blue = didn't find "BOOT.EZO"
				call change_colour
				call pause_a_sec
				
no_sd_card_os
				ld de,0ccch								; flash "no os" text when waiting for serial 
				ld hl,swait_count
				inc (hl)
				bit 0,(hl)
				jr nz,colour_a
				ld de,0
colour_a		call change_colour						; no OS on SD card - display grey, wait for serial
				
				ld hl,os_location
				call s_getblock							; get header block 
				jr c,no_sd_card_os						; if CF set, Timed out waiting: Retry.
				jr z,shdr_ok							; if ZF set, all OK
s_bad			ld de,05858h							; otherwise checksum bad: send "XX" to host to
				call send_serial_bytes					; stop file transfer.
				jp os_load_error

shdr_ok			ld de,0
				call change_colour
				call s_goodack							; send "OK" to start the first block transfer
				ld hl,os_location						; HL = Address to load code to
				ld de,(os_location+17)					; Number of blocks to load
				ld a,(os_location+16)
				or a
				jr z,s_gbloop
				inc de
s_gbloop		call s_getblock
				jr c,s_bad								; carry set = time out
				jr nz,s_bad								; zero flag not set = CRC error
				call s_goodack							; send "OK" to acknowledge block received OK	
				dec de
				ld a,d
				or e
				jr nz,s_gbloop
				ld a,0
				ld (boot_drive),a						; Boot device = serial (type 0)
			

;-------- START UP THE OS ----------------------------------------------------------------------
	
start_os		ld a,(boot_drive)						; pass drive info to OS if required
				ld b,a
				ld a,(drives_present)		
				ld c,a
				xor a
				jp.lil os_location+10h					; executable OS code starts 16 bytes in		

;-----------------------------------------------------------------------------------------------

crc_fail		ld de,0f0fh								; magenta = CRC error									
				jr failed
					
os_load_error	ld de,0f00h								; red = failed to load BOOT.EZO
failed			call change_colour
				call pause_a_sec
				rst 0
			
;-----------------------------------------------------------------------------------------------

change_colour	ld.lil ix,hw_palette+2
				ld.lil (ix),e
				ld.lil (ix+1),d
				ret
								
;---------------------------------------------------------------------------------------------
; Timer related 
;---------------------------------------------------------------------------------------------

pause_4ms
				push bc
				
				ld bc,TMR_ISS
				in a,(bc)
				and 11111100b
				or  00000001b
				out (bc),a								; timer 0 to use the RTC as source clock (32768 Hz)
					
				ld bc,TMR0_RR_L
				ld a,131
				out (bc),a								; set count value lo
				ld bc,TMR0_RR_H
				ld a,0
				out (bc),a								; set count value hi (131 * 32768Hz ticks)
				ld bc,TMR0_CTL	
				ld a,00000011b							
				out (bc),a								; enable and start timer 0 (prescale apparently ignored for RTC)

twaitlp			in a,(bc)								
				bit 7,a
				jr z,twaitlp							; wait for timer to count down to zero
				pop bc
				ret

;----------------------------------------------------------------------------------------------

pause_a_sec		ld b,0
seclp			call pause_4ms
				djnz seclp
				ret
				
;-----------------------------------------------------------------------------------------------

include 'card_load_essentials.asm'
include 'serial_load_essentials.asm'

;-----------------------------------------------------------------------------------------------

bl_filename		db 'BOOT.EZO',0
os_filename		blkb 16,0

boot_drive		db 0
drives_present	db 0
swait_count		db 0

;----------------------------------------------------------------------------------------------

include	"no_os_gfx.asm"

;----------------------------------------------------------------------------------------------

