class_name HeroVisual
extends Node3D
const ACTION_CLIPS={
 "Victory":"Cheer", "Defeat":"Death_A",
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
func _init(equipment: Dictionary={}):
 gear=equipment.duplicate(true)
 body=Node3D.new()
 body.name="Body"
 add_child(body)
 var outfit="Knight"
 if gear.get("Chest")=="Leather Vest": outfit="Rogue"
 elif gear.get("Chest")=="Verdant Robe": outfit="Mage"
 model=load("res://assets/vendor/kaykit/%s.glb" % outfit).instantiate()
 body.add_child(model)
 body.rotation.y=PI
 body.scale=Vector3.ONE*0.85
 skeleton=model.find_children("*","Skeleton3D",true,false)[0]
 player=model.find_children("*","AnimationPlayer",true,false)[0]
 for node in model.find_children("*","MeshInstance3D",true,false):
  if node.get_parent() is BoneAttachment3D: node.hide()
 # Attach pack weapons to the shared animated hand slots; never float beside the actor.
 var source=load("res://assets/vendor/kaykit/Knight.glb").instantiate()
 var weapon=source.find_child("1H_Sword",true,false).duplicate()
 var sword_name: String=gear.get("Weapon","Iron Sword")
 weapon.name="EquippedWeapon"
 weapon.visible=true
 var sword_color=Color(State.equipment_data.get(sword_name,{}).get("color","d4e4ed"))
 if sword_name!="Iron Sword": tint(weapon,sword_color)
 if sword_name=="Moonleaf Saber": weapon.scale*=Vector3(0.75,1.08,0.75)
 socket("handslot.r").add_child(weapon)
 var shield_name: String=gear.get("Shield","None")
 if shield_name!="None":
  var shield=source.find_child("Round_Shield" if shield_name=="Oak Shield" else "Badge_Shield",true,false).duplicate()
  shield.name="EquippedShield"
  shield.visible=true
  if shield_name!="Oak Shield": tint(shield,Color(State.equipment_data[shield_name].color))
  socket("handslot.l").add_child(shield)
 var helmet: String=gear.get("Helmet","None")
 if helmet=="Steel Helm":
  var mesh=source.find_child("Knight_Helmet",true,false).duplicate()
  mesh.name="EquippedHelmet"
  mesh.visible=true
  socket("head").add_child(mesh)
 elif helmet=="Ranger Hood":
  socket("head").add_child(make_hood())
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
 source.free()
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
func tint(mesh: MeshInstance3D, color_: Color):
 var material=StandardMaterial3D.new()
 material.albedo_color=color_
 material.metallic=0.4
 material.roughness=0.35
 mesh.material_override=material
func motion(moving: bool, sprint=false):
 if action_remaining>0 or locked_pose: return
 var clip="Running_A" if moving and sprint else ("Walking_A" if moving else ("Blocking" if guarding else ("2H_Melee_Idle" if battle else "Idle")))
 if clip!=current_motion:
  current_motion=clip
  player.speed_scale=1
  player.play(clip,0.15)
func play_action(action: String) -> float:
 if action=="Defeat": locked_pose=true
 last_action=action
 var clip: String=ACTION_CLIPS.get(action,"Idle")
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

func make_hood() -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 mesh.name="EquippedHelmet"
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for latitude in range(14):
  for longitude in range(24):
   var corners: Array[Vector3]=[]
   for offset in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
    var angle=-PI/2+(latitude+offset.x)*PI/14
    var around=(longitude+offset.y)*TAU/24
    corners.append(Vector3(sin(around)*cos(angle)*0.61,0.52+sin(angle)*0.66,cos(around)*cos(angle)*0.6))
   var center=(corners[0]+corners[1]+corners[2]+corners[3])/4
   # Keep an open front for the face, and a cloth shell around the hair/ears.
   if center.z>0.22 and center.y>0.12 and center.y<1.02: continue
   for index in [0,1,2,2,1,3]: surface.add_vertex(corners[index])
 surface.generate_normals()
 mesh.mesh=surface.commit()
 var material=StandardMaterial3D.new()
 material.albedo_color=Color("507263")
 material.roughness=1
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh.material_override=material
 return mesh
