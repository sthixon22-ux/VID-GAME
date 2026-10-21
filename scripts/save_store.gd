class_name SaveStore
extends RefCounted
const VERSION=4
static func inspect(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var parser=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
 var data=parser.data
 if not data is Dictionary: return {}
 if int(data.get("save_schema_version",0))>VERSION: return {"future":true}
 for key in ["level","hp","mp","xp","gold"]:
  if not data.get(key) is float and not data.get(key) is int: return {}
 for key in ["equipment","companion","investments"]:
  if not data.get(key) is Dictionary: return {}
 if not valid_nested(data): return {}
 return {"hero":data}
static func load_hero(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"hero":{},"notice":"","blocked":false}
 var current=inspect(path)
 if current.has("future"): return {"hero":{},"notice":"This save needs a newer game version. It has been preserved.","blocked":true}
 if current.has("hero"):
  var previous_version=int(current.hero.get("save_schema_version",0))
  var legacy_backup=path+".v%s.backup" % previous_version
  if previous_version<VERSION and not FileAccess.file_exists(legacy_backup):
   DirAccess.copy_absolute(path,legacy_backup)
  return {"hero":current.hero,"notice":"","blocked":false}
 var previous=inspect(path+".previous")
 if previous.has("hero"): return {"hero":previous.hero,"notice":"Recovered the previous save after the latest file could not be read.","blocked":false}
 return {"hero":{},"notice":"Save could not be read. It has been preserved; start a new adventure to reset.","blocked":true}
static func write_hero(hero: Dictionary, path: String) -> bool:
 if inspect(path).has("future"): return false
 var data=hero.duplicate(true)
 data.save_schema_version=VERSION
 var temporary=path+".tmp"
 var file=FileAccess.open(temporary,FileAccess.WRITE)
 if not file: return false
 file.store_string(JSON.stringify(data))
 file.flush()
 file.close()
 if not inspect(temporary).has("hero"): return false
 if inspect(path).has("hero"):
  if DirAccess.copy_absolute(path,path+".previous")!=OK: return false
 return DirAccess.rename_absolute(temporary,path)==OK

static func valid_nested(data: Dictionary) -> bool:
 for key in ["profile","journey","exploration","skills","class_mastery","weapon_mastery","weapon_skills","monsters","demo","items","side_quests","puzzles"]:
  if data.has(key) and not data[key] is Dictionary: return false
 for key in ["secondary","inventory"]:
  if data.has(key) and not string_array(data[key]): return false
 for value in data.equipment.values():
  if not value is String: return false
 if data.has("profile"):
  var profile: Dictionary=data.profile
  if profile.has("name") and not profile.name is String: return false
  if profile.has("sex") and (not profile.sex is String or profile.sex not in ["Male","Female"]): return false
  for key in ["skin","hair","dye"]:
   if profile.has(key) and (not numeric(profile[key]) or float(profile[key])<0 or float(profile[key])>2): return false
 for key in ["primary"]:
  if data.has(key) and not data[key] is String: return false
 for key in ["skills","weapon_skills"]:
  for value in data.get(key,{}).values():
   if not string_array(value): return false
 for key in ["investments","class_mastery","weapon_mastery","monsters"]:
  for value in data.get(key,{}).values():
   if not numeric(value): return false
 for key in ["journey","exploration","demo"]:
  for field in ["guards","seals","herbs","field_guards","position"]:
   if not data.get(key,{}).has(field): continue
   var values=data[key][field]
   if not values is Array: return false
   for value in values:
    if not numeric(value): return false
   if field=="position" and values.size()!=3: return false
 for count in data.get("items",{}).values():
  if not numeric(count) or count<0: return false
 var quests:Dictionary=data.get("side_quests",{})
 for field in ["started","claimed"]:
  if quests.has(field) and not string_array(quests[field]): return false
 if quests.has("crystals"):
  if not quests.crystals is Array: return false
  for id in quests.crystals:
   if not numeric(id) or id<0 or id>2: return false
 for field in ["goblin","mossling","bristleback"]:
  if quests.has(field) and (not numeric(quests[field]) or quests[field]<0): return false
 var puzzles:Dictionary=data.get("puzzles",{})
 if puzzles.has("solved") and not string_array(puzzles.solved): return false
 for field in ["dials","sequence"]:
  if not puzzles.has(field): continue
  if not puzzles[field] is Array: return false
  if field=="dials" and puzzles[field].size()!=3: return false
  if field=="sequence" and puzzles[field].size()>3: return false
  for value in puzzles[field]:
   if not numeric(value) or value<0 or value>(3 if field=="dials" else 2): return false
 var companion: Dictionary=data.companion
 if companion.has("owned") and not string_array(companion.owned): return false
 if companion.has("records"):
  if not companion.records is Dictionary: return false
  for record in companion.records.values():
   if not record is Dictionary: return false
   for key in ["level","xp","points","hp"]:
    if not numeric(record.get(key)): return false
   if not string_array(record.get("skills")): return false
 return true
static func numeric(value) -> bool:
 return (value is int or value is float) and is_finite(float(value))
static func string_array(value) -> bool:
 if not value is Array: return false
 for item in value:
  if not item is String: return false
 return true
