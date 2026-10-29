class_name TravelRules
extends RefCounted
const TOWNS={"forest":"Willowbrook","mirefen":"Reedcross","sahir":"Qasira","kharholt":"Kharholt Forge"}
const ENTRANCES={"dungeon":["forest",Vector3(64,0,-57)],"reliquary":["mirefen",Vector3(3,0,-58)],"emberglass":["sahir",Vector3(0,0,-46)],"ironroot":["kharholt",Vector3(0,0,-46)]}
static func discovered(hero:Dictionary)->Array:
 var result:Array=["forest"]
 if hero.journey.finished:result.append("mirefen")
 if hero.get("campaign",{}).get("reported",false):result.append("sahir")
 if ExpeditionRules.progress(hero).cleared.has("sahir"):result.append("kharholt")
 return result
static func escape(hero:Dictionary)->bool:
 var area=str(hero.journey.region)
 if not ENTRANCES.has(area):return false
 var destination=ENTRANCES[area]
 hero.journey.region=destination[0]
 State.remember_position(destination[1])
 return true
static func town(hero:Dictionary,destination:String)->bool:
 if not discovered(hero).has(destination):return false
 hero.journey.region=destination
 State.remember_position(Vector3(0,0,5) if destination=="forest" else Vector3(0,0,10) if destination in ["sahir","kharholt"] else Vector3(0,0,3))
 return true
static func breadcrumb(area:String,action:String):
 var path="user://journey-events.log"
 if FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path).size()>262144:
  if FileAccess.file_exists(path+".previous"):DirAccess.remove_absolute(path+".previous")
  DirAccess.rename_absolute(path,path+".previous")
 var file=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
 if file:
  file.seek_end();file.store_line(JSON.stringify({"time":Time.get_datetime_string_from_system(),"area":area,"action":action}));file.close()
static func waypoints(hero:Dictionary)->Array:
 return {
  "forest":[["Willowbrook",Vector3.ZERO],["Woodland crossing",Vector3(0,0,-20)],["Sunmeadow trail",Vector3(40,0,-54)],["Shrine approach",Vector3(64,0,-57)]],
  "mirefen":[["Reedcross square",Vector3(0,0,3)],["Northern causeway",Vector3(0,0,-55)]],
  "sahir":[["Qasira",Vector3(0,0,10)],["Oasis approach",Vector3(-27,0,-12)],["Observatory",Vector3(-22,0,-35)],["Kharholt pass",Vector3(36,0,-40)]],
  "kharholt":[["Forge town",Vector3(0,0,10)],["Splitpine overlook",Vector3(-27,0,-8)],["Stormwatch ruins",Vector3(26,0,-14)],["Bastion approach",Vector3(0,0,-46)]]
 }.get(str(hero.journey.region),[])
static func flight(hero:Dictionary,index:String)->bool:
 if not index.is_valid_int():return false
 var points=waypoints(hero);var selected=int(index)
 if selected<0 or selected>=points.size():return false
 State.remember_position(points[selected][1])
 return true
