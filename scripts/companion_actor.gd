class_name CompanionActor
extends Node3D
# Visual adapter only: source rigs/actions never determine stats or combat results.
const PROFILES={
 "intro_wolf":{"asset":"dire_wolf","height":1.05,"idle":"Idle","walk":"Walk","run":"Gallop","attack":"Attack","support":"Idle_2","guard":"Idle_2_HeadLow","hit":"Idle_HitReact_Left","death":"Death"},
 "dire_wolf":{"asset":"dire_wolf","height":1.18,"idle":"Idle","walk":"Walk","run":"Gallop","attack":"Attack","support":"Idle_2","guard":"Idle_2_HeadLow","hit":"Idle_HitReact_Left","death":"Death"},
 "spirit_fox":{"asset":"spirit_fox","height":1.05,"idle":"Idle","walk":"Walk","run":"Gallop","attack":"Attack","support":"Idle_2","guard":"Idle_2_HeadLow","hit":"Idle_HitReact_Left","death":"Death"},
 "warhorse":{"asset":"warhorse","height":1.8,"idle":"Idle","walk":"Walk","run":"Gallop","attack":"Attack_Headbutt","support":"Idle_2","guard":"Idle_Headlow","hit":"Idle_HitReact_Left","death":"Death"},
 "griffin":{"asset":"griffin","height":1.38,"idle":"Idle","walk":"Walk","run":"Gallop","attack":"Attack","support":"Idle_2","guard":"Idle_2_HeadLow","hit":"Idle_HitReact_Left","death":"Death"},
 "dragon":{"asset":"dragon","height":1.5,"idle":"Flying_Idle","walk":"Fast_Flying","run":"Fast_Flying","attack":"Headbutt","support":"Flying_Idle","guard":"Flying_Idle","hit":"HitReact","death":"Death"},
 "golem":{"asset":"golem","height":2.05,"idle":"Idle","walk":"Walk","run":"Jog_Fwd","attack":"Punch_Cross","support":"Yes","guard":"Idle_FoldArms","hit":"Hit_Chest","death":"Death01"}}
const ABILITY_CLIPS={
 "Rending Fang":"Attack","Pack Howl":"Idle_2","Moonfang Assault":"Gallop_Jump",
 "Gale Talons":"Attack","Skyward Grace":"Idle_2","Tempest Dive":"Gallop_Jump",
 "Ember Breath":"Headbutt","Arcane Embers":"Flying_Idle","Inferno Breath":"Punch",
 "Thunderhoof":"Attack_Kick","Wind of the Road":"Idle_2","Dawn Charge":"Attack_Headbutt",
 "Spirit Spark":"Attack","Moonlit Renewal":"Idle_2_HeadLow","Sanctuary Bloom":"Idle_2",
 "Stonefist":"Melee_Hook","Granite Shelter":"Idle_FoldArms","Mountain Ward":"Spell_Simple_Shoot"}
var companion_id=""
var profile:Dictionary
var body:Node3D
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var battle=false
var guarding=false
var locked_pose=false
var last_action=""
var current_motion=""
var action_remaining=0.0
func _init(id:String="intro_wolf"):
 companion_id=id if PROFILES.has(id) else "intro_wolf"
 profile=PROFILES[companion_id].duplicate(true)
 body=Node3D.new()
 body.name="Body"
 add_child(body)
 var path="res://assets/models/companions/refined/%s.glb" % profile.asset
 if companion_id=="dragon":
  path="res://assets/vendor/quaternius/companions/monsters/%s.glb" % "Dragon_Evolved"
 model=load(path).instantiate()
 if companion_id=="dragon":decorate_native_monster()
 body.add_child(model)
 var bounds=GearVisual.bounds(model)
 var scale_=float(profile.height)/maxf(.001,bounds.size.y)
 model.scale=Vector3.ONE*scale_
 model.position.y=-bounds.position.y*scale_
 model.position.x=-bounds.get_center().x*scale_
 model.position.z=-bounds.get_center().z*scale_
 body.rotation.y=PI
 skeleton=model.find_children("*","Skeleton3D",true,false)[0]
 if companion_id=="golem":
  player=AnimationPlayer.new()
  model.add_child(player)
  player.root_node=player.get_path_to(skeleton)
  player.add_animation_library("",HeroMotionLibrary.build(skeleton))
 else:player=model.find_children("*","AnimationPlayer",true,false)[0]
 for field in ["idle","walk","run","attack","support","guard","hit","death"]:
  profile[field]=resolve_clip(profile[field])
 # Private libraries: changing loop flags must not mutate another instance/source.
 for name_ in player.get_animation_library_list():
  var library=player.get_animation_library(name_).duplicate(true)
  player.remove_animation_library(name_)
  player.add_animation_library(name_,library)
 for clip in player.get_animation_list():
  var animation=player.get_animation(clip)
  animation.loop_mode=Animation.LOOP_LINEAR if clip in [profile.idle,profile.walk,profile.run,profile.guard] else Animation.LOOP_NONE
 if companion_id=="intro_wolf":
  for mesh in model.find_children("*","MeshInstance3D",true,false):
   for index in range(mesh.mesh.get_surface_count()):
    var material=mesh.get_active_material(index)
    if material is StandardMaterial3D:
     var copy=material.duplicate()
     copy.albedo_color=Color(1.15,1.12,1.08)
     mesh.set_surface_override_material(index,copy)
