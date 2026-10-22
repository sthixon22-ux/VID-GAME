extends Node
const SAVE = "user://hero.json"
var classes: Dictionary = {}
var companions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/companions.json"))
var weapon_trees: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_trees.json"))
var equipment_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
var hero: Dictionary
var last_reward: Dictionary={}
var notice = ""
var save_notice=""
var save_blocked=false
var menu_page="equipment"
var shop_id="willowbrook"
var return_position=Vector3.ZERO
var enemy_id="goblin"
var encounter_id=-1
var cleared_until: Dictionary={}

func _ready():
 QuestBook.add_marsh_quests()
 classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
 reset()
 load_game()
func reset():
 shop_id="willowbrook"
 notice=""
 last_reward={}
 save_notice=""
 save_blocked=false
 return_position=Vector3.ZERO
 hero = {"skills":{"Paladin":[],"Ranger":[],"Druid":[]},"journey":{"started":false,"guards":[],"seals":[],"boss":false,"finished":false,"chest":false,"entered":false,"region":"forest","position":[0.0,0.0,0.0]},"exploration":{"herbs":[],"quest_done":false,"shrine":false},"level":1,"xp":0,"hp":110,"mp":35,"gold":0,"points":3,"primary":"Paladin","secondary":["Ranger","Druid"],"investments":{"Paladin":0,"Ranger":0,"Druid":0},"equipment":{"Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"None","Chest":"Steel Cuirass","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},"companion":{"selected":0,"behavior":"Attack","active":true,"roster":["Wolf",null,null,null,null,null],"postgame":null},"mastery":0,"potions":5,"seed":137}
 hero.items={"ether":1,"treat":1}
 hero.side_quests={"goblin":0,"mossling":0,"started":[],"claimed":[],"crystals":[]}
 hero.puzzles={"dials":[0,0,0],"sequence":[],"solved":[]}
 hero.town_visit={"region":"forest","service":"weapons","name":"Town service","position":[0,0,0]}
 hero.campaign=MirefenRules.defaults()
 hero.world_version=8
 hero.progression_version=GameRules.PROGRESSION_VERSION
 hero.progression_archive={}
 hero.points=GameRules.POINTS_PER_LEVEL
 hero.profile={"created":false,"economy":false,"name":"Traveler","sex":"Female","skin":0,"hair":0,"dye":0}
 hero.inventory=[]
 hero.class_mastery={"Paladin":0,"Ranger":0,"Druid":0}
 hero.weapon_mastery={}
 hero.weapon_skills={}
 for family in weapon_trees:
  hero.weapon_mastery[family]=0
  hero.weapon_skills[family]=[]
 hero.monsters={"goblin":0,"mossling":0,"bristleback":0}
 hero.demo={"field_guards":[],"elapsed":0,"echo":false,"first_choice":false,"started_at":0}
 for class_ in classes:
  if not hero.skills.has(class_): hero.skills[class_]=[]
  if not hero.investments.has(class_): hero.investments[class_]=0
  if not hero.class_mastery.has(class_): hero.class_mastery[class_]=0
 hero.companion.merge({"current":"intro_wolf","owned":[],"records":{},"postgame_unlocked":false,"intro_hp":55})

func stats() -> Dictionary:
 var result=GameRules.combined_stats(classes,hero.primary,hero.secondary,int(hero.level))
 result.wolf_attack=0
 result.healing=0
 result.critical=5
 for slot in hero.equipment:
  if slot=="Shield" and GameRules.two_handed(equipment_data.get(hero.equipment.Weapon,{})): continue
  apply_bonus(result,equipment_data.get(hero.equipment[slot],{}))
 for class_ in classes:
  for node in classes[class_].nodes:
   if skill_active(class_,node.id): apply_bonus(result,node.bonus)
 for family in [weapon_type(),"shield" if hero.equipment.Shield!="None" and not GameRules.two_handed(equipment_data.get(hero.equipment.Weapon,{})) else ""]:
  for node in weapon_trees.get(family,[]):
   if weapon_skill_active(family,node.id): apply_bonus(result,node.bonus)
 for key in result: result[key]+=CompanionRules.bonus(hero,key)
 result.agility=maxi(1,int(result.agility))
 result.dexterity=maxi(0,int(result.dexterity))
 result.speed=result.agility # Compatibility alias for older tools; initiative uses agility.
 return result
func apply_bonus(result: Dictionary, source: Dictionary):
 for key in result:
  result[key]+=int(source.get(key,0))
func skill_active(class_: String, id: String) -> bool:
 var node=skill_node(class_,id)
 return not node.is_empty() and hero.skills.get(class_,[]).has(id)
