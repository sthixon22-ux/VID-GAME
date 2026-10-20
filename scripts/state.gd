extends Node
const SAVE = "user://hero.json"
var classes: Dictionary = {}
var companions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/companions.json"))
var weapon_trees: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_trees.json"))
var equipment_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
var hero: Dictionary
var notice = ""
var save_notice=""
var save_blocked=false
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
 save_notice=""
 save_blocked=false
 return_position=Vector3.ZERO
 hero = {"skills":{"Paladin":[],"Ranger":[],"Druid":[]},"journey":{"started":false,"guards":[],"seals":[],"boss":false,"finished":false,"chest":false,"entered":false,"region":"forest","position":[0.0,0.0,0.0]},"exploration":{"herbs":[],"quest_done":false,"shrine":false},"level":1,"xp":0,"hp":110,"mp":35,"gold":0,"points":3,"primary":"Paladin","secondary":["Ranger","Druid"],"investments":{"Paladin":0,"Ranger":0,"Druid":0},"equipment":{"Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"None","Chest":"Steel Cuirass","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},"companion":{"selected":0,"behavior":"Attack","active":true,"roster":["Wolf",null,null,null,null,null],"postgame":null},"mastery":0,"potions":5,"seed":137}
 hero.profile={"created":false,"economy":false,"name":"Traveler","skin":0,"hair":0,"dye":0}
 hero.inventory=[]
 hero.class_mastery={"Paladin":0,"Ranger":0,"Druid":0}
 hero.weapon_mastery={"sword":0,"shield":0}
 hero.weapon_skills={"sword":[],"shield":[]}
 hero.monsters={"goblin":0,"mossling":0}
 hero.demo={"field_guards":[],"elapsed":0,"echo":false,"first_choice":false,"started_at":0}
 for class_ in classes:
  if not hero.skills.has(class_): hero.skills[class_]=[]
  if not hero.investments.has(class_): hero.investments[class_]=0
  if not hero.class_mastery.has(class_): hero.class_mastery[class_]=0
 hero.companion.merge({"current":"intro_wolf","owned":[],"records":{},"postgame_unlocked":false,"intro_hp":55})

func stats() -> Dictionary:
 var l=int(hero.level)
 var result={"max_hp":100+l*10,"max_mp":30+l*5,"attack":12+l*3,"defense":4+l,"speed":12+l,"wolf_attack":0,"healing":0}
 for item in hero.equipment.values():
  var data: Dictionary=equipment_data.get(item,{})
  result.attack+=int(data.get("attack",0))
  result.defense+=int(data.get("defense",0))
 if hero.profile.economy and classes.has(hero.primary):
  for key in classes[hero.primary].primary_bonus: result[key]+=int(classes[hero.primary].primary_bonus[key])
 for c in active_classes():
  for node in classes[c].nodes:
   if hero.skills.get(c,[]).has(node.id):
    for key in node.bonus: result[key]+=int(node.bonus[key])
 if hero.equipment.Weapon!="None" and hero.weapon_skills.sword.has("edge"): result.attack+=2
 if hero.equipment.Shield!="None" and hero.weapon_skills.shield.has("brace"): result.defense+=2
 return result
func skill_node(class_: String, id: String) -> Dictionary:
 for node in classes.get(class_,{}).get("nodes",[]):
  if node.id==id: return node
 return {}
func invest_skill(class_: String, id: String) -> bool:
 var node=skill_node(class_,id)
 if node.is_empty() or hero.skills[class_].has(id): return false
 if hero.points<int(node.cost): return false
 if hero.profile.economy and int(hero.class_mastery[class_])<int(node.get("mastery_required",0)): return false
 for prerequisite in node.requires:
  if not hero.skills[class_].has(prerequisite): return false
 hero.skills[class_].append(id)
 hero.points-=int(node.cost)
 hero.investments[class_]=hero.skills[class_].size()
 save_game()
 return true
func set_primary(class_: String):
 if not classes.has(class_) or not can_change_class(): return
 hero.primary=class_
 hero.secondary=classes.keys().filter(func(c): return c!=class_).slice(0,2)
 for slot in hero.equipment:
  if hero.equipment[slot]!="None" and not compatible(hero.equipment[slot]): hero.equipment[slot]="None"
 hero.hp=mini(int(hero.hp),int(stats().max_hp))
 hero.mp=mini(int(hero.mp),int(stats().max_mp))
 save_game()
