
;-- EZ80P Hardware equates ------------------------------------------------------------------------

port_pic_data  			equ 000h
port_pic_ctrl			equ 001h
port_hw_flags			equ 001h
port_sdc_ctrl			equ 002h	; this is a set/reset type register (bit 7 controls whether selected bits are set or reset)
port_keyboard_data		equ 002h
port_sdc_data		 	equ 003h	
port_memory_paging		equ 004h
port_irq_ctrl			equ 005h
port_nmi_ack			equ 006h
port_ps2_ctrl			equ 007h
port_selector			equ 008h
port_mouse_data			equ 006h
port_clear_flags		equ 009h

sdc_power				equ 0		;(port_sd_ctrl, bit 0 - active high)
sdc_cs					equ 1		;(port_sd_ctrl, bit 1 - active low)
sdc_speed				equ 2 		;(port_sd_ctrl, bit 2 - set = full speed)

sdc_serializer_busy		equ 4 		;(port_hw_flags, bit 4 - set = busy - ie: byte being transmitted)
vrt						equ 5		;(port_hw_flags, bit 5 - set = last scan line of display)


;-- Memory locations -----------------------------------------------------------------------------

vram_a_addr				equ 0800000h
vram_b_addr				equ 0c00000h

;-- Hardware registers ----------------------------------------------------------------------------

hw_palette				equ 0ff0000h
hw_sprite_registers		equ 0ff0800h
hw_video_parameters		equ 0ff1000h
hw_audio_registers		equ 0ff1400h
hw_video_settings		equ 0ff1800h

tilemap_parameters		equ hw_video_parameters+00h
bitmap_parameters		equ hw_video_parameters+20h

video_control			equ hw_video_settings+00h
sprite_control			equ hw_video_settings+01h
bgnd_palette_select		equ hw_video_settings+02h
sprite_palette_select	equ hw_video_settings+03h
right_border_position	equ hw_video_settings+04h

;-------------------------------------------------------------------------------------------------
