class_name HeroVisual
extends Node3D
# Visual-only Quaternius adapter. Equipment IDs, stats, classes and saves stay in State.
const ACTION_CLIPS={
 "Victory":"Yes", "Defeat":"Death01", "Dodge":"Roll",
 "Attack":"Sword_Attack", "Sword Slash":"Sword_Regular_A",
 "Shield Bash":"Shield_OneShot", "Sacred Strike":"Sword_Regular_B",
 "Hunter's Mark":"OverhandThrow", "Thornbind":"Spell_Simple_Enter",
 "Regrowth":"Spell_Simple_Idle", "Dawn Avatar":"Sword_Regular_Combo",
 "Wild Hunt":"Sword_Regular_C", "Ancient Grove":"Spell_Simple_Shoot",
 "Potion":"Consume", "Items":"Consume", "Shield raised":"Sword_Block"
}
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var gear:Dictionary
var body:Node3D
var action_remaining=0.0
var battle=false
var locked_pose=false
var guarding=false
var last_action=""
var current_motion=""
var outfit_id=""
var skin_id=""
var skin_profile:Dictionary
var sex="Female"
func _init(equipment:Dictionary={},appearance:Dictionary={}):
 gear=equipment.duplicate(true)
 body=Node3D.new()
 body.name="Body"
 add_child(body)
 var chest:String=gear.get("Chest","None")
 skin_profile=HeroSkinBook.profile(str(appearance.get("class","Paladin")),str(appearance.get("sex","Female")))
 sex=skin_profile.sex
 skin_id=skin_profile.id
 outfit_id="traveler" if skin_profile.outfit=="peasant" else "ranger"
 if chest in ["Steel Cuirass","Leather Vest"]:outfit_id="ranger"
 elif chest=="Verdant Robe":outfit_id="traveler"
 model=load(HeroSkinBook.model_path(sex,outfit_id)).instantiate()
 model.name="QuaterniusTraveler" if outfit_id=="traveler" else "QuaterniusRanger"
 body.add_child(model)
 # Source faces +Z; game movement/look_at uses -Z. Same world height in every scene.
 body.rotation.y=PI
 body.scale=Vector3.ONE*(1.8/GearVisual.bounds(model).size.y)
 skeleton=model.find_children("*","Skeleton3D",true,false)[0]
 player=AnimationPlayer.new()
 player.name="HeroMotionPlayer"
 model.add_child(player)
 player.root_node=player.get_path_to(skeleton)
 player.add_animation_library("",HeroMotionLibrary.build(skeleton))
 configure_appearance(appearance,chest)
 attach_equipment()
func configure_appearance(appearance:Dictionary,chest:String):
 var skin_colors=[Color.WHITE,Color("cfa985"),Color("906951")]
 var hair_colors=[Color("493022"),Color("bc9455"),Color("bbc3cc")]
 var cloth_colors=[Color.WHITE,Color("b1c7ae"),Color("d2a5b3")]
 var cloth_texture=load(HeroSkinBook.texture_path(skin_id,outfit_id))
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var name_=String(mesh.name)
  var helmet:String=gear.get("Helmet","None")
  if name_.contains("Head_Hood"):
   mesh.visible=helmet=="Ranger Hood" or (helmet=="None" and skin_profile.hood)
  if name_.contains("Acc_Pauldron"):mesh.visible=skin_profile.pauldrons or chest=="Steel Cuirass"
  for surface in range(mesh.mesh.get_surface_count()):
   var original=mesh.get_active_material(surface)
   if not original is StandardMaterial3D:continue
   var material:StandardMaterial3D=original.duplicate()
   var material_name=String(original.resource_name)
   if material_name.contains("Superhero") or material_name.contains("Regular"):
    material.albedo_color*=skin_colors[clampi(int(appearance.get("skin",0)),0,2)]
   elif material_name.contains("Hair"):
    material.albedo_color=hair_colors[clampi(int(appearance.get("hair",0)),0,2)]
   elif material_name in ["MI_Ranger","MI_Peasant"]:
    material.albedo_texture=cloth_texture
    material.albedo_color=cloth_colors[clampi(int(appearance.get("dye",0)),0,2)]
    if chest=="Steel Cuirass" and name_.contains("Body"):
     material.metallic=.55;material.roughness=.4
   mesh.set_surface_override_material(surface,material)
