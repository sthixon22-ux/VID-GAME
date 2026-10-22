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
var buffs: Dictionary={}
var cooldowns: Dictionary={}
var companion_cooldowns:Dictionary={}
var poison=0
var weakened=0
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
 if GameRules.two_handed(AbilityBook.gear_data.get(h.equipment.Weapon,{})): h.equipment.Shield="None"
 demo_rules=h.get("profile",{}).get("economy",false)
 var record: Dictionary=h.companion.get("records",{}).get(h.companion.get("current","intro_wolf"),{})
 if not record.is_empty(): wolf_hp=int(record.get("hp",55))
 elif demo_rules: wolf_hp=int(h.companion.get("intro_hp",55))
 stats=attributes.duplicate()
 stats.agility=int(stats.get("agility",stats.get("speed",1)))
 stats.dexterity=int(stats.get("dexterity",0))
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
  var family=AbilityBook.weapon_type(h)
  if cooldowns.get(AbilityBook.id_for(action),0)>0: return false
  if entry.has("weapon_node") and not AbilityBook.techniques(h).has(AbilityBook.id_for(action)): return false
  if not entry.get("weapon_types",[]).is_empty() and (not entry.weapon_types.has(family) or not AbilityBook.proficient(h,family)): return false
  if entry.get("weapon","")=="sword" and (family!="sword" or not AbilityBook.proficient(h,"sword")): return false
  if entry.get("shield",false) and (h.equipment.Shield=="None" or not AbilityBook.proficient(h,"shield")): return false
  if entry.kind in ["spell","mythic","technique"] and not AbilityBook.available(h).has(AbilityBook.id_for(action)): return false
  return entry.effect!="potion" or h.potions>0
 if h.mp<cost(action): return false
 for c in classes:
  if classes[c].mythic==action:
   return h.primary==c and h.get("skills",{}).get(c,[]).has("mythic")
 if action not in ["Attack","Sword Slash","Shield Bash","Sacred Strike","Hunter's Mark","Thornbind","Regrowth","Items","Defend"]: return false
 return action!="Items" or h.potions>0
func emit(actor: String, target: String, amount: int, label: String):
 events.append({"actor":actor,"target":target,"amount":amount,"text":label,"state":{"hp":int(h.hp),"mp":int(h.mp),"wolf_hp":wolf_hp,"enemy_hp":enemy_hp,"statuses":status_summary()}})
func hit_enemy(actor: String, power: int, label: String) -> bool:
 var entry=AbilityBook.entry(label)
 var physical=actor=="Wolf" or entry.get("kind","") in ["attack","weapon","technique"]
 if physical and int(enemy.get("dexterity",0))>0 and rng.randf()<GameRules.dodge_chance(int(enemy.dexterity)):
  emit(actor,"Goblin",0,"Dodged")
  return false
 var amount=damage(power,maxi(0,int(enemy.defense)-(5 if weakened>0 else 0)))+(6 if marked>0 else 0)
 if demo_rules and actor=="Hero" and physical and rng.randf()<GameRules.critical_chance(current_stat("critical")):
  amount=ceili(amount*1.5)
  label+=" · Critical!"
 enemy_hp=maxi(0,enemy_hp-amount)
 emit(actor,"Goblin",amount,label)
 return true
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
 if species=="reliquary_keeper" and turns%3==1 and not charging:
  charging=true
  emit("Goblin","Goblin",0,"The crown fills with water! Oathbreaker Tide next turn — DEFEND!")
  return
 if species=="warden" and turns%3==2 and not charging:
  charging=true
  emit("Goblin","Goblin",0,"Branches coil! Crushing Canopy next turn — DEFEND!")
  return
 if enemy.get("behavior","")=="guard" and turns%3==1:
  enemy_hp=mini(int(enemy.hp),enemy_hp+12)
  emit("Goblin","Goblin",-12,"Silt mends the sentinel")
  return
 var heavy=charging
 charging=false
 var power=int(enemy.attack)-(5 if weakened>0 else 0)+rng.randi_range(-3,3)+(22 if heavy else 0)
 if enemy.get("behavior","")=="ambush" and turns==1:power+=6
 var attack_label="Oathbreaker Tide" if heavy and species=="reliquary_keeper" else ("Crushing Canopy" if heavy else str(enemy.get("attack_name","Briar lash" if species!="goblin" else "Goblin club")))
 if not heavy and wolf_hp>0 and h.companion.active and rng.randi_range(0,3)==0:
  if demo_rules and h.companion.current=="griffin" and rng.randf()<0.15:
   emit("Goblin","Wolf",0,"Aerial evasion")
   return
  var amount=damage(power,8 if demo_rules and h.companion.current=="golem" else 5)
  wolf_hp=maxi(0,wolf_hp-amount)
  emit("Goblin","Wolf",amount,attack_label)
 else:
  if rng.randf()<GameRules.dodge_chance(current_stat("dexterity")):
   emit("Goblin","Hero",0,"Dodged")
   return
  var amount=damage(power,current_stat("defense"))
  if guarding:
   amount=maxi(1,amount/2)
   if demo_rules and h.equipment.Shield!="None": prime_chemistry()
  if wolf_guard: amount=maxi(1,amount/(3 if companion_skills().has("guardian") else 2))
  h.hp=maxi(0,int(h.hp)-amount)
  emit("Goblin","Hero",amount,attack_label)
 if species=="mire_leech" and enemy_hp>0:
  var restored=mini(6,int(enemy.hp)-enemy_hp)
  enemy_hp+=restored
  emit("Goblin","Goblin",-restored,"Siphoned vitality")
 if species=="bog_wisp" and turns%2==0:
  h.mp=maxi(0,int(h.mp)-3)
  emit("Goblin","Hero",0,"Lantern siphon · 3 MP drained")
