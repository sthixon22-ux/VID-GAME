class_name SaveStore
extends RefCounted
const VERSION=1
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
 return {"hero":data}
static func load_hero(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"hero":{},"notice":"","blocked":false}
 var current=inspect(path)
 if current.has("future"): return {"hero":{},"notice":"This save needs a newer game version. It has been preserved.","blocked":true}
 if current.has("hero"):
  if not current.hero.has("save_schema_version") and not FileAccess.file_exists(path+".v0.backup"):
   DirAccess.copy_absolute(path,path+".v0.backup")
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
