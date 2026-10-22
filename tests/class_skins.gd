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
func run():
 State.new_adventure()
 var original=JSON.stringify(State.hero)
 var identities=[]
 var textures=[]
 for primary in State.classes:
  for sex in ["Male","Female"]:
   var visual=HeroVisual.new(State.hero.equipment,{"class":primary,"sex":sex})
   add_child(visual)
   await settle()
   check(not identities.has(visual.skin_id) and visual.sex==sex,"Distinct class/body identity: "+primary+" "+sex)
   identities.append(visual.skin_id)
   var texture=HeroSkinBook.texture_path(visual.skin_id,visual.outfit_id)
   var hash_=FileAccess.get_sha256(texture)
   check(not hash_.is_empty() and not textures.has(hash_),"Distinct authored outfit texture: "+visual.skin_id)
   textures.append(hash_)
   check(visual.skeleton.find_bone("Hips")>=0 and visual.skeleton.find_bone("RightHand")>=0,"Canonical animated rig: "+visual.skin_id)
   var bound=false
   for mesh in visual.model.find_children("*","MeshInstance3D",true,false):
    for surface in range(mesh.mesh.get_surface_count()):
     var material=mesh.get_active_material(surface)
     if material is StandardMaterial3D and material.albedo_texture and material.albedo_texture.resource_path==texture:bound=true
   check(bound,"Class texture reaches rendered surfaces: "+visual.skin_id)
   var bone=visual.skeleton.find_bone("RightHand")
   var movement=true
   for action in ["Attack","Shield raised","Regrowth"]:
    visual.player.play("Idle",0)
    visual.player.seek(.2,true)
    var first=visual.skeleton.get_bone_global_pose(bone)
    visual.play_action(action)
    var clip=visual.player.current_animation
    visual.player.advance(.2)
    visual.player.seek(visual.player.get_animation(clip).length*.6,true)
    movement=movement and not first.is_equal_approx(visual.skeleton.get_bone_global_pose(bone))
   check(movement,"Attack/block/spell animate actual bones: "+visual.skin_id)
   check(visual.find_child("EquippedWeapon",true,false)==null and visual.find_child("EquippedShield",true,false)==null,"Cosmetic class skin grants no starting gear: "+visual.skin_id)
   visual.queue_free()
   await settle()
 check(identities.size()==24 and JSON.stringify(State.hero)==original,"All 24 visual builds leave gameplay data untouched")
 await settle()
 get_tree().current_scene=null
 get_tree().change_scene_to_file("res://scenes/create.tscn")
 await settle()
 var creator=get_tree().current_scene
 var before=JSON.stringify(State.hero)
 for primary in State.classes:
  creator.select_class(primary)
  for sex in ["Male","Female"]:
   creator.select_sex(sex)
   await settle()
   check(creator.actor.skin_id==HeroSkinBook.profile(primary,sex).id,"Live creation selection: "+primary+" "+sex)
   check(creator.secondary1.item_count==11 and creator.secondary2.item_count==10,"Three-class choices remain independent: "+primary+" "+sex)
 check(JSON.stringify(State.hero)==before,"Creation preview never mutates the saved hero")
 var reference_stats:Dictionary={}
 for sex in ["Male","Female"]:
  State.new_adventure()
  check(State.create_hero("New hero","Wizard",1,2,0,["Barbarian","Healer"],sex),"Create and save "+sex+" Wizard")
  var stats=State.stats()
  if reference_stats.is_empty():reference_stats=stats.duplicate(true)
  check(stats==reference_stats,"Male/female choice has identical class-combination stats")
  State.reset()
  State.load_game()
  check(State.hero.profile.sex==sex and State.hero.primary=="Wizard" and State.hero.secondary==["Barbarian","Healer"],"Save/load retains sex and free three-class build: "+sex)
  check(State.stats()==stats and State.hero.equipment.values().all(func(v):return v=="None"),"Sex leaves stats and starting gear unchanged: "+sex)
 for sex in ["Male","Female"]:
  var equipped=HeroVisual.new({"Weapon":"Iron Sword","Shield":"Oak Shield","Chest":"Leather Vest","Helmet":"Steel Helm"},{"class":"Warrior","sex":sex})
  add_child(equipped)
  await settle()
  var sword=equipped.find_child("EquippedWeapon",true,false)
  var shield=equipped.find_child("EquippedShield",true,false)
  check(sword.get_parent().bone_name=="RightHand" and shield.get_parent().bone_name=="LeftHand","Equipped sword/shield attach to the correct animated "+sex+" hands")
  check(equipped.skeleton.find_bone(sword.get_parent().bone_name)>=0 and equipped.find_child("EquippedHelmet",true,false)!=null,"Equipped props resolve on "+sex+" rig")
  equipped.queue_free()
  await settle()
 State.new_adventure()
 check(not State.create_hero("Invalid","Paladin",0,0,0,[],"Invalid") and not State.hero.profile.created,"Invalid body choice rejected without creating a hero")
 State.create_hero("Legacy","Ranger",0,0,0,["Rogue","Druid"])
 var legacy=State.hero.duplicate(true)
 legacy.profile.erase("sex")
 var file=FileAccess.open(State.SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy))
 file.close()
 State.reset()
 State.load_game()
 check(State.hero.profile.sex=="Female" and State.hero.primary=="Ranger","Earlier saves retain the previous female body by default")
 var corrupt=State.hero.duplicate(true)
 corrupt.profile.sex=[]
 check(not SaveStore.valid_nested(corrupt),"Malformed sex save data is rejected")
 await Sound.stop_all()
 creator.queue_free()
 await settle()
 print("Class skin checks: %d Failures: %d" % [checks,failures])
 get_tree().quit(1 if failures else 0)
