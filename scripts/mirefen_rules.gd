class_name MirefenRules
extends RefCounted
# Additive campaign revision; schema-four hero files remain readable.
static func defaults() -> Dictionary:
 return {"version":1,"audience":false,"investigating":false,"readings":[],"sluice_key":false,"reliquary_west":false,"reliquary_east":false,"reliquary_cleared":false,"reported":false,"desert_clue":false,"cache":false,"reeds":[]}
static func campaign(hero:Dictionary) -> Dictionary:
 if not hero.get("campaign") is Dictionary: hero.campaign={}
 for key in defaults():
  if not hero.campaign.has(key): hero.campaign[key]=defaults()[key]
 return hero.campaign
static func goal(hero:Dictionary)->String:
 var c=campaign(hero)
 if c.reported:return "Chapter 2 complete · Emberglass tablet points toward Sahir"
 if c.reliquary_cleared:return "Return to Warden Iona in Reedcross"
 if c.sluice_key:return "Enter the Reliquary · drain west, divert east, quiet the heart"
 if c.readings.size()==3:return "Bring the three water-readings to Warden Iona"
 if c.investigating:return "Read the three survey stones along the causeway (%s/3)" % c.readings.size()
 if c.audience:return "Speak with Warden Iona at the northern village square"
 return "Meet King Aldren and his messenger in Reedcross"
static func collect(hero:Dictionary,kind:String,index:int)->bool:
 var c=campaign(hero)
 if kind not in ["readings","reeds"] or c[kind].has(index):return false
 if kind=="readings" and not c.investigating:return false
 c[kind].append(index)
 return true
static func valve(hero:Dictionary,west:bool)->String:
 var c=campaign(hero)
 if not c.sluice_key:return "Iona’s sluice key is required."
 if not west and not c.reliquary_west:return "Drain the western basin first."
 c["reliquary_west" if west else "reliquary_east"]=true
 return "West basin drained. Cross the dry bed to the eastern valve." if west else "East flow diverted. The inner passage is open."
