extends SceneTree
func _initialize():
 for path in ["res://art_lab/assets/quaternius_animation2/UAL2_Standard.glb","res://art_lab/assets/quaternius_characters/female_ranger.glb","res://art_lab/assets/quaternius_characters/female_peasant.glb","res://art_lab/assets/quaternius_animation/AnimationLibrary_Godot_Standard.gltf","res://art_lab/assets/vrm/VRM1_Constraint_Twist_Sample.vrm","res://art_lab/assets/quaternius_wolf/Wolf.gltf"]:
  var scene=load(path) as PackedScene
  if scene==null:push_error("Cannot import "+path);continue
  var node=scene.instantiate()
  root.add_child(node)
  print("ASSET ",path)
  for sk in node.find_children("*","Skeleton3D",true,false):
   var bones=[]
   for i in range(sk.get_bone_count()):bones.append(sk.get_bone_name(i))
   print("SKELETON ",node.get_path_to(sk)," BONES ",bones)
  for player in node.find_children("*","AnimationPlayer",true,false):
   print("PLAYER ",node.get_path_to(player)," CLIPS ",player.get_animation_list())
   if player.has_animation("Walk"):
    var anim=player.get_animation("Walk")
    print("TRACKS ",anim.track_get_path(0)," TYPE ",anim.track_get_type(0))
  var meshcount=0
  var morphs=[]
  for mesh in node.find_children("*","MeshInstance3D",true,false):
   meshcount+=1
   if mesh.mesh:
    for i in range(mesh.mesh.get_blend_shape_count()):morphs.append(mesh.mesh.get_blend_shape_name(i))
  print("MESHES ",meshcount," MORPHS ",morphs)
  node.free()
 quit()
