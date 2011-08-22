;----------------------------------------------------------------------------------------
; ez80p interrupt code v0.06 (MADL mode)
;----------------------------------------------------------------------------------------

set_irq_vectors
		
				xor a
				ld i,a
						
				ld ix,06fh								;build irq vector table 
				ld b,35
init_ivect_lp1	ld (ix),0c3h							;insert jp instruction
				lea ix,ix+4
				djnz init_ivect_lp1
				
				ld hl,6fh								;put 16bit vectors to jp locations in actual eZ80 vectors
				ld ix,0ah
				ld de,4
				ld b,11									;11 vectors from $0a
init_ivect_lp2	ld (ix),l
				ld (ix+1),h
				add hl,de
				lea ix,ix+2
				djnz init_ivect_lp2
				ld ix,30h								;25 vectors from $30
				ld b,25
init_ivect_lp3	ld (ix),l
				ld (ix+1),h
				add hl,de
				lea ix,ix+2
				djnz init_ivect_lp3
				
				ld hl,int_routine						;set up INT PB0 vector $C3 = JP instruction	
				ld (09ch),hl							;insert ** 24bit ** address as interrupt sets ADL mode

				ld a,0c3h								;set up NMI vector C3 = JP instruction
				ld (066h),a
				ld hl,nmi_routine						;insert ** 24bit ** address as interrupt sets ADL mode
				ld (067h),hl
				ret


;----------------------------------------------------------------------------------------------


enable_os_irqs	ld hl,devices_connected					;enable the IRQ sources of the devices connected
				bit 0,(hl)
				call nz,enable_kb_irq
				bit 1,(hl)
				call nz,enable_ms_irq
				ret


enable_kb_irq	ld a,10000001b
				out0 (port_irq_ctrl),a					;enable keyboard IRQ (leave other IRQs intact)
				ret

enable_ms_irq	ld a,10000010b
				out0 (port_irq_ctrl),a					;enable mouse IRQ (leave others IRQs intact)
				ret

disable_ms_irq	ld a,00000010b
				out0 (port_irq_ctrl),a					;disable mouse IRQ (leave others IRQs intact)
				ret

disable_irqs	ld a,00111111b
				out0 (port_irq_ctrl),a					;disable all IRQs (except NMI)
				ret
			
;----------------------------------------------------------------------------------------------


int_routine
				push af									;as STMIX = 1, the interrupt starts in ADL mode 
				in0 a,(port_ps2_ctrl)					;anything in keyboard buffer?
				bit 4,a
				call nz,kb_interrupt_handler
				in0 a,(port_ps2_ctrl)					;anything in mouse buffer?
				bit 5,a
				call nz,ms_interrupt_handler
				pop af

				ei										;re-enable maskable interrupts
				reti.l									;restores original ADL mode before returning

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine v0.03
;----------------------------------------------------------------------------------------

kb_interrupt_handler

;--- irq test --------------------------------------------------------------------------------

;				push bc
;				ld a,0ffh
;				ld (hw_palette),a
;				ld b,0
;testlp1		djnz testlp1
;				ld a,0
;				ld (hw_palette),a
;				pop bc
				
;--- end of test -----------------------------------------------------------------------------


				push hl									; buffer the keypresses, keep track of qualifiers
				push bc
				
key_loop		in0 a,(port_keyboard_data)				; read a scancode from buffer
				ld b,a

				ld a,(key_release_mode)
				or a
				jr z,key_pressed
			
				ld a,b									; key-released: get scan code in A
				cp 0e0h									; ignore e0/e1 codes
				jr z,kirq_done	
				cp 0e1h
				jr z,kirq_done	
				
				call qualifiers							; test for qualifier key?
				ld a,l
				cpl
				ld l,a
				ld a,(key_mod_flags)
				and l									; update qualifiers (released)
				ld (key_mod_flags),a
				xor a
				ld (key_release_mode),a
				jr kirq_done
	

key_pressed		ld a,b									; key-pressed: get scancode in A
				cp 0e0h									; ignore e0/e1 codes
				jr z,kirq_done	
				cp 0e1h
				jr z,kirq_done	
			
				cp 0f0h									; is scancode = key released token?
				jr nz,not_krel
				ld a,1									; if so, so nothing except set the next irq to
				ld (key_release_mode),a					; treat scan code as a release code
				jr kirq_done
	
	
not_krel		call qualifiers							; test for qualifier key?
				ld a,(key_mod_flags)					
				or l
				ld (key_mod_flags),a					; update qualifiers (pressed)
				ld l,b
				ld bc,0
				ld a,(key_buf_wr_idx)
				ld c,a
				ld a,l
				ld hl,scancode_buffer
				add hl,bc
				ld (hl),a								; put key press scancode in buffer 	
				ld c,16
				add hl,bc
				ld a,(key_mod_flags)					; also record qualifier status in buffer
				ld (hl),a	
				ld a,(key_buf_wr_idx)
				inc a
				and 15
				ld (key_buf_wr_idx),a					; advance the buffer location
				
kirq_done		in0 a,(port_ps2_ctrl)					;anything else in keyboard buffer?
				bit 4,a	
				jr nz,key_loop

				pop bc
				pop hl
				ret