func equip(slot: String, item: String) -> bool:
 if not hero.equipment.has(slot): return false
 if item!="None":
  if not equipment_data.has(item): return false
  if equipment_data[item].slot not in [slot,"Any"]: return false
 if item!="None" and (not owns(item) or not compatible(item)): return false
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
 if normal and hero.monsters.has(species): hero.monsters[species]+=1
 for class_ in active_classes(): hero.class_mastery[class_]+=1
 if hero.equipment.Weapon!="None": hero.weapon_mastery.sword+=1
 if hero.equipment.Shield!="None": hero.weapon_mastery.shield+=1
 if hero.companion.current!="intro_wolf" and hero.companion.active:
  var record=hero.companion.records[hero.companion.current]
  record.xp+=int(enemy.xp)
  while record.xp>=record.level*60:
   record.xp-=record.level*60
   record.level+=1
   record.points+=1
 hero.seed=(int(hero.seed)*48271)%2147483647
 if hero.seed%int(enemy.drop_chance)==0: hero.potions+=1
 while hero.xp>=int(hero.level)*70:
  hero.xp-=int(hero.level)*70
  hero.level+=1
  hero.points+=3
  notice="Level up! Three skill points earned."
func save_game() -> bool:
 if save_blocked: return false
 var success=SaveStore.write_hero(hero,SAVE)
 if not success: save_notice="Save failed. Your previous file has been preserved."
 return success
func load_game():
 var result=SaveStore.load_hero(SAVE)
 save_notice=result.notice
 save_blocked=result.blocked
 var data: Dictionary=result.hero
 if not data.is_empty():
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
  # Older wardrobe saves retain all gear; new economy saves retain only owned items.
  if not data.has("inventory"):
   for item in equipment_data: grant_item(item)

  hero.monsters.goblin=maxi(int(hero.monsters.goblin),int(hero.mastery))
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
  for key in value:
   default[key]=merge_defaults(default[key],value[key]) if default.has(key) else value[key]
  return default
 return value
func travel_scene() -> String:
 if hero.profile.economy and not hero.profile.created: return "res://scenes/create.tscn"
 return "res://scenes/dungeon.tscn" if hero.journey.region=="dungeon" else "res://scenes/world.tscn"
func restore():
 hero.hp=stats().max_hp
 hero.mp=stats().max_mp
 restore_companion()

func remember_position(pos: Vector3):
 return_position=pos
 hero.journey.position=[pos.x,pos.y,pos.z]

func new_adventure():
 reset()
 cleared_until.clear()
 enemy_id="goblin"
 hero.profile.economy=true
 hero.primary=""
 hero.secondary=[]
 for slot in hero.equipment: hero.equipment[slot]="None"
 hero.gold=120
 hero.potions=3
func create_hero(name_: String, primary: String, skin: int, hair: int, dye: int, secondary: Array=[]) -> bool:
 if hero.profile.created or not classes.has(primary): return false
 if secondary.is_empty(): secondary=classes.keys().filter(func(c): return c!=primary).slice(0,2)
 if secondary.size()!=2 or secondary[0]==secondary[1] or secondary.has(primary): return false
 for value in secondary:
  if not classes.has(value): return false
 hero.profile.merge({"created":true,"name":name_.strip_edges().left(20) if not name_.strip_edges().is_empty() else "Traveler","skin":clampi(skin,0,2),"hair":clampi(hair,0,2),"dye":clampi(dye,0,2)},true)
 hero.primary=primary
 hero.secondary=secondary.duplicate()
 restore()
 return save_game()
func active_classes() -> Array:
 var result: Array=hero.secondary.duplicate()
 if classes.has(hero.primary): result.push_front(hero.primary)
 return result
func can_change_class() -> bool:
 return not hero.profile.economy or (hero.journey.region=="forest" and return_position.length()<5)
