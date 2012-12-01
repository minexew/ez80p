;-----------------------------------------------------------------------------------------
;"Sound" - Play a section of Audio RAM v1.01
;-----------------------------------------------------------------------------------------

os_cmd_sound	ld a,81h
				out0 (port_hw_enable),a				;make sure audio system is enabled

				ld de,0ffffh						;defaults
				ld (aud_per),de
				ld a,64
				ld (aud_vol),a
				ld a,11h
				ld (aud_chans),a
				
				call hexword_or_bust				;the call only returns here if the hex in DE is valid
				jr nz,alocok						;ZF set if no hex found
				call hwsc_disable_audio				;if no parameters, silence all sound
				xor a
				ret
alocok			ld (aud_loc),de
				ld (aud_loc_loop),de
				
				call hexword_or_bust
				jr nz,gotaudlen
missaudpar		ld a,8dh							;"missing args"
				or a
				ret				
gotaudlen		ld (aud_len),de
				ld (aud_len_loop),de
				
				call hexword_or_bust
				jr z,play_sound
				ld a,e
				ld (aud_per),a
				ld a,d
				ld (aud_per+1),a
				
				call hexword_or_bust
				jr z,play_sound
				ld a,e
				ld (aud_vol),a
				
				call hexword_or_bust
				jr z,play_sound
				ld a,e
				ld (aud_chans),a
				
				call hexword_or_bust
				jr z,play_sound
				ld a,e
				or a
				jr nz,play_sound
				ld de,1
				ld (aud_len_loop),de
				
play_sound		ld hl,audio_structure
				ld a,(aud_chans)
				ld c,a
				call hwsc_play_audio
				xor a
				ret
				

;------------------------------------------------------------------------------------------

audio_structure

aud_loc			dw24 0			;loc
aud_len			dw24 0			;len
aud_loc_loop	dw24 0	  	    ;loop loc
aud_len_loop	dw24 0		    ;loop len

aud_per			dw 0ffffh		;per
aud_vol			db 64			;vol

aud_chans		db 11h			;channels to play on

;------------------------------------------------------------------------------------------
		