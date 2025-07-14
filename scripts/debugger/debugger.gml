function debugger() constructor{
	logs = [];
	
	x = 100;
	y = 100;
	
	commands = {};
	
	width = display_get_gui_width() / 2.5;
	height = display_get_gui_height() / 3;
	
	surface = surface_create(width, height);
	
	visible = false;
	
	log = function(text, col = c_white){
		array_push(logs, {text: text, col: col});
	}
	
	fontSize = 12;
	fontScale = fontSize / font_get_size(fntMono);
	
	theight = 0;
	ptheight = 0;
	
	var hHeight = 24;
	header = {
		"width": width,
		"height": hHeight,
		"fontScale": (hHeight / font_get_size(fntMono)) * 0.75,
		"hold": false,
		"offset": [0, 0],
	}
	
	slider = {
		"width": width / 48,
		"height": height,
		"value": 0,
		"hover": false,
		"hold": false,
		"offset": 0,
		"follow": true,
	}
	
	textbox = {
		"height": hHeight,
		"fontScale": (hHeight / font_get_size(fntMono)) * 0.65,
		"selected": false,
		"text": "",
		"cursor": 0,
		"blink": true,
		"timer": 1,
	}
	
	command = function(text){
		var tokens = string_split(text, " ");
		var cmd = commands[$ tokens[0]];
		if (cmd == undefined){
			log("command " + tokens[0] + " doesnt exist");
			return;
		}
		
		script_execute_ext(cmd, tokens, 1);
	}
	
	slider.draw = function(){
		var th = (height < theight) ? clamp((height / theight) * height, 16, height) : height;
		slider.height += ((th - slider.height) * 0.25) * dt;
		
		slider.height = clamp(slider.height, 16, height);
		slider.hover = mouse_in_box(x + width - slider.width, y, slider.width, height);
		
		if (slider.hover){
			if (mouse_check_button_pressed(mb_left)){
				var mouseY = device_mouse_y_to_gui(0);
				var thumb_top = y + height * slider.value;
				var thumb_bottom = thumb_top + slider.height;
				slider.hold = true;
				
				if (mouseY >= thumb_top and mouseY <= thumb_bottom){
					slider.offset = (mouseY - (height * slider.value));
				}else{
					slider.value = (mouseY - y - slider.height / 2) / height;
					slider.value = clamp(slider.value, 0, 1 - (slider.height / height));
					slider.offset = (mouseY - (height * slider.value));
				}
			}
		}
			

		if (slider.follow) slider.value = 1;
		 
		if (!slider.follow and ptheight != theight){
			var pixelOffset = slider.value * ptheight;
			slider.value = pixelOffset / theight;
			slider.value = clamp(slider.value, 0, 1 - (slider.height / height));
		}
		
		if (slider.hold){
			slider.value = (device_mouse_y_to_gui(0) - slider.offset) / height;
			slider.value = clamp(slider.value, 0, 1 - (slider.height / height));
			slider.follow = slider.value >= (1 - (th / height));
			slider.hold = !mouse_check_button_released(mb_left);
		}
		
		ptheight = theight;
		slider.value = clamp(slider.value, 0, 1 - (slider.height / height));
		draw_sprite_stretched_ext(sPixel, 0, width - slider.width, 0, slider.width, height, #0a0a0a, 0.9);
		
		var col = (slider.hover or slider.hold) ? #FaFaFa : #BaBaBa;
		draw_sprite_stretched_ext(sPixel, 0, width - slider.width, height * slider.value, slider.width, slider.height, col, 0.9);
		
		draw_set_color(c_white);
		draw_set_alpha(1);
	}
	
	draw = function(){
		if (keyboard_check_pressed(vk_f3)) visible = !visible;
		if (!visible) return;
		
		draw_set_font(fntMono);
		
		//header
		header.hover = mouse_in_box(x, y - header.height, width, header.height);
		if (header.hover and mouse_check_button_pressed(mb_left)){
			header.offset = [device_mouse_x_to_gui(0) - x, device_mouse_y_to_gui(0) - y];
			header.hold = true;
		}
		
		if (header.hold){
			x = (device_mouse_x_to_gui(0) - header.offset[0])
			y = (device_mouse_y_to_gui(0) - header.offset[1])
			
			header.hold = !mouse_check_button_released(mb_left);
		}
		
		draw_sprite_stretched_ext(sPixel, 0, x, y - header.height, width, header.height, #1F1F1F, 1);
		
		var close = mouse_in_box(x + width - header.height, y - header.height, header.height, header.height);
		draw_sprite_stretched(sClose, close, x + width - header.height, y - header.height, header.height, header.height);
		
		if (close and mouse_check_button_pressed(mb_left)){
			visible = false;
			header.hold = false;
		}
		
		draw_set_valign(fa_center);
		draw_text_transformed_color(x + 1, y + header.height / 2 - header.height, "Console", header.fontScale, header.fontScale, 0, c_white, c_white, c_white, c_white, 0.8);
		draw_set_valign(fa_top);
		
		if (!surface_exists(surface)){
			if (window_has_focus()){
				surface = surface_create(width, height);
			}else return;
		}
		
		surface_set_target(surface);
		
		//background
		var col = #121212;
		draw_set_alpha(0.9);
		draw_rectangle_color(0, 0, width, height, col, col, col, col, false);
		
		//slider
		slider.draw();
		var ty = 0;
		
		//text
		for(var i = 0; i < array_length(logs); i++){
			var log = logs[i];
			
			draw_text_ext_transformed_color(0, ty - slider.value * theight, log.text, fontSize / fontScale + 4, (width - slider.width) / fontScale, fontScale, fontScale, 0, log.col, log.col, log.col, log.col, 1);
			ty += string_height_ext(log.text, fontSize / fontScale + 4, (width - slider.width) / fontScale) * fontScale;
		}
		
		theight = ty;
		
		surface_reset_target();
		
		
		draw_surface(surface, x, y);
		
		//textbox
		if (mouse_check_button_pressed(mb_left)){
			if (mouse_in_box(x, y + height, width, textbox.height)){
				textbox.selected = true;
				keyboard_string = textbox.text;
				textbox.cursor = string_length(keyboard_string);
				textbox.blink = true;
				textbox.timer = 1;
			}else{
				textbox.selected = false;
				textbox.blink = false;
			}
		}
		

		
		draw_sprite_stretched_ext(sPixel, 0, x, y + height, width, textbox.height, #F0F0F0, 1);
		
		if (textbox.selected){
			textbox.text = keyboard_string;
			textbox.timer -= (dt) / 25;
			
			if (textbox.timer <= 0){
				textbox.timer = 1;
				textbox.blink = !textbox.blink;
			}
			
			if (keyboard_check_pressed(vk_anykey)){
				textbox.timer = 1;
				textbox.blink = 1;
			}
			
			if (keyboard_check_pressed(vk_enter)){
				command(textbox.text);
				keyboard_string = "";
				textbox.text = "";
			}
			textbox.cursor = string_length(textbox.text);

			draw_text_transformed_color(x + string_width(string_copy(textbox.text, 1, textbox.cursor)) * textbox.fontScale, y + height, (textbox.blink) ? "_" : " ", textbox.fontScale, textbox.fontScale, 0, #0F0F0F, #0F0F0F, #0F0F0F, #0F0F0F, 1);
		}
		
		draw_text_transformed_color(x, y + height, textbox.text, textbox.fontScale, textbox.fontScale, 0, #0F0F0F, #0F0F0F, #0F0F0F, #0F0F0F, 1);
		
		draw_set_font(fntMain);
	}
}