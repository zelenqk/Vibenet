if (point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), x, y, x + sprite_width, y + sprite_height)){
	if (mouse_check_button_pressed(mb_left)){
		selected = true;	
		
		keyboard_string = text;
	}
}


if (selected){
	text = keyboard_string;	

	if (keyboard_check_pressed(vk_enter)){
		messages.add(text);
		
		var buffer = buffer_create(string_byte_length(text) + 2, buffer_fixed, 1); 
		buffer_write(buffer, buffer_u8, 0x02);
		buffer_write(buffer, buffer_string, text);
		
		client.punch.broadcast(buffer);
		buffer_delete(buffer);
		
		text = "";
		selected = false;
	}
}