func round_(action: String) -> Array:
 action=AbilityBook.name_for(action)
 events=[]
 regeneration_cast=false
 if outcome!="" or not legal(action): return events
 guarding=action=="Defend"
 wolf_guard=false
 turns+=1
 var order=[{"id":"Hero","speed":current_stat("agility")},{"id":"Wolf","speed":companion_speed()},{"id":"Goblin","speed":int(enemy.get("agility",enemy.get("speed",1)))}]
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
 if poison>0 and enemy_hp>0 and h.hp>0:
  poison-=1
  enemy_hp=maxi(0,enemy_hp-5)
  emit("Hero","Goblin",5,"Poison")
 if weakened>0: weakened-=1
 for key in buffs.keys():
  buffs[key].rounds-=1
  if buffs[key].rounds<=0: buffs.erase(key)
 for id in cooldowns: cooldowns[id]=maxi(0,int(cooldowns[id])-1)
 for id in companion_cooldowns:companion_cooldowns[id]=maxi(0,int(companion_cooldowns[id])-1)
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
  var action=auto_action()
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
 var power=current_stat("attack")+int(entry.get("power",0))+blessing
 if h.equipment.Weapon=="None" and not AbilityBook.proficient(h,"unarmed"): power-=8
 if entry.kind in ["weapon","technique"] and h.weapon_skills.get(AbilityBook.weapon_type(h),[]).has("flow"): power+=4
 match entry.effect:
  "buff":
   buffs[entry.stat]={"amount":int(entry.power),"rounds":int(entry.duration)+1}
   emit("Hero","Hero",0,action+" · "+str(entry.stat)+" increased")
  "meditate":
   h.mp=mini(int(stats.max_mp),int(h.mp)+int(entry.power))
   heal(5,action)
   cooldowns[id]=int(entry.cooldown)+1
  "renewal":
   heal(int(entry.power)+int(stats.healing),action)
   regeneration=int(entry.duration)
   regeneration_cast=true
  "weaken":
   weakened=int(entry.duration)+1
   emit("Hero","Goblin",0,action+" · attack/defense weakened")
  "poison":
   if hit_enemy("Hero",power,action): poison=int(entry.duration)
  "execute": hit_enemy("Hero",power+(12 if marked>0 or poison>0 else 0),action)
  "pierce": hit_enemy("Hero",power+int(enemy.defense)/2,action)
  "rage":
   h.hp=maxi(1,int(h.hp)-int(entry.get("self_damage",0)))
   hit_enemy("Hero",power,action)
  "magic", "frost", "drain":
   var magic=int(entry.power)+int(stats.max_mp)*0.18+int(h.level)*1.5
   var before=enemy_hp
   hit_enemy("Hero",int(magic),action)
   if entry.effect=="drain": heal((before-enemy_hp)/2,action+" · drain")
   if entry.effect=="frost" and rng.randf()<float(entry.chance): bound=1
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
   var landed=hit_enemy("Hero",power,action)
   guarding=true
   var chance=float(entry.chance)+(0.2 if h.weapon_skills.shield.has("impact") else 0.0)
   if landed and rng.randf()<chance: enemy_stun=1
   emit("Hero","Goblin",0,"Stunned for one turn" if enemy_stun else "Stun resisted")
  _:
   hit_enemy("Hero",power,action)
