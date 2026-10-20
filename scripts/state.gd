extends Node
const SAVE = "user://hero.json"
var classes: Dictionary = {}
var equipment_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
var hero: Dictionary
var notice = ""
var menu_page="equipment"
var return_position=Vector3.ZERO
var enemy_id="goblin"
var encounter_id=-1
var cleared_until: Dictionary={}

func _ready():
 classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
 reset()
 load_game()
func reset():
 return_position=Vector3.ZERO
 hero = {"skills":{"Paladin":[],"Ranger":[],"Druid":[]},"journey":{"started":false,"guards":[],"seals":[],"boss":false,"finished":false,"chest":false,"entered":false,"region":"forest","position":[0.0,0.0,0.0]},"exploration":{"herbs":[],"quest_done":false,"shrine":false},"level":1,"xp":0,"hp":110,"mp":35,"gold":0,"points":3,"primary":"Paladin","secondary":["Ranger","Druid"],"investments":{"Paladin":0,"Ranger":0,"Druid":0},"equipment":{"Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"None","Chest":"Steel Cuirass","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},"companion":{"selected":0,"behavior":"Attack","active":true,"roster":["Wolf",null,null,null,null,null],"postgame":null},"mastery":0,"potions":5,"seed":137}
func stats() -> Dictionary:
 var l=int(hero.level)
 var result={"max_hp":100+l*10,"max_mp":30+l*5,"attack":12+l*3,"defense":4+l,"speed":12+l,"wolf_attack":0,"healing":0}
 for item in hero.equipment.values():
  var data: Dictionary=equipment_data.get(item,{})
  result.attack+=int(data.get("attack",0))
  result.defense+=int(data.get("defense",0))
 for c in classes:
  for node in classes[c].nodes:
   if hero.skills.get(c,[]).has(node.id):
    for key in node.bonus: result[key]+=int(node.bonus[key])
 return result
func skill_node(class_: String, id: String) -> Dictionary:
 for node in classes.get(class_,{}).get("nodes",[]):
  if node.id==id: return node
 return {}
func invest_skill(class_: String, id: String) -> bool:
 var node=skill_node(class_,id)
 if node.is_empty() or hero.skills[class_].has(id): return false
 if hero.points<int(node.cost): return false
 for prerequisite in node.requires:
  if not hero.skills[class_].has(prerequisite): return false
 hero.skills[class_].append(id)
 hero.points-=int(node.cost)
 hero.investments[class_]=hero.skills[class_].size()
 save_game()
 return true
func set_primary(class_: String):
 if not classes.has(class_): return
 hero.primary=class_
 hero.secondary=classes.keys().filter(func(c): return c!=class_)
 save_game()
func equip(slot: String, item: String) -> bool:
 if not hero.equipment.has(slot): return false
 if item!="None":
  if not equipment_data.has(item): return false
  if equipment_data[item].slot not in [slot,"Any"]: return false
 if slot=="Weapon" and item=="None": return false
 hero.equipment[slot]=item
 var attributes=stats()
 hero.hp=mini(hero.hp,attributes.max_hp)
 hero.mp=mini(hero.mp,attributes.max_mp)
 save_game()
 return true
func migrate_skills():
 for c in classes:
  var rank=int(hero.investments.get(c,0))
  var unlocked: Array=[]
  if rank>=1: unlocked.append("oath")
  if rank>=2: unlocked.append("shield")
  if rank>=3: unlocked.append_array(["light","mythic"])
  hero.skills[c]=unlocked
  hero.investments[c]=unlocked.size()
func reward(normal: bool, species: String="goblin"):
 var enemies: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 var enemy: Dictionary=enemies[species]
 hero.xp+=int(enemy.xp)
 hero.gold+=int(enemy.gold)
 if normal and species=="goblin": hero.mastery+=1
 hero.seed=(int(hero.seed)*48271)%2147483647
 if hero.seed%int(enemy.drop_chance)==0: hero.potions+=1
 while hero.xp>=int(hero.level)*70:
  hero.xp-=int(hero.level)*70
  hero.level+=1
  hero.points+=3
  notice="Level up! Three skill points earned."
func save_game():
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(hero))
func load_game():
 if FileAccess.file_exists(SAVE):
  var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  if data is Dictionary:
   var legacy_skills=not data.has("skills")
   var saved_position: Array=[]
   if data.get("journey") is Dictionary and data.journey.get("position") is Array:
    saved_position=data.journey.position.duplicate()
   for key in hero:
    if data.has(key): hero[key]=merge_defaults(hero[key],normalize(data[key]))
   if saved_position.size()==3: hero.journey.position=[float(saved_position[0]),float(saved_position[1]),float(saved_position[2])]
   if legacy_skills: migrate_skills()
   var legacy_gear={"Helmet":"Ranger Hood","Gauntlets":"Leather Gloves","Pants":"Ranger Trousers","Boots":"Trail Boots","Accessory":"Moonleaf Charm"}
   for slot in legacy_gear:
    if hero.equipment[slot]=="Leather Gear": hero.equipment[slot]=legacy_gear[slot]
   var pos=hero.journey.position
   return_position=Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
func can_mythic(class_name_: String) -> bool:
 return hero.primary==class_name_ and hero.skills.get(class_name_,[]).has("mythic")

func normalize(value):
 if value is float: return int(value)
 if value is Dictionary:
  for key in value: value[key]=normalize(value[key])
 elif value is Array:
  for i in range(value.size()): value[i]=normalize(value[i])
 return value

func merge_defaults(default, value):
 if default is Dictionary and value is Dictionary:
  for key in default:
   if value.has(key): default[key]=merge_defaults(default[key],value[key])
  return default
 return value
func travel_scene() -> String:
 return "res://scenes/dungeon.tscn" if hero.journey.region=="dungeon" else "res://scenes/world.tscn"
func restore():
 hero.hp=stats().max_hp
 hero.mp=stats().max_mp

func remember_position(pos: Vector3):
 return_position=pos
 hero.journey.position=[pos.x,pos.y,pos.z]
