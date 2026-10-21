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