func decorate_native_monster():
 # Preserve original bind transforms and animation scale. Geometry/skin arrays are untouched.
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  for index in range(mesh.mesh.get_surface_count()):
   var original=mesh.get_active_material(index)
   if not original is StandardMaterial3D:continue
   var material:StandardMaterial3D=original.duplicate()
   var name_=String(original.resource_name)
   var path="res://assets/textures/companions/%s_%s.png" % [companion_id,name_]
   if ResourceLoader.exists(path):
    material.albedo_texture=load(path)
    material.albedo_color=Color.WHITE
    material.uv1_triplanar=true
    material.uv1_scale=Vector3.ONE*1.8
   material.roughness=.78
   mesh.set_surface_override_material(index,material)
func resolve_clip(requested:String)->String:
 if player.has_animation(requested):return requested
 for available in player.get_animation_list():
  if String(available).ends_with("|"+requested) or String(available).ends_with("_"+requested):return String(available)
 return requested
func _ready():motion(false)
func motion(moving:bool,sprint=false):
 if locked_pose or action_remaining>0:return
 var clip:String=profile.run if moving and sprint else (profile.walk if moving else (profile.guard if guarding else profile.idle))
 if current_motion==clip:return
 current_motion=clip
 player.speed_scale=1
 player.play(clip,.14)
func action_clip(label:String)->String:
 var clean=label.trim_suffix(" · Critical!")
 if clean=="Defeat":return profile.death
 if clean=="Dodge":return "Jump_ToIdle" if player.has_animation("Jump_ToIdle") else profile.hit
 if clean=="Victory":return profile.support
 var ability=CompanionRules.ability_by_name(clean)
 var custom=String(ABILITY_CLIPS.get(ability.get("name",clean),""))
 if not custom.is_empty() and player.has_animation(resolve_clip(custom)):return resolve_clip(custom)
 var behavior:String=ability.get("behavior","")
 if behavior=="Support" or clean=="Wolf's encouragement" or clean.ends_with(" · support"):return profile.support
 if behavior=="Defend" or clean=="Wolf protects you" or clean.ends_with(" · protection"):return profile.guard
 return profile.attack
func play_action(label:String)->float:
 last_action=label
 if label=="Defeat":locked_pose=true
 var clip=action_clip(label)
 var ability=CompanionRules.ability_by_name(label)
 guarding=label=="Wolf protects you" or label.ends_with(" · protection") or ability.get("behavior","")=="Defend"
 var animation=player.get_animation(clip)
 var duration=clampf(animation.length,.65,1.4)
 var speed:float=UserSettings.battle_speed if battle else 1.0
 player.speed_scale=animation.length/duration*speed
 player.play(clip,.07)
 current_motion=""
 action_remaining=duration/speed
 return duration
func play_reaction():
 if locked_pose:return
 var speed:float=UserSettings.battle_speed if battle else 1.0
 player.speed_scale=player.get_animation(profile.hit).length/.4*speed
 player.play(profile.hit,.05)
 current_motion=""
 action_remaining=.4/speed
func _process(delta):
 if action_remaining<=0:return
 action_remaining=maxf(0,action_remaining-delta)
 if action_remaining==0:motion(false)
