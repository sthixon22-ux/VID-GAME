extends Node
const SAVE = "user://hero.json"
var classes: Dictionary = {}
var hero: Dictionary
var notice = ""
func _ready():
 classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
 reset()
 load_game()
func reset():
 hero = {"level":1,"xp":0,"hp":110,"mp":35,"gold":0,"points":3,"primary":"Paladin","secondary":["Ranger","Druid"],"investments":{"Paladin":0,"Ranger":0,"Druid":0},"equipment":{"Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"None","Chest":"Steel Cuirass","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"},"companion":{"selected":0,"behavior":"Attack","active":true,"roster":["Wolf",null,null,null,null,null],"postgame":null},"mastery":0,"potions":5,"seed":137}
func stats() -> Dictionary:
 var l = int(hero.level)
 var e: Dictionary = hero.equipment
 return {"max_hp":100+l*10,"max_mp":30+l*5+int(hero.investments.Druid)*2,"attack":12+l*3+int(hero.investments.Paladin)+int(hero.investments.Ranger)+(8 if e.Weapon=="Iron Sword" else 14),"defense":4+l+(5 if e.Shield!="None" else 0)+(6 if e.Chest=="Steel Cuirass" else 2)+armor_bonus(),"speed":12+l}
func armor_bonus() -> int:
 var total=0
 for slot in ["Helmet","Gauntlets","Pants","Boots","Accessory"]:
  if hero.equipment[slot]!="None": total+=2
 return total
func reward(normal: bool):
 hero.xp+=35
 hero.gold+=18
 if normal: hero.mastery+=1
 hero.seed=(int(hero.seed)*48271)%2147483647
 if hero.seed%3==0: hero.potions+=1
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
   for key in hero:
    if data.has(key): hero[key]=normalize(data[key])
func can_mythic(class_name_: String) -> bool:
 return hero.primary==class_name_ and int(hero.investments.get(class_name_,0))>=3

func normalize(value):
 if value is float: return int(value)
 if value is Dictionary:
  for key in value: value[key]=normalize(value[key])
 elif value is Array:
  for i in range(value.size()): value[i]=normalize(value[i])
 return value
