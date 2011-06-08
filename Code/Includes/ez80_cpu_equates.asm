;--- EZ80 Internal Ports --------------------------------------------------------------------

PB_DR			equ 09ah
PB_DDR			equ 09bh
PB_ALT1			equ 09ch
PB_ALT2			equ 09dh

PC_DR			equ 09eh
PC_DDR			equ 09fh
PC_ALT1			equ 0a0h
PC_ALT2			equ 0a1h

PD_DR			equ 0a2h
PD_DDR			equ 0a3h
PD_ALT1			equ 0a4h
PD_ALT2			equ 0a5h

UART0_RBR		equ 0c0h
UART0_THR		equ 0c0h
UART0_BRG_L		equ 0c0h
UART0_BRG_H		equ 0c1h
UART0_IER		equ 0c1h
UART0_FCTL		equ 0c2h
UART0_LCTL		equ 0c3h
UART0_MCTL		equ 0c4h
UART0_LSR		equ 0c5h
UART0_MSR		equ 0c6h

CS0_LBR			equ 0a8h			;eZ80 wait state CS0 control ports
CS0_UBR			equ 0a9h
CS0_CTL			equ 0aah			
CS1_LBR			equ 0abh			;eZ80 wait state CS1 control ports
CS1_UBR			equ 0ach
CS1_CTL			equ 0adh
CS2_LBR			equ 0aeh			;eZ80 wait state CS2 control ports
CS2_UBR			equ 0afh
CS2_CTL			equ 0b0h
CS3_LBR			equ 0b1h			;eZ80 wait state CS3 control ports
CS3_UBR			equ 0b2h
CS3_CTL			equ 0b3h

TMR0_CTL		equ 080h			;timer 0 equates
TMR0_DR_L		equ 081h
TMR0_RR_L		equ 081h
TMR0_DR_H		equ 082h
TMR0_RR_H		equ 082h
TMR_ISS			equ 092h

RTC_CTRL		equ 0edh			;RTC equates
RTC_ACTRL		equ 0ech
RTC_SEC			equ 0e0h
RTC_MIN			equ 0e1h
RTC_HRS			equ 0e2h
RTC_DOW			equ 0e3h
RTC_DOM			equ 0e4h
RTC_MON			equ 0e5h
RTC_YR			equ 0e6h
RTC_CEN			equ 0e7h

;-------------------------------------------------------------------------------------------------
