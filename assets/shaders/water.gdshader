shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.08,0.25,0.29);
uniform vec3 shallow_color : source_color = vec3(0.20,0.43,0.43);
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float a=world_pos.x*.72+world_pos.z*.43+TIME*.65;
 float b=world_pos.z*1.47-world_pos.x*.28-TIME*.8;
 float ripple=sin(a+sin(b)*.35)*.5+.5;
 float glint=pow(max(sin(b+sin(a)*.5),0.0),32.0);
 ALBEDO=mix(deep_color,shallow_color,ripple*.3)+glint*.035;
 NORMAL_MAP=normalize(vec3(cos(a)*.09,cos(b)*.06,1.0))*.5+.5;
 NORMAL_MAP_DEPTH=.35;
 ROUGHNESS=.30;
 METALLIC=.05;
}
