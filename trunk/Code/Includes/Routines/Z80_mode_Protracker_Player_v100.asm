;----------------------------------------------------------------------------------------
; Z80 Protracker Music Player - V1.00
; By Phil Ruston 2011
; http://www.retroleum.co.uk
;
; SYNTAX CONVERTED TO ZDSII STANDARD (Z80 mode code)
; NOT OPTIMIZED AT ALL 
;----------------------------------------------------------------------------------------
;
;
; Z80 Code to play standard 31 instrument Protracker modules.
;
; The code has been designed so that is hardware agnostic, ie: the player itself
; does not write to any hardware registers. It uses "stand-in" variables for the
; Amiga hardware registers but still uses the Amiga values** that would be written
; to them. Therefore it is up to a seperate "update_sound_hardware" routine to read these
; variables and adapt/convert the values therein to whatever hardware is being used to
; output the sound. (A routine to do this for my sound hardware is included for reference.)
;
;
; Equates (must be defined in external code)
; -------
;
; "music_module" = location of protracker module. The music module must be located
; at a word address boundary.
;
;
; Routines:
; ---------
;
; call "init_tracker" to initialize/reset tune
; call "play_tracker" every frame to update the tracker parameters
;
; (Obviously you need a routine to read the Amiga format audio registers
; that this code updates,  convert the values and write to your target hardware.)
;
;
; Variables:
; ----------
;
; "force_sample_base" (WORD) - write the WORD location of the samples IN SAMPLE RAM
; (ie: not Z80 address space) here  prior to initializing song if the samples have
; been seperated from the module (eg: written to seperate Audio RAM), otherwise
; ignore it (or write $FFFF).
;
; "filter_on_off" (BYTE) reads ONE if player has enabled the filter with FX E0,
; zero if not. (Whether or not this is of any use depends on target hardware)
;
; Replacing the Amiga hardware registers is a bank of variables for each sound channel:
; These begin at "channel_data". There are 33 bytes per channel.  Relevent offsets
; within each block are:
;
; samp_loc_lo (WORD address **)	
; samp_loc_hi (WORD address **)	
; samp_len_lo 	
; samp_len_hi 	
; samp_loop_offset_lo (IN WORDS **)
; samp_loop_offset_hi (IN WORDS **)	
; samp_loop_len_lo	
; samp_loop_len_hi	
; samp_offset_lo	
; samp_offset_hi	
; period_lo
; period_hi
; volume
; control_bits
;
; Variable names should be self-explanitory.
; "control_bits" replaces the Amiga's DMA sound channel start/stop control.
; When bit 0 of each channel's control_bits variable has been set to 1, the
; hardware conversion routine knows to trigger a sample (ie: reload start/length/
; loopstart/looplength). The conversion routine should clear bit 0 of this byte
; after triggering a sample.
;
; ** These are WORD locations, the Amiga hardware does not allow
; samples to begin on odd-byte addresses. Therefore using the 2 bytes
; to address word locations allows a sample address range of 128KB instead
; of 64KB. This is relevent - despite the Z80's 64KB address space - as sound
; hardware may have its own sample RAM . Simply multiply by two if using normal
; byte addresses.
;
; Limitations:
; ------------
; The Z80's 64KB address space limits the size of the modules that can be
; played. However, as mentioned, the samples can be split away from the module
; and loaded into seperate dedicated Audio RAM (128KB address space)
;
; Revisions:
; ----------
;
; V5.05 - If a pattern note entry is blank, clear the previous FX number
;
; V5.04 - Fixed note triggering -  a bug in the target hardware conversion routine
;         was masking the incorrect retrigging (where a zero/same instrument or zero
;         period is specified)
; 
; Known issues:
; -------------
; $EF - invert loop is not implemented (rarely used anyway..)
;
;
;========================================================================================
; Start of hardware-agnostic specific Z80 Protracker code. 
;========================================================================================

.assume ADL = 0

init_tracker

				ld a,6						; default speed setting
				ld (songspeed),a
				xor a						; clear various flags and variables
				ld (ticker),a
				ld (songpos),a
				ld (patindex),a
				ld (arpeggio_counter),a
				ld (pattloop_pos),a
				ld (pattloop_count),a
				ld (pattdelay_count),a	
				ld (pattdelay_flag),a	
				ld hl,channel_data
				ld b,vars_per_channel*4
clchdlp			ld (hl),a
				inc hl
				djnz clchdlp

				ld hl,music_module+952		; find highest used pattern in order to locate 
				ld b,128					; the address where samples start
				ld c,0
ptfhplp			ld a,(hl)	
				cp c
				jr c,patlower
				ld c,a
patlower		inc hl
				djnz ptfhplp
				inc c
				sla c
				sla c
				ld h,c
				ld l,0
				ld bc,music_module+1084			; pattern 0 address
				add hl,bc						; add on the length of the song data
				srl h							; divide by two for WORD location of sample base
				rr l							; HL = addr of samples / 2
				ld (sample_base),hl

				ld de,(force_sample_base)		; check to see if samples have been moved to
				inc de							; a fixed location. "force_sample_base" will be
				ld a,d							; something other than $FFFF if so.
				or e
				jr z,usenormsb
				ld hl,(force_sample_base)	

usenormsb		ld ix,sample_location_list		; build sample location list (31 entries)
				ld iy,music_module+42
				ld b,31
bsstlp			ld (ix),l						; put location of sample in table (low byte)
				ld (ix+1),h						; put location of sample in table (high byte)
				inc ix
				inc ix
				ld a,(iy+1)						; get length of sample (in words) low byte
				add a,l							; add to sample position
				ld l,a
				ld a,(iy)						; get length of sample (in words) hi byte
				adc a,h							; add to sample position
				ld h,a	
				ld de,30			
				add iy,de						; move next sample_data entry
				djnz bsstlp
				ret

