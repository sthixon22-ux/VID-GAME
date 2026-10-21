extends Node
var checks=0
var failures=0
func check(value:bool,label:String):
 checks+=1
 if value:print("PASS: ",label)
 else:failures+=1;push_error(label)
func _ready():call_deferred("run")
func run():
 var state_before=JSON.stringify(State.hero)
 var lab=load("res://art_lab/comparison.tscn").instantiate()
 add_child(lab)
 for i in range(3):await get_tree().process_frame
 check(lab.actors.size()==3 and lab.viewports.size()==3,"Current hero and both real candidate pipelines instantiate")
 check(lab.actors[1].skeleton.find_bone("RightHand")>=0 and lab.actors[2].skeleton.find_bone("RightHand")>=0,"Both candidate rigs import a humanoid hand mapping")
 for actor in lab.actors:
  for motion in ArtLabActor.MOTIONS:
   actor.play_motion(motion)
   var clip=actor.motion_player.current_animation
   var anim=actor.motion_player.get_animation(clip)
   check(not clip.is_empty() and anim.get_track_count()>10,"Real skeletal animation available: "+actor.kind+" / "+motion)
   var bone=actor.skeleton.find_bone("lowerarm.r" if actor.kind=="current" else "RightLowerArm")
   if bone<0:bone=actor.skeleton.find_bone("hand.r" if actor.kind=="current" else "RightHand")
   var moved=false
   var previous=actor.skeleton.get_bone_pose_rotation(bone)
   for t in [.1,.3,.6]:
    actor.seek_motion(t)
    var pose=actor.skeleton.get_bone_pose_rotation(bone)
    if pose.angle_to(previous)>.0001:moved=true
    previous=pose
   check(moved,"Preview changes actual bone poses: "+actor.kind+" / "+motion)
   if actor.kind!="current":
    var valid=true
    for track in range(anim.get_track_count()):
     var path=anim.track_get_path(track)
     if path.get_subname_count()==0 or actor.skeleton.find_bone(path.get_subname(0))<0:valid=false
    check(valid,"Retargeted tracks address existing humanoid bones: "+actor.kind+" / "+motion)
  actor.play_motion("Idle")
  actor.seek_motion(.2)
  if actor.kind!="current":
   check(actor.sockets.size()==2 and actor.sockets.all(func(s):return s is BoneAttachment3D and s.get_child_count()==1),"Sword/shield use real skeleton sockets: "+actor.kind)
   var socket_:BoneAttachment3D=actor.sockets[0]
   actor.paused=true
   actor.motion_player.speed_scale=0
   actor.seek_motion(.1)
   await get_tree().process_frame
   actor.skeleton.force_update_all_bone_transforms()
   var before=socket_.global_position
   actor.play_motion("Sword attack")
   actor.seek_motion(.35)
   await get_tree().process_frame
   actor.skeleton.force_update_all_bone_transforms()
   check(socket_.global_position.distance_to(before)>.01,"Equipped sword follows the animated hand: "+actor.kind)
 var hood=lab.actors[1].visual.find_child("Female_Ranger_Head_Hood",true,false)
 var pauldrons=lab.actors[1].visual.find_child("Female_Ranger_Acc_Pauldrons",true,false)
 lab.actors[1].toggle_outfit_part("_Head_Hood")
 lab.actors[1].toggle_outfit_part("_Acc_Pauldrons")
 check(hood!=null and not hood.visible and pauldrons!=null and not pauldrons.visible,"Authored hood and pauldrons toggle as independent skinned parts")
 lab.actors[1].change_outfit(true)
 check(lab.actors[1].visual.scene_file_path.ends_with("female_peasant.glb"),"Professionally authored second outfit swaps independently of class")
 lab.actors[1].play_motion("Walking")
 check(lab.actors[1].motion_player.is_playing(),"Swapped outfit keeps humanoid motion playback")
 lab.actors[1].change_outfit(false)
 for twist in [false,true]:
  var actor=lab.actors[2]
  lab.select_vrm_sample(1 if twist else 0)
  check(actor.expression_player.has_animation("happy") and actor.expression_player.has_animation("blink"),"VRM expression clips imported: "+actor.kind)
  lab.select_expression(1)
  var changed=false
  for mesh in actor.visual.find_children("*","MeshInstance3D",true,false):
   for index in range(mesh.mesh.get_blend_shape_count()):
    if absf(mesh.get_blend_shape_value(index))>.01:changed=true
  check(changed,"VRM facial control changes actual morph weights: "+actor.kind)
  actor.play_motion("Blocking")
  actor.seek_motion(.3)
  check(actor.motion_player.current_animation=="Blocking","Second-library block retargets: "+actor.kind)
 lab.set_camera_view(4)
 check(lab.cameras.all(func(c):return is_equal_approx(c.fov,30)),"Face review retains the same focal length")
 lab.toggle_play()
 check(lab.actors.all(func(a):return a.motion_player.speed_scale==0),"Pause freezes all compared skeletal animations")
 lab.toggle_play()
 lab.set_mode("Wolf comparison")
 check(lab.creature_players.size()==1 and lab.creature_models.size()==2,"Existing wolf and licensed skinned wolf instantiate side by side")
 for label in ["Idle","Walking","Running","Sword attack"]:
  lab.set_motion(label)
  check(lab.creature_players[0].is_playing(),"Wolf native motion plays: "+label)
 lab.set_motion("Spellcasting")
 check(lab.clip_labels[1].text.begins_with("Unavailable"),"Quadruped never claims a missing spell animation")
 lab.set_mode("Goblin audit")
 check(lab.creature_models.size()==1 and lab.note.text.contains("No Bestiary model"),"Uncleared creature asset is explicitly absent, never faked")
 check(State.classes.size()==12 and State.classes.keys().has("Necromancer"),"All twelve selectable class definitions remain")
 check(JSON.stringify(State.hero)==state_before,"Art lab never changes hero classes, equipment, quests, companions or save state")
 var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_lab/production_baseline.json"))
 var unmodified=true
 # Explicitly approved production visual changes; gameplay files retain their audit hashes.
 var approved=["scripts/hero_visual.gd"]
 for path in baseline:
  if path in approved:continue
  if FileAccess.get_sha256("res://"+path)!=baseline[path]:unmodified=false;push_error("Production changed: "+path)
 check(unmodified,"Unchanged gameplay files and assets match pre-audit hashes (approved hero adapter excluded)")
 lab.queue_free()
 for i in range(3):await get_tree().process_frame
 print("Art lab checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)
