extends SceneTree
func _initialize():
 prepare("res://art_lab/assets/quaternius_animation/AnimationLibrary_Godot_Standard.gltf","Rig/Skeleton3D",true)
 for variant in ["female_ranger","female_peasant"]:
  prepare("res://art_lab/assets/quaternius_characters/"+variant+".glb","Armature/Skeleton3D",false)
 prepare("res://art_lab/assets/quaternius_animation2/UAL2_Standard.glb","Armature/Skeleton3D",false,true)
 quit()
func prepare(path:String,skeleton_path:String,ual:bool,unsuffixed=false):
 var bone_map=BoneMap.new()
 bone_map.profile=SkeletonProfileHumanoid.new()
 var mapping={"Root":"root","Hips":"DEF-hips" if ual else "pelvis","Spine":"DEF-spine.001" if ual else "spine_01_2","Chest":"DEF-spine.002" if ual else "spine_02_2","UpperChest":"DEF-spine.003" if ual else "spine_03_2","Neck":"DEF-neck" if ual else "neck_01_2","Head":"DEF-head" if ual else "Head_2"}
 for side in ["Left","Right"]:
  var s="L" if side=="Left" else "R"
  var q="l_2" if side=="Left" else "r_2"
  var bones={"Shoulder":["shoulder","clavicle"],"UpperArm":["upper_arm","upperarm"],"LowerArm":["forearm","lowerarm"],"Hand":["hand","hand"],"UpperLeg":["thigh","thigh"],"LowerLeg":["shin","calf"],"Foot":["foot","foot"],"Toes":["toe","ball"]}
  for key in bones:mapping[side+key]="DEF-"+bones[key][0]+"."+s if ual else bones[key][1]+"_"+q
  for finger in ["Thumb","Index","Middle","Ring","Little"]:
   var source={"Thumb":"thumb","Index":"f_index","Middle":"f_middle","Ring":"f_ring","Little":"f_pinky"}[finger]
   for index in range(3):
    var segment=(["Metacarpal","Proximal","Distal"] if finger=="Thumb" else ["Proximal","Intermediate","Distal"])[index]
    mapping[side+finger+segment]="DEF-"+source+".0"+str(index+1)+"."+s if ual else source.trim_prefix("f_")+"_0"+str(index+1)+"_"+q
 for key in mapping:
  if unsuffixed:mapping[key]=mapping[key].trim_suffix("_2")
  bone_map.set_skeleton_bone_name(key,mapping[key])
 var cf=ConfigFile.new()
 if cf.load(path+".import")!=OK:push_error("Import first: "+path);return
 cf.set_value("params","_subresources",{"nodes":{"PATH:"+skeleton_path:{"retarget/bone_map":bone_map,"retarget/rest_fixer/fix_silhouette/enable":true}}})
 cf.save(path+".import")
 print("Prepared humanoid retarget: ",path)
