class_name Combat
extends RefCounted
var classes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
var h: Dictionary
var stats: Dictionary
var enemy: Dictionary
var species="goblin"
var charging=false
var chemistry: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chemistry.json"))
var companion_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/companions.json"))
var nature_blessing=0
var enemy_stun=0
var regeneration=0
var regeneration_cast=false
var bleed=0
var demo_rules=false
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
 demo_rules=h.get("profile",{}).get("economy",false)
 var record: Dictionary=h.companion.get("records",{}).get(h.companion.get("current","intro_wolf"),{})
 if not record.is_empty(): wolf_hp=int(record.get("hp",55))
 elif demo_rules: wolf_hp=int(h.companion.get("intro_hp",55))
 stats=attributes.duplicate()
 rng=RandomNumberGenerator.new()
 rng.seed=int(h.seed)
func damage(power: int, defense: int) -> int:
 return maxi(1,power-defense)
func cost(action: String) -> int:
 if demo_rules: return int(AbilityBook.entry(action).get("mp",0))
 return {"Sacred Strike":7,"Hunter's Mark":4,"Thornbind":6,"Regrowth":8,"Dawn Avatar":15,"Wild Hunt":15,"Ancient Grove":15}.get(action,0)
func legal(action: String) -> bool:
 if demo_rules:
  var entry=AbilityBook.entry(action)
  if entry.is_empty() or h.mp<entry.mp: return false
  if entry.get("weapon","")=="sword" and h.equipment.Weapon=="None": return false
  if entry.get("shield",false) and h.equipment.Shield=="None": return false
  if entry.kind in ["spell","mythic"] and not AbilityBook.spells(h).has(AbilityBook.id_for(action)): return false
  return entry.effect!="potion" or h.potions>0
 if h.mp<cost(action): return false
 for c in classes:
  if classes[c].mythic==action:
   return h.primary==c and h.get("skills",{}).get(c,[]).has("mythic")
 if action not in ["Attack","Sword Slash","Shield Bash","Sacred Strike","Hunter's Mark","Thornbind","Regrowth","Items","Defend"]: return false
 return action!="Items" or h.potions>0
func emit(actor: String, target: String, amount: int, label: String):
 events.append({"actor":actor,"target":target,"amount":amount,"text":label,"state":{"hp":int(h.hp),"mp":int(h.mp),"wolf_hp":wolf_hp,"enemy_hp":enemy_hp,"statuses":status_summary()}})
func hit_enemy(actor: String, power: int, label: String):
 var amount=damage(power,int(enemy.defense))+(6 if marked>0 else 0)
 enemy_hp=maxi(0,enemy_hp-amount)
 emit(actor,"Goblin",amount,label)
func hero_turn(action: String):
 if demo_rules:
  demo_hero_turn(action)
  return
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
 if demo_rules and h.companion.get("current","intro_wolf")!="intro_wolf":
  companion_turn()
  return
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
 if enemy_stun>0:
  enemy_stun-=1
  emit("Goblin","Goblin",0,"Stunned; loses turn")
  return
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
  if demo_rules and h.companion.current=="griffin" and rng.randf()<0.15:
   emit("Goblin","Wolf",0,"Aerial evasion")
   return
  var amount=damage(power,8 if demo_rules and h.companion.current=="golem" else 5)
  wolf_hp=maxi(0,wolf_hp-amount)
  emit("Goblin","Wolf",amount,"Crushing Canopy" if heavy else ("Briar lash" if species!="goblin" else "Goblin club"))
 else:
  var amount=damage(power,int(stats.defense))
  if guarding:
   amount=maxi(1,amount/2)
   if demo_rules and h.equipment.Shield!="None": prime_chemistry()
  if wolf_guard: amount=maxi(1,amount/(3 if companion_skills().has("guardian") else 2))
  h.hp=maxi(0,int(h.hp)-amount)
  emit("Goblin","Hero",amount,"Crushing Canopy" if heavy else ("Briar lash" if species!="goblin" else "Goblin club"))
func round_(action: String) -> Array:
 action=AbilityBook.name_for(action)
 events=[]
 regeneration_cast=false
 if outcome!="" or not legal(action): return events
 guarding=false
 wolf_guard=false
 turns+=1
 var order=[{"id":"Hero","speed":stats.speed},{"id":"Wolf","speed":companion_speed()},{"id":"Goblin","speed":int(enemy.speed)}]
 for index in range(order.size()): order[index].tie=index
 order.sort_custom(func(a,b): return a.speed>b.speed if a.speed!=b.speed else a.tie<b.tie)
 for unit in order:
  if enemy_hp<=0 or h.hp<=0: break
  match unit.id:
   "Hero": hero_turn(action)
   "Wolf": wolf_turn()
   "Goblin": enemy_turn()
 if demo_rules and enemy_hp>0 and h.hp>0:
  if regeneration>0 and not regeneration_cast:
   regeneration-=1
   heal(12+int(stats.get("healing",0)),"Regrowth · renewal")
  if bleed>0:
   bleed-=1
   enemy_hp=maxi(0,enemy_hp-5)
   emit("Wolf","Goblin",5,"Bleeding")
 if nature_blessing>0: nature_blessing-=1
 if marked>0: marked-=1
 if enemy_hp<=0: outcome="Victory"
 elif h.hp<=0: outcome="Defeat"
 if demo_rules:
  if h.companion.get("records",{}).has(h.companion.current): h.companion.records[h.companion.current].hp=wolf_hp
  else: h.companion.intro_hp=wolf_hp
 h.seed=rng.state % 2147483647
 return events.duplicate(true)
