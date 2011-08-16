;============================================================================
;
; PROSE Kernal Routines and other definitions for EZ80P Platform
;
;============================================================================

	.assume 	ADL=1
	XDEF		_KR_Mount_Volumes
	XDEF		_KR_Time_Delay

	KR_MOUNT_VOLUMES	equ		00h
	KR_TIME_DELAY		equ		39h
	
	PROSE_KERNAL		equ		0a20h
	
;extern BYTE KR_Mount_Volumes(bool suppressText);
_KR_Mount_Volumes:
	ld			iy, 0
	add			iy, sp
	ld			a, (iy + 3)				; suppressText
	xor			a
	jr			z, __MNT0
	ld			a, 01h
__MNT0:
	ld			e, a
	ld			a, KR_MOUNT_VOLUMES
	call.lil	PROSE_KERNAL
	ld			h, 0
	ld			l, a
	ret
	
;extern BYTE KR_Time_Delay(WORD ticks);
_KR_Time_Delay:
	ld			iy, 0
	add			iy, sp
	ld			de, (iy + 3)			; ticks
	ld			a, KR_TIME_DELAY
	push 		ix
	call.lil	PROSE_KERNAL
	pop			ix
	ld			h, 0
	ld			l, a
	ret
	