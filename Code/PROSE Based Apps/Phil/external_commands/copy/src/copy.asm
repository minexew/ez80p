;copy file command v0.01 by Phil

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 3bh				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

buffer_size equ 32768

			xor a
			ld (final_chunk),a
			
			push hl
			ld bc,buffer_size
			ld a,kr_allocate_ram
			ld e,0
			call.lil prose_kernal
			ld (buffer_loc),hl
			
			ld a,kr_get_volume_info
			call.lil prose_kernal
			ld (orig_volume),a
			ld a,kr_get_dir_cluster
			call.lil prose_kernal
			ld (orig_dir_cluster),de
 			pop hl
			
			call do_copy
			
			push af
			call set_orig_dir
			
			ld bc,(buffer_size)
			ld e,0
			ld a,kr_deallocate_ram
			call.lil prose_kernal

			pop af
			jp.lil prose_return

;---------------------------------------------------------------------------------------------

do_copy		ld a,(hl)
			or a
			jr nz,got_args					; if no args, show use
			
			ld a,kr_print_string
			ld hl,use_txt
			call.lil prose_kernal
			xor a
			ret

got_args	ld (src_string_loc),hl			;save source path string location
			call next_arg
			jr nz,arg_ok
			ld a,8dh						;if no dest path string follows, show "missing args" error
			or a
			ret
arg_ok		ld (dest_string_loc),hl
			
			ld hl,(src_string_loc)
			ld a,kr_parse_path
			ld e,0
			call.lil prose_kernal			;move to source directory
			ret nz
			ld (src_filename_loc),hl		;store source filename location
			ld a,kr_open_file
			call.lil prose_kernal			;if the file doesn't exist, quit (file not found)
			ret nz
			ld (file_length),de				;note the length of the file
			ld a,c
			ld (file_length+3),a
			ld a,kr_get_volume_info
			call.lil prose_kernal			;note volume and dir cluster of sourse
			ld (src_volume),a
			ld a,kr_get_dir_cluster
			call.lil prose_kernal
			ld (src_dir_cluster),de
			
			call set_orig_dir				;go back to default dir/vol - paths are relative to that
			
			ld hl,(dest_string_loc)
			ld a,kr_parse_path
			ld e,1
			call.lil prose_kernal
			ret nz							;quit if dest path is not found
			ld a,kr_get_volume_info
			call.lil prose_kernal
			ld (dest_volume),a
			ld a,kr_get_dir_cluster
			call.lil prose_kernal
			ld (dest_dir_cluster),de		;note volume and cluster of destination
			ld hl,(src_filename_loc)
			ld a,kr_create_file
			call.lil prose_kernal
			ret nz							;create the file - just quit if it already exists

			ld de,0
			ld (file_pointer),de
			xor a
			ld (file_pointer+3),a
			
copy_loop	call set_source_dir				;read source file bytes into buffer
			ld hl,(src_filename_loc)
			ld a,kr_open_file
			call.lil prose_kernal
			ret nz
			ld de,(file_pointer)
			ld a,(file_pointer+3)
			ld c,a
			ld a,kr_set_file_pointer
			call.lil prose_kernal
			ld de,buffer_size
			ld a,kr_set_load_length
			call.lil prose_kernal
			ld hl,(buffer_loc)
			ld a,kr_read_file
			call.lil prose_kernal
			ret nz
			
			ld hl,(file_length)
			ld a,(file_length+3)
			or a								;clear carry flag
			ld de,buffer_size
			ld b,0
			sbc hl,de
			sbc b
			ld (file_length),hl
			ld (file_length+3),a
			ld bc,buffer_size					;default bytes to write
			jr c,last_chunk
			ld ix,file_length
			ld a,(ix)
			or (ix+1)
			or (ix+2)
			or (ix+3)
			jr nz,not_last_chunk

last_chunk	add hl,bc
			push hl
			pop bc								;bytes to write if last chunk
			ld a,1
			ld (final_chunk),a

not_last_chunk
			
			push bc								;append the loaded bytes to the dest file
			call set_destination_dir	
			pop bc
			ld hl,(src_filename_loc)
			ld de,(buffer_loc)
			ld a,kr_write_file
			call.lil prose_kernal
			ret nz
			
			ld hl,(file_pointer)
			ld a,(file_pointer+3)
			ld de,buffer_size
			ld b,0
			add hl,de
			adc a,b
			ld (file_pointer),hl
			ld (file_pointer+3),a

			ld a,(final_chunk)
			or a
			jr z,copy_loop
			xor a
			ret
			
set_orig_dir
			
			ld a,(orig_volume)
			ld e,a
			ld a,kr_change_volume
			call.lil prose_kernal
			ld de,(orig_dir_cluster)
			ld a,kr_set_dir_cluster
			call.lil prose_kernal
			ret


set_source_dir
			
			ld a,(src_volume)
			ld e,a
			ld a,kr_change_volume
			call.lil prose_kernal
			ld de,(src_dir_cluster)
			ld a,kr_set_dir_cluster
			call.lil prose_kernal
			ret


set_destination_dir
			
			ld a,(dest_volume)
			ld e,a
			ld a,kr_change_volume
			call.lil prose_kernal
			ld de,(dest_dir_cluster)
			ld a,kr_set_dir_cluster
			call.lil prose_kernal
			ret
						

;------------------------------------------------------------------------------------------------

; ZF set if no more args.

next_arg	inc hl
			ld a,(hl)						;find a space
			or a
			ret z
			cp ' '
			jr nz,next_arg
narg2		inc hl
			ld a,(hl)						;find a non-space
			or a
			ret z
			cp ' '
			jr z,narg2
			ret
			
;------------------------------------------------------------------------------------------------
			
orig_volume			db 0
orig_dir_cluster	dw24 0
src_volume			db 0
src_dir_cluster		dw24 0
dest_volume			db 0
dest_dir_cluster	dw24 0

src_string_loc		dw24 0
dest_string_loc		dw24 0
src_filename_loc	dw24 0
buffer_loc			dw24 0

file_length			db 0,0,0,0
file_pointer		db 0,0,0,0

final_chunk			db 0

;---------------------------------------------------------------------------------------------

use_txt		db 'Use: COPY source_path/filename1 dest_path/filename2',11,0
	
;---------------------------------------------------------------------------------------------