func weapon_skill_active(family: String, id: String) -> bool:
 for node in weapon_trees.get(family,[]):
  if node.id==id: return hero.weapon_skills.get(family,[]).has(id)
 return false
func weapon_type() -> String:
 return equipment_data.get(hero.equipment.Weapon,{}).get("weapon_type","unarmed")
func proficiencies() -> Array:
 var result: Array=[]
 for class_ in active_classes():
  for family in classes[class_].proficiencies:
   if not result.has(family): result.append(family)
 for family in weapon_trees:
  if hero.weapon_skills.get(family,[]).has("master") and not result.has(family): result.append(family)
 return result
func skill_node(class_: String, id: String) -> Dictionary:
 for node in classes.get(class_,{}).get("nodes",[]):
  if node.id==id: return node
 return {}
func invest_skill(class_: String, id: String) -> bool:
 var node=skill_node(class_,id)
 if node.is_empty() or hero.skills[class_].has(id): return false
 if hero.points<int(node.cost): return false
 if not active_classes().has(class_): return false
 for prerequisite in node.requires:
  if not hero.skills[class_].has(prerequisite): return false
 hero.skills[class_].append(id)
 hero.points-=int(node.cost)
 hero.investments[class_]=hero.skills[class_].size()
 save_game()
 return true
func set_primary(class_: String):
 set_class_slot("primary",class_)
func set_class_slot(slot: String, class_: String) -> bool:
 if not classes.has(class_) or not can_change_class(): return false
 var loadout: Array=[hero.primary]+hero.secondary
 var index=["primary","secondary_1","secondary_2"].find(slot)
 if index<0 or loadout.size()!=3: return false
 var existing=loadout.find(class_)
 if existing>=0: loadout[existing]=loadout[index]
 loadout[index]=class_
 hero.primary=loadout[0]
 hero.secondary=loadout.slice(1,3)
 for gear_slot in hero.equipment:
  if hero.equipment[gear_slot]!="None" and not compatible(hero.equipment[gear_slot]): hero.equipment[gear_slot]="None"
 hero.hp=mini(int(hero.hp),int(stats().max_hp))
 hero.mp=mini(int(hero.mp),int(stats().max_mp))
 save_game()
 return true
func equip(slot: String, item: String) -> bool:
 if not hero.equipment.has(slot): return false
 if item!="None":
  if not equipment_data.has(item): return false
  if equipment_data[item].slot not in [slot,"Any"]: return false
 if item!="None" and (not owns(item) or not compatible(item)): return false
 if slot=="Shield" and item!="None" and GameRules.two_handed(equipment_data.get(hero.equipment.Weapon,{})): return false
 if slot=="Weapon" and GameRules.two_handed(equipment_data.get(item,{})): hero.equipment.Shield="None"
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
 award_gold(int(enemy.gold),"Battle victory")
 hero.side_quests[species]=int(hero.side_quests.get(species,0))+1
 if normal and species=="goblin": hero.mastery+=1
 if normal: hero.monsters[species]=int(hero.monsters.get(species,0))+1
 for class_ in active_classes(): hero.class_mastery[class_]+=1
 if proficiencies().has(weapon_type()): hero.weapon_mastery[weapon_type()]+=1
 if hero.equipment.Shield!="None": hero.weapon_mastery.shield+=1
 if hero.companion.current!="intro_wolf" and hero.companion.active:
  var record=hero.companion.records[hero.companion.current]
  record.xp+=int(enemy.xp)
  while record.xp>=record.level*60:
   record.xp-=record.level*60
   record.level+=1
   record.points+=2
 hero.seed=(int(hero.seed)*48271)%2147483647
 if hero.seed%int(enemy.drop_chance)==0: hero.potions+=1
 while hero.xp>=int(hero.level)*70:
  hero.xp-=int(hero.level)*70
  hero.level+=1
  hero.points+=GameRules.POINTS_PER_LEVEL
  notice="Level up! Two skill points earned; class stats increased."
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
  # Loading a legacy save must not inherit campaign flags from the running session.
  hero.campaign=MirefenRules.defaults()
  var legacy_skills=not data.has("skills")
  var saved_visit:Array=[]
  if data.get("town_visit") is Dictionary and data.town_visit.get("position") is Array:saved_visit=data.town_visit.position.duplicate()
  var saved_position: Array=[]
  if data.get("journey") is Dictionary and data.journey.get("position") is Array:
   saved_position=data.journey.position.duplicate()
  for key in hero:
   if data.has(key): hero[key]=merge_defaults(hero[key],normalize(data[key]))
  if saved_position.size()==3: hero.journey.position=[float(saved_position[0]),float(saved_position[1]),float(saved_position[2])]
  if saved_visit.size()==3:hero.town_visit.position=[float(saved_visit[0]),float(saved_visit[1]),float(saved_visit[2])]
  if legacy_skills: migrate_skills()
  var legacy_gear={"Helmet":"Ranger Hood","Gauntlets":"Leather Gloves","Pants":"Ranger Trousers","Boots":"Trail Boots","Accessory":"Moonleaf Charm"}
  for slot in legacy_gear:
   if hero.equipment[slot]=="Leather Gear": hero.equipment[slot]=legacy_gear[slot]
  # Older wardrobe saves retain all gear; new economy saves retain only owned items.
  if not data.has("inventory"):
   for item in equipment_data: grant_item(item)

  hero.monsters.goblin=maxi(int(hero.monsters.goblin),int(hero.mastery))
  MirefenRules.campaign(hero)
  migrate_progression(data)
  if GameRules.two_handed(equipment_data.get(hero.equipment.Weapon,{})): hero.equipment.Shield="None"
  if int(data.get("world_version",0))<8:
   # The authored outdoor route moved; keep progress but place old saves safely in town.
   if hero.journey.region!="dungeon":
    hero.journey.position=[0.0,0.0,0.0]
    saved_position=[0.0,0.0,0.0]
   hero.world_version=8
  if hero.journey.boss:
   hero.puzzles.solved=["dials","song"]
  hero.hp=mini(int(hero.hp),int(stats().max_hp))
  hero.mp=mini(int(hero.mp),int(stats().max_mp))
  var pos=hero.journey.position
  return_position=Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