;--------------------------------------------------------------------------------------

play_tracker

				ld a,(ticker)
				or a			
				jp nz,not_new_line

				ld a,(songpos)					; tick 0, so set up a new line of notes 
				ld b,0
				ld c,a
				ld hl,music_module+952			; hl = start of pattern table
				add hl,bc						; add on song position index
				ld b,(hl)			
				ld c,0
				sla b
				sla b							; bc = pattern data offset (1024 bytes per pattern)
				
				ld a,(patindex)					; multiply line index by 16 
				ld h,c							; (4 bytes per note x 4 tracks)	
				ld l,a
				add hl,hl
				add hl,hl
				add hl,hl
				add hl,hl						; hl = line offset
				add hl,bc						; add on pattern data offset
				ex de,hl
				
				ld iy,channel_data	
				ld ix,music_module+1084			; ix = start of pattern data
				add ix,de						; add on req'd pattern offset
				ld b,4							; 4 channels to do
chan_loop		push bc
				ld a,(ix)						; any data on the note bytes?
				or (ix+1)
				or (ix+2)
				or (ix+3)
				jr nz,parse_dat
				ld (iy+fx_number),0ffh			; if all zeros clear the chan's previous fx number (v5.05)
				jr skipchan	
parse_dat		call new_note_data	
skipchan		ld bc,vars_per_channel		
				add iy,bc						; move to next channel's data table
				ld bc,4
				add ix,bc						; move next channel in song pattern
				pop bc
				djnz chan_loop
				jp tick_advance


;----- New note routines -------------------------------------------------------------------

new_note_data
				
				ld (iy+instrument_waiting),0
				ld a,(ix)						; get new instrument (sample) number in A
				and 0f0h
				ld b,(ix+2)
				srl b
				srl b
				srl b
				srl b
				or b			
				jr z,no_new_instrument			; dont get values when there's no new instrument specified

				ld (iy+instrument_waiting),a
				dec a
				sla a
				ld c,a
				ld b,0
				ld hl,sample_location_list		; find location of sample from table
				add hl,bc
				ld a,(hl)
				ld (iy+samp_loc_lo),a			; note start location of this sample (lo)
				inc hl
				ld a,(hl)
				ld (iy+samp_loc_hi),a			; note start location of this sample (hi)
				
				ld hl,multiply_30_table			; find sample info for this instrument from module data
				add hl,bc
				ld a,(hl)
				inc hl
				ld h,(hl)
				ld l,a
				ld bc,music_module+42	
				add hl,bc						; hl = sample length of this instrument
				ld a,(hl)
				ld (iy+samp_len_hi),a			; note sample length (in words) of this instrument (hi)
				inc hl
				ld a,(hl)
				ld (iy+samp_len_lo),a			; note sample length (in words) of this instrument (lo)
				inc hl	
				ld a,(hl)			
				and 0fh
				ld (iy+finetune),a				; note the fine tune value of this instrument
				inc hl
				ld a,(hl)
				ld (iy+volume_waiting),a		; note the volume value of this instrument
				inc hl
				ld b,(hl)						; sample loop offset hi
				inc hl
				ld c,(hl)						; sample loop offset lo
				push hl
				ld h,(iy+samp_loc_hi)
				ld l,(iy+samp_loc_lo)
				add hl,bc
				ld (iy+samp_loop_loc_hi),h		; note sample loop loc for this instrument in words (hi)
				ld (iy+samp_loop_loc_lo),l		; note sample loop loc for this instrument in words (lo)
				pop hl	
				inc hl
				ld a,(hl)
				ld (iy+samp_loop_len_hi),a		; note sample loop length of this instrument in words (hi)
				inc hl
				ld a,(hl)
				ld (iy+samp_loop_len_lo),a		; note sample loop lenth of this instrument in words (lo)
				
				
				
no_new_instrument	

				ld a,(ix)						; get new period
				and 0fh
				ld b,a
				ld c,(ix+1)						; bc = new note's period
					
				ld a,(ix+3)						; get new effect args
				ld (iy+fx_args),a				; store
				ld a,(ix+2)						; get new effect number
				and 0fh							; store
				ld (iy+fx_number),a

				cp 3							; if fx = tone portamento (or tone portamento+volside)
				jp z,set_portadest				; then period (if >0) goes to slide destination
				cp 5 			
				jr z,set_portadest

				cp 0eh							; check for e5 "fine tune override" command
				jr nz,no_ftoveride
				ld a,(iy+fx_args)
				and 0f0h
				cp 050h
				jr nz,no_ftoveride
				ld a,(iy+fx_args)
				and 0fh
				ld (iy+finetune),a				; overwrite instruments normal tuning value

no_ftoveride

				res 3,(iy+control_bits)			; clear "new period" bit
				ld a,b							; bc = period
				or c							; if period = 0, dont write to frequency settings
				jr z,nonewp1

				set 3,(iy+control_bits)			; allows ED command to know if a new period was specified	
				push bc
				ld (iy+arp_base_period_lo),c	; store untuned version of note for arpeggio 
				ld (iy+arp_base_period_hi),b	; which post converts to tuned values itself
				call finetune_bc_period
				ld (iy+period_for_fx_lo),c		; store tuned version for other fx
				ld (iy+period_for_fx_hi),b
				pop bc
				
nonewp1			ld a,(iy+fx_number)
				cp 0eh							; if fx = $ed: delayed trig - dont trigger note now
				jr nz,not_ed		 
				ld a,(iy+fx_args)
				and 0f0h
				cp 0d0h
				jp z,check_more_fx
				
