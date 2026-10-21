class_name HeroVisual
extends Node3D
const ACTION_CLIPS={
 "Victory":"Cheer", "Defeat":"Death_A", "Dodge":"Dodge_Backward",
 "Attack":"1H_Melee_Attack_Stab",
 "Sword Slash":"1H_Melee_Attack_Slice_Diagonal",
 "Shield Bash":"Block_Attack",
 "Sacred Strike":"1H_Melee_Attack_Chop",
 "Hunter's Mark":"1H_Ranged_Shoot",
 "Thornbind":"Spellcast_Raise",
 "Regrowth":"Spellcast_Long",
 "Dawn Avatar":"2H_Melee_Attack_Spin",
 "Wild Hunt":"Dualwield_Melee_Attack_Slice",
 "Ancient Grove":"Spellcasting",
 "Potion":"Use_Item",
 "Items":"Use_Item",
 "Shield raised":"Block"
}
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var gear: Dictionary
var body: Node3D
var action_remaining=0.0
var battle=false
var locked_pose=false
var guarding=false
var last_action=""
var current_motion=""
func _init(equipment: Dictionary={}, appearance: Dictionary={}):
 gear=equipment.duplicate(true)
 body=Node3D.new()
 body.name="Body"
 add_child(body)
 var outfit="Knight"
 if gear.get("Chest") in ["Leather Vest","Traveler's Clothing","None"]: outfit="Rogue"
 elif gear.get("Chest")=="Verdant Robe": outfit="Mage"
 model=load("res://assets/models/heroes/%s.glb" % outfit).instantiate()
 body.add_child(model)
 body.rotation.y=PI
 body.scale=Vector3.ONE*0.85
 skeleton=model.find_children("*","Skeleton3D",true,false)[0]
 player=model.find_children("*","AnimationPlayer",true,false)[0]
 for node in model.find_children("*","MeshInstance3D",true,false):
  if node.get_parent() is BoneAttachment3D: node.hide()
 # Attach pack weapons to the shared animated hand slots; never float beside the actor.
 var sword_name: String=gear.get("Weapon","Iron Sword")
 var weapon:Node3D=GearVisual.item(sword_name) if sword_name!="None" else Node3D.new()
 weapon.name="EquippedWeapon"
 weapon.visible=sword_name!="None"
 socket("handslot.r").add_child(weapon)
 var shield_name: String=gear.get("Shield","None")
 if shield_name!="None":
  var shield=GearVisual.item(shield_name)
  shield.name="EquippedShield"
  shield.rotation.y=PI
  socket("handslot.l").add_child(shield)
 var helmet: String=gear.get("Helmet","None")
 if helmet!="None":
  var helm=GearVisual.item(helmet)
  helm.name="EquippedHelmet"
  helm.position.y=0.06
  helm.scale=Vector3.ONE*.52
  helm.rotation.y=PI
  socket("head").add_child(helm)
 var chest_name:String=gear.get("Chest","None")
 if chest_name!="None":
  var armor=GearVisual.item(chest_name)
  armor.name="EquippedChest"
  armor.scale=Vector3(.72,.78,1.12)
  armor.position.z=0.06
  armor.rotation.y=PI
  socket("chest").add_child(armor)
 # Independent modular pieces remain visible regardless of chest outfit.
 for slot in ["Gauntlets","Pants","Boots","Accessory"]:
  var item: String=gear.get(slot,"None")
  if item=="None": continue
  var color_=Color(State.equipment_data.get(item,{}).get("color","81694e"))
  var targets={"Gauntlets":["hand.l","hand.r"],"Pants":["lowerleg.l","lowerleg.r"],"Boots":["foot.l","foot.r"],"Accessory":["chest"]}[slot]
  for bone in targets:
   var attachment=socket(bone)
   var piece: MeshInstance3D
   if slot=="Accessory": piece=Art.shape(attachment,Vector3(0,0.08,-0.23),Vector3(0.1,0.15,0.06),color_,"cone")
   elif slot=="Boots": piece=Art.box(attachment,Vector3(0,0.02,0.08),Vector3(0.22,0.2,0.36),color_)
   else: piece=Art.shape(attachment,Vector3(0,0.08,0),Vector3(0.23,0.28,0.23),color_,"cylinder")
   piece.name="Equipped"+slot+bone.replace(".","_")
   piece.material_override.metallic=0.75 if "Steel" in item else 0.05
   piece.material_override.roughness=0.3 if "Steel" in item else 0.85
   if slot!="Accessory":
    var trim=Art.shape(attachment,Vector3(0,0.16,0),Vector3(0.245,0.035,0.245),Color("a68a53"),"cylinder")
    trim.material_override.metallic=0.7
    trim.material_override.roughness=0.32
 var skins=[Color("b98d70"),Color("95664b"),Color("60412e")]
 var hairs=[Color("302117"),Color("9f7947"),Color("737f89")]
 var dyes=[Color("516778"),Color("626b4b"),Color("79504b")]
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  if str(mesh.name) not in ["Skin","Hair","Tunic","Trousers","Boots"]:continue
  var material=StandardMaterial3D.new()
  material.roughness=.82
  match str(mesh.name):
   "Skin":material.albedo_color=skins[int(appearance.get("skin",0))];material.roughness=.62
   "Hair":material.albedo_color=hairs[int(appearance.get("hair",0))]
   "Tunic":
    material.albedo_color=dyes[int(appearance.get("dye",0))]
    material.albedo_texture=load("res://assets/textures/rpg/cloth_albedo.png")
    material.uv1_scale=Vector3(5,5,5)
   "Trousers":material.albedo_color=Color("343e43")
   "Boots":material.albedo_color=Color("49382a");material.roughness=.65
  mesh.material_override=material
 for clip in player.get_animation_list():
  var animation=player.get_animation(clip)
  if clip in ["Idle","2H_Melee_Idle","Walking_A","Running_A","Blocking"]: animation.loop_mode=Animation.LOOP_LINEAR