func auto_resolve() -> String:
 while outcome=="" and turns<200:
  var action="Attack"
  if h.hp<stats.max_hp/2 and legal("Regrowth"): action="Regrowth"
  elif legal("Sacred Strike"): action="Sacred Strike"
  round_(action)
 if outcome=="": outcome="Defeat"
 return outcome

func companion_skills() -> Array:
 return h.companion.get("records",{}).get(h.companion.get("current","intro_wolf"),{}).get("skills",[])
func heal(power: int, label: String):
 var healed=mini(power,int(stats.max_hp)-int(h.hp))
 h.hp+=healed
 emit("Hero","Hero",-healed,label)
func prime_chemistry():
 var active: Array=h.secondary.duplicate()
 active.append(h.primary)
 var ids=active.map(func(value): return str(value).to_lower())
 for rule in chemistry:
  if rule.trigger!="shield_block": continue
  var matches=true
  for class_ in rule.classes:
   if not ids.has(class_): matches=false
  if matches:
   nature_blessing=int(rule.duration)+1
   emit("Hero","Hero",0,rule.name+" · blessing ready")
func consume_blessing(id: String) -> int:
 if nature_blessing<=0: return 0
 for rule in chemistry:
  if rule.consumers.has(id):
   nature_blessing=0
   emit("Hero","Hero",0,rule.name+" · empowered")
   return int(rule.bonus)
 return 0
func demo_hero_turn(action: String):
 var id=AbilityBook.id_for(action)
 var entry=AbilityBook.entry(id)
 h.mp-=int(entry.mp)
 var blessing=consume_blessing(id)
 var power=int(stats.attack)+int(entry.get("power",0))+blessing
 if h.equipment.Weapon=="None": power-=8
 match entry.effect:
  "guard":
   guarding=true
   emit("Hero","Hero",0,"Shield raised")
  "potion":
   h.potions-=1
   heal(45,"Potion")
  "heal": heal(int(entry.power)+int(stats.healing),action)
  "regrowth":
   heal(int(entry.power)+int(stats.healing)+blessing,action)
   regeneration=int(entry.duration)
   regeneration_cast=true
  "mark":
   marked=int(entry.duration)+1
   hit_enemy("Hero",int(stats.attack)/2+blessing,action)
  "root":
   hit_enemy("Hero",power,action)
   if rng.randf()<float(entry.chance): bound=1
   emit("Hero","Goblin",0,"Rooted for one turn" if bound else "Roots resisted")
  "bash":
   hit_enemy("Hero",power,action)
   guarding=true
   var chance=float(entry.chance)+(0.2 if h.weapon_skills.shield.has("impact") else 0.0)
   if rng.randf()<chance: enemy_stun=1
   emit("Hero","Goblin",0,"Stunned for one turn" if enemy_stun else "Stun resisted")
  _:
   if id=="sword_slash" and h.weapon_skills.sword.has("flow"): power+=4
   hit_enemy("Hero",power,action)
func companion_turn():
 if wolf_hp<=0 or not h.companion.active: return
 var id: String=h.companion.current
 var data: Dictionary=companion_data[id]
 var record: Dictionary=h.companion.records[id]
 var skills=companion_skills()
 var active: Array=h.secondary.duplicate()
 active.append(h.primary)
 var synergy=0
 for class_ in active:
  if data.synergy_classes.has(str(class_).to_lower()): synergy=int(data.synergy_bonus)
 match h.companion.behavior:
  "Support":
   var healed=mini(int(data.support)+synergy+(6 if skills.has("bond") else 0),int(stats.max_hp)-int(h.hp))
   h.hp+=healed
   if id=="spirit_fox": regeneration=maxi(regeneration,1)
   emit("Wolf","Hero",-healed,data.name+" · support")
  "Defend":
   wolf_guard=true
   emit("Wolf","Hero",0,data.name+" · protection")
  _:
   var power=int(data.attack)+synergy+int(record.level)*2+int(stats.get("wolf_attack",0))+(4 if skills.has("predator") else 0)
   hit_enemy("Wolf",power,data.name+" · "+{"dire_wolf":"Rending bite","griffin":"Wind dive","dragon":"Ember breath","warhorse":"Charge","spirit_fox":"Spirit spark","golem":"Earth fist"}[id])
   if id=="dire_wolf": bleed=2
   if id=="golem" and rng.randf()<0.2: enemy_stun=1
func status_summary() -> String:
 var labels: Array=[]
 if marked>0: labels.append("Marked %s" % marked)
 if bound>0: labels.append("Rooted %s" % bound)
 if enemy_stun>0: labels.append("Stunned %s" % enemy_stun)
 if regeneration>0: labels.append("Regrowth %s" % regeneration)
 if nature_blessing>0: labels.append("Nature blessing %s" % nature_blessing)
 if bleed>0: labels.append("Bleeding %s" % bleed)
 return " · ".join(labels) if not labels.is_empty() else "No active status effects"

func companion_speed() -> int:
 return int(companion_data.get(h.companion.get("current","intro_wolf"),{"speed":15}).speed) if demo_rules else 15
