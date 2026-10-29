shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 energy_color : source_color = vec4(1.0,.84,.48,.6);
void fragment(){
 float edge=pow(max(0.0,sin(UV.x*3.14159)),.7);
 float ends=smoothstep(0.0,.16,UV.y)*(1.0-smoothstep(.8,1.0,UV.y));
 float pulse=.65+.35*sin(TIME*7.0+UV.y*35.0);
 ALBEDO=energy_color.rgb;EMISSION=energy_color.rgb*2.0;
 ALPHA=energy_color.a*edge*ends*pulse;
}