func can_mythic(class_name_: String) -> bool:
 return hero.primary==class_name_ and skill_active(class_name_,"mythic")

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
 if hero.journey.region=="dungeon": return "res://scenes/dungeon.tscn"
 if hero.journey.region=="interior":return "res://scenes/town_interior.tscn"
 if hero.journey.region=="mirefen": return "res://scenes/mirefen.tscn"
 if hero.journey.region=="reliquary": return "res://scenes/reliquary.tscn"
 return "res://scenes/world.tscn"
func retreat_to_safety():
 var marsh=hero.journey.region in ["mirefen","reliquary"]
 hero.journey.region="mirefen" if marsh else "forest"
 remember_position(Vector3(0,0,-10) if marsh else Vector3.ZERO)
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
 encounter_id=-1
 enemy_id="goblin"
 hero.profile.economy=true
 hero.primary=""
 hero.secondary=[]
 for slot in hero.equipment: hero.equipment[slot]="None"
 hero.gold=120
 hero.potions=3
func create_hero(name_: String, primary: String, skin: int, hair: int, dye: int, secondary: Array=[], sex: String="Female") -> bool:
 if hero.profile.created or not classes.has(primary) or sex not in ["Male","Female"]: return false
 if secondary.is_empty(): secondary=classes[primary].recommended_secondary.duplicate()
 if secondary.size()!=2 or secondary[0]==secondary[1] or secondary.has(primary): return false
 for value in secondary:
  if not classes.has(value): return false
 hero.profile.merge({"created":true,"sex":sex,"name":name_.strip_edges().left(20) if not name_.strip_edges().is_empty() else "Traveler","skin":clampi(skin,0,2),"hair":clampi(hair,0,2),"dye":clampi(dye,0,2)},true)
 hero.primary=primary
 hero.secondary=secondary.duplicate()
 restore()
 return save_game()
func active_classes() -> Array:
 var result: Array=hero.secondary.duplicate()
 if classes.has(hero.primary): result.push_front(hero.primary)
 return result
func can_change_class() -> bool:
 return false # Class reassignment is reserved for a later chapter.
func compatible(item: String) -> bool:
 var entry: Dictionary=equipment_data.get(item,{})
 if entry.is_empty(): return false
 if entry.slot=="Weapon" or entry.slot=="Shield": return proficiencies().has(entry.get("weapon_type","sword"))
 if entry.get("style")=="plate": return hero.primary in ["Paladin","Warrior"]
 return true
func owns(item: String) -> bool:
 return not hero.profile.economy or hero.inventory.has(equipment_data.get(item,{}).get("id",""))
func grant_item(item: String):
 var id: String=equipment_data.get(item,{}).get("id","")
 if not id.is_empty() and not hero.inventory.has(id): hero.inventory.append(id)
