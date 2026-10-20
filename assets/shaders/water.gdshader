shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.10, 0.37, 0.43);
uniform vec3 shallow_color : source_color = vec3(0.34, 0.64, 0.64);
void fragment() {
 float ripple = sin(UV.y * 110.0 + TIME * 1.7 + sin(UV.x * 18.0)) * 0.5 + 0.5;
 float glint = pow(max(sin(UV.y * 190.0 - TIME * 2.2 + UV.x * 8.0), 0.0), 18.0);
 ALBEDO = mix(deep_color, shallow_color, ripple * 0.35) + glint * 0.06;
 ROUGHNESS = 0.35;
 METALLIC = 0.1;
}
