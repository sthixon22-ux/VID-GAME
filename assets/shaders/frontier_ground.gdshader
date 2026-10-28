shader_type spatial;
render_mode cull_back;
uniform sampler2D detail : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_detail : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(.65,.49,.29,1.0);
uniform float grain_scale = .45;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=world_pos.xz*grain_scale;
 vec3 tex=texture(detail,uv).rgb;
 float value=dot(tex,vec3(.3,.59,.11));
 float dune=sin(world_pos.x*.35+sin(world_pos.z*.12)*2.0)*.025;
 ALBEDO=tint.rgb*(.7+value*.65+dune);
 NORMAL_MAP=texture(normal_detail,uv).rgb;
 NORMAL_MAP_DEPTH=.23;
 ROUGHNESS=.96;
}