qualifiers		ld l,040h		;apps
				cp 02fh
				ret z
			
				ld l,020h		;r gui
				cp 027h
				ret z
			
				ld l,010h		;r shift
				cp 059h
				ret z
			
				ld l,08h		; alt
				cp 011h
				ret z
			
				ld l,04h		; l gui
				cp 01fh
			
				ld l,02h		;l ctrl / r ctrl
				cp 14h
				ret z
			
				ld l,01h		;l shift
				cp 12h
				ret z
				
				ld l,0
				ret

;------------------------------------------------------------------------------------------
; Mouse IRQ routine v0.03
;------------------------------------------------------------------------------------------

ms_interrupt_handler

;--- irq test --------------------------------------------------------------------------------

;				push bc
;				ld a,0ffh
;				ld (hw_palette),a
;				ld b,0
;testlp1		djnz testlp1
;				ld a,0
;				ld (hw_palette),a
;				pop bc
				
;--- end of test -----------------------------------------------------------------------------


				push bc							; buffers the movement packet bytes on 3rd byte
				push de							; cumulative mouse displacement counters
				push hl							; and button registers are updated 
							
ms_loop			ld de,0		
				ld a,(mouse_packet_index)		; packet byte number 
				ld e,a
				ld hl,mouse_packet	
				add hl,de
				in0 a,(port_mouse_data)
				ld (hl),a
								
				ld hl,mouse_packet_size
				inc e							; was this the last byte of the mouse packet?
				ld a,e
				cp (hl)
				jr nz,msubpkt

				ld a,(mouse_packet)				; update OS mouse registers, first the buttons
				ld c,a	
				and 0111b
				ld (mouse_buttons),a
				
				ld de,0							; update x accumulator
				bit 4,c
				jr z,mxsignpos
				dec de
mxsignpos		ld a,(mouse_packet+1)
				ld e,a
				ld hl,(mouse_disp_x)
				add hl,de
				ld (mouse_disp_x),hl
				
				ld de,0							; update y accumulator
				bit 5,c
				jr z,mysignpos
				dec de
mysignpos		ld a,(mouse_packet+2)
				ld e,a
				ld hl,(mouse_disp_y)			; mouse uses positive displacement = upwards	
				xor a							; motion so subtract value instead of adding
				sbc hl,de
				ld (mouse_disp_y),hl
				
				ld hl,mouse_packet+3			; scroll wheel data for 4-byte packet mice (where available)
				ld a,(mouse_wheel)
				add a,(hl)
				ld (mouse_wheel),a
				
				ld a,1
				ld (mouse_updated),a			; allows main program to check if mouse registers have been changed
				
				xor a
msubpkt			ld (mouse_packet_index),a
				
				in0 a,(port_ps2_ctrl)			; anything else in mouse buffer?
				bit 5,a
				jr nz,ms_loop				
				
				pop hl
				pop de
				pop bc
				ret
				
;----------------------------------------------------------------------------------------
; ez80p NMI code v0.03
;----------------------------------------------------------------------------------------

nmi_routine		push af									
				in0 a,(port_irq_flags)					; make sure NMI was sourced from freeze button
				bit 6,a									; (IE: spareIO NMI flip/flop is set)
				jr nz,freeze
				ld a,00100000b							; if not, it could only be a video NMI
				out0 (port_clear_flags),a				; so clear its flag and return
				pop af
				retn.l
				
freeze			pop af
				call os_store_CPU_regs
				
				ld hl,0
				add hl,sp
				ld a,(hl)								; will be 3 if was in ADL mode when NMI occured, 2 for Z80 mode 
				and 1
				ld (store_adl),a
				jr nz,adl_freeze
				inc hl
				ld e,(hl)								; get PC for Z80 mode freeze
				inc hl
				ld d,(hl)
				call mbase_de
				jr got_pc
				
adl_freeze		inc sp
				pop de									; get PC for ADL mode freeze
got_pc			ld (store_pc),de						
				
				call disable_button_nmi
				ld a,01000000b
				out0 (port_clear_flags),a				; clear button flip/flop
				ld a,1
				ld (frozen),a
				jp os_cold_start							

;--------------------------------------------------------------------------------------------

;nmi_routine
;
;				push af									;NMI test: change background colour briefly
;				push bc
;				ld a,0ffh
;				ld (hw_palette),a
;				ld b,0
;nmi_testlp2		djnz nmi_testlp2
;				ld a,0
;				ld (hw_palette),a
;				pop bc
;				ld a,01100000b
;				out0 (port_clear_flags)
;				pop af
;				retn.l									;restores original ADL mode before returning


;----------------------------------------------------------------------------------------

enable_button_nmi

				ld a,01000000b
				out0 (port_clear_flags),a				;clear button NMI flip-flop in case previously set	
				ld a,11000000b							
				out0 (port_irq_ctrl),a					;enable button NMI (leave other IRQs intact)
				ret


disable_button_nmi

				ld a,01000000b							;disable button NMI (leave other IRQs intact)
				out0 (port_irq_ctrl),a
				ret


disable_all_nmis

				ld a,01100000b							;disable NMIs (leave other IRQs intact)
				out0 (port_irq_ctrl),a
				ret
				
;----------------------------------------------------------------------------------------