func _ready():
 motion(false)
func socket(bone: String) -> BoneAttachment3D:
 for child in skeleton.get_children():
  if child is BoneAttachment3D and child.bone_name==bone: return child
 var attachment=BoneAttachment3D.new()
 attachment.bone_name=bone
 attachment.name="Slot_"+bone.replace(".","_")
 skeleton.add_child(attachment)
 return attachment
func motion(moving: bool, sprint=false):
 if action_remaining>0 or locked_pose: return
 var clip="Running_A" if moving and sprint else ("Walking_A" if moving else ("Blocking" if guarding else ("2H_Melee_Idle" if battle else "Idle")))
 if clip!=current_motion:
  current_motion=clip
  player.speed_scale=1
  player.play(clip,0.15)
func play_action(action: String) -> float:
 action=action.trim_suffix(" · Critical!")
 if action=="Defeat": locked_pose=true
 last_action=action
 var clip: String=ACTION_CLIPS.get(action,"")
 if clip.is_empty():
  var entry=AbilityBook.entry(action)
  clip="Spellcast_Long" if entry.get("effect","") in ["heal","buff","renewal","meditate"] else ("Spellcast_Raise" if entry.get("kind","") in ["spell","mythic"] else "1H_Melee_Attack_Chop")
 var family: String=State.equipment_data.get(gear.get("Weapon","None"),{}).get("weapon_type","unarmed")
 if action=="Attack":
  if family=="bow": clip="2H_Ranged_Shoot"
  elif family=="wand": clip="Spellcast_Shoot"
  elif family in ["unarmed","claws"]: clip="Unarmed_Melee_Attack_Punch_A"
  elif family in ["greatsword","hammer","scythe"]: clip="2H_Melee_Attack_Chop"
 var animation=player.get_animation(clip)
 var duration=clampf(animation.length,0.7,1.8)
 current_motion=""
 player.speed_scale=animation.length/duration*(UserSettings.battle_speed if battle else 1.0)
 player.play(clip,0.07)
 action_remaining=duration/(UserSettings.battle_speed if battle else 1.0)
 if action=="Shield raised" or action=="Shield Bash": guarding=true
 return duration
func _process(delta):
 if action_remaining>0:
  action_remaining=maxf(0,action_remaining-delta)
  if action_remaining==0: motion(false)

func play_reaction():
 if locked_pose: return
 current_motion=""
 var clip="Block_Hit" if guarding else "Hit_A"
 player.speed_scale=player.get_animation(clip).length/0.45*(UserSettings.battle_speed if battle else 1.0)
 player.play(clip,0.05)
 action_remaining=0.45/(UserSettings.battle_speed if battle else 1.0)
