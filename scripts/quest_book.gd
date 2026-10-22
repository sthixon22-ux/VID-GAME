class_name QuestBook
extends RefCounted
static var data: Dictionary={
 "roadwatch":{"name":"A Safer Road","giver":"Captain Rowan","description":"Defeat 4 Forest Goblins along the woodland road.","goal":4,"counter":"goblin","gold":55,"xp":65},
 "skyglass":{"name":"Glass for the Lanterns","giver":"Artisan Nessa","description":"Gather 3 skyglass clusters in Sunmeadow Plains.","goal":3,"counter":"crystals","gold":60,"xp":70},
 "briar":{"name":"Roots in the Cellar","giver":"Keeper Oren","description":"Defeat both Briar Mosslings beneath the shrine.","goal":2,"counter":"mossling","gold":45,"xp":55}}
static func add_marsh_quests():
 data["silverreed"]={"name":"Medicine on the High Water","giver":"Healer Sella","description":"Gather four silverreed bundles along the causeway, then return to Sella.","goal":4,"counter":"silverreed","gold":100,"xp":140}
 data["causeway"]={"name":"The Ferryman’s Road","giver":"Ferryman Jory","description":"Defeat three Reed Stalkers and return to Jory.","goal":3,"counter":"reed_stalker","gold":120,"xp":160}
static func progress(hero: Dictionary,id: String) -> int:
 var value=hero.side_quests.get(data[id].counter,0)
 return value.size() if value is Array else int(value)
static func complete(hero: Dictionary,id: String) -> bool:
 return data.has(id) and hero.side_quests.started.has(id) and progress(hero,id)>=int(data[id].goal)
