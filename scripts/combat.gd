class_name Combat
extends RefCounted
var classes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
var h: Dictionary
var stats: Dictionary
var enemy: Dictionary
var species="goblin"
var charging=false
var enemy_hp=85
var wolf_hp=55
var marked=0
var bound=0
var guarding=false
var wolf_guard=false
var turns=0
var events: Array = []
var outcome=""
var rng: RandomNumberGenerator
func _init(hero: Dictionary, attributes: Dictionary, species_: String="goblin"):
 species=species_
 var enemies: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 enemy=enemies[species].duplicate(true)
 enemy_hp=int(enemy.hp)
 h=hero.duplicate(true)
 stats=attributes.duplicate()
 rng=RandomNumberGenerator.new()
 rng.seed=int(h.seed)
func damage(power: int, defense: int) -> int:
 return maxi(1,power-defense)
func cost(action: String) -> int:
 return {"Sacred Strike":7,"Hunter's Mark":4,"Thornbind":6,"Regrowth":8,"Dawn Avatar":15,"Wild Hunt":15,"Ancient Grove":15}.get(action,0)
func legal(action: String) -> bool:
 if h.mp<cost(action): return false
 for c in classes:
  if classes[c].mythic==action:
   return h.primary==c and h.get("skills",{}).get(c,[]).has("mythic")
 if action not in ["Attack","Sword Slash","Shield Bash","Sacred Strike","Hunter's Mark","Thornbind","Regrowth","Items","Defend"]: return false
 return action!="Items" or h.potions>0
func emit(actor: String, target: String, amount: int, label: String):
 events.append({"actor":actor,"target":target,"amount":amount,"text":label,"state":{"hp":int(h.hp),"mp":int(h.mp),"wolf_hp":wolf_hp,"enemy_hp":enemy_hp}})
func hit_enemy(actor: String, power: int, label: String):
 var amount=damage(power,int(enemy.defense))+(6 if marked>0 else 0)
 enemy_hp=maxi(0,enemy_hp-amount)
 emit(actor,"Goblin",amount,label)
func hero_turn(action: String):
 h.mp-=cost(action)
 match action:
  "Defend":
   guarding=true
   emit("Hero","Hero",0,"Shield raised")
  "Items":
   h.potions-=1
   var healed=mini(45,stats.max_hp-int(h.hp))
   h.hp+=healed
   emit("Hero","Hero",-healed,"Potion")
  "Regrowth", "Ancient Grove":
   var healed=mini((40 if action=="Regrowth" else 75)+int(stats.get("healing",0)),stats.max_hp-int(h.hp))
   h.hp+=healed
   emit("Hero","Hero",-healed,action)
  "Hunter's Mark":
   marked=4
   hit_enemy("Hero",int(stats.attack)/2,action)
  "Thornbind":
   bound=2
   hit_enemy("Hero",int(stats.attack),action)
  _:
   var bonus={"Attack":0,"Sword Slash":5,"Shield Bash":2,"Sacred Strike":13,"Dawn Avatar":32,"Wild Hunt":32}.get(action,0)
   hit_enemy("Hero",int(stats.attack)+bonus,action)
   if action=="Shield Bash": guarding=true
func wolf_turn():
 if wolf_hp<=0 or not h.companion.active: return
 match h.companion.behavior:
  "Support":
   var healed=mini(12,stats.max_hp-int(h.hp))
   h.hp+=healed
   emit("Wolf","Hero",-healed,"Wolf's encouragement")
  "Defend":
   wolf_guard=true
   emit("Wolf","Hero",0,"Wolf protects you")
  _: hit_enemy("Wolf",12+int(h.level)*2+int(stats.get("wolf_attack",0)),"Wolf bite")
func enemy_turn():
 if bound>0:
  bound-=1
  emit("Goblin","Goblin",0,"Entangled; loses turn")
  return
 if species=="warden" and turns%3==2 and not charging:
  charging=true
  emit("Goblin","Goblin",0,"Branches coil! Crushing Canopy next turn — DEFEND!")
  return
 var heavy=charging
 charging=false
 var power=int(enemy.attack)+rng.randi_range(-3,3)+(22 if heavy else 0)
 if not heavy and wolf_hp>0 and h.companion.active and rng.randi_range(0,3)==0:
  var amount=damage(power,5)
  wolf_hp=maxi(0,wolf_hp-amount)
  emit("Goblin","Wolf",amount,"Crushing Canopy" if heavy else ("Briar lash" if species!="goblin" else "Goblin club"))
 else:
  var amount=damage(power,int(stats.defense))
  if guarding: amount=maxi(1,amount/2)
  if wolf_guard: amount=maxi(1,amount/2)
  h.hp=maxi(0,int(h.hp)-amount)
  emit("Goblin","Hero",amount,"Crushing Canopy" if heavy else ("Briar lash" if species!="goblin" else "Goblin club"))
func round_(action: String) -> Array:
 events=[]
 if outcome!="" or not legal(action): return events
 guarding=false
 wolf_guard=false
 turns+=1
 var order=[{"id":"Hero","speed":stats.speed},{"id":"Wolf","speed":15},{"id":"Goblin","speed":int(enemy.speed)}]
 order.sort_custom(func(a,b): return a.speed>b.speed)
 for unit in order:
  if enemy_hp<=0 or h.hp<=0: break
  match unit.id:
   "Hero": hero_turn(action)
   "Wolf": wolf_turn()
   "Goblin": enemy_turn()
 if marked>0: marked-=1
 if enemy_hp<=0: outcome="Victory"
 elif h.hp<=0: outcome="Defeat"
 h.seed=rng.state % 2147483647
 return events.duplicate(true)
func auto_resolve() -> String:
 while outcome=="" and turns<200:
  var action="Attack"
  if h.hp<stats.max_hp/2 and h.mp>=8: action="Regrowth"
  elif h.mp>=7: action="Sacred Strike"
  round_(action)
 if outcome=="": outcome="Defeat"
 return outcome
