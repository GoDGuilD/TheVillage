// File: flash.gdshader
// Description: Whole-sprite white flash used for hit feedback (flash=0 normal, flash=1 solid white, alpha preserved).
// Author: Jose-Jorge HERNANDEZ
// Company: Parlee Conseiller, Inc.
// Date: 2026-10-12
// Last edit date: 2026-10-12
// Version: 1.0.1
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// In canvas_item fragment(), COLOR already holds texture * modulate - do not multiply by the texture again.
	vec4 c = COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
