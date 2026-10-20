class_name AbilityBook
extends RefCounted
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
static func id_for(value: String) -> String:
 if data.has(value): return value
 for id in data:
  if data[id].name==value: return id
 return ""
static func entry(value: String) -> Dictionary:
 return data.get(id_for(value),{})
static func name_for(value: String) -> String:
 return entry(value).get("name",value)
static func spells(hero: Dictionary) -> Array:
 var classes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
 var result: Array=[]
 var active: Array=hero.secondary.duplicate()
 active.append(hero.primary)
 for class_ in active:
  if not classes.has(class_): continue
  for id in classes[class_].spellbook:
   if not result.has(id): result.append(id)
 if hero.get("skills",{}).get(hero.primary,[]).has("mythic") and classes.has(hero.primary): result.append(id_for(classes[hero.primary].mythic))
 return result
