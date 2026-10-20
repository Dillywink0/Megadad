class_name RetroShaderOverlay
extends CanvasLayer
## Code-driven CRT screen shader adding scanlines, curvature, and vignette.

func _init() -> void:
	layer = 100 # Keep on top of HUD and gameplay elements
	
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
	uniform float scanline_count : hint_range(0.0, 600.0) = 240.0;
	uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
	uniform float warp_amount : hint_range(0.0, 0.1) = 0.015;
	uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.2;

	vec2 warp(vec2 uv) {
		vec2 delta = uv - 0.5;
		float dist = dot(delta, delta);
		return uv + delta * dist * warp_amount;
	}

	void fragment() {
		vec2 uv = warp(SCREEN_UV);
		
		// Use an if/else block instead of an early return statement
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			vec4 tex = texture(SCREEN_TEXTURE, uv);

			// Scanline calculation (matches retro 240p line density)
			float scanline = sin(uv.y * scanline_count * 3.14159 * 2.0);
			scanline = (scanline + 1.0) * 0.5;
			tex.rgb -= scanline * scanline_intensity * tex.rgb;

			// Corner Vignette calculation
			float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
			vignette = clamp(pow(16.0 * vignette, vignette_intensity), 0.0, 1.0);
			tex.rgb *= vignette;

			COLOR = tex;
		}
	}
	"""

	var material := ShaderMaterial.new()
	material.shader = shader

	var color_rect := ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.material = material
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