not_ed			ld a,b							; is a new period given?
				or c			
				jr z,nonewp2
				ld c,(iy+period_for_fx_lo)		; if so lock new period into actual playing freq 
				ld b,(iy+period_for_fx_hi)
				ld (iy+period_lo),c
				ld (iy+period_hi),b
				set 0,(iy+control_bits)			; a new period always retriggers the note
				ld a,(iy+instrument_waiting)	
				or a
				jp z,check_more_fx
				jr do_vol						; update the volume too unless instrument is zero
				
nonewp2			ld a,(iy+instrument_waiting)	; if there's a new instrument and its different
				or a							; to the current instrument, that'll also trigger the note
				jp z,check_more_fx
				cp (iy+instrument)			
				jr z,do_vol
				set 0,(iy+control_bits)

do_vol			ld (iy+instrument),a
				ld a,(iy+volume_waiting)		; new instrument = set volume	
				ld (iy+volume),a	
				ld (iy+volume_for_fx),a			; lock in new instrument's volume
				jp check_more_fx
				

set_portadest

				ld a,b							; if period=0, dont change portamento destination
				or c			
				jr z,spd_same			
				call finetune_bc_period
				ld (iy+portamento_dest_lo),c	
				ld (iy+portamento_dest_hi),b
				
spd_same		ld a,(iy+instrument_waiting)	; check for new instrument - if zero, no new volume or any trigger
				or a			
				ret z
				cp (iy+instrument)				; same instrument? if so, do not retrigger just reset volume
				jr z,skiptrig
				set 0,(iy+control_bits)			; different instrument so set retrigger.
				ld (iy+instrument),a
skiptrig		ld a,(iy+volume_waiting)
				ld (iy+volume),a	
				ld (iy+volume_for_fx),a	
				ret
				


finetune_bc_period

				ld a,(iy+finetune)				; nothing to do if finetune = 0 
				or a
				ret z
				sla a
				ld hl,tuning_table_list	
				ld e,a			
				ld d,0
				add hl,de
				ld e,(hl)
				inc hl	
				ld d,(hl)						; de = start addr of relevent tuning table
				ld hl,period_lookup_table-113
				add hl,bc
				ld a,(hl)						; a = period index 0 - 36
				sla a
				add a,e
				jr nc,ttmok
				inc d
ttmok			ld e,a			
				ex de,hl						; hl =addr of index in crrect tuing table
				ld c,(hl)
				inc hl
				ld b,(hl)						; bc = new tuned value
				ret
				
				
;-------- "FX during line" routines ---------------------------------------------------


not_new_line

				ld iy,channel_data				; not a new line of notes so just update
				ld b,4							; any playing notes using the fx set up when
chanfxlp		push bc							; the line started (if channel is enabled.)
				call check_fx		
				ld bc,vars_per_channel
				add iy,bc
				pop bc
				djnz chanfxlp
				
tick_advance

				ld hl,arpeggio_counter			; arpeggio counter always cycles 0,1,2..0,1,2..
				inc (hl)
				ld a,(hl)
				cp 3
				jr nz,arp_ok
				ld (hl),0
arp_ok			ld hl,ticker					; inc ticker
				inc (hl)
				ld a,(songspeed)	
				cp (hl)							; reached speed count?
				jr nz,nspwrap
				xor a
				ld (hl),a						; reset ticker		
				ld (arpeggio_counter),a			; also zero arpeggio counter on ticker zero (?)
				ld hl,pattdelay_count			; any pattern delay? (from "ee" command)
				or (hl)
				jr z,nopatdel
				dec (hl)						; decrement delay and stay at same note
				jp nspwrap
nopatdel		xor a
				ld (pattdelay_flag),a
				ld hl,patindex
				inc (hl)						; inc pattern line number
				ld a,(hl)
				cp 64							; last line of pattern?
				jr nz,nspwrap
				xor a
				ld (hl),a
				ld (pattloop_pos),a				; clear pattern loop pos (for "e6" command)
				ld (pattloop_count),a			; clear pattern loop count "" ""
				ld hl,songpos		
				inc (hl)						; inc song position
				ld a,(music_module+950)
				cp (hl)							; last song pos?
				jr nz,nspwrap
				ld (hl),0
nspwrap			ret


;--------------------------------------------------------------------------------
				
check_fx		ld a,(iy+fx_number)	
				or a							; these fx are checked during the ticks of a line
				jp z,arpeggio					; (not tick 0)
				cp 1
				jp z,portamento_up
				cp 2
				jp z,portamento_down
				cp 3
				jp z,tone_portamento
				cp 4
				jp z,vibrato
				cp 5
				jp z,tone_portamento_volslide
				cp 6
				jp z,vibrato_volslide
				cp 7
				jp z,tremolo
				cp 0ah
				jp z,volslide
				cp 0eh
				jp z,extended_fx
				ret


check_more_fx

				ld a,(iy+fx_number)				; effects called at the start of lines (tick 0)
				cp 9
				jp z,sample_offset
				cp 0bh			
				jp z,position_jump
				cp 0dh
				jp z,pattern_break
				cp 0eh
				jp z,extended_fx
				cp 0fh
				jp z,set_speed
				cp 0ch
				jp z,set_volume
				ret
					

;------- FX $00 -----------------------------------------------------------------------

arpeggio		ld a,(iy+fx_args)				; dont do arpeggio if fx args = $00
				or a
				ret z
				ld c,(iy+arp_base_period_lo)	; untuned "step 0" period of the arp chord
				ld b,(iy+arp_base_period_hi)
				ld a,(arpeggio_counter)	
				ld e,0
				or a	
				jr z,doarp		
				cp 2
				jr z,arptwo
arpone			ld e,(iy+fx_args)
				srl e
				srl e
				srl e
				srl e							; E = "half-steps" to reach 2nd note of chord
				jr doarp
arptwo			ld a,(iy+fx_args)
				and 15
				ld e,a							; E = "half-steps" to reach 3rd note of chord	
