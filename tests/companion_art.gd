extends Node
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;push_error(label)
func _ready():call_deferred("run")
func settle():
 for i in range(3):await get_tree().process_frame
func bone_extent(skeleton:Skeleton3D,rest=false)->float:
 var first=true
 var bounds=AABB()
 for index in range(skeleton.get_bone_count()):
  var point=skeleton.get_bone_global_rest(index).origin if rest else skeleton.get_bone_global_pose(index).origin
  if first:bounds=AABB(point,Vector3.ZERO);first=false
  else:bounds=bounds.expand(point)
 return bounds.size.length()
func run():
 Engine.time_scale=8
 State.reset()
 var before=JSON.stringify(State.hero)
 var ids:Array=["intro_wolf"]+State.companions.keys()
 for id in ids:
  var pet=CompanionVisual.build(id)
  add_child(pet)
  await settle()
  check(pet is CompanionActor and pet.has_node("Body"),"Animated companion factory: "+id)
  check(pet.skeleton.get_bone_count()>=13,"Real articulated skeleton: "+id)
  check(pet.player.get_animation_list().size()>=6,"Authored native or retargeted motion library: "+id)
  var bounds=GearVisual.bounds(pet)
  check(bounds.size.y>=1 and bounds.size.y<=2.2 and bounds.size.x>.25,"World proportions fit hero scale: "+id)
  check(absf(bounds.get_center().x)<.01 and absf(bounds.get_center().z)<.01 and absf(bounds.position.y)<.01,"Root centered and grounded: "+id)
  var textured=false
  for mesh in pet.model.find_children("*","MeshInstance3D",true,false):
   for surface in range(mesh.mesh.get_surface_count()):
    var material=mesh.get_active_material(surface)
    if material is StandardMaterial3D and material.albedo_texture:textured=true
  check(textured,"Painted material textures reach actual meshes: "+id)
  for field in ["idle","walk","run","attack","support","guard","hit","death"]:
   check(pet.player.has_animation(pet.profile[field]),"Resolved source clip "+field+": "+id)
  for moving in [false,true]:
   pet.action_remaining=0
   pet.motion(moving,true)
   check(pet.player.current_animation==(pet.profile.run if moving else pet.profile.idle),"Idle/sprint playback: "+id)
  var pet_name=State.companions.get(id,{}).get("name","Wolf")
  var labels=[pet_name+" · strike",pet_name+" · support",pet_name+" · protection"] if id!="intro_wolf" else ["Wolf bite","Wolf's encouragement","Wolf protects you"]
  for label in labels:
   pet.player.play(pet.profile.idle,0)
   pet.player.seek(.05,true)
   var originals=[]
   for index in range(pet.skeleton.get_bone_count()):originals.append(pet.skeleton.get_bone_global_pose(index))
   var duration=pet.play_action(label)
   var clip=pet.player.current_animation
   pet.player.advance(.2)
   pet.player.seek(pet.player.get_animation(clip).length*.6,true)
   var changed=false
   for index in range(pet.skeleton.get_bone_count()):
    if not originals[index].is_equal_approx(pet.skeleton.get_bone_global_pose(index)):changed=true
   check(duration>0 and clip==pet.action_clip(label) and changed,"Behavior animates real bones: "+label)
   var ratio=bone_extent(pet.skeleton)/maxf(.01,bone_extent(pet.skeleton,true))
   check(ratio>.25 and ratio<4,"Animated rig retains visible scale: "+label)
  if id=="griffin":
   var wing=pet.skeleton.find_bone("Wing.L")
   check(wing>=0,"Griffin has real wing bones")
   pet.player.play(pet.profile.run,0)
   pet.player.seek(.05,true)
   var first=pet.skeleton.get_bone_pose_rotation(wing)
   pet.player.seek(.35,true)
   check(not first.is_equal_approx(pet.skeleton.get_bone_pose_rotation(wing)),"Griffin wing layer animates with locomotion")
  pet.play_reaction()
  check(pet.player.current_animation==pet.profile.hit,"Damage reaction: "+id)
  pet.play_action("Defeat")
  var death=pet.player.current_animation
  pet.action_remaining=0
  pet.motion(true)
  check(pet.locked_pose and pet.player.current_animation==death,"Defeated companion cannot resume walking: "+id)
  pet.queue_free()
  await settle()
 # Actual combat presentation dispatch for each learned companion ability.
 var host=Node3D.new()
 add_child(host)
 var target=Art.actor("Goblin")
 host.add_child(target)
 target.position.x=3
 for id in State.companions:
  var pet=CompanionVisual.build(id)
  host.add_child(pet)
  await settle()
  for ability in State.companions[id].abilities.values():
   await BattleMotion.present(host,pet,target,ability.name)
   check(pet.last_action==ability.name,"Battle presentation dispatches companion ability: "+ability.name)
  pet.queue_free()
  await settle()
 host.queue_free()
 check(JSON.stringify(State.hero)==before,"Visuals and presentations leave HP/MP, bonds, classes, items and skills unchanged")
 var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/validation/companion_gameplay_baseline.json"))
 for path in baseline:
  # Campaign chapter intentionally extends simulator and state; companion data stays protected.
  if path in ["scripts/state.gd","scripts/combat.gd"]:continue
  check(FileAccess.get_sha256("res://"+path)==baseline[path],"Gameplay/class/hero source unchanged: "+path)
 # Open the actual companion menu; previews must remain visible for wide wings and tall guardian.
 State.hero.journey.finished=true
 State.menu_page="companions"
 get_tree().current_scene=null
 get_tree().change_scene_to_file("res://scenes/character.tscn")
 await settle()
 var menu=get_tree().current_scene
 for id in State.companions:
  menu.pending_companion=id
  menu.show_page("companions")
  await settle()
  check(menu.preview_actor is CompanionActor and menu.preview_actor.companion_id==id,"Companion select uses new animated model: "+id)
  var viewport:SubViewport=menu.preview_actor.get_viewport()
  var camera=viewport.get_camera_3d()
  var bounds=GearVisual.bounds(menu.preview_actor)
  var fits=true
  for x in [0,1]:
   for y in [0,1]:
    for z in [0,1]:
     var corner=bounds.position+Vector3(bounds.size.x*x,bounds.size.y*y,bounds.size.z*z)
     var projected=camera.unproject_position(corner)
     if projected.x<0 or projected.y<0 or projected.x>viewport.size.x or projected.y>viewport.size.y:fits=false
  check(fits,"Preview camera fits full companion including depth/wings: "+id)
 await Sound.stop_all()
 menu.queue_free()
 await settle()
 print("Companion art checks: %d Failures: %d" % [checks,failures])
 get_tree().quit(1 if failures else 0)