func attach_equipment():
 var weapon:String=gear.get("Weapon","None")
 if weapon!="None":
  var prop=GearVisual.item(weapon)
  prop.name="EquippedWeapon"
  prop.scale=Vector3.ONE*.65
  prop.rotation_degrees=Vector3(90,0,0)
  socket("RightHand").add_child(prop)
 var shield:String=gear.get("Shield","None")
 var family:String=State.equipment_data.get(weapon,{}).get("weapon_type","unarmed")
 if shield!="None" and not GameRules.TWO_HANDED.has(family):
  var prop=GearVisual.item(shield)
  prop.name="EquippedShield"
  prop.scale=Vector3.ONE*.65
  prop.rotation_degrees=Vector3(0,90,90)
  socket("LeftHand").add_child(prop)
 var helmet:String=gear.get("Helmet","None")
 if helmet!="None" and helmet!="Ranger Hood":
  var prop=GearVisual.item(helmet)
  prop.name="EquippedHelmet"
  prop.scale=Vector3.ONE*.40
  prop.position.y=.15
  prop.rotation.y=PI
  socket("Head").add_child(prop)
 # No rigid chest shell over a deforming torso. The two source outfits are skinned.
 # Existing small gear models are retained as transitional accessories, not final armor art.
 for slot in ["Gauntlets","Pants","Boots","Accessory"]:
  var item:String=gear.get(slot,"None")
  if item=="None":continue
  var bones={"Gauntlets":["LeftLowerArm","RightLowerArm"],"Pants":["LeftLowerLeg","RightLowerLeg"],"Boots":["LeftFoot","RightFoot"],"Accessory":["Chest"]}[slot]
  for bone in bones:
   var prop=GearVisual.item(item)
   prop.name="Equipped"+slot+bone
   prop.scale=Vector3.ONE*(.30 if slot!="Accessory" else .25)
   prop.rotation.y=PI
   # Each legacy item contains a pair; retain only the correct side at each limb.
   if slot!="Accessory":
    for mesh in prop.find_children("*","MeshInstance3D",true,false):
     var x=mesh.position.x
     if absf(x)<.001:x=mesh.get_aabb().get_center().x
     if (bone.begins_with("Left") and x<0) or (bone.begins_with("Right") and x>0):mesh.hide()
   if slot=="Accessory":prop.position=Vector3(0,.0,.13)
   socket(bone).add_child(prop)
func socket(bone:String)->BoneAttachment3D:
 for child in skeleton.get_children():
  if child is BoneAttachment3D and child.bone_name==bone:return child
 var attachment=BoneAttachment3D.new()
 attachment.name="Slot_"+bone
 attachment.bone_name=bone
 skeleton.add_child(attachment)
 return attachment
func _ready():motion(false)
func motion(moving:bool,sprint=false):
 if action_remaining>0 or locked_pose:return
 var clip="Sprint" if moving and sprint else ("Walk" if moving else ("Idle_Shield" if guarding else ("Sword_Idle" if battle else "Idle")))
 if clip==current_motion:return
 current_motion=clip
 player.speed_scale=1
 player.play(clip,.15)
func play_action(action:String)->float:
 action=action.trim_suffix(" · Critical!")
 last_action=action
 if action=="Defeat":locked_pose=true
 var clip:String=ACTION_CLIPS.get(action,"")
 if clip.is_empty():
  var entry=AbilityBook.entry(action)
  clip="Spell_Simple_Idle" if entry.get("effect","") in ["heal","buff","renewal","meditate"] else ("Spell_Simple_Shoot" if entry.get("kind","") in ["spell","mythic"] else "Sword_Attack")
 if action=="Attack":
  var family:String=State.equipment_data.get(gear.get("Weapon","None"),{}).get("weapon_type","unarmed")
  if family in ["staff","wand"]:clip="Spell_Simple_Shoot"
  elif family in ["unarmed","claws"]:clip="Punch_Jab"
  elif family=="bow":clip="OverhandThrow" # No bow-specific clip in the licensed free libraries yet.
 var animation=player.get_animation(clip)
 var duration=clampf(animation.length,.7,1.8)
 var speed:float=UserSettings.battle_speed if battle else 1.0
 current_motion=""
 player.speed_scale=animation.length/duration*speed
 player.play(clip,.07)
 action_remaining=duration/speed
 if action in ["Shield raised","Shield Bash"]:guarding=true
 return duration
func _process(delta):
 if action_remaining>0:
  action_remaining=maxf(0,action_remaining-delta)
  if action_remaining==0:motion(false)
func play_reaction():
 if locked_pose:return
 current_motion=""
 var clip="Idle_Shield_Break" if guarding else "Hit_Chest"
 var speed:float=UserSettings.battle_speed if battle else 1.0
 player.speed_scale=player.get_animation(clip).length/.45*speed
 player.play(clip,.05)
 action_remaining=.45/speed
