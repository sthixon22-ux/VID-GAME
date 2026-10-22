class_name GameRules
extends RefCounted
const STAT_KEYS=["max_hp","max_mp","attack","defense","agility","dexterity"]
const STAT_LABELS={"max_hp":"HP","max_mp":"MP","attack":"ATK","defense":"DEF","agility":"AGI","dexterity":"DEX"}
const TWO_HANDED=["greatsword","axe","spear","bow","staff","claws","scythe","hammer"]
const POINTS_PER_LEVEL=2
const PROGRESSION_VERSION=3
static func critical_chance(points:int)->float:
 return clampf(points*.01,0.0,.60)
static func dodge_chance(dexterity: int) -> float:
 return clampf(float(dexterity)*0.004,0.0,0.35)
static func gold_chance(dexterity: int) -> float:
 return clampf(float(dexterity)*0.006,0.0,0.60)
static func next_seed(seed_: int) -> int:
 var positive=posmod(seed_,2147483646)+1
 return (positive*48271)%2147483647
static func gold_roll(base: int, dexterity: int, seed_: int) -> Dictionary:
 var seed=next_seed(seed_)
 var chance=gold_chance(dexterity)
 var bonus=maxi(1,int(ceil(float(base)*0.25))) if float(seed)/2147483647.0<chance and base>0 else 0
 return {"base":base,"bonus":bonus,"total":base+bonus,"seed":seed}
static func base_stats(class_data: Dictionary, level_: int) -> Dictionary:
 var result={}
 for key in STAT_KEYS: result[key]=int(class_data.base_stats[key])+floori(float(class_data.growth[key])*maxi(0,level_-1))
 return result
static func combined_stats(classes: Dictionary, primary: String, secondary: Array, level_: int) -> Dictionary:
 var result={}
 var roles:Array=[primary]+secondary
 var weights=[0.6,0.2,0.2]
 for key in STAT_KEYS:
  var total=0.0
  for index in range(mini(3,roles.size())):
   var data:Dictionary=classes.get(roles[index],classes.Paladin)
   total+=float(data.base_stats[key]+float(data.growth[key])*maxi(0,level_-1))*weights[index]
  result[key]=maxi(1,roundi(total))
 return result
static func two_handed(item: Dictionary) -> bool:
 return item.get("slot","")=="Weapon" and TWO_HANDED.has(item.get("weapon_type",""))
static func summary(stats: Dictionary, signed=false) -> String:
 var parts: Array=[]
 for key in STAT_KEYS:
  var value=int(stats.get(key,0))
  if signed and value==0: continue
  parts.append(("%s %+d" if signed else "%s %d") % [STAT_LABELS[key],value])
 return " · ".join(parts)
