class_name CompanionRules
extends RefCounted
static var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/companions.json"))
static func bonus(hero:Dictionary,key:String)->int:
 if not hero.companion.active or hero.companion.current=="intro_wolf":return 0
 var id:String=hero.companion.current
 var value=int(data[id].hero_bonus.get(key,0))
 for node in data[id].nodes:
  if hero.companion.records.get(id,{}).get("skills",[]).has(node.id):value+=int(node.hero_bonus.get(key,0))
 return value
static func pet_bonus(hero:Dictionary,key:String)->int:
 var id:String=hero.companion.current
 var value=0
 for node in data.get(id,{}).get("nodes",[]):
  if hero.companion.records.get(id,{}).get("skills",[]).has(node.id):value+=int(node.bonus.get(key,0))
 return value
static func learned_abilities(hero:Dictionary)->Array:
 var id:String=hero.companion.current
 var result:Array=[]
 for node in data.get(id,{}).get("nodes",[]):
  if hero.companion.records.get(id,{}).get("skills",[]).has(node.id): result.append_array(node.grants)
 return result

static func ability_by_name(label:String)->Dictionary:
 var name_=label.split(" · ")[0]
 for companion in data.values():
  for entry in companion.abilities.values():
   if entry.name==name_:return entry
 return {}
static func threshold(level_:int)->int:
 return 240+level_*120
static func field_ready(hero:Dictionary)->bool:
 var id=str(hero.companion.get("current","intro_wolf"))
 var record:Dictionary=hero.companion.get("records",{}).get(id,{})
 return hero.companion.active and int(hero.hp)>0 and (int(record.get("hp",0))>0 or id=="spirit_fox") and record.get("skills",[]).has("capstone") and not record.get("field_used",false)
static func field(hero:Dictionary,destination:String="")->bool:
 if not field_ready(hero):return false
 var id=str(hero.companion.current)
 match id:
  "warhorse":
   if not TravelRules.town(hero,destination):return false
  "griffin":
   if not TravelRules.flight(hero,destination):return false
  "dragon":
   if not TravelRules.escape(hero):return false
  "golem":
   if hero.hp>=State.stats().max_hp and hero.mp>=State.stats().max_mp:return false
   hero.hp=State.stats().max_hp;hero.mp=State.stats().max_mp
  "spirit_fox":
   if hero.hp>=State.stats().max_hp and hero.mp>=State.stats().max_mp and int(hero.companion.records[id].hp)>=State.companion_max_hp():return false
   hero.hp=mini(int(State.stats().max_hp),int(hero.hp)+int(State.stats().max_hp)/2)
   hero.mp=mini(int(State.stats().max_mp),int(hero.mp)+int(State.stats().max_mp)/2)
   hero.companion.records[id].hp=State.companion_max_hp()
  "dire_wolf":
   State.field_reveal_area=str(hero.journey.region)
   hero.campaign.field_reveal_area=State.field_reveal_area
  _:return false
 hero.companion.records[id].field_used=true
 State.notice=data[id].field_ability.name+" used. Rest at an inn with this companion to recharge."
 return State.save_game()
