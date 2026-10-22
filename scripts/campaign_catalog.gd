class_name CampaignCatalog
extends RefCounted

# Planning registry only. Gameplay must opt in to these records as regions become playable.
const PATH := "res://data/campaign.json"
const CLASSES := ["Warrior", "Barbarian", "Paladin", "Wizard", "Sorcerer", "Healer", "Ranger", "Rogue", "Assassin", "Monk", "Druid", "Necromancer"]

static func load_data() -> Dictionary:
 var file := FileAccess.open(PATH, FileAccess.READ)
 if file == null:
  return {}
 var parsed = JSON.parse_string(file.get_as_text())
 return parsed if parsed is Dictionary else {}

static func validate(data: Dictionary) -> Array[String]:
 var errors: Array[String] = []
 if int(data.get("schema_version", -1)) != 1:
  errors.append("Unsupported catalog schema version")
 for key in ["regions", "towns", "dungeons"]:
  if not data.get(key) is Array:
   errors.append("Missing array: " + key)
 if not errors.is_empty():
  return errors
 var regions: Dictionary = {}
 var towns: Dictionary = {}
 var dungeons: Dictionary = {}
 for region in data.regions:
  if not region is Dictionary or String(region.get("id", "")).is_empty():
   errors.append("Region missing id")
   continue
  if regions.has(region.id):
   errors.append("Duplicate region: " + region.id)
  regions[region.id] = region
 for town in data.towns:
  if not town is Dictionary or String(town.get("id", "")).is_empty():
   errors.append("Town missing id")
   continue
  if towns.has(town.id):
   errors.append("Duplicate town: " + town.id)
  towns[town.id] = town
  if not regions.has(town.get("region_id", "")):
   errors.append("Town has unknown region: " + town.id)
  var specialties = town.get("shop_specialties", {})
  if not specialties is Dictionary:
   errors.append("Missing specialties for " + town.id)
   continue
  for name in specialties.get("classes", []):
   if not CLASSES.has(name):
    errors.append("Unknown shop class " + str(name) + " in " + town.id)
 for dungeon in data.dungeons:
  if not dungeon is Dictionary or String(dungeon.get("id", "")).is_empty():
   errors.append("Dungeon missing id")
   continue
  if dungeons.has(dungeon.id):
   errors.append("Duplicate dungeon: " + dungeon.id)
  dungeons[dungeon.id] = dungeon
  if not regions.has(dungeon.get("region_id", "")):
   errors.append("Unknown dungeon region: " + dungeon.id)
  if int(dungeon.get("level_min", -1)) < 1 or int(dungeon.get("level_max", 0)) < int(dungeon.get("level_min", -1)):
   errors.append("Invalid level band for " + dungeon.id)
 if dungeons.size() != 12:
  errors.append("Campaign must define twelve dungeons")
 for n in range(1, 13):
  var id = "dungeon_%s" % n
  if not dungeons.has(id):
   errors.append("Missing dungeon: " + id)
   continue
  var dungeon: Dictionary = dungeons[id]
  if int(dungeon.get("number", -1)) != n:
   errors.append("Dungeon order incorrect: " + id)
  for prerequisite in dungeon.get("requires", []):
   if not dungeons.has(prerequisite):
    errors.append("Missing dungeon prerequisite: " + str(prerequisite))
  if n == 12:
   var branches = dungeon.get("branch_options", {})
   if not branches is Dictionary or not branches.has("human_crown") or not branches.has("demon_throne"):
    errors.append("Final dungeon must have both allegiance branches")
 for region in regions.values():
  if not towns.has(region.get("starting_town", "")):
   errors.append("Unknown region starting town: " + region.id)
  if not dungeons.has(region.get("main_dungeon", "")):
   errors.append("Unknown region dungeon: " + region.id)
 return errors

static func dungeon(id: String) -> Dictionary:
 for entry in load_data().get("dungeons", []):
  if entry.get("id", "") == id:
   return entry
 return {}

static func region(id: String) -> Dictionary:
 for entry in load_data().get("regions", []):
  if entry.get("id", "") == id:
   return entry
 return {}
