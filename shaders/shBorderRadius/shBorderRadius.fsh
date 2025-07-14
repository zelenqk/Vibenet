varying vec2 v_texcoord;
varying vec4 v_color;

uniform float u_radius; // pixel radius
uniform vec2 u_dimensions; // width, height of sprite in pixels
uniform sampler2D gm_BaseTexture;

void main() {
	vec4 base_color = texture2D(gm_BaseTexture, v_texcoord);
	
	// convert texcoord to pixel coordinates
	vec2 pixel_pos = v_texcoord * u_dimensions;
	
	float r = u_radius;
	float w = u_dimensions.x;
	float h = u_dimensions.y;

	bool discard_pixel = false;

	// Bottom-left corner
	if (pixel_pos.x < r && pixel_pos.y < r) {
		vec2 corner = vec2(r, r);
		if (distance(pixel_pos, corner) > r) discard_pixel = true;
	}
	// Bottom-right corner
	else if (pixel_pos.x > (w - r) && pixel_pos.y < r) {
		vec2 corner = vec2(w - r, r);
		if (distance(pixel_pos, corner) > r) discard_pixel = true;
	}
	// Top-left corner
	else if (pixel_pos.x < r && pixel_pos.y > (h - r)) {
		vec2 corner = vec2(r, h - r);
		if (distance(pixel_pos, corner) > r) discard_pixel = true;
	}
	// Top-right corner
	else if (pixel_pos.x > (w - r) && pixel_pos.y > (h - r)) {
		vec2 corner = vec2(w - r, h - r);
		if (distance(pixel_pos, corner) > r) discard_pixel = true;
	}

	if (discard_pixel || base_color.a == 0.0) {
		discard;
	}

	gl_FragColor = base_color * v_color;
}
