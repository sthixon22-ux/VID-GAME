class_name HeroSkinBook
extends RefCounted
# Cosmetic identity only. This catalog grants no items, armor stats or proficiencies.
static var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/hero_skins.json"))
static func profile(primary:String,sex:String)->Dictionary:
 var key=primary if data.has(primary) else "Paladin"
 var body_sex=sex if sex in ["Male","Female"] else "Female"
 var result:Dictionary=data[key][body_sex].duplicate(true)
 for field in ["outfit","hood","pauldrons","motif"]:result[field]=data[key][field]
 result.primary=key
 result.sex=body_sex
 return result
static func model_path(sex:String,outfit:String)->String:
 return "res://assets/vendor/quaternius/characters/%s_%s.glb" % [sex.to_lower(),"peasant" if outfit=="traveler" else "ranger"]
static func texture_path(id:String,outfit:String)->String:
 return "res://assets/textures/class_skins/%s_%s.webp" % [id,outfit]