func buy(item: String) -> bool:
 if not ShopBook.in_stock(item,shop_id): return false
 if not equipment_data.has(item) or owns(item) or not compatible(item): return false
 var price=int(equipment_data[item].price)
 if not can_buy(item): return false
 hero.gold-=price
 grant_item(item)
 save_game()
 return true
func buy_potion() -> bool:
 if not can_buy_potion(): return false
 hero.gold-=8
 hero.potions+=1
 save_game()
 return true
func use_potion() -> bool:
 if hero.potions<=0 or hero.hp<=0 or hero.hp>=stats().max_hp: return false
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
 hero.companion.records[id]={"level":maxi(1,int(hero.level)-1),"xp":0,"points":maxi(1,int(hero.level)-1)*2,"skills":[],"hp":int(companions[id].hp)}
 hero.demo.first_choice=true
 hero.companion.records[id].hp=companion_max_hp()
 hero.hp=mini(int(hero.hp),int(stats().max_hp))
 hero.mp=mini(int(hero.mp),int(stats().max_mp))
 save_game()
 return true
func activate_companion(id: String) -> bool:
 if not hero.companion.owned.has(id): return false
 hero.companion.current=id
 hero.companion.active=true
 hero.hp=mini(int(hero.hp),int(stats().max_hp))
 hero.mp=mini(int(hero.mp),int(stats().max_mp))
 save_game()
 return true
func train_companion(id:String,companion_id:String="")->bool:
 if companion_id.is_empty():companion_id=hero.companion.current
 if not hero.companion.records.has(companion_id):return false
 var record:Dictionary=hero.companion.records[companion_id]
 var node:Dictionary={}
 for candidate in companions[companion_id].nodes:
  if candidate.id==id:node=candidate
 if node.is_empty() or record.skills.has(id) or record.points<int(node.cost):return false
 for prerequisite in node.requires:
  if not record.skills.has(prerequisite):return false
 record.points-=int(node.cost)
 record.skills.append(id)
 record.hp+=int(node.bonus.get("max_hp",0))
 save_game()
 return true
func train_companion_for(companion_id:String,id:String)->bool:
 if not hero.companion.owned.has(companion_id):return false
 return train_companion(id,companion_id)
func learn_weapon(type_: String, id: String) -> bool:
 for node in weapon_trees.get(type_,[]):
  if node.id!=id: continue
  if hero.points<int(node.cost) or hero.weapon_skills[type_].has(id): return false
  for prerequisite in node.prerequisites:
   if not hero.weapon_skills[type_].has(prerequisite): return false
  hero.points-=int(node.cost)
  hero.weapon_skills[type_].append(id)
  save_game()
  return true
 return false
func companion_record() -> Dictionary:
 return hero.companion.records.get(hero.companion.current,{})
func companion_max_hp() -> int:
 var record=companion_record()
 return int(companions.get(hero.companion.current,{"hp":55}).hp)+int(record.get("level",1))*3+CompanionRules.pet_bonus(hero,"max_hp")
func travel_multiplier() -> float:
 return 1.25 if hero.companion.active and not hero.companion.owned.is_empty() else 1.0
func restore_companion():
 hero.companion.intro_hp=55
 var record=companion_record()
 if not record.is_empty(): record.hp=companion_max_hp()

func starter_ready() -> bool:
 # Owning a weapon is the only opening combat requirement; armor and quests are optional.
 for item in equipment_data:
  if equipment_data[item].slot=="Weapon" and owns(item): return true
 return false
func weapon_reserve() -> int:
 if starter_ready(): return 0
 var cheapest=100000
 for item in ShopBook.stock():
  if equipment_data[item].slot=="Weapon" and compatible(item):
   cheapest=mini(cheapest,int(equipment_data[item].price))
 return cheapest
func can_buy_potion() -> bool:
 return int(hero.gold)>=8+weapon_reserve()
func can_buy(item: String) -> bool:
 if not ShopBook.in_stock(item,shop_id): return false
 if not equipment_data.has(item) or owns(item) or not compatible(item): return false
 var reserve=0 if equipment_data[item].slot=="Weapon" else weapon_reserve()
 return int(hero.gold)>=int(equipment_data[item].price)+reserve
func award_gold(base: int, source: String="Quest") -> Dictionary:
 var roll=GameRules.gold_roll(base,int(stats().dexterity),int(hero.seed))
 hero.seed=roll.seed
 hero.gold+=roll.total
 last_reward={"source":source,"base":roll.base,"bonus":roll.bonus,"total":roll.total}
 notice="%s: +%s gold%s" % [source,roll.total," (Dexterity bonus +%s)" % roll.bonus if roll.bonus>0 else ""]
 return last_reward
