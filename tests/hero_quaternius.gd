extends Node
var failures=0
var checks=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
 else:print("PASS: ",label)
func _ready():call_deferred("run")
func run():
 State.reset()
 var before=JSON.stringify(State.hero)
 var gear={"Weapon":"Iron Sword","Shield":"Oak Shield","Chest":"Leather Vest","Helmet":"Ranger Hood"}
 var hero=HeroVisual.new(gear,{"dye":1})
 add_child(hero)
 await get_tree().process_frame
 check(hero.model.name=="QuaterniusRanger","Approved authored model is the production hero")
 check(hero.skeleton.find_bone("RightHand")>=0,"Production rig uses canonical humanoid bones")
 check(hero.model.find_child("*Head_Hood*",true,false).visible,"Equipped hood is the authored skinned hood")
 check(is_equal_approx(cos(hero.body.rotation.y),-1.0) and hero.body.scale.y>.98 and hero.body.scale.y<1.03,"Hero matches world facing and height")
 for clip in hero.player.get_animation_list():
  var anim=hero.player.get_animation(clip)
  var valid=true
  for track in range(anim.get_track_count()):
   var path=anim.track_get_path(track)
   if hero.skeleton.find_bone(String(path.get_subname(0)))<0:valid=false
  check(valid,"Retarget resolves all bones: "+clip)
 var hand=hero.skeleton.find_bone("RightHand")
 hero.player.play("Sword_Attack")
 hero.player.seek(.05,true)
 var first=hero.skeleton.get_bone_global_pose(hand)
 hero.player.seek(.5,true)
 var second=hero.skeleton.get_bone_global_pose(hand)
 check(not first.is_equal_approx(second),"Sword attack moves actual hand bones")
 await get_tree().process_frame
 var attachment=hero.find_child("EquippedWeapon",true,false).get_parent()
 check(attachment is BoneAttachment3D and attachment.bone_name=="RightHand","Sword follows animated hand attachment")
 hero.action_remaining=0
 hero.motion(true,true)
 check(hero.player.current_animation=="Sprint","Sprint plays authored movement")
 hero.play_action("Shield raised")
 hero.action_remaining=0
 hero.motion(false)
 check(hero.player.current_animation=="Idle_Shield","Defend settles into shield stance")
 hero.play_reaction()
 check(hero.player.current_animation=="Idle_Shield_Break","Guarded damage uses shield reaction")
 hero.guarding=false
 hero.play_reaction()
 check(hero.player.current_animation=="Hit_Chest","Normal damage uses hit reaction")
 for action in HeroVisual.ACTION_CLIPS:
  check(hero.play_action(action)>0 and hero.player.has_animation(hero.player.current_animation),"Mapped action plays: "+action)
 var traveler=HeroVisual.new({"Weapon":"None","Shield":"None","Chest":"None"})
 add_child(traveler)
 check(traveler.skin_id=="paladin_female" and traveler.find_child("EquippedWeapon",true,false)==null,"New adventure is visibly unequipped in authored traveler clothing")
 for item in State.equipment_data:
  if State.equipment_data[item].slot!="Weapon":continue
  var equipped=gear.duplicate()
  equipped.Weapon=item
  var visual=HeroVisual.new(equipped)
  add_child(visual)
  check((visual.find_child("EquippedShield",true,false)==null)==GameRules.two_handed(State.equipment_data[item]),"Shield visibility matches weapon rules: "+item)
  visual.play_action("Attack")
  visual.queue_free()
 for primary in State.classes:
  var old=State.hero.primary
  State.hero.primary=primary
  var visual=Art.actor("Hero",gear)
  add_child(visual)
  check(visual.model.name=="QuaterniusRanger","Authored hero available to class "+primary)
  visual.queue_free()
  State.hero.primary=old
 check(JSON.stringify(State.hero)==before,"Visual construction does not alter hero data or save format")
 hero.queue_free()
 traveler.queue_free()
 await get_tree().process_frame
 print("Quaternius hero checks: %d Failures: %d" % [checks,failures])
 get_tree().quit(1 if failures else 0)
