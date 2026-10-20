shader_type spatial;
uniform sampler2D palette : source_color, filter_linear;
uniform vec4 skin_tone : source_color = vec4(1.0);
uniform vec4 hair_tone : source_color = vec4(0.25,0.12,0.07,1.0);
uniform vec4 cloth_tone : source_color = vec4(0.2,0.4,0.6,1.0);
uniform bool head = false;
uniform bool plain_clothes = false;
void fragment() {
 vec3 color = texture(palette, UV).rgb;
 float brightness = max(max(color.r,color.g),color.b);
 bool skin = color.r > 0.65 && color.g > 0.32 && color.g < color.r * 0.91 && color.b < color.g * 0.9;
 if (skin) color = skin_tone.rgb * (0.7 + brightness * 0.3);
 else if (head && brightness > 0.11 && brightness < 0.7) color = hair_tone.rgb * (0.6 + brightness * 0.6);
 else if (plain_clothes && color.g > color.r * 1.15) color = cloth_tone.rgb * (0.65 + brightness * 0.35);
 ALBEDO = color;
 float weave=sin(UV.x*1100.0)*sin(UV.y*1100.0)*0.015;
 ALBEDO *= 1.0+weave;
 bool metal = !head && !plain_clothes && abs(color.r-color.b)<0.2 && brightness>0.35;
 METALLIC = metal ? 0.55 : 0.0;
 ROUGHNESS = metal ? 0.32 : 0.85;
}
