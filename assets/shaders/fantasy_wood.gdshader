shader_type spatial;
uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color=vec4(.8,.7,.6,1);
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
vec3 sample_wood(vec2 p){vec2 uv=fract(p*vec2(.4,1.1));uv.y=.015+uv.y*.25;return texture(atlas,uv).rgb;}
void fragment(){
 vec3 blend=pow(abs(world_normal),vec3(6));blend/=max(.001,blend.x+blend.y+blend.z);
 vec3 wood=sample_wood(world_pos.yz)*blend.x+sample_wood(world_pos.xz)*blend.y+sample_wood(world_pos.yx)*blend.z;
 ALBEDO=wood*tint.rgb*1.25;
 ROUGHNESS=.83;
}