doarp			ld hl,period_lookup_table-113
				add hl,bc
				ld a,(hl)						; note base
				add a,e							; add on arp offset
				sla a
				ld hl,period_table_p0
				add a,l
				jr nc,alumok
				inc h
alumok			ld l,a
				ld c,(hl)
				inc hl
				ld b,(hl)
				call finetune_bc_period
				ld (iy+period_lo),c
				ld (iy+period_hi),b
				ret


;-------- FX $01 ---------------------------------------------------------------------

portamento_up

				ld b,0							; subtract fx arg byte from period
				ld c,(iy+fx_args)				; min value = 113
				ld l,(iy+period_for_fx_lo)
				ld h,(iy+period_for_fx_hi)
				xor a
				sbc hl,bc
				jr c,portumin
				or h
				jr nz,portugnp
				ld a,l
				cp 113
				jr nc,portugnp
portumin		ld hl,113
portugnp		ld (iy+period_for_fx_lo),l
				ld (iy+period_for_fx_hi),h
				ld (iy+period_lo),l
				ld (iy+period_hi),h
				ret

				
;--------- FX $02 -------------------------------------------------------------------

portamento_down			

				ld b,0							; add fx arg byte to period
				ld c,(iy+fx_args)				; max value = 907
				ld l,(iy+period_for_fx_lo)
				ld h,(iy+period_for_fx_hi)
				add hl,bc
				ld a,h
				cp 3
				jr c,portdgnp
				jr nz,portdmax
				ld a,l
				cp 139
				jr c,portdgnp
portdmax		ld hl,856
portdgnp		ld (iy+period_for_fx_lo),l
				ld (iy+period_for_fx_hi),h
				ld (iy+period_lo),l
				ld (iy+period_hi),h
				ret


;--------- FX $03 --------------------------------------------------------------------

tone_portamento

				ld c,(iy+portamento_rate)		; if args = 0, use existing portamento rate
				ld a,(iy+fx_args)
				or a
				jr z,uexistpr
				ld c,a
				ld a,(iy+fx_number)
				cp 3							; only if fx = 3 set this as portamento rate
				jr nz,uexistpr
				ld (iy+portamento_rate),c	
uexistpr		ld e,(iy+portamento_dest_lo)	; de = destination period
				ld d,(iy+portamento_dest_hi)
				ld l,(iy+period_for_fx_lo)		; hl = current period
				ld h,(iy+period_for_fx_hi)
				xor a
				sbc hl,de						; compare hl / de
				ret z							; if same, nothing to do
				jr c,tp_peru					; if de is higher, period requires increasing

tp_perd			ld l,(iy+period_for_fx_lo)		; decrease period by portamento rate
				ld h,(iy+period_for_fx_hi)
				ld b,0
				xor a
				sbc hl,bc						; subtact portamento rate from current period
				jr nc,tp_dnw					; make sure it hasnt been pulled below zero
				ld hl,0
tp_dnw			ld c,l							; store result in bc
				ld b,h
				xor a
				sbc hl,de						; compare with destination
				jr nc,chk_gliss
				ld c,e
				ld b,d
				jr tp_end						; if dest now bigger fix period at destination		

tp_peru			ld l,(iy+period_for_fx_lo)		; increase period by portamento rate
				ld h,(iy+period_for_fx_hi)
				ld b,0
				add hl,bc
				ld c,l							; store result in bc
				ld b,h
				xor a
				sbc hl,de		
				jr c,chk_gliss
				ld c,e							; if destination is now smaller fix period at dest
				ld b,d
				jr tp_end	

chk_gliss		bit 1,(iy+control_bits)			; finally, check if glissando (step slide) is req'd 
				jr nz,do_gliss		
				
tp_end			ld (iy+period_for_fx_lo),c
				ld (iy+period_for_fx_hi),b
				ld (iy+period_lo),c	
				ld (iy+period_hi),b
				ret	
				
do_gliss		ld (iy+period_for_fx_lo),c		; store updated "background" smooth slide
				ld (iy+period_for_fx_hi),b
				ld a,(iy+finetune)	
				sla a
				ld hl,tuning_table_list	
				ld e,a			
				ld d,0
				add hl,de
				ld e,(hl)
				inc hl	
				ld d,(hl)						; de = start of relevent tuning table

				push ix
				push de
				pop ix
				xor a
				ld de,0							; divide period table into 3
				ld l,(ix+22)					; to save max search loop time
				ld h,(ix+23)
				sbc hl,bc
				jr z,tp_glend
				jr c,gltest
				ld de,24
				ld l,(ix+46)
				ld h,(ix+47)
				sbc hl,bc
				jr z,tp_glend
				jr c,gltest
				ld de,48

gltest			add ix,de
				ld d,b
				ld e,c
				xor a
				ld b,12
glissfper		ld l,(ix)						; scan period table for nearest step
				ld h,(ix+1)
				sbc hl,de
				jr nc,nggliss
				ld c,(ix)
				ld b,(ix+1)
tp_glend		ld (iy+period_lo),c	
				ld (iy+period_hi),b
				pop ix
				ret

nggliss			inc ix
				inc ix
				djnz glissfper
				ld b,d
				ld c,e
				jr tp_glend


;--------- FX $04 -----------------------------------------------------------------

vibrato			ld b,(iy+vibrato_args)			; get current args for vibrato effect
				ld a,(iy+fx_number)
				cp 4
				jr nz,vibrsame					; only change args setting if fx_number = 4
				ld a,(iy+fx_args)
				or a
				jr z,vibrsame					; and then only if new args are not zero
				ld c,a
				and 15
				jr z,vibdsame					; if lower nyb = 0, dont change vibrato depth
				ld d,a
				ld a,b
				and 0f0h
				or d
				ld b,a							; update depth side of arg byte
