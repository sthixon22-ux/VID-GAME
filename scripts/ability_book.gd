class_name AbilityBook
extends RefCounted
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
static var class_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
static var weapon_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_trees.json"))
static var gear_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
static func id_for(value: String) -> String:
 if data.has(value): return value
 for id in data:
  if data[id].name==value: return id
 return ""
static func entry(value: String) -> Dictionary:
 return data.get(id_for(value),{})
static func name_for(value: String) -> String:
 return entry(value).get("name",value)
static func available(hero: Dictionary) -> Array:
 var result: Array=[]
 var active: Array=hero.secondary.duplicate()
 active.push_front(hero.primary)
 for class_ in active:
  if not class_data.has(class_): continue
  for id in class_data[class_].spellbook:
   if not result.has(id): result.append(id)
  for node in class_data[class_].nodes:
   if not hero.get("skills",{}).get(class_,[]).has(node.id): continue
   for id in node.get("grants",[]):
    if data[id].kind=="mythic" and hero.primary!=class_: continue
    if not result.has(id): result.append(id)
 return result
static func spells(hero: Dictionary) -> Array:
 return available(hero).filter(func(id): return data[id].kind in ["spell","mythic"])
static func techniques(hero: Dictionary) -> Array:
 var result: Array=["sword_slash","shield_bash"]
 var family=weapon_type(hero)
 if data.has(family+"_technique"): result.append(family+"_technique")
 for type_ in [family,"shield" if hero.equipment.Shield!="None" else ""]:
  for node in weapon_data.get(type_,[]):
   if hero.weapon_skills.get(type_,[]).has(node.id):
    for id in node.get("grants",[]): result.append(id)
 for id in available(hero):
  if data[id].kind=="technique": result.append(id)
 return result
static func weapon_type(hero: Dictionary) -> String:
 return gear_data.get(hero.equipment.Weapon,{}).get("weapon_type","unarmed")
static func proficient(hero: Dictionary, family: String) -> bool:
 if hero.get("weapon_skills",{}).get(family,[]).has("master"):return true
 var active: Array=hero.secondary.duplicate()
 active.append(hero.primary)
 for class_ in active:
  if class_data.get(class_,{}).get("proficiencies",[]).has(family): return true
 return false
