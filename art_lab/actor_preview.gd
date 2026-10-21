class_name ArtLabActor
extends Node3D
# Presentation adapter for the review scene only. It never reads class/equipment choices into gameplay.
const UAL1="res://art_lab/assets/quaternius_animation/AnimationLibrary_Godot_Standard.gltf"
const UAL2="res://art_lab/assets/quaternius_animation2/UAL2_Standard.glb"
const MOTIONS={"Idle":[UAL1,"Idle"],"Walking":[UAL1,"Walk"],"Running":[UAL1,"Sprint"],"Sword attack":[UAL1,"Sword_Attack"],"Blocking":[UAL2,"Idle_Shield"],"Spellcasting":[UAL1,"Spell_Simple_Shoot"]}
const CURRENT={"Idle":"Idle","Walking":"Walking_A","Running":"Running_A","Sword attack":"1H_Melee_Attack_Slice_Diagonal","Blocking":"Blocking","Spellcasting":"Spellcast_Raise"}
var kind=""
var visual:Node3D
var skeleton:Skeleton3D
var motion_player:AnimationPlayer
var expression_player:AnimationPlayer
var sockets:Array[BoneAttachment3D]=[]
var active_motion="Idle"
var active_expression="neutral"
var actor_height=2.2
var paused=false
var speed=1.0
var source_clips:Dictionary={}
func setup(id:String):
 kind=id
 if id=="current":
  visual=HeroVisual.new({"Weapon":"Iron Sword","Shield":"Oak Shield","Chest":"Traveler's Clothing","Helmet":"None","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},{"skin":0,"hair":0,"dye":0})
  visual.rotation.y=PI
  visual.locked_pose=true
  motion_player=visual.player
  skeleton=visual.skeleton
  var baseline_library=motion_player.get_animation_library("").duplicate(true)
  motion_player.remove_animation_library("")
  motion_player.add_animation_library("",baseline_library)
 else:
  var path="res://art_lab/assets/vrm/seed/Seed-san.vrm" if id=="vrm" else ("res://art_lab/assets/vrm/VRM1_Constraint_Twist_Sample.vrm" if id=="vrm_twist" else "res://art_lab/assets/quaternius_characters/female_ranger.glb")
  visual=load(path).instantiate()
  skeleton=visual.find_children("*","Skeleton3D",true,false)[0]
  if id.begins_with("vrm"):expression_player=visual.find_children("*","AnimationPlayer",true,false)[0]
 add_child(visual)
 if id=="vrm":
  # Seed-san has an unrelated sci-fi robot-arm accessory. Hide it for the body comparison.
  for mesh in visual.find_children("*","MeshInstance3D",true,false):
   if str(mesh.name).begins_with("robo_arm"):mesh.hide()
 # Equal normalized height; source proportions/materials are retained.
 var bounds=mesh_bounds(visual)
 if bounds.size.y>0:
  var ratio=actor_height/bounds.size.y
  visual.scale*=ratio
  visual.position.y-=bounds.position.y*ratio
 if id!="current":
  motion_player=AnimationPlayer.new()
  motion_player.name="ReviewMotionPlayer"
  visual.add_child(motion_player)
  install_motion_library()
  attach_reference_gear()
 play_motion("Idle")
func install_motion_library():
 var library=AnimationLibrary.new()
 var loaded:Dictionary={}
 for label in MOTIONS:
  var path:String=MOTIONS[label][0]
  if not loaded.has(path):
   var source=load(path).instantiate()
   loaded[path]=source
  var source:Node=loaded[path]
  var player:AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
  var clip:String=MOTIONS[label][1]
  if not player.has_animation(clip):push_error("Missing licensed source clip "+clip);continue
  var anim:Animation=player.get_animation(clip).duplicate(true)
  # Native import bone maps normalized both Quaternius rigs to SkeletonProfileHumanoid.
  # The VRM importer uses the same profile. Keep valid skeletal tracks only.
  for index in range(anim.get_track_count()-1,-1,-1):
   var original=anim.track_get_path(index)
   var bone=String(original.get_subname(0)) if original.get_subname_count()>0 else ""
   if skeleton.find_bone(bone)<0 or anim.track_get_type(index) not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
    anim.remove_track(index)
   else:anim.track_set_path(index,NodePath(String(visual.get_path_to(skeleton))+":"+bone))
  anim.loop_mode=Animation.LOOP_LINEAR
  library.add_animation(label,anim)
  source_clips[label]=clip+" (UAL"+("2" if path==UAL2 else "1")+" Standard)"
 motion_player.add_animation_library("",library)
 for source in loaded.values():source.free()
func attach_reference_gear():
 for entry in [["RightHand","Iron Sword"],["LeftHand","Oak Shield"]]:
  var bone=skeleton.find_bone(entry[0])
  if bone<0:continue
  var attachment=BoneAttachment3D.new()
  attachment.name="Review"+entry[0]
  skeleton.add_child(attachment)
  attachment.bone_name=entry[0]
  var prop=GearVisual.item(entry[1])
  # Reference props only: a grip calibration test, not replacement production equipment.
  prop.name="ReferenceSword" if entry[0]=="RightHand" else "ReferenceShield"
  prop.scale=Vector3.ONE*.65
  prop.rotation_degrees=Vector3(90,0,0) if entry[0]=="RightHand" else Vector3(0,90,90)
  attachment.add_child(prop)
  sockets.append(attachment)
func play_motion(label:String):
 active_motion=label
 var clip:String=CURRENT.get(label,"Idle") if kind=="current" else label
 if not motion_player.has_animation(clip):push_error("Unavailable review motion "+clip);return
 motion_player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
 motion_player.speed_scale=0 if paused else speed
 motion_player.play(clip)
 motion_player.seek(0,true)
func seek_motion(time_:float):
 if motion_player.current_animation.is_empty():return
 var anim=motion_player.get_animation(motion_player.current_animation)
 motion_player.seek(fposmod(time_,maxf(.01,anim.length)),true)
func set_expression(label:String):
 active_expression=label
 if expression_player==null:return
 # Reset prior binds so expressions do not accumulate across selections.
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh:
   for index in range(mesh.mesh.get_blend_shape_count()):mesh.set_blend_shape_value(index,0)
 if expression_player.has_animation(label):
  expression_player.play(label)
  expression_player.seek(.1,true)
func set_gear_visible(enabled:bool):
 if kind=="current":
  for name_ in ["EquippedWeapon","EquippedShield"]:
   var prop=visual.find_child(name_,true,false)
   if prop:prop.visible=enabled
 else:
  for socket_ in sockets:socket_.visible=enabled
func change_outfit(peasant:bool):
 if kind!="quaternius":return
 visual.free()
 sockets.clear()
 source_clips.clear()
 var path="res://art_lab/assets/quaternius_characters/female_peasant.glb" if peasant else "res://art_lab/assets/quaternius_characters/female_ranger.glb"
 visual=load(path).instantiate()
 add_child(visual)
 skeleton=visual.find_children("*","Skeleton3D",true,false)[0]
 var bounds=mesh_bounds(visual)
 var ratio=actor_height/bounds.size.y
 visual.scale*=ratio
 visual.position.y-=bounds.position.y*ratio
 motion_player=AnimationPlayer.new()
 motion_player.name="ReviewMotionPlayer"
 visual.add_child(motion_player)
 install_motion_library()
 attach_reference_gear()
 play_motion(active_motion)
static func mesh_bounds(node:Node3D)->AABB:
 var result=AABB()
 var first=true
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh==null or not mesh.visible:continue
  var transform_=Transform3D.IDENTITY
  var cursor:Node=mesh
  while cursor!=node:
   if cursor is Node3D:transform_=cursor.transform*transform_
   cursor=cursor.get_parent()
  var box: AABB=transform_*mesh.get_aabb()
  result=box if first else result.merge(box)
  first=false
 return result

func change_vrm_sample(twist:bool):
 if not kind.begins_with("vrm"):return
 var previous=active_motion
 var face=active_expression
 visual.free()
 sockets.clear()
 source_clips.clear()
 expression_player=null
 setup("vrm_twist" if twist else "vrm")
 play_motion(previous)
 set_expression(face)

func toggle_outfit_part(fragment:String):
 if kind!="quaternius":return
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  if str(mesh.name).contains(fragment):mesh.visible=not mesh.visible
func toggle_native_accessory():
 if kind!="vrm":return
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  if str(mesh.name).begins_with("robo_arm"):mesh.visible=not mesh.visible