func migrate_progression(data: Dictionary):
 if int(data.get("progression_version",0))>=GameRules.PROGRESSION_VERSION: return
 if not hero.profile.economy:
  for item in equipment_data: grant_item(item)
 hero.profile.economy=true
 if classes.has(hero.primary): hero.profile.created=true
 hero.progression_archive={"skills":hero.skills.duplicate(true),"weapon_skills":hero.weapon_skills.duplicate(true),"old_points":hero.points}
 for class_ in classes:
  hero.skills[class_]=[]
  hero.investments[class_]=0
 for family in weapon_trees: hero.weapon_skills[family]=[]
 hero.points=maxi(1,int(hero.level))*GameRules.POINTS_PER_LEVEL
 hero.progression_version=GameRules.PROGRESSION_VERSION
 save_notice="Progression updated: skills reset to %s unspent points for the point-based trees. Previous investments are archived; level, quests, equipment and companions are kept." % hero.points

func item_count(id: String) -> int:
 return int(hero.potions) if id=="potion" else int(hero.items.get(id,0))
func can_use_item(id: String) -> bool:
 if item_count(id)<=0 or hero.hp<=0: return false
 if id=="potion": return hero.hp<stats().max_hp
 if id=="ether": return hero.mp<stats().max_mp
 if id=="treat":
  return hero.companion.intro_hp<55 if hero.companion.current=="intro_wolf" else companion_record().get("hp",0)<companion_max_hp()
 return false
func use_item(id: String) -> bool:
 if not can_use_item(id): return false
 if id=="potion": return use_potion()
 hero.items[id]-=1
 if id=="ether": hero.mp=mini(int(stats().max_mp),int(hero.mp)+20)
 if id=="treat":
  if hero.companion.current=="intro_wolf": hero.companion.intro_hp=mini(55,int(hero.companion.intro_hp)+35)
  else:
   var record=companion_record()
   record.hp=mini(companion_max_hp(),int(record.hp)+35)
 notice="Used "+InventoryBook.data[id].name+"."
 save_game()
 return true
func buy_supply(id: String) -> bool:
 if not InventoryBook.data.has(id): return false
 if hero.gold<int(InventoryBook.data[id].price)+weapon_reserve(): return false
 hero.gold-=int(InventoryBook.data[id].price)
 if id=="potion": hero.potions+=1
 else: hero.items[id]=item_count(id)+1
 return save_game()
func award_xp(amount: int):
 hero.xp+=amount
 while hero.xp>=int(hero.level)*70:
  hero.xp-=int(hero.level)*70
  hero.level+=1
  hero.points+=GameRules.POINTS_PER_LEVEL
  hero.hp=mini(int(stats().max_hp),int(hero.hp)+20)
  hero.mp=mini(int(stats().max_mp),int(hero.mp)+8)
func accept_side_quest(id: String):
 if not QuestBook.data.has(id) or hero.side_quests.started.has(id): return
 hero.side_quests.started.append(id)
 save_game()
func claim_side_quest(id: String) -> bool:
 if not QuestBook.complete(hero,id) or hero.side_quests.claimed.has(id): return false
 hero.side_quests.claimed.append(id)
 var quest:Dictionary=QuestBook.data[id]
 award_xp(int(quest.xp))
 award_gold(int(quest.gold),quest.name)
 save_game()
 return true
func puzzle_dial(index: int):
 if hero.puzzles.solved.has("dials"): return
 hero.puzzles.dials[index]=(int(hero.puzzles.dials[index])+1)%4
 if hero.puzzles.dials==[1,3,2]: hero.puzzles.solved.append("dials")
 save_game()
func puzzle_note(index: int):
 if hero.puzzles.solved.has("song"): return
 var target=[2,0,1]
 var progress: Array=hero.puzzles.sequence
 if index==target[progress.size()]: progress.append(index)
 else: progress.clear()
 if progress.size()==3: hero.puzzles.solved.append("song")
 save_game()

func species_wins(species: String) -> int:
 return maxi(int(hero.mastery),int(hero.monsters.get(species,0))) if species=="goblin" else int(hero.monsters.get(species,0))
func record_encounter_clear():
 cleared_until[encounter_id]=Time.get_ticks_msec()+45000
 if encounter_id>=300 and encounter_id<=302 and not hero.demo.field_guards.has(encounter_id-300): hero.demo.field_guards.append(encounter_id-300)
 if encounter_id in [100,101] and not hero.journey.guards.has(encounter_id-100): hero.journey.guards.append(encounter_id-100)