vibdsame		ld a,c
				and 0f0h
				jr z,vibrsame					; if higher nyb = 0, dont change vibrato rate
				ld c,a
				ld a,b
				and 0fh
				or c							; update the rate side of byte
				ld b,a			
vibrsame		ld (iy+vibrato_args),b			; fix settings as current
				
				ld c,(iy+vibrato_pos)
				srl c
				srl c
				ld a,c
				and 1fh
				ld c,a							; c = step 0-31 in wave list
				ld a,(iy+wave_type)	
				and 0fh
				or a							; what type of wave is to used?
				jr z,vib_sine					; 0 = sine wave using lookup table
				sla c		
				sla c
				sla c							; multiply c by 8, now in range 0-248
				cp 1
				jr z,vib_ramp					; 1 = use c as a ramp type vibrato wave
				ld e,255			
				jr vib_gotd						; else, use a square wave

vib_ramp		bit 7,(iy+vibrato_pos)			;
				jr z,vibr2
				ld a,255
				sub c
				ld e,a
				jr vib_gotd
vibr2			ld e,c
				jr vib_gotd

vib_sine		ld hl,vibrato_table				;get wave value from sine table
				ld b,0
				add hl,bc
				ld e,(hl)			

vib_gotd		push ix
				ld a,(iy+vibrato_args)	
				cpl
				and 0fh			
				ld c,a							;get depth of effect in c (flipped for jump table)
				ld b,0			
				ld d,b
				ld hl,vmul15
				add hl,bc
				push hl
				pop ix
				ld h,b
				ld l,b
				jp (ix)							; multiply wave value (de) by depth
vmul15			add hl,de						;+0 
vmul14			add hl,de						;+1
vmul13			add hl,de						;+2
vmul12			add hl,de						;+3
vmul11			add hl,de						;+4
vmul10			add hl,de						;+5
vmul9			add hl,de						;+6
vmul8			add hl,de						;+7
vmul7			add hl,de						;+8
vmul6			add hl,de						;+9
vmul5			add hl,de						;+10
vmul4			add hl,de						;+11
vmul3			add hl,de						;+12
vmul2			add hl,de						;+13
vmul1			add hl,de						;+14
vmul0			sla l							;15 - divide result in hl by 128
				rl h
				ld e,h
				ld d,0
				pop ix
				
				ld l,(iy+period_for_fx_lo)		; normal "base" period
				ld h,(iy+period_for_fx_hi)
				bit 7,(iy+vibrato_pos)
				jr nz,vib_sub	
				add hl,de						; add on the displacement
				jr vib_pdone
vib_sub			xor a
				sbc hl,de						; subtract the displacement
vib_pdone		ld (iy+period_lo),l
				ld (iy+period_hi),h

				ld b,(iy+vibrato_pos)			; get the current vibrato index position
				ld a,(iy+vibrato_args)
				srl a
				srl a
				and 3ch							; add on speed nybble arg * 4
				add a,b
				ld (iy+vibrato_pos),a			; update vibrato index position
				ret


;-------- FX $05 -------------------------------------------------------------------
				
tone_portamento_volslide

				call tone_portamento
				jp volslide

			
;-------- FX $06 -------------------------------------------------------------------
				
vibrato_volslide	
				
				call vibrato
				jp volslide
				
				
;-------- FX $07 ------------------------------------------------------------------

tremolo			ld b,(iy+tremolo_args)			; get current args for tremolo effect
				ld a,(iy+fx_args)
				or a
				jr z,trersame					; only change if new args are not zero
				ld c,a
				and 15
				jr z,tredsame					; if lower nyb = 0, dont change tremolo depth
				ld d,a
				ld a,b
				and 0f0h
				or d
				ld b,a							; update depth side of arg byte
tredsame		ld a,c
				and 0f0h
				jr z,trersame					; if higher nyb = 0, dont change tremolo rate
				ld c,a
				ld a,b
				and 0fh
				or c							; update the rate side of byte
				ld b,a			
trersame		ld (iy+tremolo_args),b			; fix settings as current
				
				ld c,(iy+tremolo_pos)
				srl c
				srl c
				ld a,c
				and 1fh
				ld c,a							; c = step 0-31 in wave list
				ld a,(iy+wave_type)				; type of tremolo wave is in the upper 4 bits
				srl a
				srl a
				srl a
				srl a
				and 0fh							; what type of wave is to used?
				jr z,tre_sine					; 0 = sine wave using lookup table
				sla c		
				sla c
				sla c							; multiply c by 8, now in range 0-248
				cp 1
				jr z,tre_ramp					; 1 = use c as a ramp type tremolo wave
				ld e,255			
				jr tre_gotd						; else, use a square wave

tre_ramp		bit 7,(iy+tremolo_pos)			;
				jr z,trer2
				ld a,255
				sub c
				ld e,a
				jr tre_gotd
trer2			ld e,c
				jr tre_gotd

tre_sine		ld hl,vibrato_table				;get wave value from sine table
				ld b,0
				add hl,bc
				ld e,(hl)			

tre_gotd		push ix
				ld a,(iy+tremolo_args)	
				cpl
				and 0fh			
				ld c,a							;get depth of effect in c (flipped for jump table)
				ld b,0			
				ld d,b
				ld hl,tmul15
				add hl,bc
				push hl
				pop ix
				ld h,b
				ld l,b
				jp (ix)							; multiply wave value (de) by depth
tmul15			add hl,de						;+0 
tmul14			add hl,de						;+1
tmul13			add hl,de						;+2
tmul12			add hl,de						;+3
tmul11			add hl,de						;+4
tmul10			add hl,de						;+5
tmul9			add hl,de						;+6
tmul8			add hl,de						;+7
tmul7			add hl,de						;+8
tmul6			add hl,de						;+9
tmul5			add hl,de						;+10
tmul4			add hl,de						;+11
tmul3			add hl,de						;+12
tmul2			add hl,de						;+13
tmul1			add hl,de						;+14
tmul0			sla l							;+15 - divide result in hl by 64
				rl h
				sla l
				rl h
				ld l,h
				pop ix
				