func companion_turn():
 if wolf_hp<=0 or not h.companion.active:return
 var id:String=h.companion.current
 var data:Dictionary=companion_data[id]
 var record:Dictionary=h.companion.records[id]
 var chosen=""
 for ability in CompanionRules.learned_abilities(h):
  var entry:Dictionary=data.abilities[ability]
  var useful=not (entry.effect in ["heal","renewal"] and h.hp>=stats.max_hp) and not (entry.effect=="mana" and h.mp>=stats.max_mp)
  if useful and entry.behavior==h.companion.behavior and int(companion_cooldowns.get(ability,0))==0:chosen=ability
 if not chosen.is_empty():
  companion_ability(chosen)
  return
 var synergy=0
 for class_ in [h.primary]+h.secondary:
  if data.synergy_classes.has(str(class_).to_lower()):synergy=int(data.synergy_bonus)
 match h.companion.behavior:
  "Support":
   var healed=mini(int(data.support)+synergy+CompanionRules.pet_bonus(h,"support"),int(stats.max_hp)-int(h.hp))
   h.hp+=healed
   emit("Wolf","Hero",-healed,data.name+" · support")
  "Defend":
   wolf_guard=true
   emit("Wolf","Hero",0,data.name+" · protection")
  _:
   var power=int(data.attack)+synergy+int(record.level)*2+int(stats.get("wolf_attack",0))+CompanionRules.pet_bonus(h,"attack")
   hit_enemy("Wolf",power,data.name+" · strike")
func companion_ability(id:String):
 var data:Dictionary=companion_data[h.companion.current]
 var entry:Dictionary=data.abilities[id]
 var power=int(entry.power)
 companion_cooldowns[id]=int(entry.cooldown)+1
 match entry.effect:
  "heal","renewal":
   var amount=mini(power+CompanionRules.pet_bonus(h,"support"),int(stats.max_hp)-int(h.hp))
   h.hp+=amount
   if entry.effect=="renewal":regeneration=maxi(regeneration,3)
   emit("Wolf","Hero",-amount,entry.name)
  "mana":
   var amount=mini(power,int(stats.max_mp)-int(h.mp))
   h.mp+=amount
   emit("Wolf","Hero",0,entry.name+" · MP +%s" % amount)
  "buff_attack","buff_defense","buff_agility","buff_dexterity","ward":
   var stat="defense" if entry.effect=="ward" else str(entry.effect).trim_prefix("buff_")
   buffs[stat]={"amount":power,"rounds":4}
   if entry.effect=="ward":wolf_guard=true
   emit("Wolf","Hero",0,entry.name+" · "+stat+" increased")
  _:
   var attack=int(data.attack)+int(h.companion.records[h.companion.current].level)*2+power+CompanionRules.pet_bonus(h,"attack")
   if entry.effect=="pierce":attack+=int(enemy.defense)/2
   var landed=hit_enemy("Wolf",attack,entry.name)
   if landed and entry.effect=="bleed":bleed=3
   if landed and entry.effect=="stun":enemy_stun=1
func status_summary() -> String:
 var labels: Array=[]
 if marked>0: labels.append("Marked %s" % marked)
 if bound>0: labels.append("Rooted %s" % bound)
 if enemy_stun>0: labels.append("Stunned %s" % enemy_stun)
 if regeneration>0: labels.append("Regeneration %s" % regeneration)
 if nature_blessing>0: labels.append("Nature blessing %s" % nature_blessing)
 if bleed>0: labels.append("Bleeding %s" % bleed)
 if poison>0: labels.append("Poison %s" % poison)
 if weakened>0: labels.append("Weakened %s" % weakened)
 for stat in buffs: labels.append("%s +%s (%s)" % [stat.capitalize(),buffs[stat].amount,buffs[stat].rounds])
 return " · ".join(labels) if not labels.is_empty() else "No active status effects"

func companion_speed() -> int:
 return int(companion_data.get(h.companion.get("current","intro_wolf"),{"speed":15}).speed) if demo_rules else 15

func current_stat(key: String) -> int:
 return int(stats.get(key,0))+int(buffs.get(key,{}).get("amount",0))
func auto_action() -> String:
 if not demo_rules:
  if h.hp<stats.max_hp/2 and legal("Regrowth"): return "Regrowth"
  if legal("Sacred Strike"): return "Sacred Strike"
  return "Attack"
 if charging: return "Defend"
 if h.hp<stats.max_hp/2:
  for id in ["healing_light","regrowth","purifying_light"]:
   if legal(id) and (id!="regrowth" or regeneration==0): return id
  if legal("items"): return "Items"
 var candidates=AbilityBook.available(h)+AbilityBook.techniques(h)
 var best="Attack"
 var score=0.0
 for id in candidates:
  if not legal(id): continue
  var entry=AbilityBook.entry(id)
  if entry.effect not in ["damage","magic","drain","rage","execute","pierce","frost"]: continue
  var value=float(entry.get("power",0))
  if entry.effect in ["magic","drain","frost"]: value+=float(stats.max_mp)*0.18+float(h.level)*1.5-float(stats.attack)
  if value>score:
   score=value
   best=id
 return best