func compatible(item: String) -> bool:
 if not hero.profile.economy: return true
 var entry: Dictionary=equipment_data.get(item,{})
 if entry.get("style")=="plate": return hero.primary=="Paladin"
 return entry.get("classes",[]).has(hero.primary)
func owns(item: String) -> bool:
 return not hero.profile.economy or hero.inventory.has(equipment_data.get(item,{}).get("id",""))
func grant_item(item: String):
 var id: String=equipment_data.get(item,{}).get("id","")
 if not id.is_empty() and not hero.inventory.has(id): hero.inventory.append(id)
func buy(item: String) -> bool:
 if not equipment_data.has(item) or owns(item) or not compatible(item): return false
 var price=int(equipment_data[item].price)
 if not can_buy(item): return false
 hero.gold-=price
 grant_item(item)
 save_game()
 return true
func buy_potion() -> bool:
 if hero.gold<8 or (hero.profile.economy and not starter_ready()): return false
 hero.gold-=8
 hero.potions+=1
 save_game()
 return true
func use_potion() -> bool:
 if hero.potions<=0 or hero.hp>=stats().max_hp: return false
 hero.potions-=1
 hero.hp=mini(int(hero.hp)+45,int(stats().max_hp))
 save_game()
 return true
func companion_name() -> String:
 return companions.get(hero.companion.current,{"name":"Mira's Wolf"}).name
func choose_companion(id: String) -> bool:
 if not hero.journey.finished or not companions.has(id) or hero.companion.owned.has(id): return false
 var limit=2 if hero.companion.postgame_unlocked else 1
 if hero.companion.owned.size()>=limit: return false
 hero.companion.owned.append(id)
 hero.companion.current=id
 hero.companion.active=true
 hero.companion.records[id]={"level":maxi(1,int(hero.level)-1),"xp":0,"points":2,"skills":[],"hp":int(companions[id].hp)}
 hero.demo.first_choice=true
 hero.companion.records[id].hp=companion_max_hp()
 save_game()
 return true
func activate_companion(id: String) -> bool:
 if not hero.companion.owned.has(id): return false
 hero.companion.current=id
 hero.companion.active=true
 save_game()
 return true
func train_companion(id: String) -> bool:
 if not hero.companion.records.has(hero.companion.current): return false
 var record=hero.companion.records[hero.companion.current]
 if record.points<1 or record.skills.has(id) or id not in ["predator","guardian","bond"]: return false
 record.points-=1
 record.skills.append(id)
 if id=="guardian": record.hp+=15
 save_game()
 return true
func learn_weapon(type_: String, id: String) -> bool:
 for node in weapon_trees.get(type_,[]):
  if node.id==id and hero.points>=node.cost and hero.weapon_mastery[type_]>=node.requires and not hero.weapon_skills[type_].has(id):
   hero.points-=int(node.cost)
   hero.weapon_skills[type_].append(id)
   save_game()
   return true
 return false
func companion_record() -> Dictionary:
 return hero.companion.records.get(hero.companion.current,{})
func companion_max_hp() -> int:
 var record=companion_record()
 return int(companions.get(hero.companion.current,{"hp":55}).hp)+int(record.get("level",1))*3+(15 if record.get("skills",[]).has("guardian") else 0)
func travel_multiplier() -> float:
 return 1.25 if hero.companion.active and not hero.companion.owned.is_empty() else 1.0
func restore_companion():
 hero.companion.intro_hp=55
 var record=companion_record()
 if not record.is_empty(): record.hp=companion_max_hp()

func starter_ready() -> bool:
 return hero.equipment.Weapon!="None" and hero.equipment.Shield!="None" and hero.equipment.Chest!="None"
func can_buy(item: String) -> bool:
 if not equipment_data.has(item) or owns(item) or not compatible(item): return false
 var reserve=0
 for slot in ["Weapon","Shield","Chest"]:
  if equipment_data[item].slot==slot: continue
  var slot_owned=false
  for gear in equipment_data:
   if equipment_data[gear].slot==slot and owns(gear) and compatible(gear): slot_owned=true
  if not slot_owned: reserve+={"Weapon":30,"Shield":20,"Chest":25}[slot]
 return int(hero.gold)>=int(equipment_data[item].price)+reserve