tshftl			ld a,(iy+volume_for_fx)			; normal "base" volume
				bit 7,(iy+tremolo_pos)
				jr nz,tre_sub	
				add a,l							; add on the displacement
				cp 64
				jr c,tre_done
				ld a,64
				jr tre_done
tre_sub			sub l							; subtract the displacement
				jr nc,tre_done
				xor a
tre_done		ld (iy+volume),a
				
				ld b,(iy+tremolo_pos)			; get the current tremolo index position
				ld a,(iy+tremolo_args)
				srl a
				srl a
				and 3ch							; add on speed nybble arg * 4
				add a,b
				ld (iy+tremolo_pos),a			; update tremolo index position
				ret

;-------- FX $09 -------------------------------------------------------------------

sample_offset

				ld a,(iy+fx_args)		
				or a
				jr z,usexoffs					; use existing offset if args = 0
				ld b,a
				ld c,0
				srl b
				rr c							; bc = offset in words
				ld (iy+samp_offset_lo),c
				ld (iy+samp_offset_hi),b
				
usexoffs		ld c,(iy+samp_offset_lo)		; check if offset is larger than length of sample
				ld b,(iy+samp_offset_hi)
				ld l,(iy+samp_len_lo)
				ld h,(iy+samp_len_hi)
				xor a
				sbc hl,bc
				jr z,soffbad
				jr c,soffbad
				ld (iy+samp_len_lo),l			; adjust the length of the sample
				ld (iy+samp_len_hi),h
				ld l,(iy+samp_loc_lo)
				ld h,(iy+samp_loc_hi)
				add hl,bc
				ld (iy+samp_loc_lo),l			; adjust the start position of the sample
				ld (iy+samp_loc_hi),h
				ret

soffbad			ld (iy+samp_len_lo),1			; if offset is too high, just set the sample 
				ld (iy+samp_len_hi),0			; length at 1
				ret
				

;-------- FX $0A -----------------------------------------------------------------------


volslide		ld a,(iy+fx_args)				; sub lower nybble of fx args from volume	
				ld b,a
				and 15			
				jr z,volup
				ld a,(iy+volume)
				sub b
				jr nc,voldok
				xor a
voldok			ld (iy+volume),a
				ret

volup			ld a,b							; or add higher nybble of fx args >>4 to volume
				rrca
				rrca
				rrca
				rrca
				add a,(iy+volume)
				cp 64
				jr c,voluok
				ld a,64
voluok			ld (iy+volume),a
				ret


;-------- FX $0B -------------------------------------------------------------------

position_jump

				ld a,(iy+fx_args)
				ld (songpos),a
				ld a,255
				ld (patindex),a
				ret


;-------- FX $0C -------------------------------------------------------------------

set_volume
				
				ld a,(iy+fx_args)
				cp 40h
				jr c,vsetok
				ld a,40h
vsetok			ld (iy+volume),a
				ld (iy+volume_waiting),a
				ret


;-------- FX $0D -------------------------------------------------------------------

pattern_break
				
				ld a,(iy+fx_args)
				ld b,a
				srl a
				srl a
				srl a
				srl a
				ld c,a
				add a,c
				add a,c
				add a,c
				add a,c
				sla a
				ld c,a
				ld a,b
				and 0fh
				add a,c
				dec a
				ld (patindex),a
				ld hl,songpos
				inc (hl)
				ld a,(music_module+950)
				cp (hl)								; last song pos?
				jr nz,nspw_pb
				ld (hl),0
nspw_pb			ret

				
;-------- FX $0E --------------------------------------------------------------------


extended_fx

				ld a,(iy+fx_args)
				ld b,a
				and 0f0h
				cp 0h
				jr z,e0_filter
				cp 10h
				jr z,e1_fineport_up
				cp 20h
				jr z,e2_fineport_down
				cp 30h
				jp z,e3_glissando_control
				cp 40h
				jp z,e4_vibrato_control
				cp 50h
				jp z,e5_finetune_control
				cp 60h
				jp z,e6_pattern_loop
				cp 70h
				jp z,e7_tremolo_control
				cp 90h
				jp z,e9_retrigger_note
				cp 0a0h
				jp z,ea_finevol_up
				cp 0b0h
				jp z,eb_finevol_down
				cp 0c0h
				jp z,ec_cutnote
				cp 0d0h
				jp z,ed_delayedtrig
				cp 0e0h
				jp z,ee_pattdelay
				ret

e0_filter

				ld a,b							; set sound filter on or off
				and 01h			
				ld (filter_on_off),a
				ret
				

e1_fineport_up

				ld a,(ticker)
				or a
				ret nz
				ld b,0							; subtract fx arg lo nyb from period, once only
				ld a,(iy+fx_args)		
				and 0fh
				ld c,a
				ld l,(iy+period_lo)
				ld h,(iy+period_hi)
				xor a
				sbc hl,bc
				jr c,fportumin
				or h
				jr nz,fportugnp
				ld a,l
				cp 113
				jr nc,fportugnp
fportumin		ld hl,113						; min period = 113
fportugnp		ld (iy+period_lo),l
				ld (iy+period_hi),h
				ret


e2_fineport_down
				
				ld a,(ticker)
				or a
				ret nz
				ld b,0							; add fx arg low nyb to period, once only
				ld a,(iy+fx_args)		
				and 0fh
				ld c,a
				ld l,(iy+period_lo)
				ld h,(iy+period_hi)
				add hl,bc
				ld a,h
				cp 3
				jr c,fportdgnp
				jr nz,fportdmax
				ld a,l
				cp 88
				jr c,fportdgnp
