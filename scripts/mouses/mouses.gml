function mouse_in_box(tx, ty, width, height, mouse = 0){
	return point_in_rectangle(device_mouse_x_to_gui(mouse), device_mouse_y_to_gui(mouse), tx, ty, tx + width, ty + height);
}