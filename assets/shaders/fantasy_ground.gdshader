shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D detail_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(0.43,0.53,0.31,1.0);
uniform bool path = false;
varying vec3 world_pos;
varying vec3 local_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;local_pos=VERTEX;}
void fragment(){
 vec2 uv=world_pos.xz*.6;
 vec3 detail=texture(detail_color,uv).rgb;
 float shade=dot(detail,vec3(.30,.59,.11));
 float macro=noise(world_pos.xz*.13)*.65+noise(world_pos.xz*.37)*.35;
 vec3 ground=tint.rgb*(.78+shade*.65);
 vec3 warm=tint.rgb*vec3(1.13,1.01,.81);
 ground=mix(ground,warm,smoothstep(.43,.8,macro)*.5);
 if(!path){
  vec2 cell=floor(world_pos.xz*6.0), f=fract(world_pos.xz*6.0)-vec2(.5);
  float seed=hash(cell);
  float angle=seed*6.28318;
  vec2 q=mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)))*f;
  float leaf=1.0-smoothstep(.72,1.0,length(q/vec2(.29,.12)));
  float patch=smoothstep(.35,.62,noise(world_pos.xz*.7));
  vec3 leaf_color=seed>.91?vec3(.34,.25,.12):tint.rgb*vec3(.82,1.12,.78);
  ground=mix(ground,leaf_color,leaf*patch*.65);
 }
 if(path){
  vec3 stones=texture(stone_color,world_pos.xz*.72).rgb;
  float gravel=smoothstep(.69,.87,noise(world_pos.xz*2.8));
  ground=mix(ground,stones*.78,gravel*.28);
  ALPHA=smoothstep(.50,.39,length(local_pos.xz));
 }
 ALBEDO=ground;
 NORMAL_MAP=texture(detail_normal,uv).rgb;
 NORMAL_MAP_DEPTH=.18;
 ROUGHNESS=.92;
}
