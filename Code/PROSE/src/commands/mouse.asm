;-----------------------------------------------------------------------------------------------
; "Mouse" = Reset / Enable Mouse Driver v0.04 - ADL mode
;-----------------------------------------------------------------------------------------------

window_width_pixels		equ 640
window_height_pixels	equ 480

default_sample_rate 	equ 100			; 100 samples per second, valid: 10,20,40,60,80,100,200
default_resolution		equ 03h			; 8 counts per mm, valid: 00h-03h
default_scaling			equ 0e6h		; valid commands 0e6h (1:1) / 0e7h (2:1)

os_cmd_mouse

				ld a,default_sample_rate
				ld (mouse_sample_rate),a
				ld a,default_resolution
				ld (mouse_resolution),a
				ld a,default_scaling
				ld (mouse_scaling),a

				ld hl,devices_connected
				res 1,(hl)
		
				call reset_mouse
				ret nz
			
				xor a
				ld (mouse_packet_index),a
				ld (mouse_buttons),a
				ld hl,0
				ld (mouse_disp_x),hl
				ld (mouse_disp_y),hl

				ld hl,window_width_pixels
				ld de,window_height_pixels
				call os_set_mouse_window

				call enable_ms_irq

				ld hl,devices_connected
				set 1,(hl)
				xor a
				ret				
				
;-----------------------------------------------------------------------------------------------
	