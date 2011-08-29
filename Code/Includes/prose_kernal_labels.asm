;--------- PROSE Kernal Routine labels ---------------------------------------------------
		
kr_mount_volumes				equ 00h	
kr_get_device_info				equ 01h	
kr_check_volume_format			equ 02h	
kr_change_volume				equ 03h	
kr_get_volume_info				equ 04h	
kr_format_device				equ 05h	
kr_make_dir						equ 06h

kr_change_dir					equ 07h	
kr_parent_dir					equ 08h	
kr_root_dir						equ 09h
kr_delete_dir					equ 0ah
kr_find_file					equ 0bh
kr_set_file_pointer				equ 0ch
kr_set_load_length				equ 0dh
kr_read_file					equ 0eh

kr_erase_file					equ 0fh
kr_rename_file					equ 10h
kr_create_file					equ 11h
kr_write_file					equ 12h
kr_get_total_sectors			equ 13h
kr_dir_list_first_entry			equ 14h
kr_dir_list_get_entry			equ 15h
kr_dir_list_next_entry			equ 16h

kr_read_sector					equ 17h
kr_write_sector					equ 18h
kr_file_sector_list				equ 19h
kr_get_dir_cluster				equ 1ah
kr_set_dir_cluster				equ 1bh
kr_get_dir_name					equ 1ch
kr_wait_key						equ 1dh
kr_get_key						equ 1eh

kr_get_key_mod_flags			equ 1fh
kr_serial_receive_header		equ 20h
kr_serial_receive_file			equ 21h
kr_serial_send_file				equ 22h
kr_serial_tx_byte				equ 23h
kr_serial_rx_byte				equ 24h

kr_print_string					equ 25h
kr_clear_screen					equ 26h
kr_wait_vrt						equ 27h
kr_set_cursor_position			equ 28h
kr_plot_char					equ 29h
kr_set_pen						equ 2ah
kr_background_colours			equ 2bh
kr_draw_cursor					equ 2ch
kr_get_pen						equ 2dh
kr_scroll_up					equ 2eh
kr_os_display					equ 2fh

kr_get_display_size				equ 30h	
kr_get_video_mode				equ 30h	;prefered name for above

kr_get_charmap_addr_xy			equ 31h
kr_get_cursor_position			equ 32h

kr_set_envar					equ 33h
kr_get_envar					equ 34h
kr_delete_envar					equ 35h

kr_set_mouse_window				equ 36h
kr_get_mouse_position			equ 37h

kr_get_mouse_motion				equ 38h
kr_get_mouse_counters			equ 38h	;preferred name for above

kr_time_delay					equ 39h
kr_compare_strings				equ 3ah
kr_hex_byte_to_ascii			equ 3bh
kr_ascii_to_hex_word			equ 3ch
kr_get_string					equ 3dh

kr_get_version					equ 3eh
kr_dont_store_registers			equ 3fh
kr_get_font_info				equ 40h
kr_read_rtc						equ 41h
kr_write_rtc					equ 42h

kr_get_keymap_location			equ 43h

kr_get_os_high_mem				equ 44h
kr_get_mem_base					equ 44h	;preferred name for above

kr_play_audio					equ 45h
kr_disable_audio				equ 46h
kr_get_joysticks				equ 47h
kr_set_video_mode				equ 48h
kr_set_cursor_image				equ 49h
kr_remove_cursor				equ 4ah
kr_char_to_font					equ 4bh

kr_get_disk_sector_ptr			equ 4ch
kr_set_timeout					equ 4dh
kr_test_timeout					equ 4eh
kr_set_pointer					equ 4fh
kr_allocate_ram					equ 50h
kr_deallocate_ram				equ 51h
kr_get_mem_top					equ 52h

;---------------------------------------------------------------------------------------------------
