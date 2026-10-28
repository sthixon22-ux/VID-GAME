class_name ExpeditionRules
extends RefCounted
static var regions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/frontier_regions.json"))
static func defaults()->Dictionary:
 return {"chests":[],"inscriptions":[],"briefed":[],"cleared":[],"side_claimed":[],"mirrors":[0,0,0],"lifts":[],"rooms":[],"boss_intro":[]}
static func progress(hero:Dictionary)->Dictionary:
 var c=MirefenRules.campaign(hero)
 if not c.get("expedition") is Dictionary:c.expedition={}
 for key in defaults():
  if not c.expedition.has(key):c.expedition[key]=defaults()[key]
 return c.expedition
static func region_for(area:String)->String:
 return {"emberglass":"sahir","ironroot":"kharholt"}.get(area,area)
static func scene(area:String)->String:return "res://scenes/"+area+".tscn"
static func accessible(hero:Dictionary,area:String)->bool:
 var p=progress(hero)
 match region_for(area):
  "sahir":return hero.campaign.get("reported",false)
  "kharholt":return p.cleared.has("sahir")
 return false
static func count(hero:Dictionary,region:String)->int:
 var p=progress(hero)
 var n=0
 for i in 3:
  if p.inscriptions.has(region+str(i)):n+=1
 return n
static func goal(hero:Dictionary,region:String)->String:
 var p=progress(hero)
 var d:Dictionary=regions[region]
 if p.cleared.has(region):return "Glasswing quieted · the highland pass is open" if region=="sahir" else "Ironroot restored · Chapters 1–4 complete · explore or return to town"
 if p.briefed.has(region):return d.title+" · Solve its chamber mechanisms and confront its guardian"
 return d.objective+" (%s/3)" % count(hero,region)
static func boss_win(species:String):
 var region={"glass_sentinel":"sahir","ironroot_colossus":"kharholt"}.get(species,"")
 if region.is_empty():return
 var p=progress(State.hero)
 if not p.cleared.has(region):
  p.cleared.append(region)
  State.grant_item("Prismheart Pendant" if region=="sahir" else "Ironroot Signet")
  State.notice="Guardian restored. Return to "+regions[region].quest_npc+"."
static func can_open(hero:Dictionary,region:String)->bool:
 var p=progress(hero)
 return p.mirrors==[1,3,2] if region=="sahir" else p.lifts.has("west") and p.lifts.has("east")
