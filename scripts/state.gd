extends Node
const SAVE = "user://hero.json"
var classes: Dictionary = {}
var hero: Dictionary
var notice = ""
var return_position=Vector3.ZERO
var enemy_id="goblin"
var encounter_id=-1
var cleared_until: Dictionary={}

func _ready():
 classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
 reset()
 load_game()
func reset():
 return_position=Vector3.ZERO
 hero = {"journey":{"started":false,"guards":[],"seals":[],"boss":false,"finished":false,"chest":false,"entered":false,"region":"forest","position":[0.0,0.0,0.0]},"exploration":{"herbs":[],"quest_done":false,"shrine":false},"level":1,"xp":0,"hp":110,"mp":35,"gold":0,"points":3,"primary":"Paladin","secondary":["Ranger","Druid"],"investments":{"Paladin":0,"Ranger":0,"Druid":0},"equipment":{"Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"None","Chest":"Steel Cuirass","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},"companion":{"selected":0,"behavior":"Attack","active":true,"roster":["Wolf",null,null,null,null,null],"postgame":null},"mastery":0,"potions":5,"seed":137}
func stats() -> Dictionary:
 var l = int(hero.level)
 var e: Dictionary = hero.equipment
 return {"max_hp":100+l*10,"max_mp":30+l*5+int(hero.investments.Druid)*2,"attack":12+l*3+int(hero.investments.Paladin)+int(hero.investments.Ranger)+(8 if e.Weapon=="Iron Sword" else 14),"defense":4+l+(5 if e.Shield!="None" else 0)+(6 if e.Chest=="Steel Cuirass" else 2)+armor_bonus(),"speed":12+l}
func armor_bonus() -> int:
 var total=0
 for slot in ["Helmet","Gauntlets","Pants","Boots","Accessory"]:
  if hero.equipment[slot]!="None": total+=2
 return total
func reward(normal: bool, species: String="goblin"):
 var enemies: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 var enemy: Dictionary=enemies[species]
 hero.xp+=int(enemy.xp)
 hero.gold+=int(enemy.gold)
 if normal and species=="goblin": hero.mastery+=1
 hero.seed=(int(hero.seed)*48271)%2147483647
 if hero.seed%int(enemy.drop_chance)==0: hero.potions+=1
 while hero.xp>=int(hero.level)*70:
  hero.xp-=int(hero.level)*70
  hero.level+=1
  hero.points+=3
  notice="Level up! Three skill points earned."
func save_game():
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(hero))
func load_game():
 if FileAccess.file_exists(SAVE):
  var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  if data is Dictionary:
   var saved_position: Array=[]
   if data.get("journey") is Dictionary and data.journey.get("position") is Array:
    saved_position=data.journey.position.duplicate()
   for key in hero:
    if data.has(key): hero[key]=merge_defaults(hero[key],normalize(data[key]))
   if saved_position.size()==3: hero.journey.position=[float(saved_position[0]),float(saved_position[1]),float(saved_position[2])]
   var pos=hero.journey.position
   return_position=Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
func can_mythic(class_name_: String) -> bool:
 return hero.primary==class_name_ and int(hero.investments.get(class_name_,0))>=3

func normalize(value):
 if value is float: return int(value)
 if value is Dictionary:
  for key in value: value[key]=normalize(value[key])
 elif value is Array:
  for i in range(value.size()): value[i]=normalize(value[i])
 return value

func merge_defaults(default, value):
 if default is Dictionary and value is Dictionary:
  for key in default:
   if value.has(key): default[key]=merge_defaults(default[key],value[key])
  return default
 return value
func travel_scene() -> String:
 return "res://scenes/dungeon.tscn" if hero.journey.region=="dungeon" else "res://scenes/world.tscn"
func restore():
 hero.hp=stats().max_hp
 hero.mp=stats().max_mp

func remember_position(pos: Vector3):
 return_position=pos
 hero.journey.position=[pos.x,pos.y,pos.z]