fportdmax		ld hl,856						; max period = 856
fportdgnp		ld (iy+period_lo),l
				ld (iy+period_hi),h
				ret


e3_glissando_control

				res 1,(iy+control_bits)
				ld a,b
				and 01h
				ret z
				set 1,(iy+control_bits)
				ret


e4_vibrato_control
				
				ld a,b
				and 07h
				ld b,a
				ld a,(iy+wave_type)
				and 0f0h
				or b
				ld (iy+wave_type),a
				ret


e5_finetune_control
				
				ld a,b							; override the finetune value of this instrument
				and 0fh			
				ld (iy+finetune),a
				ret


e6_pattern_loop

				ld a,(ticker)
				or a
				ret nz
				ld a,b
				and 0fh
				jr z,setplp
				ld hl,pattloop_count
				inc (hl)
				cp (hl)
				jr c,plp_end
				ld a,(pattloop_pos)					;jump back to previously stored position
				dec a								;compensate for normal increment
				ld (patindex),a
				ret
plp_end			xor a			
				ld (pattloop_count),a				;loop count maxed, continue with pattern
				ret
setplp			ld a,(patindex)						;set pattern loop jump back position
				ld (pattloop_pos),a
				ret
				

e7_tremolo_control
				
				ld a,b
				and 07h
				ld b,a
				sla b
				sla b
				sla b
				sla b
				ld a,(iy+wave_type)
				and 0fh
				or b
				ld (iy+wave_type),a
				ret
				

e9_retrigger_note

				ld a,b
				and 0fh
				ret z
				ld b,a
				ld a,(ticker)
				or a
				jr z,retrigit
rtloop			sub b
				jr z,retrigit
				jr nc,rtloop
				ret
retrigit		set 0,(iy+control_bits)
				ret
				


ea_finevol_up

				ld a,(ticker)
				or a
				ret nz
				ld a,b
				and 0fh
				add a,(iy+volume)
				cp 64
				jr c,eavolok
				ld a,64
eavolok			ld (iy+volume),a
				ret
				

eb_finevol_down
					
				ld a,(ticker)
				or a
				ret nz
				ld a,b
				and 0fh
				ld b,a
				ld a,(iy+volume)
				sub b
				jr nc,ebvolok
				xor a
ebvolok			ld (iy+volume),a
				ret


ec_cutnote

				ld a,b
				and 0fh
				ld b,a
				ld a,(ticker)
				cp b
				ret nz
				xor a
				ld (iy+volume),a
				ret
				


				
ed_delayedtrig	
				
				ld a,b
				and 0fh
				ld b,a
				ld a,(ticker)
				cp b
				ret nz
				
				bit 3,(iy+control_bits)				; was a new period specifed?
				jr z,ed_nonewp2
				ld c,(iy+period_for_fx_lo)			; if so lock new period into actual playing freq 
				ld b,(iy+period_for_fx_hi)
				ld (iy+period_lo),c
				ld (iy+period_hi),b
				set 0,(iy+control_bits)				; a new period always retriggers the note
				ld a,(iy+instrument_waiting)	
				or a
				ret z
				jr ed_do_vol						; update the volume too unless instrument is zero
				
ed_nonewp2

				ld a,(iy+instrument_waiting)		; if there's a new instrument and its different
				or a								; to the current instrument, that'll also trigger the note
				ret z
				cp (iy+instrument)			
				jr z,ed_do_vol
				set 0,(iy+control_bits)

ed_do_vol		ld (iy+instrument),a
				ld a,(iy+volume_waiting)			; new instrument = set volume	
				ld (iy+volume),a	
				ld (iy+volume_for_fx),a				; lock in new instrument's volume
				ret



				
				
ee_pattdelay

				ld a,(pattdelay_flag)				;if already delayed skip this
				or a
				ret nz
				ld a,b
				and 0fh
				ld (pattdelay_count),a
				ld a,1
				ld (pattdelay_flag),a
				ret
				


;-------- FX $0F -------------------------------------------------------------------

set_speed
				ld a,(iy+fx_args)
				ld (songspeed),a
				ret


;---- Amiga Period List ------------------------------------------------------------

period_lookup_table	

					DB 35,0,0,0,0,0,0,34,0,0,0,0,0,0,33,0
					DB 0,0,0,0,0,0,32,0,0,0,0,0,0,0,31,0
					DB 0,0,0,0,0,0,30,0,0,0,0,0,0,0,0,29
					DB 0,0,0,0,0,0,0,0,0,28,0,0,0,0,0,0
					DB 0,0,0,27,0,0,0,0,0,0,0,0,0,26,0,0
					DB 0,0,0,0,0,0,0,0,0,25,0,0,0,0,0,0
					DB 0,0,0,0,0,24,0,0,0,0,0,0,0,0,0,0
					DB 0,23,0,0,0,0,0,0,0,0,0,0,0,0,0,22
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,21,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,20,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,19,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,18,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,15,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,14,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,13,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,11,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
					DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


tuning_table_list	dw period_table_p0
					dw period_table_p1
					dw period_table_p2
					dw period_table_p3
					dw period_table_p4
					dw period_table_p5
					dw period_table_p6
					dw period_table_p7
					dw period_table_m8
					dw period_table_m7
					dw period_table_m6
					dw period_table_m5
					dw period_table_m4
					dw period_table_m3
					dw period_table_m2
					dw period_table_m1
		

period_table_p0	dw 856,808,762,720,678,640,604,570,538,508,480,453
				dw 428,404,381,360,339,320,302,285,269,254,240,226
				dw 214,202,190,180,170,160,151,143,135,127,120,113

period_table_p1	dw 850,802,757,715,674,637,601,567,535,505,477,450
				dw 425,401,379,357,337,318,300,284,268,253,239,225
				dw 213,201,189,179,169,159,150,142,134,126,119,113

