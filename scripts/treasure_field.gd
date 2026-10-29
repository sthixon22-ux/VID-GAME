class_name TreasureField
extends Node3D
static var table:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/treasure.json"))
var area="forest"
var chests:Dictionary={}
func _init(region:String="forest"):area=region
func _ready():
 var progress=ExpeditionRules.progress(State.hero)
 for id in table:
  var entry:Dictionary=table[id]
  if entry.region!=area:continue
  var chest=Node3D.new();add_child(chest)
  chest.position=Vector3(entry.position[0],0,entry.position[2])
  VillageArt.piece(chest,"Prop_Crate",Vector3.ZERO,Vector3(1.2,.8,.8))
  for x in [-.4,.4]:Art.box(chest,Vector3(x,.45,0),Vector3(.09,.9,.84),Color("d0ab61")).material_override=Art.surface(Color("c8a362"),"metal",1)
  Art.box(chest,Vector3(0,.45,.44),Vector3(.18,.25,.07),Color("f1d494"))
  Art.sign_(chest,Vector3(0,1.6,0),"Treasure chest · [E]")
  chest.visible=not progress.chests.has(id)
  chests[id]=chest
func nearby(pos:Vector3)->String:
 for id in chests:
  if chests[id].visible and chests[id].position.distance_to(pos)<2.2:return id
 return ""
func open_near(pos:Vector3)->bool:
 var id=nearby(pos)
 if id.is_empty():return false
 var p=ExpeditionRules.progress(State.hero)
 if p.chests.has(id):return false
 var entry:Dictionary=table[id]
 p.chests.append(id)
 if int(entry.gold)>0:State.award_gold(int(entry.gold),"Treasure")
 State.hero.potions+=int(entry.potions)
 State.hero.items.ether+=int(entry.ether)
 if not entry.equipment.is_empty():State.grant_item(entry.equipment)
 State.notice="Treasure: %s gold · %s potions · %s ether%s" % [entry.gold,entry.potions,entry.ether," · "+entry.equipment if not entry.equipment.is_empty() else ""]
 chests[id].hide()
 Sound.cue("confirm")
 State.save_game()
 return true

func _process(_delta):
 if State.field_reveal_area!=area:return
 for child in get_parent().get_children():
  if child is ExplorationHUD:
   for id in chests:
    if not chests[id].visible:
     child.map.markers=child.map.markers.filter(func(marker):return marker.get("treasure","")!=id)
    if not chests[id].get_meta("mapped",false) and chests[id].visible:
     child.map.markers.append({"position":chests[id].position,"color":Color("f2d185"),"treasure":id})
     chests[id].set_meta("mapped",true)
