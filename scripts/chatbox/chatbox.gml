function chatbox(width, height) constructor{
	self.width = width;
	self.height = height;
	
	x = other.x;
	y = other.y - height;
	
	messages = [];
	
	scale = 1;
	fontSize = font_get_size(fntMain);
	
	add = function(text = ""){
		messages[array_length(messages)] = {
			"text": text,
		}
	}
	
	draw = function(){
		draw_set_font(fntMain);
		draw_sprite_stretched_ext(sPixel, 0, x, y, width, height, c_white, 0.25);
		
		var ty = 0;
		for(var i = 0; i < array_length(messages); i++){
			var msg = messages[i];
			draw_text_ext_transformed(x, y + ty, msg.text, fontSize * scale + 4, width / scale, scale, scale, 0);	
		
			ty += string_height_ext(msg.text, fontSize, width / scale) * scale;
		}
	}
}