period_table_p2	dw 844,796,752,709,670,632,597,563,532,502,474,447
				dw 422,398,376,355,335,316,298,282,266,251,237,224
				dw 211,199,188,177,167,158,149,141,133,125,118,112

period_table_p3	dw 838,791,746,704,665,628,592,559,528,498,470,444
				dw 419,395,373,352,332,314,296,280,264,249,235,222
				dw 209,198,187,176,166,157,148,140,132,125,118,111

period_table_p4	dw 832,785,741,699,660,623,588,555,524,495,467,441
				dw 416,392,370,350,330,312,294,278,262,247,233,220
				dw 208,196,185,175,165,156,147,139,131,124,117,110

period_table_p5	dw 826,779,736,694,655,619,584,551,520,491,463,437
				dw 413,390,368,347,328,309,292,276,260,245,232,219
				dw 206,195,184,174,164,155,146,138,130,123,116,109

period_table_p6	dw 820,774,730,689,651,614,580,547,516,487,460,434
				dw 410,387,365,345,325,307,290,274,258,244,230,217
				dw 205,193,183,172,163,154,145,137,129,122,115,109

period_table_p7	dw 814,768,725,684,646,610,575,543,513,484,457,431
				dw 407,384,363,342,323,305,288,272,256,242,228,216
				dw 204,192,181,171,161,152,144,136,128,121,114,108

period_table_m8	dw 907,856,808,762,720,678,640,604,570,538,508,480
				dw 453,428,404,381,360,339,320,302,285,269,254,240
				dw 226,214,202,190,180,170,160,151,143,135,127,120

period_table_m7	dw 900,850,802,757,715,675,636,601,567,535,505,477
				dw 450,425,401,379,357,337,318,300,284,268,253,238
				dw 225,212,200,189,179,169,159,150,142,134,126,119

period_table_m6	dw 894,844,796,752,709,670,632,597,563,532,502,474
				dw 447,422,398,376,355,335,316,298,282,266,251,237
				dw 223,211,199,188,177,167,158,149,141,133,125,118

period_table_m5	dw 887,838,791,746,704,665,628,592,559,528,498,470
				dw 444,419,395,373,352,332,314,296,280,264,249,235
				dw 222,209,198,187,176,166,157,148,140,132,125,118

period_table_m4	dw 881,832,785,741,699,660,623,588,555,524,494,467
				dw 441,416,392,370,350,330,312,294,278,262,247,233
				dw 220,208,196,185,175,165,156,147,139,131,123,117

period_table_m3	dw 875,826,779,736,694,655,619,584,551,520,491,463
				dw 437,413,390,368,347,328,309,292,276,260,245,232
				dw 219,206,195,184,174,164,155,146,138,130,123,116

period_table_m2	dw 868,820,774,730,689,651,614,580,547,516,487,460
				dw 434,410,387,365,345,325,307,290,274,258,244,230
				dw 217,205,193,183,172,163,154,145,137,129,122,115

period_table_m1	dw 862,814,768,725,684,646,610,575,543,513,484,457
				dw 431,407,384,363,342,323,305,288,272,256,242,228
				dw 216,203,192,181,171,161,152,144,136,128,121,114

;----- Vibrato sine wave -----------------------------------------------------------

vibrato_table		db 000,024,049,074,097,120,141,161
					db 180,197,212,224,235,244,250,253
					db 255,253,250,244,235,224,212,197
					db 180,161,141,120,097,074,049,024

;-----------------------------------------------------------------------------------

multiply_30_table	dw 000,030,060,090,120,150,180,210
					dw 240,270,300,330,360,390,420,450
					dw 480,510,540,570,600,630,660,690
					dw 720,750,780,810,840,870,900,930

;-----------------------------------------------------------------------------------

sample_base				dw 0			; "init_tracker" sets this variable
force_sample_base		dw 0			; set to $ffff if samples are NOT split from mod

sample_location_list	blkb 62,0		; for 31 instruments

;-----------------------------------------------------------------------------------

ticker				db 0
songpos				db 0
patindex			db 0
songspeed			db 0
arpeggio_counter	db 0
pattloop_pos		db 0
pattloop_count		db 0
pattdelay_count		db 0
pattdelay_flag		db 0
filter_on_off		db 0

;-----------------------------------------------------------------------------------

vars_per_channel	equ 33

channel_data		blkb vars_per_channel*4,0
	
instrument			equ 0
period_lo			equ 1
period_hi			equ 2
volume				equ 3
fx_number			equ 4
fx_args				equ 5
period_for_fx_lo	equ 6
period_for_fx_hi	equ 7
volume_for_fx		equ 8
portamento_rate		equ 9
vibrato_args		equ 10
vibrato_pos			equ 11
tremolo_args		equ 12
tremolo_pos			equ 13
wave_type 			equ 14		;bits 7:4 = tremolo / bits 0:3 = vibrato
control_bits		equ 15		;bit 0 = note triggered, 1 = glissando on/off 
portamento_dest_lo	equ 16		;bit 2 = channel muted, bit 3 = there was a new period specified (for cmd ed)
portamento_dest_hi	equ 17
instrument_waiting	equ 18
volume_waiting		equ 19
finetune			equ 20
arp_base_period_lo  equ 21
arp_base_period_hi	equ 22

samp_loc_lo			equ 23
samp_loc_hi			equ 24
samp_len_lo			equ 25
samp_len_hi			equ 26
samp_loop_loc_lo	equ 27
samp_loop_loc_hi	equ 28
samp_loop_len_lo	equ 29
samp_loop_len_hi	equ 30
samp_offset_lo		equ 31
samp_offset_hi		equ 32

;========================================================================================
; End of non-hardware specific Z80 Protracker code. 
;========================================================================================

