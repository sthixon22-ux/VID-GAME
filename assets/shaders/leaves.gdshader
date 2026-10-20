shader_type spatial;
uniform vec3 leaf_color : source_color = vec3(0.20, 0.38, 0.22);
void vertex() {
 float breeze = sin(TIME * 1.2 + NODE_POSITION_WORLD.x * 0.3 + NODE_POSITION_WORLD.z * 0.2);
 VERTEX.x += breeze * 0.035 * max(VERTEX.y + 0.5, 0.0);
}
void fragment() {
 float shade = smoothstep(-0.4, 0.5, NORMAL.y);
 ALBEDO = leaf_color * mix(0.85, 1.12, shade);
 ROUGHNESS = 0.95;
}
