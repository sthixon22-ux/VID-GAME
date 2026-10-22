class_name HeroMotionLibrary
extends RefCounted
# Licensed CC0 Standard clips. No class IDs or gameplay state in this adapter.
const SOURCES=["res://assets/vendor/quaternius/animation/AnimationLibrary_Godot_Standard.gltf","res://assets/vendor/quaternius/animation2/UAL2_Standard.glb"]
static var libraries:Dictionary={}
static func build(target:Skeleton3D)->AnimationLibrary:
 var height=target.get_bone_rest(target.find_bone("Hips")).origin.y
 var signature=str(height)
 for index in range(target.get_bone_count()):signature+="|"+String(target.get_bone_name(index))
 if libraries.has(signature):return libraries[signature]
 var cached=AnimationLibrary.new()
 for path in SOURCES:
  var source=load(path).instantiate()
  var rig:Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0]
  var ratio=height/rig.get_bone_rest(rig.find_bone("Hips")).origin.y
  var player:AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
  for clip in player.get_animation_list():
   if cached.has_animation(clip) or clip.ends_with("_RM"):continue
   var anim:Animation=player.get_animation(clip).duplicate(true)
   for index in range(anim.get_track_count()-1,-1,-1):
    var original=anim.track_get_path(index)
    var bone=String(original.get_subname(0)) if original.get_subname_count()>0 else ""
    # Fixed paths resolve from AnimationPlayer.root_node, set to the target skeleton.
    if target.find_bone(bone)<0 or (anim.track_get_type(index)!=Animation.TYPE_ROTATION_3D and not (bone=="Hips" and anim.track_get_type(index)==Animation.TYPE_POSITION_3D)):
     anim.remove_track(index)
    else:
     anim.track_set_path(index,NodePath(".:"+bone))
     if anim.track_get_type(index)==Animation.TYPE_POSITION_3D:
      for key in range(anim.track_get_key_count(index)):
       anim.track_set_key_value(index,key,anim.track_get_key_value(index,key)*ratio)
   anim.loop_mode=Animation.LOOP_LINEAR if clip in ["Idle","Walk","Sprint","Sword_Idle","Idle_Shield","Spell_Simple_Idle"] else Animation.LOOP_NONE
   cached.add_animation(clip,anim)
  source.free()
 libraries[signature]=cached
 return cached
