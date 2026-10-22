shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D canopy : source_color, filter_linear_mipmap_anisotropic;
void vertex() {
 float breeze=sin(TIME*1.15+NODE_POSITION_WORLD.x*.3+NODE_POSITION_WORLD.z*.2);
 VERTEX.x+=breeze*.07*max(VERTEX.y+.5,0.0);
}
void fragment() {
 vec4 leaf=texture(canopy,UV);
 ALBEDO=leaf.rgb;
 ALPHA=leaf.a;
 ALPHA_SCISSOR_THRESHOLD=.5;
 ROUGHNESS=.94;
 BACKLIGHT=vec3(.22,.29,.12);
}
