;*****************************************************************************
; cstartup.asm
;
; ZDS II C Runtime Startup for the eZ80 and eZ80Acclaim! C Compiler
;*****************************************************************************
; Copyright (C) 2005 by ZiLOG, Inc.  All Rights Reserved.
;*****************************************************************************

        XDEF _errno
        XDEF __c_startup
        XDEF __cstartup
        XREF _main

        __cstartup EQU %1

;*****************************************************************************
; Startup code
        DEFINE .STARTUP, SPACE = ROM
        SEGMENT .STARTUP
        .ASSUME ADL=1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initializes the C environment
__c_startup:
	call		_main
	xor			a
	jp.lil		0a14h	; Prose return

;*****************************************************************************
; Define global system var _errno. Used by floating point libraries
;
	SEGMENT 	DATA
;
_errno:
    DS 			3                   ; extern int _errno

;*****************************************************************************
; Initial reset
;  1. skip the header
;  2. include the PROSE .EZP header
;
	DEFINE 		.RESET, SPACE = ROM
	SEGMENT 	.RESET
;
_reset:
	jr 			__skip_hdr			; Skip the header
	db 			'PRO'				; PROSE Signature
mb_loc 
	dw24 		10000h				; Load location
	dw24 		0					; Truncate load to n bytes if >0
	dw 			0					; Minimum PROSE version if >0
	dw 			0					; Minimum AMOEBA version if >0
	db 			1					; Z80 (0) or ADL mode (1)
__skip_hdr:	
;
;*****************************************************************************
; Usually interrupt vectors,
; but not supporting those here
;
	DEFINE 		.IVECTS, SPACE = ROM
	SEGMENT 	.IVECTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
	END
;